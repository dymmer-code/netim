defmodule Netim.Domain do
  @moduledoc """
  Domain functions and operations for checking, buying, and transfering.
  """
  use TypedEctoSchema

  require Logger

  alias Netim.Domain.Check, as: DomainCheck
  alias Netim.Domain.List, as: DomainList
  alias Netim.Domain.Price, as: DomainPrice
  alias Netim.Fault
  alias Netim.Operation
  alias Netim.Session
  alias Netim.Soap, as: NetimSoap

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

  @typedoc """
  The information about the domains as it's stored in the provider,
  we have the following data:

  - `domain` the name of the domain
  - `created_at` the date when it was created
  - `expires_at` the date when it will expire
  - `min_renew_at` the minimum date when it's possible to renew it
  - `max_renew_at` the maximum date when it's possible to renew it
  - `max_restore_at` the maximum date when it's possible to restore it
  - `status` the status of the domain, it could be one of the following ones:
    - `pending` the domain is in a temporal status, it could be move to anyone else
    - `error` the domain couldn't be processed
    - `parked` the domain was parked
    - `active` the domain is active and ready to be in use
    - `reserved` the domain was reserved
    - `expired` the domain expired
    - `parked_expired` the domain parked expired
    - `quarantine` the domain is in a grace period
    - `hold` the domain is on hold
    - `transferred_out` the domain was transferred out of Netim
    - `deleted` the domain was removed
  - `contact_owner_id` the ID of the contact owner
  - `contact_admin_id` the ID of the contact admin
  - `contact_tech_id` the ID of the contact tech
  - `contact_billing_id` the ID of the contact billing
  - `lock?` is the domain locked?
  - `whois_privacy?` is the WHOIS privacy activated?
  - `auto_renew?` is going to be auto renewed?
  - `ns` list of NS servers
  - `auth_id` the auth ID needed for transfer the domain
  - `signed?` is the domain signed?
  - `dns4service?` has the domain DNS4Service?
  - `dns_sec` data about the domain security
  """
  typed_embedded_schema do
    field(:domain, :string, primary_key: true)
    field(:created_at, :date, source: :dateCreate)
    field(:expires_at, :date, source: :dateExpiration)
    field(:min_renew_at, :date, source: :dateMinRenew)
    field(:max_renew_at, :date, source: :dateMaxRenew)
    field(:max_restore_at, :date, source: :dateMaxRestore)
    field(:status, Ecto.Enum, values: @domain_statuses)
    field(:contact_owner_id, :string, source: :idOwner)
    field(:contact_admin_id, :string, source: :idAdmin)
    field(:contact_tech_id, :string, source: :idTech)
    field(:contact_billing_id, :string, source: :idBilling)
    field(:lock?, Ecto.Enum, values: [true: 1, false: 0], source: :domainIsLock)
    field(:whois_privacy?, Ecto.Enum, values: [true: 1, false: 0], source: :whoisPrivacy)
    field(:auto_renew?, Ecto.Enum, values: [true: 1, false: 0], source: :autoRenew)
    field(:ns, {:array, :string})
    field(:auth_id, :string, source: :authID)
    field(:signed?, Ecto.Enum, values: [true: 1, false: 0], source: :IsSigned)
    field(:dns4service?, Ecto.Enum, values: [true: 1, false: 0], source: :HasDNS4Service)
    field(:dns_sec, :map)
  end

  @doc """
  Get the info for a specified domain.
  """
  @spec info(String.t()) :: t() | nil
  def info(domain), do: Session.transaction(&info(&1, domain))

  @doc """
  Same as `info/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  @spec info(String.t(), String.t()) :: t() | nil
  def info(id_session, domain) do
    "domainInfo"
    |> NetimSoap.base([id_session, domain])
    |> NetimSoap.request()
    |> case do
      {:ok, %{"return" => return}} ->
        Ecto.embedded_load(__MODULE__, return, :json)

      error ->
        Logger.error("cannot get domain info: #{inspect(error)}")
        nil
    end
  end

  @doc """
  Check domain given the name. It gives us information about if we can
  buy the domain and other information depending on the TLD and the
  domain.
  """
  @spec check(String.t()) :: DomainCheck.t() | Fault.t()
  def check(domain), do: Session.transaction(&check(&1, domain))

  @doc """
  Same as `check/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def check(id_session, domain) do
    "domainCheck"
    |> NetimSoap.base([id_session, domain])
    |> NetimSoap.request()
    |> case do
      {:ok, %{"domainCheckResponseReturn" => [result]}} ->
        DomainCheck.cast(result)

      {:error, reason} ->
        fault = Ecto.embedded_load(Fault, reason, :json)
        Logger.error("cannot check domain availability: #{fault.message}")
        fault
    end
  end

  @doc """
  Tell us if there's a claim on the domain name or not.
  """
  @spec claim?(String.t()) :: boolean() | nil
  def claim?(domain), do: Session.transaction(&claim?(&1, domain))

  @doc """
  Same as `claim?/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  @spec claim?(String.t(), String.t()) :: boolean() | nil
  def claim?(id_session, domain) do
    "queryDomainClaim"
    |> NetimSoap.base([id_session, domain])
    |> NetimSoap.request()
    |> case do
      {:ok, %{"queryDomainClaimReturn" => 0}} ->
        false

      {:ok, %{"queryDomainClaimReturn" => 1}} ->
        true

      error ->
        Logger.error("cannot check domain claim: #{inspect(error)}")
        nil
    end
  end

  @doc """
  Retrieve the WHOIS information for the specified domain.
  """
  @spec whois(String.t()) :: String.t() | nil
  def whois(domain), do: Session.transaction(&whois(&1, domain))

  @doc """
  Same as `whois/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  @spec whois(String.t(), String.t()) :: String.t() | nil
  def whois(id_session, domain) do
    "domainWhois"
    |> NetimSoap.base([id_session, domain])
    |> NetimSoap.request()
    |> case do
      {:ok, %{"strWhois" => whois}} ->
        whois

      error ->
        Logger.error("cannot get whois for domain: #{inspect(error)}")
        nil
    end
  end

  @doc """
  Create a domain. It register the domain if that's possible.

  It's possible to use a preconfigured tempalte for DNS therefore,
  it let us to provide an empty list for `ns`.
  """
  @spec create(String.t(), [String.t()], [String.t()], pos_integer()) ::
          Operation.t() | nil

  @spec create(String.t(), [String.t()], [String.t()], pos_integer(), String.t() | nil) ::
          Operation.t() | nil
  def create(domain, contacts, ns, duration, template_dns \\ nil) do
    Session.transaction(&create(&1, domain, contacts, ns, duration, template_dns))
  end

  @doc """
  Same as `create/5` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def create(_id_session, _domain, contacts, _ns, _duration, _template_dns)
      when not is_list(contacts) or length(contacts) != 4 do
    {:error, :contacts}
  end

  def create(_id_session, _domain, _contacts, ns, _duration, nil)
      when not is_list(ns) or length(ns) < 2 do
    {:error, :ns}
  end

  def create(id_session, domain, contacts, ns, duration, template_dns) when length(ns) > 5 do
    create(id_session, domain, contacts, Enum.slice(ns, 0..4), duration, template_dns)
  end

  def create(id_session, domain, contacts, ns, duration, template_dns) when length(ns) in 0..4 do
    ns = ns ++ List.duplicate(nil, 5 - length(ns))
    create(id_session, domain, contacts, ns, duration, template_dns)
  end

  def create(id_session, domain, contacts, ns, duration, template_dns) do
    "domainCreate"
    |> NetimSoap.base([id_session, domain] ++ contacts ++ ns ++ [duration, template_dns])
    |> NetimSoap.request()
    |> return_or_fault()
  end

  @doc """
  Transfer your domain from another provider to Netim.
  """
  def transfer_in(domain, auth_id, contacts, ns) do
    Session.transaction(&transfer_in(&1, domain, auth_id, contacts, ns))
  end

  @doc """
  Same as `transfer_in/4` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def transfer_in(id_session, domain, auth_id, contacts, ns) do
    "domainTransferIn"
    |> NetimSoap.base([id_session, domain, auth_id] ++ contacts ++ ns)
    |> NetimSoap.request()
    |> return_or_fault()
  end

  @doc """
  Perform an internal transfer to move the domain from another reseller of
  Netim to our reseller account.
  """
  def internal_transfer(domain, auth_id, contacts, ns) do
    Session.transaction(&internal_transfer(&1, domain, auth_id, contacts, ns))
  end

  @doc """
  Same as `internal_transfer/4` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def internal_transfer(id_session, domain, auth_id, contacts, ns) do
    "domainInternalTransfer"
    |> NetimSoap.base([id_session, domain, auth_id] ++ contacts ++ ns)
    |> NetimSoap.request()
    |> return_or_fault()
  end

  @doc """
  Renew the domain passed as first parameter for the indicated duration
  in years.
  """
  def renew(domain, duration) do
    Session.transaction(&renew(&1, domain, duration))
  end

  @doc """
  Same as `renew/2` but adding the session ID. Check `Netim.Session` for
  further information.
  """
  def renew(id_session, domain, duration) do
    "domainRenew"
    |> NetimSoap.base([id_session, domain, duration])
    |> NetimSoap.request()
    |> return_or_fault()
  end

  @doc """
  Restore a domain name in quarantine / redemption status
  """
  def restore(domain) do
    Session.transaction(&restore(&1, domain))
  end

  @doc """
  Same as `restore/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def restore(id_session, domain) do
    "domainRestore"
    |> NetimSoap.base([id_session, domain])
    |> NetimSoap.request()
    |> return_or_fault()
  end

  @doc """
  Lock domain for avoiding tranfer to another domain.
  """
  def lock(domain) do
    set_preference(domain, "registrar_lock", "1")
  end

  @doc """
  Unlock domain for transfer it to another domain.
  """
  def unlock(domain) do
    set_preference(domain, "registrar_lock", "0")
  end

  @doc """
  Set a preference for the domain. It could be:

  - `registrar_lock`
  - `note`
  - `tag`
  - `to_be_renewed`
  - `whois_privacy`
  """
  def set_preference(domain, key, value) do
    Session.transaction(&set_preference(&1, domain, key, value))
  end

  def set_preference(id_session, domain, key, value) do
    "domainSetPreference"
    |> NetimSoap.base([id_session, domain, key, value])
    |> NetimSoap.request()
    |> return_or_fault()
  end

  @doc """
  List all of the domains.

  We can provide optionally a paramter for the criteria.
  For the `filter` you can use `*` (wildcard), i.e. `*.com`
  """
  @spec list() :: [DomainList.t()]
  @spec list(String.t() | nil) :: [DomainList.t()]
  def list(filter \\ nil), do: Session.transaction(&list(&1, filter))

  @doc """
  Same as `list/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  @spec list(String.t(), String.t() | nil) :: [DomainList.t()]
  def list(id_session, filter) do
    "queryDomainList"
    |> NetimSoap.base([id_session, filter])
    |> NetimSoap.request()
    |> case do
      {:ok, %{"queryDomainListReturn" => return}} ->
        Enum.map(return, &DomainList.cast/1)

      error ->
        Logger.error("cannot list domains: #{inspect(error)}")
        nil
    end
  end

  @doc """
  Get the price of a specific domain. It is useful because the domain
  could be in grace period or it could be a premium domain.

  In some circunstances the provider could require us to ask the price passing
  first the auth ID, it could be needed for a domain that's going to be
  transferred.
  """
  @spec price(String.t()) :: DomainPrice.t()
  @spec price(String.t(), String.t() | nil) :: DomainPrice.t()
  def price(domain, auth_id \\ nil), do: Session.transaction(&price(&1, domain, auth_id))

  @doc """
  Same as `price/2` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  @spec price(String.t(), String.t(), String.t() | nil) :: DomainPrice.t()
  def price(id_session, domain, auth_id) do
    "queryDomainPrice"
    |> NetimSoap.base([id_session, domain, auth_id])
    |> NetimSoap.request()
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

  @doc """
  Delete a domain given as a parameter. The first parameter is letting us
  to define a session ID. Check `Netim.Session` for further information.

  The third parameter is giving us the possibility of when we are going to
  perform the removing of the domain. By default, and at this moment only
  it's possible to indicate `"NOW"`.
  """
  @spec delete(String.t()) :: Operation.t() | Fault.t()
  @spec delete(String.t() | nil, String.t()) :: Operation.t() | Fault.t()
  @spec delete(String.t() | nil, String.t(), String.t()) :: Operation.t() | Fault.t()
  def delete(id_session \\ nil, domain, type \\ "NOW")

  def delete(nil, domain, type) do
    Session.transaction(&delete(&1, domain, type))
  end

  def delete(id_session, domain, type) do
    "domainDelete"
    |> NetimSoap.base([id_session, domain, type])
    |> NetimSoap.request()
    |> return_or_fault()
  end

  defp return_or_fault({:ok, %{"return" => operation}}) do
    Ecto.embedded_load(Operation, operation, :json)
  end

  defp return_or_fault({:error, reason}) do
    Ecto.embedded_load(Fault, reason, :json)
  end
end
