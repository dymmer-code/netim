defmodule Netim.Contact.List do
  @moduledoc """
  Entry data for the list of contacts needed for the list contacts.
  """
  use TypedEctoSchema

  @primary_key false

  @body_forms [
    individual: "IND",
    organization: "ORG"
  ]

  @boolean [
    true: 1,
    false: 0
  ]

  @typedoc """
  Each entry is composed from the following fields:

  - `id` is the contact id (`idContact`)
  - `type` is the type of entity: individual or organization.
  - `name` is the name of the organization, if any.
  - `first_name` for the individual mainly.
  - `last_name` for the individual mainly.
  - `owner?` is the contact an owner or another kind of contact?
  """
  typed_embedded_schema do
    field(:id, :string, source: :idContact, primary_key: true)
    field(:type, Ecto.Enum, values: @body_forms, source: :bodyForm)
    field(:name, :string, source: :bodyName)
    field(:first_name, :string, source: :firstName)
    field(:last_name, :string, source: :lastName)
    field(:owner?, Ecto.Enum, values: @boolean, source: :isOwner)
  end

  @doc """
  Perform a conversion of a parameters provided by Netim to
  the struct defined in its module.
  """
  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
