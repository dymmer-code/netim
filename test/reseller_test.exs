defmodule Netim.ResellerTest do
  use Netim.Case

  @session_id "123456789012345678901234567890ab"

  test "get_settings retrieves reseller account info", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["queryResellerAccount"] ->
          response(conn, "queryResellerAccountResponse", [
            {"return",
             [
               {"BALANCE_AMOUNT", "150.50"},
               {"BALANCE_LOW_LIMIT", "50.00"},
               {"BALANCE_HARD_LIMIT", "10.00"},
               {"DOMAIN_AUTO_RENEW", 1},
               {"HOSTING_AUTO_RENEW", 0},
               {"DEFAULT_OWNER", "OWN1"},
               {"DEFAULT_ADMIN", "ADM1"},
               {"DEFAULT_TECH", "TEC1"},
               {"DEFAULT_BILLING", "BIL1"},
               {"PREMIUM_PROCESSING", "AUTO"},
               {"DEFAULT_DNS_1", "ns1.example.com"},
               {"DEFAULT_DNS_2", "ns2.example.com"}
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    settings = Netim.Reseller.get_settings()
    assert %Netim.Reseller{} = settings
    assert settings.balance_amount == Decimal.new("150.50")
    assert settings.domain_auto_renew == true
    assert settings.hosting_auto_renew == false
    assert settings.default_owner == "OWN1"
    assert settings.default_dns_1 == "ns1.example.com"
  end

  test "get_settings handles error response", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      response(conn, :error, "E01-M0101", "Session expired")
    end)

    assert {:error, _} = Netim.Reseller.get_settings(@session_id)
  end
end
