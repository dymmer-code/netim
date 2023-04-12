defmodule Netim.SessionTest do
  use Netim.Case

  @session_id "123456789012345678901234567890ab"
  @reseller_id "AW11"
  @password "secret"

  test "open a session", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/2.0/", fn conn ->
      assert ["sessionOpen"] = Plug.Conn.get_req_header(conn, "soapaction")
      response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])
    end)

    assert @session_id == Netim.Session.open(@reseller_id, @password)
  end

  test "open a session with wrong credentials", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/2.0/", fn conn ->
      assert ["sessionOpen"] = Plug.Conn.get_req_header(conn, "soapaction")
      # combinaison is french, I know, but it's copied from the real response
      response(conn, :error, "E01-M0101", "Unable to connect - Bad login / password combinaison")
    end)

    result = IO.inspect(Netim.Session.open(@reseller_id, @password), label: "result")
    assert is_nil(result)
  end

  test "close a session", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/2.0/", fn conn ->
      assert ["sessionClose"] = Plug.Conn.get_req_header(conn, "soapaction")
      response(conn, "sessionCloseResponse")
    end)

    assert :ok == Netim.Session.close(@session_id)
  end

  test "open/close session using transaction", %{bypass: bypass} do
    parent = self()
    Bypass.expect(bypass, "POST", "/2.0/", fn conn ->
      case Plug.Conn.get_req_header(conn, "soapaction") do
        ["sessionOpen"] ->
          response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

        ["sessionClose"] ->
          response(conn, "sessionCloseResponse")
      end
    end)

    assert {:session, @session_id} == Netim.Session.transaction(&send(parent, {:session, &1}), @reseller_id, @password)

    assert_receive {:session, @session_id}, 500
  end

  test "info session", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/2.0/", fn conn ->
      case Plug.Conn.get_req_header(conn, "soapaction") do
        ["sessionInfo"] ->
          response(conn, "sessionInfoResponse", [{"return", [{"IDSession", @session_id}, {"timeLogin", 1681259368}, {"timeLastActivity", 1681259578}, {"lang", "EN"}, {"sync", 1}]}])
      end
    end)

    assert %Netim.Session.Info{session_id: @session_id, time_login_unix: 1681259368, time_last_activity_unix: 1681259578, lang: :en, sync: true} == Netim.Session.info(@session_id)
  end

  test "list active sessions", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/2.0/", fn conn ->
      case Plug.Conn.get_req_header(conn, "soapaction") do
        ["queryAllSessions"] ->
          response(conn, "queryAllSessionsResponse", [{"return", [[{"IDSession", @session_id}, {"timeLogin", 1681259368}, {"timeLastActivity", 1681259578}, {"lang", "EN"}, {"sync", 1}]]}])
      end
    end)

    assert [%Netim.Session.Info{session_id: @session_id, time_login_unix: 1681259368, time_last_activity_unix: 1681259578, lang: :en, sync: true}] == Netim.Session.get_all_sessions(@session_id)
  end
end
