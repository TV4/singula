defmodule Paywizard.PPV do
  alias Paywizard.Asset

  defstruct [:order_id, :item_id, :asset]

  @type t :: %__MODULE__{order_id: integer, item_id: binary, asset: Asset.t()}

  def new(purchases) do
    purchases
    |> Enum.map(fn purchase ->
      %__MODULE__{
        order_id: purchase["orderId"],
        item_id: purchase["salesItemCode"],
        asset: %Asset{id: purchase["itemData"]["id"], title: purchase["itemData"]["name"]}
      }
    end)
  end
end
