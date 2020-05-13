defmodule Paywizard.CartDetail.Discount do
  defstruct [:discount_end_date, :discount_amount]
end

defmodule Paywizard.CartDetail.Item.Trial do
  defstruct [:free_trial, :first_payment_date, :first_payment_amount]
end

defmodule Paywizard.CartDetail.Item do
  defstruct [:cost, :quantity, :trial, :item_id, :item_name, :asset]

  # creates a PPV Item (free trial not applicable for PPV)
  def new(%{
        "cost" => amount_and_currency,
        "quantity" => quantity,
        "itemCode" => item_id,
        "itemName" => name,
        "itemData" => %{"id" => asset_id, "name" => asset_name}
      }) do
    %__MODULE__{
      cost: cost(amount_and_currency),
      quantity: quantity,
      item_id: item_id,
      item_name: name,
      asset: %Paywizard.Asset{id: asset_id, title: asset_name}
    }
  end

  # creates a Subscription Item with free trial
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

  # creates a Subscription Item without free trial
  def new(%{"cost" => amount_and_currency, "quantity" => quantity, "itemCode" => item_id, "itemName" => name}) do
    %__MODULE__{cost: cost(amount_and_currency), quantity: quantity, item_id: item_id, item_name: name}
  end

  defp cost(%{"amount" => cost}), do: cost

  defp free_trial?(%{
         "applied" => applied,
         "firstPaymentDate" => paymentDate,
         "firstPaymentAmount" => %{"amount" => first_payment_amount}
       }) do
    {:ok, payment_date, utc_offset} = DateTime.from_iso8601(paymentDate)
    first_payment_date = payment_date |> DateTime.add(utc_offset) |> DateTime.to_date()

    %Paywizard.CartDetail.Item.Trial{
      free_trial: applied,
      first_payment_date: first_payment_date,
      first_payment_amount: first_payment_amount
    }
  end

  defp free_trial?(%{"applied" => applied}), do: %Paywizard.CartDetail.Item.Trial{free_trial: applied}
  defp free_trial?(_), do: nil
end

defmodule Paywizard.CartDetail do
  alias Paywizard.CartDetail.Item

  defstruct [:order_id, :contract_id, :total_cost, :currency, :discount, items: []]

  @type t :: %__MODULE__{currency: Paywizard.Client.currency()}

  def new(cart_payload) do
    %{"amount" => amount, "currency" => currency} = cart_payload["totalCost"]

    discount =
      if discount = cart_payload["discount"] do
        %Paywizard.CartDetail.Discount{
          discount_end_date:
            unless(discount["indefinite"], do: Timex.shift(today(), months: discount["numberOfOccurrences"])),
          discount_amount: get_in(discount, ["discountAmount", "amount"])
        }
      end

    %__MODULE__{
      contract_id: get_in(cart_payload, ["contractDetails", "contractId"]),
      order_id: cart_payload["orderId"],
      total_cost: amount,
      currency: String.to_atom(currency),
      items: Enum.map(cart_payload["items"], &Item.new/1),
      discount: discount
    }
  end

  defp today, do: Application.get_env(:paywizard, :today, &Date.utc_today/0).()
end
