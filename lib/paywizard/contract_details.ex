defmodule Paywizard.ContractDetails do
  defstruct [:id, :item_name, :recurring_billing, :minimum_term, :status, :start_date, :paid_up_to_date]

  @type t :: %__MODULE__{}

  def new(response) do
    %__MODULE__{
      id: response["contractId"],
      item_name: response["name"],
      recurring_billing: recurring_billing(response["billing"]),
      minimum_term: minimum_term(response["minimumTerm"]),
      status: String.to_atom(response["status"]),
      start_date: Date.from_iso8601!(response["startDate"]),
      paid_up_to_date: Date.from_iso8601!(response["paidUpToDate"])
    }
  end

  defp recurring_billing(%{
         "recurring" => %{"amount" => amount, "currency" => currency},
         "frequency" => %{"frequency" => frequency, "length" => length}
       }) do
    %{amount: amount, currency: currency_term(currency), frequency: frequency_term(frequency), length: length}
  end

  defp minimum_term(%{"frequency" => frequency, "length" => length}) do
    %{frequency: frequency_term(frequency), length: length}
  end

  defp minimum_term(_), do: nil

  defp frequency_term("MONTH"), do: :MONTH
  defp frequency_term("YEAR"), do: :YEAR

  defp currency_term(currency), do: String.to_atom(currency)
end
