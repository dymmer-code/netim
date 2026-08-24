defmodule Netim.FaultTest do
  use ExUnit.Case, async: true

  test "loads fault structure" do
    data = %{"faultcode" => "E01-M0101", "faultstring" => "Session expired"}
    fault = Ecto.embedded_load(Netim.Fault, data, :json)
    assert %Netim.Fault{} = fault
    assert fault.code == "E01-M0101"
    assert fault.message == "Session expired"
  end
end
