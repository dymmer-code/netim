defmodule Netim.Session.Info do
  @moduledoc """
  Information about the opened session.
  """
  use TypedEctoSchema

  @boolean [true: 1, false: 0]
  @languages [en: "EN", fr: "FR"]

  @type languages() :: :en | :fr

  @primary_key false

  @typedoc """
  The information available about the session is:

  - `session_id` is the ID for the session.
  - `time_login_unix` is the time in seconds in epoch format.
  - `time_last_activity_unix` is the last time the session performed an action.
  - `lang` the language used, it could be or `:en` (English) or `:fr` (French).
  - `sync?` is the session sync?
  """
  typed_embedded_schema do
    field(:session_id, :string, source: :IDSession)
    field(:time_login_unix, :integer, source: :timeLogin)
    field(:time_last_activity_unix, :integer, source: :timeLastActivity)
    field(:lang, Ecto.Enum, values: @languages) :: languages()
    field(:sync?, Ecto.Enum, values: @boolean, source: :sync)
  end

  @doc """
  Perform a conversion of a parameters provided by Netim to
  the struct defined in its module.
  """
  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
