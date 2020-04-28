defmodule Paywizard.Contract do
  defstruct [:contract_id, :item_id, :item_name, :active]

  @type contract_id :: integer | binary
  @type t :: %__MODULE__{contract_id: contract_id, active: boolean, item_id: binary}

  def new(%{"contractCount" => 0}), do: []

  def new(%{"contractCount" => _} = response) do
    response["contracts"]
    |> Enum.map(fn contract ->
      %__MODULE__{
        contract_id: contract["contractId"],
        item_id: contract["itemCode"],
        item_name: contract["name"],
        active: contract["active"]
      }
    end)
  end
end
