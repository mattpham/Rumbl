defmodule Rumbl.InfoSys.Supervisor do
  # We `use Supervisor` to prepare our code to use the Supervisor API. We're actually implementing a
  # behaviour, which is an API contract. Supervisors need to specify `start_link` function to start
  # the supervisor, and an `init` function to initialize each of the workers
  use Supervisor

  alias Rumbl.InfoSys

  def start_link(opts) do
    # `__MODULE__` is a compiler directive to pick up this current module's name
    # Default passes initial state of an empty list `[]` which we don't intent to use
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      # Genserver to define cache
      InfoSys.Cache,
      # Task supervisor to spawn tasks isolated under their own supervisor
      # We pass a name option to use to spawn our backend tasks
      {Task.Supervisor, name: InfoSys.TaskSupervisor},
    ]

    Supervisor.init(children, strategy: :rest_for:one)
  end
end
