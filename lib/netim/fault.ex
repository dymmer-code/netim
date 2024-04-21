defmodule Netim.Fault do
  @moduledoc """
  Information when we receive a fault object.
  """
  use TypedEctoSchema

  @primary_key false

  @typedoc """
  The fault struct is containing only the code of error (`code`) and
  the message of the error (`message`).
  """
  typed_embedded_schema do
    field(:code, :string, source: :faultcode)
    field(:message, :string, source: :faultstring)
  end
end
