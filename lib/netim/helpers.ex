defmodule Netim.Helpers do
  @moduledoc """
  Helpers for letting load data into schemas in a more relaxed way,
  instead of the Ecto.embedded_load function.
  """
  import Ecto.Changeset

  @doc """
  Let us load the `params` passed as second parameter into a schema
  based on the `module` passed as first parameter.
  """
  def load(module, params) do
    defaults = module.__schema__(:loaded)

    for {key, data} <- module.__schema__(:load), into: %{} do
      case data do
        {:source, name, type} ->
          {key, to_type(type, params[to_string(name)] || Map.get(defaults, key))}

        type ->
          {key, to_type(type, params[to_string(key)] || Map.get(defaults, key))}
      end
    end
    |> then(&struct(module, &1))
  end

  defp to_type(_, nil), do: nil
  defp to_type(:date, ""), do: nil
  defp to_type(:date, date), do: Date.from_iso8601!(date)
  defp to_type({:parameterized, {Ecto.Enum, opts}}, key), do: opts[:on_load][key]
  defp to_type(_, data), do: data

  def traverse_errors(changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(
        ~r"%{(\w+)}",
        msg,
        fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end
      )
    end)
  end
end
