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

  # Main entry point for our service
  def compute(query, opts \\ []) do
    opts = Keyword.put_new(opts, :limit, 10)
    backends = opts[:backends] || @backends
    # maps over all backends and calls async_query for each
    backends
    |> Enum.map(&async_query(&1, query, opts))
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
