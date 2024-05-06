defmodule Netim.Reseller do
  @moduledoc """
  Get information and settings about the reseller account.
  """
  use TypedEctoSchema

  alias Netim.Session
  alias Netim.Soap, as: NetimSoap

  @primary_key false

  typed_embedded_schema do
    field(:balance_amount, :decimal)
    field(:balance_low_limit, :decimal)
    field(:balance_hard_limit, :decimal)
    field(:domain_auto_renew, Ecto.Enum, values: [true: 1, false: 0], embed_as: :dumped)
    field(:hosting_auto_renew, Ecto.Enum, values: [true: 1, false: 0], embed_as: :dumped)
    field(:default_owner, :string)
    field(:default_admin, :string)
    field(:default_tech, :string)
    field(:default_billing, :string)
    field(:premium_processing, :string)
    field(:default_dns_1, :string)
    field(:default_dns_2, :string)
    field(:default_dns_3, :string)
    field(:default_dns_4, :string)
    field(:default_dns_5, :string)
    field(:default_dns_template, {:array, :map})
  end

  @doc """
  Perform a conversion of a parameters provided by Netim to
  the struct defined in its module.
  """
  def cast(data) do
    data
    |> Map.new(fn {key, value} -> {String.downcase(key), value} end)
    |> then(&Ecto.embedded_load(__MODULE__, &1, :json))
  end

  @doc """
  Retrieve the reseller settings.
  """
  def get_settings do
    Session.transaction(&get_settings/1)
  end

  def get_settings(id_session) do
    "queryResellerAccount"
    |> NetimSoap.base([id_session])
    |> NetimSoap.request()
    |> case do
      {:ok, %{"return" => data}} -> cast(data)
      {:error, _} = error -> error
    end
  end
end
