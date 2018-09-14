defmodule Rumbl.Accounts.User do
  @moduledoc """
  Schema that defines a user.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :username, :string

    timestamps()
  end
end
