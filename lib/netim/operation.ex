defmodule Netim.Operation do
  use TypedEctoSchema
  require Logger
  alias Netim.Session
  alias Netim.Operation.List

  @operation_statuses [
    cancelled: "Cancelled",
    done: "Done",
    failed: "Failed",
    pending: "Pending"
  ]

  @primary_key false
  typed_embedded_schema do
    field(:id, :integer, source: :ID_OPE)
    field(:created_at, :naive_datetime, source: :DATE)
    field(:message, :string, source: :MESSAGE)
    field(:status, Ecto.Enum, values: @operation_statuses, source: :STATUS)
    field(:type, :string, source: :TYPE)
  end

  def info(id_operation), do: Session.transaction(&info(&1, id_operation))

  def info(id_session, id_operation) do
    "queryOpe"
    |> Netim.base([id_session, id_operation])
    |> Netim.request()
    |> cast()
  end

  def cast({:ok, %{"return" => params}}) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  def cast(error) do
    Logger.error("cannot get contact info: #{inspect(error)}")
    nil
  end

  def list(tld), do: Session.transaction(&list(&1, tld))

  def list(id_session, tld) do
    "queryOpeList"
    |> Netim.base([id_session, tld])
    |> Netim.request()
    |> case do
      {:ok, %{"return" => return}} ->
        return = Map.put(return, "tld", tld)
        Ecto.embedded_load(List, return, :json)

      error ->
        Logger.error("cannot list TLD operation list: #{inspect(error)}")
        nil
    end
  end
end
