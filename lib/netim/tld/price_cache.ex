defmodule Netim.Tld.PriceCache do
  @moduledoc """
  The price cache module is responsible for caching the prices.
  """
  use GenServer
  require Logger
  alias Netim.Tld

  @default_refresh_interval :timer.hours(24)

  @wait_before_retry :timer.seconds(5)

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Retrieve from cache the prices for the given TLD.
  """
  @spec get_prices_by_tld(String.t()) :: Tld.t() | nil
  def get_prices_by_tld(tld) do
    GenServer.call(__MODULE__, {:get_prices_by_tld, tld})
  end

  @impl GenServer
  @doc false
  def init([]) do
    if Application.get_env(:netim, :auto_refresh, true) do
      {:ok, %{timestamp: NaiveDateTime.utc_now()}, {:continue, :refresh}}
    else
      {:ok, %{}}
    end
  end

  @impl GenServer
  @doc false
  def handle_continue(:refresh, state) do
    Logger.info("populating cache")
    timeout = Application.get_env(:netim, :refresh_interval_ms, @default_refresh_interval)

    if price_list = Netim.Tld.price_list() do
      Logger.info("cache ready")

      state
      |> Map.put(:prices, price_list)
      |> Map.put(:timestamp, NaiveDateTime.utc_now())
      |> refresh(timeout)
    else
      Logger.error("using (#{state.timestamp}) - cannot populate the cache")
      refresh(state, @wait_before_retry)
    end
  end

  defp refresh(%{timer_ref: timer_ref} = state, timeout) do
    Process.cancel_timer(timer_ref)
    refresh(Map.delete(state, :timer_ref), timeout)
  end

  defp refresh(state, timeout) do
    timer_ref = Process.send_after(self(), :refresh, timeout)
    {:noreply, Map.put(state, :timer_ref, timer_ref)}
  end

  @impl GenServer
  @doc false
  def handle_info(:refresh, state) do
    {:noreply, state, {:continue, :refresh}}
  end

  @impl GenServer
  @doc false
  def handle_call({:get_prices_by_tld, tld}, _from, state) do
    if tld = Enum.find(state.prices, &(&1.tld == tld)) do
      {:reply, tld, state}
    else
      {:reply, nil, state}
    end
  end
end
