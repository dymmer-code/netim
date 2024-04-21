defmodule Netim.Domain.List do
  @moduledoc """
  Each element inside of a list of domains, it's not a lot of information
  indeed, you can see the `t/0` type.
  """
  use TypedEctoSchema

  @primary_key false

  @typedoc """
  The following cells are included for each row:

  - `domain` the domain name
  - `created_at` the date when the domain was created first time
    independently of the transfers it suffered.
  - `expires_at` the date when the domain expires.
  """
  typed_embedded_schema do
    field(:domain, :string, primary_key: true)
    field(:created_at, :date, source: :dateCreate)
    field(:expires_at, :date, source: :dateExpiration)
  end

  @doc """
  Perform a conversion of a parameters provided by Netim to
  the struct defined in its module.
  """
  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
