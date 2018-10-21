defmodule Rumbl.InfoSys do
  @moduledoc """
    Generic module to spawn computations for queries. Each backend is its own process, but
    InfoSys isn't
  """
  alias Rumbl.InfoSys

  # List of backends that are supported
  @backends [InfoSys.Wolfram]

  # Define Result struct to hold each search result
  # :score for storing relevance, :text to describe result, :url for the URL it came from,
  # and :backend to use for the computation
  defmodule Result do
    defstruct score: 0, text: nil, url: nil, backend: nil
  end

  alias Rumbl.InfoSys.Cache

  # Main entry point for our service
  def compute(query, opts \\ []) do
    timeout = opts[:timeout] || 10_000
    opts = Keyword.put_new(opts, :limit, 10)
    backends = opts[:backends] || @backends

    {uncached_backends, cached_results} = fetch_cached_results(backends, query, opts)

    # maps over all backends and calls async_query for each backet
    uncached_backends
    |> Enum.map(&async_query(&1, query, opts))
    # will wait for results
    |> Task.yield_many(timeout)
    # map over each result that comes in task-result tuple
    # Shortcircuited evaluation for res, if res is nil process the right side
    #   to shutdown the task with the :brutal_kill option "immediate shutdown"
    #   without waiting for compeltion.
    # This also protects us from a race condition. A task could complete between
    #   when we yield_many and when we process results
    |> Enum.map(fn {task, res} -> res || Task.shutdown(task, :brutal_kill) end)
    # Task either returns :ok or :error, we ignore errors by returning []
    |> Enum.flat_map(fn
      {:ok, results} -> results
      _ -> []
    end)
    |> write_results_to_cache(query, opts)
    # Concatenates with cached_results
    |> Kernel.++(cached_results)
    # sort results by score and report top ones
    |> Enum.sort(&(&1.score >= &2.score))
    # return up to client specified limit
    |> Enum.take(opts[:limit])
  end

  # Function to take all backends and accumulate the cached results for the given
  # query, as well as backends which contain no cached information.
  #
  # This way we can return both cached result set as well as the remaing backends
  # that need fresh queries
  defp fetch_cached_results(backends, query, opts) do
    {uncached_backends, results} =
      Enum.reduce(
        backends,
        {[], []},
        fn backend, {uncached_backends, acc_results} ->
          case Cache.fetch({backend.name(), query, opts[:limit]}) do
            {:ok, results} -> {uncached_backends, [results | acc_results]}
            :error -> {[backend | uncached_backends], acc_results}
          end
        end
      )

    {uncached_backends, List.flatten(results)}
  end

  defp write_results_to_cache(results, query, opts) do
    Enum.map(results, fn %Result{backend: backend} = result ->
      :ok = Cache.put({backend.name(), query, opts[:limit]}, result)

      result
    end)
  end

  # spawn off a task to do the work
  defp async_query(backend, query, opts) do
    # spawns a task in a new process, async_noling spawns it isolated from our caller, allowing
    # clients to query backends and not be worried about a crash or unexpected error.
    Task.Supervisor.async_nolink(InfoSys.TaskSupervisor, backend, :compute, [query, opts],
      shutdown: :brutal_kill
    )
  end
end
