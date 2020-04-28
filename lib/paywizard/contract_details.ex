defmodule Paywizard.ContractDetails do
  defstruct [:id, :item_name, :recurring_billing, :balance, :minimum_term, :status, :start_date, :paid_up_to_date]

  @type t :: %__MODULE__{}

  def new(response) do
    %__MODULE__{
      id: response["contractId"],
      item_name: response["name"],
      balance: amount(response["balance"]),
      recurring_billing: recurring_billing(response["billing"]),
      minimum_term: frequency(response["minimumTerm"]),
      status: String.to_atom(response["status"]),
      start_date: Date.from_iso8601!(response["startDate"]),
      paid_up_to_date: Date.from_iso8601!(response["paidUpToDate"])
    }
  end

  defp amount(%{"amount" => amount, "currency" => currency}) do
    %{amount: amount, currency: currency_term(currency)}
  end

  defp recurring_billing(%{"recurring" => recurring, "frequency" => frequency}) do
    amount(recurring) |> Map.merge(frequency(frequency))
  end

  defp frequency(%{"frequency" => frequency, "length" => length}) do
    %{frequency: frequency_term(frequency), length: length}
  end

  defp frequency(_), do: nil

  defp frequency_term("MONTH"), do: :MONTH
  defp frequency_term("YEAR"), do: :YEAR

  defp currency_term(currency), do: String.to_atom(currency)
end
