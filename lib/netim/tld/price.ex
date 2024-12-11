defmodule Netim.Tld.Price do
  @moduledoc """
  Price for a domain under the specified TLD.
  """
  use TypedEctoSchema

  @primary_key false

  @typedoc """
  The price struct is giving information about the prices depending on
  what we want to do. The fields are:

  - `tld` the name of the TLD
  - `registration` the fee for the registration
  - `transfer` the fee for the transfer
  - `renewal` the fee for renew the domain
  - `restore` the fee for restoration the domain
  - `trade` the fee for trading the domain
  """
  typed_embedded_schema do
    field(:tld, :string, primary_key: true)
    field(:registration, :decimal, source: :Fee4Registration)
    field(:transfer, :decimal, source: :Fee4Transfer)
    field(:renewal, :decimal, source: :Fee4Renewal)
    field(:restore, :decimal, source: :Fee4Restore)
    field(:trade, :decimal, source: :Fee4Trade)
    field(:local_contact_service, :decimal, source: :Free4LocalContactService)
    field(:truee_service, :decimal, source: :Fee4TrusteeService)
  end
end
