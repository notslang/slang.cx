# A Cleaner Way to Organize Ecto Schema Fields

When you [generate](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.html) a new schema in a Phoenix project, you will get something like this:

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :favorite_color, :string
    field :name, :string
    field :total_pets, :integer

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :favorite_color, :total_pets])
    |> validate_required([:email, :name])
    |> unique_constraint(:email)
  end
end
```

The fields `favorite_color` and `total_pets` have been removed from `validate_required` because our users can sign up without divulging that information. They are optional fields. In this fictional application, all we require is their email and name.

This code is fine, but there's a little redundancy in the changeset function. The email and name fields are repeated in `cast` and `validate_required`. Usually, you need to cast a field *before* it can be required. Also, it's not immediately obvious that `favorite_color` and `total_pets` are optional. You need to compare the casted fields with the required fields.

That isn't a problem when you only have 4 fields, but in a schema with 20 fields, it's a mess.

I like to write schemas like this:

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(email name)a
  @optional_fields ~w(favorite_color total_pets)a

  schema "users" do
    field :email, :string
    field :favorite_color, :string
    field :name, :string
    field :total_pets, :integer

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:email)
  end
end
```

Now it's explicit which fields are optional vs required and they're listed clearly at the top of the module.
