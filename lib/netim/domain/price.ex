defmodule Netim.Domain.Price do
  use TypedEctoSchema

  @boolean [true: 1, false: 0]

  @primary_key false
  typed_embedded_schema do
    field :domain, :string, primary_key: true
    field :currency_fee, :string, source: :FeeCurrency
    field :registration_fee, :decimal, source: :Fee4Registration
    field :renewal_fee, :decimal, source: :Fee4Renewal
    field :transfer_fee, :decimal, source: :Fee4Transfer
    field :trade_fee, :decimal, source: :Fee4Trade
    field :transfer_trade_fee, :decimal, source: :Fee4TransferTrade
    field :restore_fee, :decimal, source: :Fee4Restore
    field :trustee_service_fee, :decimal, source: :Fee4TrusteeService
    field :local_contact_service_fee, :decimal, source: :Fee4LocalContactService
    field :premium?, Ecto.Enum, values: @boolean, source: :IsPremium
  end

  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
