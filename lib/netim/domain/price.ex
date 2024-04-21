defmodule Netim.Domain.Price do
  @moduledoc """
  The price information for the queried domain.
  """
  use TypedEctoSchema

  @boolean [true: 1, false: 0]

  @primary_key false

  @typedoc """
  Each domain has the following information about the fees:

  - `domain` the name of the domain
  - `currency_fee` the currency code used for specifying the prices
  - `registration_fee` the price for register a new domain
  - `renewal_fee` the price for renewal an existing domain
  - `transfer_fee` the price for transfer to Netim an existing domain
  - `trade_fee` the price for trading the domain
  - `transfer_trade_fee` the price for trading transfer (sell) a domain
  - `restore_fee` the price for restore a domain
  - `trustee_service_fee` the price for the Trustee Service
  - `local_contact_service_fee` the price for the Contact Service
  - `premium?` is that a premium domain?
  """
  typed_embedded_schema do
    field(:domain, :string, primary_key: true)
    field(:currency_fee, :string, source: :FeeCurrency)
    field(:registration_fee, :decimal, source: :Fee4Registration)
    field(:renewal_fee, :decimal, source: :Fee4Renewal)
    field(:transfer_fee, :decimal, source: :Fee4Transfer)
    field(:trade_fee, :decimal, source: :Fee4Trade)
    field(:transfer_trade_fee, :decimal, source: :Fee4TransferTrade)
    field(:restore_fee, :decimal, source: :Fee4Restore)
    field(:trustee_service_fee, :decimal, source: :Fee4TrusteeService)
    field(:local_contact_service_fee, :decimal, source: :Fee4LocalContactService)
    field(:premium?, Ecto.Enum, values: @boolean, source: :IsPremium)
  end

  @doc """
  Perform a conversion of a parameters provided by Netim to
  the struct defined in its module.
  """
  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
