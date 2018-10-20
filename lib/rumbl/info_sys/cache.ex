defmodule Rumbl.InfoSys.Cache do
  use GenServer

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def put(name \\ __MODULE__, key, value) do
    true = :ets.insert(tab_name(name), {key, value})
    :ok
  end

  def fetch(name \\ __MODULE__, key) do
    {:ok, :ets.lookup_element(tab_name(name), key, 2)}
    # ETS throws an `ArgumentError` if we lookup a nonexistent key, we use rescue to
    # transform it to an error
  rescue
    ArgumentError -> :error
  end

  def init(opts) do
    {:ok, %{table: new_table(opts[:name])}}
  end

  # Creates and names our ETS table, ETS tables are woned by a single process
  # The table's existence lives and dies with that of its owner.
  defp new_table(name) do
    name
    |> tab_name()
    # set is a type of ETS table taht acts as a key-value store
    # named_table allows us to locate the table by its name
    # public lets processes other than the owner read and write values
    |> :ets.new([:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
  end

  # Function that simply returns atom of the table name to use for our ETS table
  defp tab_name(name), do: :"#{name}_cache"
end
