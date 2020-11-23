defmodule Singula.PPV do
  alias Singula.Asset

  defstruct [:order_id, :item_id, :asset, entitlements: []]

  @type t :: %__MODULE__{order_id: integer, item_id: binary, asset: Asset.t(), entitlements: [Singula.Entitlement.t()]}

  def new(purchases) do
    purchases
    |> Enum.map(fn purchase ->
      %__MODULE__{
        order_id: purchase["orderId"],
        item_id: purchase["salesItemCode"],
        asset: %Asset{id: purchase["itemData"]["id"], title: purchase["itemData"]["name"]},
        entitlements: Enum.map(purchase["entitlements"], fn entitlement -> Singula.Entitlement.new(entitlement) end)
      }
    end)
  end
end
