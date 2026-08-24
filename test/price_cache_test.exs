defmodule Netim.Tld.PriceCacheTest do
  use ExUnit.Case

  alias Netim.Tld.PriceCache

  test "init and get_prices_by_tld handle state directly" do
    prices = [
      %Netim.Tld.Price{tld: "com", registration: Decimal.new("10.00")},
      %Netim.Tld.Price{tld: "es", registration: Decimal.new("5.00")}
    ]

    state = %{prices: prices, timestamp: NaiveDateTime.utc_now()}

    assert {:reply, %Netim.Tld.Price{tld: "com"}, _state} =
             PriceCache.handle_call({:get_prices_by_tld, "com"}, self(), state)

    assert {:reply, nil, _state} =
             PriceCache.handle_call({:get_prices_by_tld, "org"}, self(), state)
  end

  test "init with auto_refresh false" do
    Application.put_env(:netim, :auto_refresh, false)
    assert {:ok, %{}} = PriceCache.init([])
    Application.put_env(:netim, :auto_refresh, true)
  end

  test "handle_info :refresh returns continue refresh" do
    state = %{prices: [], timestamp: NaiveDateTime.utc_now()}
    assert {:noreply, ^state, {:continue, :refresh}} = PriceCache.handle_info(:refresh, state)
  end
end
