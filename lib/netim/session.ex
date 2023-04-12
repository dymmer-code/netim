defmodule Netim.Session do
  require Logger
  alias Netim.Session.Info

  @opaque session_id() :: String.t()
  @type reseller_id() :: String.t() | nil
  @type password() :: String.t() | nil
  @type language() :: String.t()

  @spec open(reseller_id()) :: session_id() | nil
  @spec open(reseller_id(), password()) :: session_id() | nil
  @spec open(reseller_id(), password(), language()) :: session_id() | nil
  def open(id_reseller \\ nil, password \\ nil, language \\ "EN") do
    id_reseller = id_reseller || Application.get_env(:netim, :id_reseller)
    password = password || Application.get_env(:netim, :password)

    "sessionOpen"
    |> Netim.base([id_reseller, password, language])
    |> Netim.request()
    |> case do
      {:ok, %{"IDSession" => session}} ->
        session

      error ->
        Logger.error("cannot open session: #{inspect(error)}")
        nil
    end
  end

  @spec close(session_id()) :: :ok | {:error, any()}
  def close(id_session) do
    "sessionClose"
    |> Netim.base([{"IDSession", id_session}])
    |> Netim.request()
    |> case do
      {:ok, %{}} ->
        :ok

      error ->
        Logger.error("cannot close session: #{inspect(error)}")
        error
    end
  end

  @spec info(session_id()) :: Info.t() | nil
  def info(id_session) do
    "sessionInfo"
    |> Netim.base([{"IDSession", id_session}])
    |> Netim.request()
    |> case do
      {:ok, %{"return" => return}} ->
        Info.cast(return)

      error ->
        Logger.error("cannot get session info: #{inspect(error)}")
        nil
    end
  end

  @spec set_sync(session_id(), boolean()) :: :ok | {:error, any()}
  def set_sync(id_session, true), do: set_preference(id_session, "sync", "1")
  def set_sync(id_session, false), do: set_preference(id_session, "sync", "0")

  @spec set_lang(session_id(), Info.languages()) :: :ok | {:error, any()}
  def set_lang(id_session, :en), do: set_preference(id_session, "lang", "EN")
  def set_lang(id_session, :fr), do: set_preference(id_session, "lang", "FR")

  defp set_preference(id_session, type, value) do
    "sessionSetPreference"
    |> Netim.base([id_session, type, value])
    |> Netim.request()
    |> case do
      {:ok, %{}} ->
        :ok

      error ->
        Logger.error("cannot set #{type} preference: #{inspect(error)}")
        error
    end
  end

  @spec get_all_sessions(session_id()) :: [Info.t()] | nil
  def get_all_sessions(id_session) do
    "queryAllSessions"
    |> Netim.base([id_session])
    |> Netim.request()
    |> case do
      {:ok, %{"return" => sessions_info}} ->
        Enum.map(sessions_info, &Info.cast/1)

      error ->
        Logger.error("cannot list sessions: #{inspect(error)}")
        nil
    end
  end

  @spec transaction((session_id() -> any())) :: any()
  @spec transaction((session_id() -> any()), reseller_id()) :: any()
  @spec transaction((session_id() -> any()), reseller_id(), password()) :: any()
  @spec transaction((session_id() -> any()), reseller_id(), password(), language()) :: any()
  def transaction(f, id_reseller \\ nil, password \\ nil, language \\ "EN") do
    if session = open(id_reseller, password, language) do
      try do
        f.(session)
      after
        close(session)
      end
    else
      {:error, :cannot_open_session}
    end
  end
end
