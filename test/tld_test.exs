defmodule Netim.TldTest do
  use Netim.Case

  @session_id "123456789012345678901234567890ab"

  test "get info", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/2.0/", fn conn ->
      case Plug.Conn.get_req_header(conn, "soapaction") do
        ["domainTldInfo"] ->
          response(conn, "domainTldInfo", [
            {"return",
             [
               {"tld", "eu"},
               {"Extensions",
                [
                  [
                    {"type", "popular"},
                    {"tld", ["eu"]}
                  ],
                  [
                    {"type", "functional"}
                  ],
                  [
                    {"type", "regional"}
                  ]
                ]},
               {"PeriodCreate", "1-1"},
               {"PeriodRenew", "1-10"},
               {"DelaiRenewBeforeExpiration", 3650},
               {"DelaiRenewAfterExpiration", 0},
               {"DelaiRestoreAfterDelete", 40},
               {"HasEppCode", 1},
               {"HasRegistrarLock", 0},
               {"HasAutorenew", 1},
               {"HasWhoisPrivacy", 1},
               {"HasMultipleCheck", 0},
               {"HasImmediateDelete", 1},
               {"HasTrusteeService", 0},
               {"HasLocalContactService", 0},
               {"HasZonecheck", 0},
               {"HasDnsSec", 1},
               {"FeeCurrency", "EUR"},
               {"Fee4Registration", 5.25},
               {"Fee4Renewal", 5.0},
               {"Fee4Transfer", 5.25},
               {"Fee4Trade", 0.0},
               {"Fee4Restore", 5.0},
               {"Fee4TrusteeService", 0.0},
               {"Fee4LocalContactService", 0.0},
               {"Informations", ""}
             ]}
          ])
      end
    end)

    assert %Netim.Tld{
             tld: "eu",
             country: nil,
             delay_renew_after_expiration: 0,
             delay_renew_before_expiration: 3650,
             delay_restore_after_delete: 40,
             extension: [
               %Netim.Tld.Extension{tld: ["eu"], type: :popular},
               %Netim.Tld.Extension{tld: nil, type: :functional},
               %Netim.Tld.Extension{tld: nil, type: :regional}
             ],
             local_contact_service_fee: Decimal.new("0.0"),
             registration_fee: Decimal.new("5.25"),
             renewal_fee: Decimal.new("5.0"),
             restore_fee: Decimal.new("5.0"),
             trade_fee: Decimal.new("0.0"),
             transfer_fee: Decimal.new("5.25"),
             trustee_service_fee: Decimal.new("0.0"),
             currency_fee: :EUR,
             auto_renew?: true,
             dns_sec?: true,
             epp_code?: true,
             has_immediate_delete?: true,
             has_local_contact_service?: false,
             has_multiple_check?: false,
             has_registrar_lock?: false,
             has_trustee_service?: false,
             whois_privacy?: true,
             zone_check?: false,
             information: "",
             period_create: [1],
             period_renew: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
           } == Netim.Tld.info(@session_id, "eu")
  end
end
