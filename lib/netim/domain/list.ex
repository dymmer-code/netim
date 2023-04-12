defmodule Netim.Domain.List do
  use TypedEctoSchema

  @primary_key false
  typed_embedded_schema do
    field(:domain, :string, primary_key: true)
    field(:created_at, :date, source: :dateCreate)
    field(:expires_at, :date, source: :dateExpiration)
  end

  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
