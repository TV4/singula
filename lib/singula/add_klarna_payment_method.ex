defmodule Singula.AddKlarnaPaymentMethod do
  defstruct [:receipt, :transactionId, :redirectUrl, order_lines: [], locale: "sv-SE"]

  alias Singula.CartDetail

  @type t :: %__MODULE__{}

  @default_tax_rate 0.25

  def populate_struct_from(
        %__MODULE__{} = struct,
        %CartDetail{items: [item], currency: currency, total_cost: total_cost}
      ) do
    %{
      struct
      | order_lines: [
          %{
            name: item.item_name,
            quantity: item.quantity,
            unit_price: item.cost,
            tax_amount: calculate_tax(total_cost),
            total_amount: total_cost,
            purchase_currency: currency
          }
        ]
    }
  end

  def to_provider_data(%__MODULE__{} = struct) do
    struct
    |> Map.take([:receipt, :transactionId, :redirectUrl, :locale])
    |> Map.put(:order_lines, Jason.encode!(struct.order_lines))
  end

  defp calculate_tax(price, tax_rate \\ @default_tax_rate) do
    (String.to_float(price) * tax_rate)
    |> Float.round()
    |> to_string()
  end
end
