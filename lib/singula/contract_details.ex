defmodule Singula.ContractDetails do
  defstruct [
    :id,
    :order_id,
    :item_id,
    :item_name,
    :recurring_billing,
    :upcoming_billing,
    :balance,
    :minimum_term,
    :status,
    :start_date,
    :paid_up_to_date,
    :change_date,
    :change_to_item_id
  ]

  @type t :: %__MODULE__{}

  def new(response) do
    %__MODULE__{
      id: response["contractId"],
      order_id: response["orderId"],
      item_id: response["itemCode"],
      item_name: response["name"],
      balance: amount(response["balance"]),
      recurring_billing: billing(response["billing"], "recurring"),
      upcoming_billing: billing(response["billing"], "upcoming"),
      minimum_term: frequency(response["minimumTerm"]),
      status: String.to_atom(response["status"]),
      start_date: date(response["startDate"]),
      paid_up_to_date: date(response["paidUpToDate"]),
      change_date: date(response["changeDate"]),
      change_to_item_id: response["changeToItem"]
    }
  end

  defp amount(%{"amount" => amount, "currency" => currency}) do
    %{amount: amount, currency: currency_term(currency)}
  end

  defp billing(%{"frequency" => frequency} = billing, type) do
    if billing_type = Map.get(billing, type) do
      amount(billing_type) |> Map.merge(frequency(frequency))
    end
  end

  defp frequency(%{"frequency" => frequency, "length" => length}) do
    %{frequency: frequency_term(frequency), length: length}
  end

  defp frequency(_), do: nil

  defp frequency_term("MONTH"), do: :MONTH
  defp frequency_term("YEAR"), do: :YEAR

  defp currency_term(currency), do: String.to_atom(currency)

  defp date(nil), do: nil
  defp date(date_string), do: Date.from_iso8601!(date_string)
end
