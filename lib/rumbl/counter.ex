defmodule Rumbl.Counter do
@moduledoc """
  Module that implements a Counter server as well as functions for itneracting with it as a client.

  The `client` serves as the API and exists only to send messages to the process that does the work.
  It's the `interface` for the counter. The `server` is a process that recursively loops, processing
  a message and sending updated state to itself. Our server is the `implementation`.
"""
  ##
  # Client API
  ##

  def inc(pid), do: send(pid, :inc)

  def dec(pid), do: send(pid, :dec)

  @doc """
    Function that sends a request for a value of the coutner and must await the response.

  """
  def val(pid, timeout \\ 5000) do
      # make_ref() creates a unique reference, thats just a value guaranteed to be globally unique,
      # to associate with the particular request
      ref = make_ref()
      send(pid, {:val, self(), ref})

      # Awaits for the response to match on the reference.
      receive do
        {^ref, val} -> val # ^ref means it is matching prev ref vs rebinding.
      after
        timeout -> exit(:timeout)
      end
  end

  ###
  # Server Implementation
  ###

  # `start_link` function required by OTP. Accepts only initial state, and its job is to spawn a
  # process and return {:ok, pid}, where pid it the identifier of the spawned process
  def start_link(initial_val) do
    {:ok, spawn_link(fn -> listen(initial_val) end)}
  end

  # Function that maintains state through recursive calls.
  # Each call to listen waits for a message and does the matching action before callint itself again.
  defp listen(val) do
    receive do
      :inc ->
        listen(val + 1)

      :dec ->
        listen(val - 1)

      {:val, sender, ref} ->
        send(sender, {ref, val})
        listen(val)
    end
  end
end
