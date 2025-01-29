defmodule Netim.Tld do
  @moduledoc """
  TLD module let us retrieve the information about a TLD and the list of
  prices.
  """
  use TypedEctoSchema

  require Logger

  alias Netim.Session
  alias Netim.Soap, as: NetimSoap
  alias Netim.Tld.Extension
  alias Netim.Tld.Price
  alias Netim.Tld.Range

  @primary_key false

  @typedoc """
  The information about the TLD. The information available is:

  - `tld` the name of the TLD, i.e. "com"
  - `country` the name of the country where it belongs.
  """
  typed_embedded_schema do
    field(:tld, :string, primary_key: true)
    field(:country, :string, source: :Country)
    field(:delay_renew_after_expiration, :integer, source: :DelaiRenewAfterExpiration)
    field(:delay_renew_before_expiration, :integer, source: :DelaiRenewBeforeExpiration)
    field(:delay_renew_after_delete, :integer, source: :DelaiRenewAfterDelete)

    embeds_many(:extension, Extension, source: :Extensions)

    field(:local_contact_service_fee, :decimal, source: :Fee4LocalContactService)
    field(:registration_free, :decimal, source: :Fee4Registration)
    field(:renewal_fee, :decimal, source: :Fee4Renewal)
    field(:restore_fee, :decimal, source: :Fee4Restore)
    field(:trade_fee, :decimal, source: :Fee4Trade)
    field(:transfer_fee, :decimal, source: :Fee4Transfer)
    field(:trustee_service_fee, :decimal, source: :Fee4TrusteeService)
    field(:currency_fee, Money.Ecto.Currency.Type, source: :FeeCurrency) :: atom()
    field(:auto_renew?, Ecto.Enum, values: [true: 1, false: 0], source: :HasAutorenew)
    field(:dns_sec?, Ecto.Enum, values: [true: 1, false: 0], source: :HasDnsSec)
    field(:epp_code?, Ecto.Enum, values: [true: 1, false: 0], source: :HasEppCode)

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

    field(:whois_privacy?, Ecto.Enum, values: [true: 1, false: 0], source: :HasWhoisPrivacy)
    field(:zone_check?, Ecto.Enum, values: [true: 1, false: 0], source: :HasZonecheck)
    field(:information, :string, source: :Informations)
    field(:period_create, Range, source: :PeriodCreate)
    field(:period_renew, Range, source: :PeriodRenew)
  end

  @doc """
  Retrieve information about the TLD.
  """
  def info(tld), do: Session.transaction(&info(&1, tld))

  @doc """
  Same as `info/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def info(id_session, tld) do
    "domainTldInfo"
    |> NetimSoap.base([id_session, tld])
    |> NetimSoap.request()
    |> case do
      {:ok, %{"return" => return}} ->
        Ecto.embedded_load(__MODULE__, return, :json)

      error ->
        Logger.error("cannot get TLD info: #{inspect(error)}")
        nil
    end
  end

  @doc """
  Get the list of prices.
  """
  def price_list, do: Session.transaction(&price_list/1)

  @doc """
  Same as `price_list/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def price_list(id_session) do
    "domainPriceList"
    |> NetimSoap.base([id_session])
    |> NetimSoap.request()
    |> case do
      {:ok, %{"return" => prices}} ->
        for price <- prices, do: Ecto.embedded_load(Price, price, :json)

      error ->
        Logger.error("cannot retrieve price list: #{inspect(error)}")
        nil
    end
  end
end
