defmodule Netim.Session.Info do
  use TypedEctoSchema

  @boolean [true: "1", false: "0"]
  @languages [en: "EN", fr: "FR"]

  @type languages() :: :en | :fr

  @primary_key false
  typed_embedded_schema do
    field(:session_id, :string, source: :IDSession)
    field(:time_login_unix, :integer, source: :timeLogin)
    field(:time_last_activity_unix, :integer, source: :timeLastActivity)
    field(:lang, Ecto.Enum, values: @languages) :: languages()
    field(:sync, Ecto.Enum, values: @boolean)
  end

  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
