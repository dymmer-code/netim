defmodule Netim.DomainTest do
  use Netim.Case

  @session_id "123456789012345678901234567890ab"
  @contacts ["CNT-OWN", "CNT-ADM", "CNT-TEC", "CNT-BIL"]
  @ns ["ns1.example.com", "ns2.example.com"]

  test "info retrieves domain info", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["domainInfo"] ->
          response(conn, "domainInfoResponse", [
            {"return",
             [
               {"domain", "example.com"},
               {"dateCreate", "2020-01-01"},
               {"dateExpiration", "2027-01-01"},
               {"status", "ACTIVE, DELEGATED"},
               {"idOwner", "CNT-OWN"},
               {"idAdmin", "CNT-ADM"},
               {"idTech", "CNT-TEC"},
               {"idBilling", "CNT-BIL"},
               {"domainIsLock", 1},
               {"whoisPrivacy", 0},
               {"autoRenew", 1},
               {"authID", "AUTH-SECRET"}
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    domain = Netim.Domain.info("example.com")
    assert %Netim.Domain{} = domain
    assert domain.domain == "example.com"
    assert domain.created_at == ~D[2020-01-01]
    assert domain.expires_at == ~D[2027-01-01]
    assert domain.status == :active
    assert domain.lock? == true
    assert domain.auto_renew? == true
    assert domain.auth_id == "AUTH-SECRET"
  end

  test "info handles error", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      response(conn, :error, "E01-M0101", "Domain not found")
    end)

    assert is_nil(Netim.Domain.info(@session_id, "nonexistent.com"))
  end

  test "check domain availability and error", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["domainCheck"] ->
          response(conn, "domainCheckResponse", [
            {"domainCheckResponseReturn",
             [
               [
                 {"domain", "available.com"},
                 {"result", "AVAILABLE"},
                 {"reason", ""}
               ]
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    result = Netim.Domain.check("available.com")
    assert %Netim.Domain.Check{} = result
    assert result.domain == "available.com"
    assert result.result == :available
  end

  test "check domain handles error", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      response(conn, :error, "E01-M0101", "Check failed")
    end)

    assert %Netim.Fault{code: "E01-M0101"} = Netim.Domain.check(@session_id, "error.com")
  end

  test "claim? returns boolean and handles error", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["queryDomainClaim"] ->
          response(conn, "queryDomainClaimResponse", [
            {"queryDomainClaimReturn", 0}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert Netim.Domain.claim?("notclaimed.com") == false
  end

  test "claim? error", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      response(conn, :error, "E01-M0101", "Error")
    end)

    assert is_nil(Netim.Domain.claim?(@session_id, "error.com"))
  end

  test "whois retrieves and parses whois record and handles error", %{bypass: bypass} do
    raw_whois = "Domain Name: EXAMPLE.COM\nRegistry Domain ID: 2138514_DOMAIN_COM-VRSN\n"

    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["domainWhois"] ->
          response(conn, "domainWhoisResponse", [{"strWhois", raw_whois}])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert %Whois.Record{} = Netim.Domain.whois("example.com")
  end

  test "whois handles error", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      response(conn, :error, "E01-M0101", "Error")
    end)

    assert is_nil(Netim.Domain.whois(@session_id, "error.com"))
  end

  test "create domain and validations", %{bypass: bypass} do
    assert {:error, :contacts} =
             Netim.Domain.create(@session_id, "test.com", ["CNT1"], @ns, 1, nil)

    assert {:error, :ns} =
             Netim.Domain.create(@session_id, "test.com", @contacts, ["ns1.com"], 1, nil)

    six_ns = ["ns1.com", "ns2.com", "ns3.com", "ns4.com", "ns5.com", "ns6.com"]

    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["domainCreate"] ->
          response(conn, "domainCreateResponse", [
            {"return",
             [
               {"ID_OPE", 1111},
               {"DATE", "2026-08-24 00:00:00"},
               {"MESSAGE", "Domain created"},
               {"STATUS", "Done"},
               {"TYPE", "domainCreate"}
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert %Netim.Operation{id: 1111, status: :done} =
             Netim.Domain.create("newdomain.com", @contacts, @ns, 1)

    assert %Netim.Operation{id: 1111, status: :done} =
             Netim.Domain.create("newdomain2.com", @contacts, six_ns, 1)
  end

  test "transfer_in and internal_transfer", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["domainTransferIn"] ->
          response(conn, "domainTransferInResponse", [
            {"return",
             [
               {"ID_OPE", 2222},
               {"DATE", "2026-08-24 00:00:00"},
               {"MESSAGE", "Transfer in started"},
               {"STATUS", "Pending"},
               {"TYPE", "domainTransferIn"}
             ]}
          ])

        ["domainInternalTransfer"] ->
          response(conn, "domainInternalTransferResponse", [
            {"return",
             [
               {"ID_OPE", 3333},
               {"DATE", "2026-08-24 00:00:00"},
               {"MESSAGE", "Internal transfer started"},
               {"STATUS", "Pending"},
               {"TYPE", "domainInternalTransfer"}
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert %Netim.Operation{id: 2222} =
             Netim.Domain.transfer_in("transfer.com", "AUTH123", @contacts, @ns)

    assert %Netim.Operation{id: 3333} =
             Netim.Domain.internal_transfer("internal.com", "AUTH123", @contacts, @ns)
  end

  test "renew and restore", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["domainRenew"] ->
          response(conn, "domainRenewResponse", [
            {"return",
             [
               {"ID_OPE", 4444},
               {"DATE", "2026-08-24 00:00:00"},
               {"MESSAGE", "Renewed"},
               {"STATUS", "Done"},
               {"TYPE", "domainRenew"}
             ]}
          ])

        ["domainRestore"] ->
          response(conn, "domainRestoreResponse", [
            {"return",
             [
               {"ID_OPE", 5555},
               {"DATE", "2026-08-24 00:00:00"},
               {"MESSAGE", "Restored"},
               {"STATUS", "Done"},
               {"TYPE", "domainRestore"}
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert %Netim.Operation{id: 4444} = Netim.Domain.renew("renew.com", 1)
    assert %Netim.Operation{id: 5555} = Netim.Domain.restore("restore.com")
  end

  test "lock and unlock preferences", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["domainSetPreference"] ->
          response(conn, "domainSetPreferenceResponse", [
            {"return",
             [
               {"ID_OPE", 6666},
               {"DATE", "2026-08-24 00:00:00"},
               {"MESSAGE", "Preference updated"},
               {"STATUS", "Done"},
               {"TYPE", "domainSetPreference"}
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert %Netim.Operation{id: 6666} = Netim.Domain.lock("lock.com")
    assert %Netim.Operation{id: 6666} = Netim.Domain.unlock("lock.com")
  end

  test "list and price", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["queryDomainList"] ->
          response(conn, "queryDomainListResponse", [
            {"queryDomainListReturn",
             [
               [
                 {"domain", "mydomain.com"},
                 {"dateCreate", "2021-01-01"},
                 {"dateExpiration", "2027-01-01"}
               ]
             ]}
          ])

        ["queryDomainPrice"] ->
          response(conn, "queryDomainPriceResponse", [
            {"queryDomainPriceReturn",
             [
               {"FeeCurrency", "EUR"},
               {"Fee4Registration", "10.00"},
               {"Fee4Renewal", "10.00"},
               {"Fee4Transfer", "10.00"},
               {"IsPremium", 0}
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert [d] = Netim.Domain.list("*.com")
    assert %Netim.Domain.List{domain: "mydomain.com"} = d

    price = Netim.Domain.price("mydomain.com")
    assert %Netim.Domain.Price{domain: "mydomain.com"} = price
    assert price.registration_fee == Decimal.new("10.00")
  end

  test "list and price errors", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      response(conn, :error, "E01-M0101", "Error")
    end)

    assert is_nil(Netim.Domain.list(@session_id, nil))
    assert is_nil(Netim.Domain.price(@session_id, "error.com", nil))
  end

  test "delete and change_dns", %{bypass: bypass} do
    assert {:error, :ns} = Netim.Domain.change_dns(@session_id, "dns.com", ["ns1.com"])

    six_ns = ["ns1.com", "ns2.com", "ns3.com", "ns4.com", "ns5.com", "ns6.com"]

    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["domainDelete"] ->
          response(conn, "domainDeleteResponse", [
            {"return",
             [
               {"ID_OPE", 7777},
               {"DATE", "2026-08-24 00:00:00"},
               {"MESSAGE", "Domain deleted"},
               {"STATUS", "Done"},
               {"TYPE", "domainDelete"}
             ]}
          ])

        ["domainChangeDNS"] ->
          response(conn, "domainChangeDNSResponse", [
            {"return",
             [
               {"ID_OPE", 8888},
               {"DATE", "2026-08-24 00:00:00"},
               {"MESSAGE", "DNS changed"},
               {"STATUS", "Done"},
               {"TYPE", "domainChangeDNS"}
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert %Netim.Operation{id: 7777} = Netim.Domain.delete("delete.com")
    assert %Netim.Operation{id: 8888} = Netim.Domain.change_dns("dns.com", @ns)
    assert %Netim.Operation{id: 8888} = Netim.Domain.change_dns("dns.com", six_ns)
  end
end
