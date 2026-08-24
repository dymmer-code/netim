defmodule Netim.OperationTest do
  use Netim.Case

  @session_id "123456789012345678901234567890ab"

  test "info retrieves operation details", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["queryOpe"] ->
          response(conn, "queryOpeResponse", [
            {"return",
             [
               {"ID_OPE", 4_958_385},
               {"DATE", "2026-08-24 01:41:19"},
               {"MESSAGE", "Operation done"},
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

    operation = Netim.Operation.info(4_958_385)
    assert %Netim.Operation{} = operation
    assert operation.id == 4_958_385
    assert operation.status == :done
    assert operation.type == :domain_create
  end

  test "info handles error gracefully", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      response(conn, :error, "E01-M0101", "Not found")
    end)

    assert is_nil(Netim.Operation.info(@session_id, 999_999))
  end

  test "list retrieves operation list by TLD", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["queryOpeList"] ->
          response(conn, "queryOpeListResponse", [
            {"return",
             [
               {"domainCreate", "1"},
               {"domainRenew", "1"},
               {"domainDelete", "0"},
               {"domainTransferIn", "1"}
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    list = Netim.Operation.list("com")
    assert %Netim.Operation.List{} = list
    assert list.tld == "com"
    assert list.domain_create == true
    assert list.domain_delete == false
  end

  test "list handles error gracefully", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      response(conn, :error, "E01-M0101", "Error")
    end)

    assert is_nil(Netim.Operation.list(@session_id, "invalid"))
  end

  test "list_pending retrieves pending operations", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      case Passby.get_req_header(conn, "soapaction") do
        ["queryOpePending"] ->
          response(conn, "queryOpePendingResponse", [
            {"return",
             [
               [
                 {"ID_OPE", 1234},
                 {"DATE", "2026-08-24 01:00:00"},
                 {"MESSAGE", "Pending domain create"},
                 {"STATUS", "Pending"},
                 {"TYPE", "domainCreate"}
               ]
             ]}
          ])

        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert {:ok, [op]} = Netim.Operation.list_pending()
    assert op.id == 1234
    assert op.status == :pending
  end

  test "list_pending handles error", %{bypass: bypass} do
    Passby.expect(bypass, "POST", "/2.0/", fn conn ->
      response(conn, :error, "E01-M0101", "Error")
    end)

    assert {:error, _} = Netim.Operation.list_pending(@session_id)
  end
end
