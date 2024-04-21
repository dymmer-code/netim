defmodule Netim.Operation do
  @moduledoc """
  The operations are the actions we request to Netim, this module let us
  retrieve a list of operations and get the information of an operation.
  """
  use TypedEctoSchema

  require Logger

  alias Netim.Operation.List
  alias Netim.Session

  @operation_statuses [
    cancelled: "Cancelled",
    done: "Done",
    failed: "Failed",
    pending: "Pending"
  ]

  @operation_types [
    contact_update: "contactUpdate",
    domain_authid: "domainAuthid",
    domain_change_contact: "domainChangeContact",
    domain_change_dns: "domainChangeDNS",
    domain_create: "domainCreate",
    domain_create_lp: "domainCreateLP",
    domain_delete: "domainDelete",
    domain_internal_transfer: "domainInternalTransfer",
    domain_mail_fwd_create: "domainMailFwdCreate",
    domain_mail_fwd_delete: "domainMailFwdDelete",
    domain_renew: "domainRenew",
    domain_restore: "domainRestore",
    domain_set_dnssec: "domainSetDNSSEC",
    domain_set_dnssec_ext: "domainSetDNSSECExt",
    domain_set_membership: "domainSetMembership",
    domain_set_preference_auto_renew: "domainSetPreference.auto_renew",
    domain_set_preference_registrar_lock: "domainSetPreference.registrar_lock",
    domain_set_preference_to_be_renewed: "domainSetPreference.to_be_renewed",
    domain_set_preference_whois_privacy: "domainSetPreference.whois_privacy",
    domain_transfer_in: "domainTransferIn",
    domain_transfer_owner: "domainTransferOwner",
    domain_transfer_trade: "domainTransferTrade",
    domain_web_fwd_create: "domainWebFwdCreate",
    domain_web_fwd_delete: "domainWebFwdDelete",
    domain_zone_create: "domainZoneCreate",
    domain_zone_delete: "domainZoneDelete",
    domain_zone_init: "domainZoneInit",
    domain_zone_init_soa: "domainZoneInitSoa",
    host_create: "hostCreate",
    host_delete: "hostDelete",
    host_update: "hostUpdate"
  ]

  @primary_key false

  @typedoc """
  The operation is composed for the following fields:

  - `id` the ID of the operation
  - `created_at` the date and time of the operation creation
  - `message` the information as a string
  - `status` of the operation, it could be:
    - `cancelled` the operation was cancelled
    - `done` the operation was done
    - `failed` the operation failed
    - `pending` the operation is still pending
  - `type` of the operation
  """
  typed_embedded_schema do
    field(:id, :integer, source: :ID_OPE)
    field(:created_at, :naive_datetime, source: :DATE)
    field(:message, :string, source: :MESSAGE)
    field(:status, Ecto.Enum, values: @operation_statuses, source: :STATUS)
    field(:type, Ecto.Enum, values: @operation_types, source: :TYPE)
  end

  @doc """
  Perform a conversion of a parameters provided by Netim to
  the struct defined in its module.
  """
  def cast({:ok, %{"return" => params}}) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  def cast(error) do
    Logger.error("cannot get contact info: #{inspect(error)}")
    nil
  end

  @doc """
  Get information about an operation given the operation ID.
  """
  def info(id_operation), do: Session.transaction(&info(&1, id_operation))

  @doc """
  Same as `info/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def info(id_session, id_operation) do
    "queryOpe"
    |> Netim.base([id_session, id_operation])
    |> Netim.request()
    |> cast()
  end

  @doc """
  List all of the operations performed by TLD. These are the operations
  performed only for domains, operations regarding contacts and other
  operations are out of this scope.
  """
  def list(tld), do: Session.transaction(&list(&1, tld))

  @doc """
  Same as `list/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def list(id_session, tld) do
    "queryOpeList"
    |> Netim.base([id_session, tld])
    |> Netim.request()
    |> case do
      {:ok, %{"return" => return}} ->
        return = Map.put(return, "tld", tld)
        Ecto.embedded_load(List, return, :json)

      error ->
        Logger.error("cannot list TLD operation list: #{inspect(error)}")
        nil
    end
  end

  @doc """
  List all of the pending operations. These operations could be regarding
  whatever topic.
  """
  def list_pending, do: Session.transaction(&list_pending/1)

  @doc """
  Same as `list_pending/1` but adding the session ID. Check `Netim.Session`
  for further information.
  """
  def list_pending(id_session) do
    "queryOpePending"
    |> Netim.base([id_session])
    |> Netim.request()
    |> case do
      {:ok, %{"return" => operations}} ->
        {:ok, Enum.map(operations, &Ecto.embedded_load(__MODULE__, &1, :json))}

      {:error, _reason} = error ->
        error
    end
  end
end
