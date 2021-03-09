defmodule Singula.CartDetail.Discount do
  defstruct [:discount_end_date, :discount_amount]

  def new(discount, items) do
    discounted_item = items |> Enum.find(fn item -> item.item_id == discount["itemCode"] end)

    %Singula.CartDetail.Discount{
      discount_end_date: discount_end_date(discount, discounted_item),
      discount_amount: get_in(discount, ["discountAmount", "amount"])
    }
  end

  defp discount_end_date(discount, discounted_item) do
    trial = Map.get(discounted_item, :trial) || %{}
    first_payment_date = Map.get(trial, :first_payment_date) || today()

    unless discount["indefinite"] do
      Timex.shift(first_payment_date, months: discount["numberOfOccurrences"] - 1)
    end
  end

  defp today, do: Application.get_env(:singula, :today, &Date.utc_today/0).()
end

defmodule Singula.CartDetail.Item.Trial do
  defstruct [:free_trial, :first_payment_date, :first_payment_amount]
end

defmodule Singula.CartDetail.Item do
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
      asset: %Singula.Asset{id: asset_id, title: asset_name}
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

    %Singula.CartDetail.Item.Trial{
      free_trial: applied,
      first_payment_date: first_payment_date,
      first_payment_amount: first_payment_amount
    }
  end

  defp free_trial?(%{"applied" => applied}), do: %Singula.CartDetail.Item.Trial{free_trial: applied}
  defp free_trial?(_), do: nil
end

defmodule Singula.CartDetail do
  alias Singula.CartDetail.{Discount, Item}

  defstruct [:id, :order_id, :contract_id, :total_cost, :currency, :discount, items: []]

  @type t :: %__MODULE__{currency: Singula.Item.currency()}

  def new(cart_payload) do
    %{"amount" => amount, "currency" => currency} = cart_payload["totalCost"]

    items = Enum.map(cart_payload["items"], &Item.new/1)

    discount =
      if discount = cart_payload["discount"] do
        Discount.new(discount, items)
      end

    %__MODULE__{
      id: cart_payload["id"],
      contract_id: get_in(cart_payload, ["contractDetails", "contractId"]),
      order_id: cart_payload["orderId"],
      total_cost: amount,
      currency: String.to_atom(currency),
      items: items,
      discount: discount
    }
  end
end
