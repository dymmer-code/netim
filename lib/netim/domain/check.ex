defmodule Netim.Domain.Check do
  use TypedEctoSchema

  @domain_check_results [
    nil: "",
    available: "AVAILABLE",
    not_available: "NOT AVAILABLE",
    unknown: "UNKNOWN",
    not_sold: "NOT SOLD",
    closed: "CLOSED"
  ]

  @domain_check_reasons [
    nil: "",
    reserved: "RESERVED",
    pending_application: "PENDING APPLICATION",
    premium: "PREMIUM",
    timeout: "TIMEOUT",
    internal_error: "INTERNAL ERROR",
    bad_syntax: "BAD_SYNTAX"
  ]

  @primary_key false
  typed_embedded_schema do
    field :domain, :string, primary_key: true
    field :result, Ecto.Enum, values: @domain_check_results
    field :reason, Ecto.Enum, values: @domain_check_reasons
  end

  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
