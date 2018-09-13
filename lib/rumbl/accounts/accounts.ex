defmodule Rumbl.Accounts do
  @moduledoc """
  The Accounts context defines an interface to fetch user accounts in the system.
  """

  alias Rumbl.Accounts.User

  # !Temporarily hardcode Users
  def list_users do
    [
      %User{id: "1", name: "Jose", username: "josevalim"},
      %User{id: "2", name: "Bruce", username: "redrapids"},
      %User{id: "3", name: "Chris", username: "chrismccord"},
    ]
  end

  @doc """
  Returns a single user with matching id.
  """
  def get_user(id) do
    Enum.find(list_users(), fn map -> map.id == id end)
  end

  @doc """
  Returns a single user matching a single attribute or list of attributes.
  """
  def get_user_by(params) do
    Enum.find(list_users(), fn map ->
      Enum.all?(params, fn {key, val} -> Map.get(map, key) == val end)
    end)
  end
end
