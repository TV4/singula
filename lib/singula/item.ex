defmodule Singula.Item do
  # TODO: Change recurring_billing: %{amount: "139.00", month_count: 1} => recurring_price: "139.00" since frequency is always 1 month.
  # See change contract endpoint which do not include frequency and also must assume frequency to alwyas be 1 month
  defstruct [
    :id,
    :currency,
    :category_id,
    :name,
    :recurring_billing,
    :one_off_price,
    :minimum_term_month_count,
    :free_trial,
    entitlements: []
  ]

  @type currency :: :DKK | :NOK | :SEK
  @type t :: %__MODULE__{id: binary, currency: currency, entitlements: [Singula.Entitlement.t()]}

  def new(
        %{"itemId" => id, "categoryId" => category_id, "name" => name, "pricing" => pricing, "freeTrial" => free_trial} =
          payload
      ) do
    %__MODULE__{
      id: id,
      currency: currency(pricing),
      category_id: category_id,
      name: name,
      recurring_billing: recurring_billing(pricing),
      one_off_price: one_off_price(pricing),
      entitlements: entitlements(payload["entitlements"]),
      minimum_term_month_count: month_count(payload["minimumTerm"]),
      free_trial: free_trial(free_trial)
    }
  end

  def new(%{"itemId" => id, "categoryId" => category_id, "name" => name, "pricing" => pricing} = payload) do
    %__MODULE__{
      id: id,
      currency: currency(pricing),
      category_id: category_id,
      name: name,
      recurring_billing: recurring_billing(pricing),
      one_off_price: one_off_price(pricing),
      entitlements: entitlements(payload["entitlements"]),
      minimum_term_month_count: month_count(payload["minimumTerm"])
    }
  end

  defp currency(%{"recurring" => %{"currency" => currency}}), do: String.to_atom(currency)
  defp currency(%{"oneOff" => %{"currency" => currency}}), do: String.to_atom(currency)

  defp entitlements(entitlements) do
    Enum.map(entitlements, fn entitlement -> Singula.Entitlement.new(entitlement) end)
  end

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

  defp free_trial(%{"active" => true, "numberOfDays" => number_of_days}) do
    Singula.FreeTrial.new(number_of_days)
  end

  defp free_trial(_) do
    nil
  end
end
