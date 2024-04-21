defmodule Netim.Operation.List do
  @moduledoc """
  Each kind of operation let by a TLD.
  """
  use TypedEctoSchema

  @boolean [true: "1", false: "0"]

  @primary_key false
  typed_embedded_schema do
    field(:tld, :string, primary_key: true)
    field(:domain_authid, Ecto.Enum, values: @boolean, source: :domainAuthid)
    field(:domain_change_contact, Ecto.Enum, values: @boolean, source: :domainChangeContact)
    field(:domain_change_dns, Ecto.Enum, values: @boolean, source: :domainChangeDNS)
    field(:domain_create, Ecto.Enum, values: @boolean, source: :domainCreate)
    field(:domain_create_lp, Ecto.Enum, values: @boolean, source: :domainCreateLP)
    field(:domain_delete, Ecto.Enum, values: @boolean, source: :domainDelete)
    field(:domain_internal_transfer, Ecto.Enum, values: @boolean, source: :domainInternalTransfer)
    field(:domain_mail_fwd_create, Ecto.Enum, values: @boolean, source: :domainMailFwdCreate)
    field(:domain_mail_fwd_delete, Ecto.Enum, values: @boolean, source: :domainMailFwdDelete)
    field(:domain_renew, Ecto.Enum, values: @boolean, source: :domainRenew)
    field(:domain_restore, Ecto.Enum, values: @boolean, source: :domainRestore)
    field(:domain_set_dnssec, Ecto.Enum, values: @boolean, source: :domainSetDNSSEC)
    field(:domain_set_dnssec_ext, Ecto.Enum, values: @boolean, source: :domainSetDNSSECExt)
    field(:domain_set_membership, Ecto.Enum, values: @boolean, source: :domainSetMembership)

    field(:domain_set_preference_auto_renew, Ecto.Enum,
      values: @boolean,
      source: :"domainSetPreference.auto_renew"
    )

    field(:domain_set_preference_registrar_lock, Ecto.Enum,
      values: @boolean,
      source: :"domainSetPreference.registrar_lock"
    )

    field(:domain_set_preference_to_be_renewed, Ecto.Enum,
      values: @boolean,
      source: :"domainSetPreference.to_be_renewed"
    )

    field(:domain_set_preference_whois_privacy, Ecto.Enum,
      values: @boolean,
      source: :"domainSetPreference.whois_privacy"
    )

    field(:domain_transfer_in, Ecto.Enum, values: @boolean, source: :domainTransferIn)
    field(:domain_transfer_owner, Ecto.Enum, values: @boolean, source: :domainTransferOwner)
    field(:domain_transfer_trade, Ecto.Enum, values: @boolean, source: :domainTransferTrade)
    field(:domain_web_fwd_create, Ecto.Enum, values: @boolean, source: :domainWebFwdCreate)
    field(:domain_web_fwd_delete, Ecto.Enum, values: @boolean, source: :domainWebFwdDelete)
    field(:domain_zone_create, Ecto.Enum, values: @boolean, source: :domainZoneCreate)
    field(:domain_zone_delete, Ecto.Enum, values: @boolean, source: :domainZoneDelete)
    field(:domain_zone_init, Ecto.Enum, values: @boolean, source: :domainZoneInit)
    field(:domain_zone_init_soa, Ecto.Enum, values: @boolean, source: :domainZoneInitSoa)
    field(:host_create, Ecto.Enum, values: @boolean, source: :hostCreate)
    field(:host_delete, Ecto.Enum, values: @boolean, source: :hostDelete)
    field(:host_update, Ecto.Enum, values: @boolean, source: :hostUpdate)
  end
end
