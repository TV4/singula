defmodule Paywizard.PPV do
  defstruct [:order_id, :item_id, :asset_id]

  @type t :: %__MODULE__{order_id: integer, item_id: binary, asset_id: binary}

  def new(purchases) do
    purchases
    |> Enum.map(fn purchase ->
      %__MODULE__{
        order_id: purchase["orderId"],
        item_id: purchase["salesItemCode"],
        asset_id: purchase["itemData"]["id"] |> to_string
      }
    end)
  end
end
