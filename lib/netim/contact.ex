defmodule Netim.Contact do
  use TypedEctoSchema
  import Ecto.Changeset
  require Logger
  alias Netim.Session

  @name_regex ~r|^[a-zA-Zàáâãäåāăąæçćĉċčďđèéêëēĕėęěĝġģĥħìíîïĩīĭįıĵķĺļľŀłñńņňŉòóôõöōŏőøœŕŗřśŝšșťŧț
  úûüũūŭůűųŵýÿŷźżžßÀÁÂÃÄÅĀĂĄÆÇĆĈĊČĎĐÈÉÊËĒĔĖĘĚĜĠĢĤĦÌÍÎÏĨĪĬĮIĴĶĹĻĽĿŁÑŃŅŇÒÓÔÕÖŌŎŐØŒŔŖŘŚŜŠȘŤŦȚÙÚÛÜŨŪŬŮŰŲŴÝŸŶ
  ŹŻŽ\ \-\']{0,30}$|

  @company_name_regex ~r|^[0-9a-zA-Zàáâãäåāăąæçćĉċčďđèéêëēĕėęěĝġģĥħìíîïĩīĭįıĵķĺļľŀłñńņňŉòóôõöōŏőøœŕŗřśŝšș
  ťŧțúûüũūŭůűųŵýÿŷźżžßÀÁÂÃÄÅĀĂĄÆÇĆĈĊČĎĐÈÉÊËĒĔĖĘĚĜĠĢĤĦÌÍÎÏĨĪĬĮIĴĶĹĻĽĿŁÑŃŅŇÒÓÔÕÖŌŎŐØŒŔŖŘŚŜŠȘŤŦȚÙÚÛÜŨŪŬŮŰŲŴ
  ÝŸŶŹŻŽ&\ \-\,\.\'\/]{0,100}$|

  @address_regex ~r|^[0-9a-zA-Zàáâãäåāăąæçćĉċčďđèéêëēĕėęěĝġģĥħìíîïĩīĭįıĵķĺļľŀłñńņňŉòóôõöōŏőøœŕŗřśŝšș
  ťŧțúûüũūŭůűųŵýÿŷźżžßÀÁÂÃÄÅĀĂĄÆÇĆĈĊČĎĐÈÉÊËĒĔĖĘĚĜĠĢĤĦÌÍÎÏĨĪĬĮIĴĶĹĻĽĿŁÑŃŅŇÒÓÔÕÖŌŎŐØŒŔŖŘŚŜŠȘŤŦȚÙÚÛÜŨŪŬŮŰŲŴ
  ÝŸŶŹŻŽ&\ \-\,\.\'\/]{0,80}$|

  @primary_key false
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:first_name, :string, source: :firstName)
    field(:last_name, :string, source: :lastName)

    field(:body_form, Ecto.Enum,
      values: [individual: "IND", organization: "ORG"],
      default: :individual,
      source: :bodyForm,
      embed_as: :dumped
    )

    field(:body_name, :string, source: :bodyName)
    field(:address1, :string)
    field(:address2, :string)
    field(:zip_code, :string, source: :zipCode)
    field(:area, :string)
    field(:city, :string)
    field(:country, :string)
    field(:phone, :string)
    field(:fax, :string)
    field(:email, :string)
    field(:language, Ecto.Enum, values: [en: "EN", fr: "FR"], default: :en, embed_as: :dumped)

    field(:is_owner, Ecto.Enum,
      values: [true: 1, false: 0],
      default: false,
      source: :isOwner,
      embed_as: :dumped
    )

    #  tm (Trademark) data
    field(:tm_name, :string, source: :tmName)
    field(:tm_date, :date, source: :tmDate)
    field(:tm_number, :string, source: :tmNumber)

    field(:tm_type, Ecto.Enum,
      values: [nil: "", national: "INPI", european: "OHIM", international: "WIPO"],
      source: :tmType,
      embed_as: :dumped
    )

    field(:company_number, :string, source: :companyNumber)
    field(:vat_number, :string, source: :vatNumber)
    field(:birth_date, :date, source: :birthDate)
    field(:birth_zip_code, :string, source: :birthZipCode)
    field(:birth_city, :string, source: :birthCity)
    field(:birth_country, :string, source: :birthCountry)
    field(:id_number, :string, source: :idNumber)
    field(:additional, :map, default: %{})
  end

  @required_fields ~w[first_name last_name address1 zip_code city country phone email]a
  @optional_fields ~w[body_form body_name address2 area fax language is_owner tm_name tm_date tm_number tm_type company_number vat_number birth_date birth_country birth_zip_code birth_city id_number additional]a

  def info(contact), do: Session.transaction(&info(&1, contact))

  def info(id_session, contact_id) do
    "contactInfo"
    |> Netim.base([id_session, contact_id])
    |> Netim.request()
    |> case do
      {:ok, %{"contact" => contact}} ->
        contact
        |> Map.put("id", contact_id)
        |> then(&Ecto.embedded_load(__MODULE__, &1, :json))

      error ->
        Logger.error("cannot get contact info: #{inspect(error)}")
        nil
    end
  end

  def changeset(contact \\ %__MODULE__{}, params) when is_map(params) do
    contact
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:first_name, @name_regex)
    |> validate_length(:first_name, max: 30)
    |> validate_format(:last_name, @name_regex)
    |> validate_length(:last_name, max: 30)
    |> validate_format(:body_name, @company_name_regex)
    |> validate_length(:body_name, max: 100)
    |> validate_format(:address1, @address_regex)
    |> validate_length(:address1, max: 80)
    |> validate_format(:address2, @address_regex)
    |> validate_length(:address2, max: 80)
    |> validate_length(:zip_code, max: 10)
    |> validate_length(:area, max: 5)
    |> validate_subdivision(:country, :area)
    |> validate_length(:city, max: 30)
    |> validate_format(:city, @address_regex)
    |> validate_country(:country, message: "invalid country")
    |> validate_format(:phone, ~r/^\+[0-9]{2} [0-9]+$/)
    |> validate_length(:phone, max: 17)
    |> validate_format(:fax, ~r/^\+[0-9]{2} [0-9]+$/)
    |> validate_length(:fax, max: 17)
    |> validate_length(:email, max: 255)
    |> validate_organization_data()
    |> case do
      changeset when changeset.valid? ->
        changeset
        |> apply_changes()
        |> Ecto.embedded_dump(:json)
        |> to_arguments()
        |> then(&{:ok, &1})

      changeset ->
        {:error, changeset.errors}
    end
  end

  defp areas_for(country) do
    country
    |> Countries.get()
    |> Countries.Subdivisions.all()
    |> Enum.map(&to_string(&1.id))
  end

  @countries_required_areas ~w[ AU BR CA IE IT JP MX GB US ]

  defp validate_subdivision(changeset, country_field, area_field) do
    country = get_field(changeset, country_field)
    area = get_field(changeset, area_field)

    error =
      (country in @countries_required_areas and area not in areas_for(country)) or
        (country not in @countries_required_areas and area not in ["", nil])

    if error do
      add_error(changeset, area_field, "invalid area for given country")
    else
      changeset
    end
  end

  defp validate_organization_data(changeset) do
    if get_field(changeset, :body_form) == :organization do
      changeset
      |> validate_length(:tm_name, max: 50)
      |> validate_length(:tm_number, max: 20)
      |> validate_length(:company_number, max: 20)
      |> validate_length(:vat_number, max: 20)
      |> validate_length(:id_number, max: 20)
      |> validate_length(:birth_zip_code, max: 10)
      |> validate_length(:birth_city, max: 50)
      |> validate_country(:birth_country, message: "invalid country")
    else
      changeset
    end
  end

  defp validate_country(changeset, country_field, opts) do
    with country when country != nil <- get_field(changeset, country_field),
         false <- Countries.exists?(:alpha2, country) do
      add_error(changeset, country_field, opts[:message])
    else
      _ -> changeset
    end
  end

  defp to_arguments(arguments) when is_map(arguments) or is_list(arguments) do
    for {key, value} <- arguments do
      {to_string(key), if(is_map(value) or is_list(value), do: to_arguments(value), else: value)}
    end
  end

  def create(data) when is_list(data) do
    create(Map.new(data))
  end

  def create(data) when is_map(data) do
    Session.transaction(&create(&1, data))
  end

  def create(id_session, params) do
    with {:ok, data} <- changeset(params) do
      "contactCreate"
      |> Netim.base([{"IDSession", id_session}, {"contact", data}])
      |> Netim.request()
    end
  end

  def update(contact, data) when is_list(data) do
    update(contact, Map.new(data))
  end

  def update(contact, data) when is_map(data) do
    Session.transaction(&update(&1, contact, data))
  end

  def update(id_session, contact, params) do
    with {:ok, data} <- changeset(contact, params) do
      "contactUpdate"
      |> Netim.base([{"IDSession", id_session}, {"idContact", contact.id}, {"contact", data}])
      |> Netim.request()
      |> Netim.Operation.cast()
    end
  end

  def delete(contact_id) do
    Session.transaction(&delete(&1, contact_id))
  end

  def delete(id_session, contact_id) do
    "contactDelete"
    |> Netim.base([{"IDSession", id_session}, {"idContact", contact_id}])
    |> Netim.request()
    |> Netim.Operation.cast()
  end
end
