defmodule Netim.Tld do
  use TypedEctoSchema
  require Logger
  alias Netim.Session

  @primary_key false
  typed_embedded_schema do
    field(:tld, :string, primary_key: true)
    field(:country, :string, source: :Country)
    field(:delai_renew_after_expiration, :integer, source: :DelaiRenewAfterExpiration)
    field(:delai_renew_before_expiration, :integer, source: :DelaiRenewBeforeExpiration)
    field(:delai_renew_after_delete, :integer, source: :DelaiRenewAfterDelete)

    embeds_many :extension, Extension, source: :Extensions, primary_key: false do
      field(:tld, {:array, :string})
      field(:type, Ecto.Enum, values: ~w[ popular regional functional ]a)
    end

    field(:local_contact_service_fee, :decimal, source: :Fee4LocalContactService)
    field(:registration_free, :decimal, source: :Fee4Registration)
    field(:renewal_fee, :decimal, source: :Fee4Renewal)
    field(:restore_fee, :decimal, source: :Fee4Renewal)
    field(:trade_fee, :decimal, source: :Fee4Trade)
    field(:transfer_fee, :decimal, source: :Fee4Transfer)
    field(:trustee_service_fee, :decimal, source: :Fee4TrusteeService)
    field(:currency_fee, :string, source: :FeeCurrency)
    field(:has_autorenew?, Ecto.Enum, values: [true: 1, false: 0], source: :HasAutorenew)
    field(:has_dns_sec?, Ecto.Enum, values: [true: 1, false: 0], source: :HasDnsSec)
    field(:has_epp_code?, Ecto.Enum, values: [true: 1, false: 0], source: :HasEppCode)

    field(:has_immediate_delete?, Ecto.Enum,
      values: [true: 1, false: 0],
      source: :HasImmediateDelete
    )

    field(:has_local_contact_service?, Ecto.Enum,
      values: [true: 1, false: 0],
      source: :HasLocalContactService
    )

    field(:has_multiple_check?, Ecto.Enum, values: [true: 1, false: 0], source: :HasMultipleCheck)
    field(:has_registrar_lock?, Ecto.Enum, values: [true: 1, false: 0], source: :HasRegistrarLock)

    field(:has_trustee_service?, Ecto.Enum,
      values: [true: 1, false: 0],
      source: :HasTrusteeService
    )

    field(:has_whois_privacy?, Ecto.Enum, values: [true: 1, false: 0], source: :HasWhoisPrivacy)
    field(:has_zonecheck?, Ecto.Enum, values: [true: 1, false: 0], source: :HasZonecheck)
    field(:informations, :string, source: :Informations)
    field(:period_create, :string, source: :PeriodCreate)
    field(:period_renew, :string, source: :PeriodRenew)
  end

  def info(tld), do: Session.transaction(&info(&1, tld))

  def info(id_session, tld) do
    "domainTldInfo"
    |> Netim.base([id_session, tld])
    |> Netim.request()
    |> case do
      {:ok, %{"return" => return}} ->
        Ecto.embedded_load(__MODULE__, return, :json)

      error ->
        Logger.error("cannot get TLD info: #{inspect(error)}")
        nil
    end
  end

  def price_list, do: Session.transaction(&price_list/1)

  def price_list(id_session) do
    "domainPriceList"
    |> Netim.base([id_session])
    |> Netim.request()
    |> case do
      {:ok, %{"return" => return}} ->
        return

      error ->
        Logger.error("cannot retrieve price list: #{inspect(error)}")
        nil
    end
  end
end
