defmodule Netim.HelpersTest do
  use ExUnit.Case, async: true
  alias Netim.Helpers

  defmodule SampleSchema do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema do
      field(:name, :string)
      field(:created_at, :date, source: :date_create)
      field(:status, Ecto.Enum, values: [active: 1, inactive: 0], source: :is_active)
    end
  end

  test "load parses data and handles sources, dates, and enums" do
    params = %{
      "name" => "example",
      "date_create" => "2026-08-24",
      "is_active" => 1
    }

    result = Helpers.load(SampleSchema, params)
    assert result.name == "example"
    assert result.created_at == ~D[2026-08-24]
    assert result.status == :active
  end

  test "load handles nil and empty dates" do
    params = %{
      "name" => "example",
      "date_create" => "",
      "is_active" => nil
    }

    result = Helpers.load(SampleSchema, params)
    assert is_nil(result.created_at)
    assert is_nil(result.status)
  end

  test "traverse_errors formats changeset errors with opts" do
    import Ecto.Changeset
    data = %{name: nil}
    types = %{name: :string}

    changeset =
      {data, types}
      |> cast(%{}, [:name])
      |> validate_required([:name])

    errors = Helpers.traverse_errors(changeset)
    assert errors == %{name: ["can't be blank"]}
  end
end
