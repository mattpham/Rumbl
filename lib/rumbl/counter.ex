defmodule Rumbl.Counter do
  @moduledoc """
    Module that implements a Counter server as well as functions for itneracting with it as a client.

    The `client` serves as the API and exists only to send messages to the process that does the work.
    It's the `interface` for the counter. The `server` is a process that recursively loops, processing
    a message and sending updated state to itself. Our server is the `implementation`.
  """

  use GenServer

  ##
  # Client API
  ##

  # GenServer.cast does not return a value
  def inc(pid), do: GenServer.cast(pid, :inc)

  def dec(pid), do: GenServer.cast(pid, :dec)
  # GenServer.call with return the state of the server
  def val(pid), do: GenServer.call(pid, :val)

  ###
  # Server Implementation
  ###

  # `start_link` function required by OTP. Accepts only initial state, and its job is to spawn a
  # process and return {:ok, pid}, where pid it the identifier of the spawned process
  def start_link(initial_val) do
    GenServer.start_link(__MODULE__, initial_val)
  end

  def init(initial_val) do
    {:ok, initial_val}
  end

  def handle_cast(:inc, val) do
    {:noreply, val + 1}
  end

  def handle_cast(:dec, val) do
    {:noreply, val - 1}
  end

  # the arugument with a leading `_` is used to explicitely describe the argument while ignoreing
  # the contents
  def handle_call(:val, _from, val) do
    {:reply, val, val}
  end
end
