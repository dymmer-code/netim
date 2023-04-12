defmodule Netim.Case do
  alias Proximal.Xmlel

  def netim_setup(_args) do
    bypass = Bypass.open()
    Application.put_env(:netim, :url, endpoint_url(bypass))
    {:ok, bypass: bypass}
  end

  defmacro __using__(_args) do
    quote do
      use ExUnit.Case
      import Netim.Case

      setup :netim_setup
    end
  end

  defp endpoint_url(bypass) do
    "http://localhost:#{bypass.port}/2.0/"
  end

  def envelope(name, data) do
    Netim.base(name, data)
    |> Proximal.to_xmlel()
    |> to_string()
  end

  def response(conn, name, data \\ []) do
    Plug.Conn.resp(conn, 200, envelope(name ,data))
  end

  def response(conn, :error, code, string) do
    Plug.Conn.resp(conn, 500, fault(code ,string))
  end

  def fault(code, string) do
    Xmlel.new("soap-env:Envelope", %{"xmlns:soap-env" => "http://schemas.xmlsoap.org/soap/envelope/"}, [
      Xmlel.new("soap-env:Body", %{}, [
        Xmlel.new("soap-env:Fault", %{}, [
          Xmlel.new("faultcode", %{}, [code]),
          Xmlel.new("faultstring", %{}, ["#{code} : #{string}"])
        ])
      ])
    ])
    |> to_string()
  end
end
