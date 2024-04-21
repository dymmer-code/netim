defmodule Netim.Domain.Check do
  @moduledoc """
  Domain check struct. The information needed for getting all of the
  information of the checking domain.
  """
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

  @typedoc """
  The return of some functions is including the following fields:

  - `domain` the name of the domain
  - `result` it could be whatever of the following states:
    - `nil` nothing, the checking has no an status
    - `available` the domain queried is available
    - `not_available` the domain is unavailable
    - `unknown` the status of the domain is unknown, maybe invalid
    - `not_sold` the status is not sold (maybe related to trade)
    - `closed` the status is closed (maybe related to trade)
  - `reason` it could be whatever of the followin reasons:
    - `nil` no reason
    - `reserved` the domain is reserved so, maybe it's also unavailable
    - `pending_application`
    - `premium` the domain should be bought in a special way
    - `timeout` the request failed because of a timeout
    - `internal_error` the request failed because of an internal error
    - `bad_syntax` the request was malformed
  """
  typed_embedded_schema do
    field(:domain, :string, primary_key: true)
    field(:result, Ecto.Enum, values: @domain_check_results)
    field(:reason, Ecto.Enum, values: @domain_check_reasons)
  end

  @doc """
  Perform a conversion of a parameters provided by Netim to
  the struct defined in its module.
  """
  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
