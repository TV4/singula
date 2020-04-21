defmodule Paywizard.CartDetail.Item do
  defstruct [
    :cost,
    :quantity,
    :eligible_for_free_trial,
    :item_id,
    :item_name,
    :asset
  ]

  # creates a Subscription Item (free trial is applicable for some subscriptions)
  def new(%{
        "cost" => amount_and_currency,
        "quantity" => quantity,
        "itemCode" => item_id,
        "itemName" => name,
        "freeTrial" => trial
      }) do
    %__MODULE__{
      cost: cost(amount_and_currency),
      quantity: quantity,
      item_id: item_id,
      item_name: name,
      eligible_for_free_trial: free_trial?(trial)
    }
  end

  # creates a PPV Item (free trial not applicable for PPV)
  def new(%{
        "cost" => amount_and_currency,
        "quantity" => quantity,
        "itemCode" => item_id,
        "itemName" => name,
        "itemData" => item_data
      }) do
    %__MODULE__{
      cost: cost(amount_and_currency),
      quantity: quantity,
      item_id: item_id,
      item_name: name,
      asset: to_asset(item_data)
    }
  end

  defp to_asset(""), do: nil
  defp to_asset(asset_data), do: %Paywizard.Asset{id: asset_data["id"], title: asset_data["name"]}
  defp cost(%{"amount" => cost}), do: cost
  defp free_trial?(%{"applied" => free}), do: free
  defp free_trial?(_), do: nil
end

defmodule Paywizard.CartDetail do
  alias Paywizard.CartDetail.Item

  defstruct [:order_id, :total_cost, :currency, items: []]

  @type t :: %__MODULE__{currency: Paywizard.Client.currency()}

  def new(fetch_cart_payload) do
    %{
      "amount" => amount,
      "currency" => currency
    } = fetch_cart_payload["totalCost"]

    %__MODULE__{
      order_id: fetch_cart_payload["orderId"],
      total_cost: amount,
      currency: String.to_atom(currency),
      items: Enum.map(fetch_cart_payload["items"], &Item.new/1)
    }
  end
end
