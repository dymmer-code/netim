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
    results =
      String.split(numbers, [";", ":"])
      |> Enum.flat_map(fn block ->
        only_one_number = Integer.parse(block)
        nums = String.split(block, "-", parts: 2)

        cond do
          match?({_, ""}, only_one_number) ->
            [elem(only_one_number, 0)]

          match?([_, _], nums) ->
            [n1, n2] = nums
            n1 = String.to_integer(n1)
            n2 = String.to_integer(n2)
            Enum.to_list(Range.new(n1, n2))

          :else ->
            :error
        end
      end)

    if Enum.any?(results, &is_atom/1) do
      :error
    else
      {:ok, Enum.uniq(results)}
    end
  end

  @doc false
  def load(data), do: cast(data)

  @doc false
  def dump(data) when is_list(data) do
    data
    |> Enum.sort()
    |> Enum.uniq()
    |> Enum.map(&to_string/1)
    |> Enum.join(":")
    |> then(&{:ok, &1})
  end
end
