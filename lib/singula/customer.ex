defmodule Singula.Address do
  defstruct [:post_code, :country_code]
  @type t :: %__MODULE__{}
end

defmodule Singula.Customer do
  defstruct [
    :id,
    :external_unique_id,
    :username,
    :password,
    :first_name,
    :last_name,
    :email,
    :date_of_birth,
    :active,
    addresses: [],
    custom_attributes: []
  ]

  @type id :: <<_::288>>
  @type t :: %__MODULE__{id: id | nil, active: boolean | nil, addresses: list(Singula.Address.t())}

  def new(payload) do
    %Singula.Customer{
      id: Map.get(payload, "customerId"),
      external_unique_id: Map.get(payload, "externalUniqueIdentifier") |> to_string(),
      username: Map.get(payload, "username"),
      first_name: Map.get(payload, "firstName"),
      last_name: Map.get(payload, "lastName"),
      email: Map.get(payload, "email"),
      date_of_birth: Map.get(payload, "dateOfBirth"),
      addresses:
        Map.get(payload, "addresses", [])
        |> Enum.map(fn address ->
          %Singula.Address{post_code: address["postCode"], country_code: address["countryCode"]}
        end),
      active: Map.get(payload, "active"),
      custom_attributes:
        Map.get(payload, "customAttributes", [])
        |> Enum.map(fn %{"name" => name, "value" => value} -> %{name: name, value: value} end)
    }
  end

  def to_payload(customer) do
    %{
      externalUniqueIdentifier: customer.external_unique_id,
      username: customer.username,
      password: customer.password,
      firstName: customer.first_name,
      lastName: customer.last_name,
      email: customer.email,
      dateOfBirth: customer.date_of_birth,
      addresses:
        customer.addresses
        |> Enum.map(fn address ->
          %{postCode: address.post_code, countryCode: address.country_code}
        end),
      customAttributes: customer.custom_attributes
    }
  end
end
