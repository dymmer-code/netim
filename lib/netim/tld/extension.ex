defmodule Netim.Tld.Extension do
  @moduledoc """
  Extension is giving the different extensions available for the TLD.
  """
  use TypedEctoSchema

  @primary_key false

  @typedoc """
  The extension, each extension could be popular, regional, or functional.
  """
  typed_embedded_schema do
    field(:tld, {:array, :string})
    field(:type, Ecto.Enum, values: ~w[ popular regional functional ]a)
  end
end
