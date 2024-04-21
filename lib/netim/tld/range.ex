defmodule Netim.Tld.Range do
  @moduledoc """
  Define a range of numbers, useful for example for range of years
  when we want to renew a domain.
  """
  use Ecto.Type

  @type t() :: Range.t()

  @doc false
  def type, do: :string

  @doc false
  def cast(nil), do: nil

  def cast(numbers) when is_binary(numbers) do
    with [n1, n2] <- String.split(numbers, "-", parts: 2),
         {first, ""} <- Integer.parse(n1),
         {last, ""} <- Integer.parse(n2),
         true <- first <= last do
      {:ok, Range.new(first, last)}
    else
      _ -> :error
    end
  end

  @doc false
  def load(data), do: cast(data)

  @doc false
  def dump(data) when is_struct(data, Range), do: {:ok, "#{data.first}-#{data.last}"}
end
