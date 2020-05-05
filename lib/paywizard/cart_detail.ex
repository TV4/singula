defmodule Paywizard.CartDetail.Item.Trial do
  defstruct [
    :free_trial,
    :first_payment_date
  ]
end

defmodule Paywizard.CartDetail.Item do
  defstruct [
    :cost,
    :quantity,
    :trial,
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
      trial: free_trial?(trial)
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

  defp free_trial?(%{"applied" => applied, "firstPaymentDate" => paymentDate}) do
    {:ok, payment_date, utc_offset} = DateTime.from_iso8601(paymentDate)
    first_payment_date = payment_date |> DateTime.add(utc_offset) |> DateTime.to_date()
    %Paywizard.CartDetail.Item.Trial{free_trial: applied, first_payment_date: first_payment_date}
  end

  defp free_trial?(%{"applied" => applied}), do: %Paywizard.CartDetail.Item.Trial{free_trial: applied}
  defp free_trial?(_), do: nil
end

defmodule Paywizard.CartDetail do
  alias Paywizard.CartDetail.Item

  defstruct [:order_id, :contract_id, :total_cost, :currency, items: []]

  @type t :: %__MODULE__{currency: Paywizard.Client.currency()}

  def new(cart_payload) do
    %{
      "amount" => amount,
      "currency" => currency
    } = cart_payload["totalCost"]

    %__MODULE__{
      contract_id: get_in(cart_payload, ["contractDetails", "contractId"]),
      order_id: cart_payload["orderId"],
      total_cost: amount,
      currency: String.to_atom(currency),
      items: Enum.map(cart_payload["items"], &Item.new/1)
    }
  end
end
