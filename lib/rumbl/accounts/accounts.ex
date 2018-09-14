defmodule Rumbl.Accounts do
  @moduledoc """
  The Accounts context defines an interface to fetch user accounts in the system.
  """

  alias Rumbl.Accounts.User

  alias Rumbl.Repo

  @doc """
  Returns a single user with matching id.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Raises an `Ecto.NotFoundError` if user does not exist.
  """
  def get_user!(id) do
    Repo.get!(User, id)
  end

  @doc """
  Returns a single user matching a single attribute or list of attributes.
  """
  def get_user_by(params) do
    Repo.get_by(User, params)
  end

  @doc """
  Returns a list of all users.
  """
  def list_users do
    Repo.all(User)
  end
end
