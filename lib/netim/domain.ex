defmodule Netim.Domain do
  use TypedEctoSchema
  require Logger
  alias Netim.Session
  alias Netim.Domain.List, as: DomainList
  alias Netim.Domain.Price, as: DomainPrice

  @domain_statuses [
    pending: "PENDING",
    error: "ERROR",
    parked: "ACTIVE, NOT DELEGATED",
    active: "ACTIVE, DELEGATED",
    reserved: "RESERVED, NOT DELEGATED",
    expired: "EXPIRED",
    parked_expired: "EXPIRED, HOLD, NOT DELEGATED",
    quarantine: "QUARANTINE, NOT DELEGATED",
    hold: "HOLD, NOT DELEGATED",
    transferred_out: "TRANSFERRED OUT",
    deleted: "DELETED"
  ]

  @primary_key false
  typed_embedded_schema do
    field :domain, :string, primary_key: true
    field :created_at, :date, source: :dateCreate
    field :expires_at, :date, source: :dateExpiration
    field :min_renew_at, :date, source: :dateMinRenew
    field :max_renew_at, :date, source: :dateMaxRenew
    field :max_restore_at, :date, source: :dateMaxRestore
    field :status, Ecto.Enum, values: @domain_statuses
    field :contact_owner_id, :string, source: :idOwner
    field :contact_admin_id, :string, source: :idAdmin
    field :contact_tech_id, :string, source: :idTech
    field :contact_billing_id, :string, source: :idBilling
    field :lock?, Ecto.Enum, values: [true: 1, false: 0], source: :domainIsLock
    field :whois_privacy?, Ecto.Enum, values: [true: 1, false: 0], source: :whoisPrivacy
    field :auto_renew?, Ecto.Enum, values: [true: 1, false: 0], source: :autoRenew
    field :ns, {:array, :string}
    field :auth_id, :string, source: :authID
    field :signed?, Ecto.Enum, values: [true: 1, false: 0], source: :IsSigned
    field :dns4service?, Ecto.Enum, values: [true: 1, false: 0], source: :HasDNS4Service
    field :dns_sec, :map
  end

  @spec info(String.t()) :: t() | nil
  def info(domain), do: Session.transaction(&info(&1, domain))

  @spec info(String.t(), String.t()) :: t() | nil
  def info(id_session, domain) do
    "domainInfo"
    |> Netim.base([id_session, domain])
    |> Netim.request()
    |> case do
      {:ok, %{"return" => return}} ->
        Ecto.embedded_load(__MODULE__, return, :json)

      error ->
        Logger.error("cannot get domain info: #{inspect(error)}")
        nil
    end
  end

  def check(domain), do: Session.transaction(&check(&1, domain))

  def check(id_session, domain) do
    "domainCheck"
    |> Netim.base([id_session, domain])
    |> Netim.request()
    |> case do
      {:ok, %{"domainCheckResponseReturn" => [result]}} ->
        Netim.Domain.Check.cast(result)

      error ->
        Logger.error("cannot check domain availability: #{inspect(error)}")
        error
    end
  end

  @spec claim?(String.t()) :: boolean() | nil
  def claim?(domain), do: Session.transaction(&claim?(&1, domain))

  @spec claim?(String.t(), String.t()) :: boolean() | nil
  def claim?(id_session, domain) do
    "queryDomainClaim"
    |> Netim.base([id_session, domain])
    |> Netim.request()
    |> case do
      {:ok, %{"queryDomainClaimReturn" => 0}} -> false
      {:ok, %{"queryDomainClaimReturn" => 1}} -> true
      error ->
        Logger.error("cannot check domain claim: #{inspect(error)}")
        nil
    end
  end

  def whois(domain), do: Session.transaction(&whois(&1, domain))

  def whois(id_session, domain) do
    "domainWhois"
    |> Netim.base([id_session, domain])
    |> Netim.request()
    |> case do
      {:ok, %{"strWhois" => whois}} ->
        whois

      error ->
        Logger.error("cannot get whois for domain: #{inspect(error)}")
        nil
    end
  end

  def create(domain, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5, duration, template_dns \\ nil) do
    Session.transaction(&create(&1, domain, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5, duration, template_dns))
  end

  def create(id_session, domain, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5, duration, template_dns) do
    "domainCreate"
    |> Netim.base([id_session, domain, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5, duration, template_dns])
    |> Netim.request()
  end

  def transfer_in(domain, auth_id, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5) do
    Session.transaction(&transfer_in(&1, domain, auth_id, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5))
  end

  def transfer_in(id_session, domain, auth_id, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5) do
    "domainTransferIn"
    |> Netim.base([id_session, domain, auth_id, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5])
    |> Netim.request()
  end

  def internal_transfer(domain, auth_id, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5) do
    Session.transaction(&internal_transfer(&1, domain, auth_id, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5))
  end

  def internal_transfer(id_session, domain, auth_id, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5) do
    "domainInternalTransfer"
    |> Netim.base([id_session, domain, auth_id, id_owner, id_admin, id_tech, id_billing, ns1, ns2, ns3, ns4, ns5])
    |> Netim.request()
  end

  @spec list() :: [DomainList.t()]
  @spec list(String.t() | nil) :: [DomainList.t()]
  def list(filter \\ nil), do: Session.transaction(&list(&1, filter))

  @spec list(String.t(), String.t() | nil) :: [DomainList.t()]
  def list(id_session, filter) do
    "queryDomainList"
    |> Netim.base([id_session, filter])
    |> Netim.request()
    |> case do
      {:ok, %{"queryDomainListReturn" => return}} ->
        Enum.map(return, &DomainList.cast/1)

      error ->
        Logger.error("cannot list domains: #{inspect(error)}")
        nil
    end
  end

  @spec price(String.t()) :: DomainPrice.t()
  @spec price(String.t(), String.t() | nil) :: DomainPrice.t()
  def price(domain, auth_id \\ nil), do: Session.transaction(&price(&1, domain, auth_id))

  @spec price(String.t(), String.t(), String.t() | nil) :: DomainPrice.t()
  def price(id_session, domain, auth_id) do
    "queryDomainPrice"
    |> Netim.base([id_session, domain, auth_id])
    |> Netim.request()
    |> case do
      {:ok, %{"queryDomainPriceReturn" => return}} ->
        return
        |> Map.put(:domain, domain)
        |> DomainPrice.cast()

      error ->
        Logger.error("cannot retrieve price for #{domain}: #{inspect(error)}")
        nil
    end
  end
end
