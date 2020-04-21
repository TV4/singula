defmodule Paywizard.Customer do
  @enforce_keys [:customer_id, :active]
  defstruct [
    :customer_id,
    :external_unique_id,
    :username,
    :first_name,
    :last_name,
    :email,
    :date_of_birth,
    :address_post_code,
    :active,
    custom_attributes: []
  ]

  @type customer_id :: <<_::288>>
  @type t :: %__MODULE__{customer_id: customer_id, active: boolean}

  def new(response) do
    %Paywizard.Customer{
      customer_id: Map.get(response, "customerId"),
      external_unique_id: Map.get(response, "externalUniqueIdentifier") |> to_string(),
      username: Map.get(response, "username"),
      first_name: Map.get(response, "firstName"),
      last_name: Map.get(response, "lastName"),
      email: Map.get(response, "email"),
      date_of_birth: Map.get(response, "dateOfBirth"),
      address_post_code: get_in(response, ["addresses", Access.at(0), "postCode"]),
      active: Map.get(response, "active"),
      custom_attributes:
        Map.get(response, "customAttributes", [])
        |> Enum.map(fn %{"name" => name, "value" => value} -> %{name: name, value: value} end)
    }
  end
end
