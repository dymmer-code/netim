defmodule Netim.ContactTest do
  use Netim.Case

  @session_id "123456789012345678901234567890ab"
  @valid_individual_params %{
    first_name: "Manuel",
    last_name: "Rubio",
    address1: "Calle Mayor 1",
    zip_code: "28001",
    city: "Madrid",
    country: "ES",
    phone: "+34 600000000",
    email: "manuel@example.com"
  }

  @valid_org_params %{
    first_name: "Manuel",
    last_name: "Rubio",
    body_form: :organization,
    body_name: "Altenwald Solutions",
    address1: "Calle Mayor 1",
    zip_code: "28001",
    city: "Madrid",
    country: "ES",
    phone: "+34 600000000",
    email: "manuel@example.com",
    vat_number: "ESB12345678"
  }

  describe "changeset validation" do
    test "validates required fields for individual" do
      assert {:ok, _} = Netim.Contact.changeset(@valid_individual_params)
    end

    test "fails when required fields are missing" do
      assert {:error, errors} = Netim.Contact.changeset(%{})
      assert Keyword.has_key?(errors, :first_name)
      assert Keyword.has_key?(errors, :last_name)
    end

    test "validates organization fields" do
      assert {:ok, _} = Netim.Contact.changeset(@valid_org_params)
    end

    test "validates subdivisions for required countries like US" do
      invalid_us_params =
        Map.merge(@valid_individual_params, %{country: "US", area: "INVALID"})

      assert {:error, errors} = Netim.Contact.changeset(invalid_us_params)
      assert Keyword.has_key?(errors, :area)
    end
  end

  describe "API operations" do
    test "create contact with session", %{bypass: bypass} do
      Passby.expect(bypass, "POST", "/2.0/", fn conn ->
        case Passby.get_req_header(conn, "soapaction") do
          ["contactCreate"] ->
            response(conn, "contactCreateResponse", [{"idContact", "CNT-1234"}])

          ["sessionOpen"] ->
            response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

          ["sessionClose"] ->
            response(conn, "sessionCloseResponse")
        end
      end)

      assert {:ok, "CNT-1234"} = Netim.Contact.create(@valid_individual_params)
    end

    test "create contact handles server error", %{bypass: bypass} do
      Passby.expect(bypass, "POST", "/2.0/", fn conn ->
        response(conn, :error, "E01-M0101", "Creation failed")
      end)

      assert {:error, _} = Netim.Contact.create(@session_id, @valid_individual_params)
    end

    test "info retrieves contact info", %{bypass: bypass} do
      Passby.expect(bypass, "POST", "/2.0/", fn conn ->
        case Passby.get_req_header(conn, "soapaction") do
          ["contactInfo"] ->
            response(conn, "contactInfoResponse", [
              {"contact",
               [
                 {"firstName", "Manuel"},
                 {"lastName", "Rubio"},
                 {"address1", "Calle Mayor 1"},
                 {"zipCode", "28001"},
                 {"city", "Madrid"},
                 {"country", "ES"},
                 {"phone", "+34 600000000"},
                 {"email", "manuel@example.com"},
                 {"bodyForm", "IND"},
                 {"isOwner", 1}
               ]}
            ])

          ["sessionOpen"] ->
            response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

          ["sessionClose"] ->
            response(conn, "sessionCloseResponse")
        end
      end)

      contact = Netim.Contact.info("CNT-1234")
      assert %Netim.Contact{} = contact
      assert contact.first_name == "Manuel"
      assert contact.last_name == "Rubio"
      assert contact.owner? == true
    end

    test "info handles error gracefully", %{bypass: bypass} do
      Passby.expect(bypass, "POST", "/2.0/", fn conn ->
        response(conn, :error, "E01-M0101", "Contact not found")
      end)

      assert is_nil(Netim.Contact.info(@session_id, "NONEXISTENT"))
    end

    test "list contacts by field and filter", %{bypass: bypass} do
      Passby.expect(bypass, "POST", "/2.0/", fn conn ->
        case Passby.get_req_header(conn, "soapaction") do
          ["queryContactList"] ->
            response(conn, "queryContactListResponse", [
              {"queryContactListReturn",
               [
                 [
                   {"idContact", "CNT-1"},
                   {"bodyForm", "IND"},
                   {"firstName", "Manuel"},
                   {"lastName", "Rubio"},
                   {"isOwner", 1}
                 ]
               ]}
            ])

          ["sessionOpen"] ->
            response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

          ["sessionClose"] ->
            response(conn, "sessionCloseResponse")
        end
      end)

      assert {:ok, [c]} = Netim.Contact.list("lastName", "Rubio")
      assert %Netim.Contact.List{} = c
      assert c.id == "CNT-1"
      assert c.first_name == "Manuel"
    end

    test "list contacts error", %{bypass: bypass} do
      Passby.expect(bypass, "POST", "/2.0/", fn conn ->
        response(conn, :error, "E01-M0101", "Error")
      end)

      assert {:error, _} = Netim.Contact.list("lastName", "Error")
    end

    test "update contact for non-owner, owner, and error", %{bypass: bypass} do
      contact = %Netim.Contact{
        id: "CNT-123",
        first_name: "Manuel",
        last_name: "Rubio",
        address1: "Calle Mayor 1",
        zip_code: "28001",
        city: "Madrid",
        country: "ES",
        phone: "+34 600000000",
        email: "manuel@example.com",
        owner?: false
      }

      owner_contact = %{contact | owner?: true}

      Passby.expect(bypass, "POST", "/2.0/", fn conn ->
        case Passby.get_req_header(conn, "soapaction") do
          ["contactUpdate"] ->
            response(conn, "contactUpdateResponse", [
              {"return",
               [
                 {"ID_OPE", 9999},
                 {"DATE", "2026-08-24 00:00:00"},
                 {"MESSAGE", "Contact updated"},
                 {"STATUS", "Done"},
                 {"TYPE", "contactUpdate"}
               ]}
            ])

          ["contactOwnerUpdate"] ->
            response(conn, "contactOwnerUpdateResponse", [
              {"return",
               [
                 {"ID_OPE", 10_000},
                 {"DATE", "2026-08-24 00:00:00"},
                 {"MESSAGE", "Owner contact updated"},
                 {"STATUS", "Done"},
                 {"TYPE", "contactOwnerUpdate"}
               ]}
            ])

          ["sessionOpen"] ->
            response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

          ["sessionClose"] ->
            response(conn, "sessionCloseResponse")
        end
      end)

      assert %Netim.Operation{id: 9999, status: :done} =
               Netim.Contact.update(contact, %{city: "Barcelona"})

      assert %Netim.Operation{id: 10_000, status: :done} =
               Netim.Contact.update(owner_contact, %{city: "Barcelona"})
    end

    test "update contact error response", %{bypass: bypass} do
      contact = %Netim.Contact{
        id: "CNT-123",
        first_name: "Manuel",
        last_name: "Rubio",
        address1: "Calle Mayor 1",
        zip_code: "28001",
        city: "Madrid",
        country: "ES",
        phone: "+34 600000000",
        email: "manuel@example.com",
        owner?: false
      }

      Passby.expect(bypass, "POST", "/2.0/", fn conn ->
        response(conn, :error, "E01-M0101", "Update error")
      end)

      assert %Netim.Fault{code: "E01-M0101"} =
               Netim.Contact.update(@session_id, contact, %{city: "Barcelona"})
    end

    test "delete contact", %{bypass: bypass} do
      Passby.expect(bypass, "POST", "/2.0/", fn conn ->
        case Passby.get_req_header(conn, "soapaction") do
          ["contactDelete"] ->
            response(conn, "contactDeleteResponse", [
              {"return",
               [
                 {"ID_OPE", 8888},
                 {"DATE", "2026-08-24 00:00:00"},
                 {"MESSAGE", "Contact deleted"},
                 {"STATUS", "Done"},
                 {"TYPE", "contactDelete"}
               ]}
            ])

          ["sessionOpen"] ->
            response(conn, "sessionOpenResponse", [{"IDSession", @session_id}])

          ["sessionClose"] ->
            response(conn, "sessionCloseResponse")
        end
      end)

      assert %Netim.Operation{id: 8888, status: :done} = Netim.Contact.delete("CNT-123")
    end
  end
end
