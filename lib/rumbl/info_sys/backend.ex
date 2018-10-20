defmodule Rumbl.InfoSys.Backend do
  @moduledoc """
  Defines a backend interface.
  """
  # Since all our backends have the same contract, this is a good use cae for
  # behaviour. A behaviour is a contract, common API across modules.

  # typespec which defines two function that specify the name of our functions
  # and the type of values our functions will return
  # By convention, `t` macro returns types you'll use within individual typespecs
  @callback name() :: String.t()
  @callback compute(query :: String.t(), opts :: Keyword.t()) :: [Rumbl.InfoSys.Result.t()]
end
