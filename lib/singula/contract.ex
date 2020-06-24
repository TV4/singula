defmodule Singula.Contract do
  defstruct [:contract_id, :order_id, :item_id, :item_name, :active]

  @type contract_id :: integer | binary
  @type t :: %__MODULE__{contract_id: contract_id, order_id: integer, item_id: binary, active: boolean}

  def new(%{"contractCount" => 0}), do: []

  def new(%{"contractCount" => _} = response) do
    response["contracts"]
    |> Enum.map(fn contract ->
      %__MODULE__{
        contract_id: contract["contractId"],
        order_id: contract["orderId"],
        item_id: contract["itemCode"],
        item_name: contract["name"],
        active: contract["active"]
      }
    end)
  end
end
