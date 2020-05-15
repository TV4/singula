defmodule Paywizard.Item do
  defstruct [:id, :currency, :name, :recurring_billing, :one_off_price, :minimum_term_month_count, entitlements: []]

  @type t :: %__MODULE__{}

  def new(%{"itemId" => id, "name" => name, "pricing" => pricing, "entitlements" => entitlements} = payload) do
    %__MODULE__{
      id: id,
      currency: currency(pricing),
      name: name,
      recurring_billing: recurring_billing(pricing),
      one_off_price: one_off_price(pricing),
      entitlements: entitlements(entitlements),
      minimum_term_month_count: month_count(payload["minimumTerm"])
    }
  end

  defp currency(%{"recurring" => %{"currency" => currency}}), do: String.to_atom(currency)
  defp currency(%{"oneOff" => %{"currency" => currency}}), do: String.to_atom(currency)

  defp entitlements(entitlements), do: Enum.map(entitlements, & &1["id"])

  defp month_count(%{"frequency" => "MONTH", "length" => months}), do: months
  defp month_count(%{"frequency" => "YEAR", "length" => years}), do: years * 12
  defp month_count(_), do: nil

  defp one_off_price(%{"oneOff" => %{"amount" => amount}}), do: amount
  defp one_off_price(%{"initial" => %{"amount" => "0.00"}}), do: nil
  defp one_off_price(%{"initial" => %{"amount" => amount}}), do: amount
  defp one_off_price(_), do: nil

  defp recurring_billing(%{"recurring" => recurring, "frequency" => frequency}) do
    %{
      amount: recurring["amount"],
      month_count: month_count(frequency)
    }
  end

  defp recurring_billing(_), do: nil
end
