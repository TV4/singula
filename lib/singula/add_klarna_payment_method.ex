defmodule Singula.AddKlarnaPaymentMethod do
  defstruct [
    :receipt,
    :transactionId,
    redirectUrl: "http://localhost/klarna/transaction",
    order_lines: [],
    locale: "sv-SE"
  ]

  @type t :: %__MODULE__{}

  def new(transaction_id, receipt, order_lines) do
    %Singula.AddKlarnaPaymentMethod{receipt: receipt, transactionId: transaction_id, order_lines: order_lines}
  end
end

defimpl Singula.AddPaymentMethod, for: Singula.AddKlarnaPaymentMethod do
  def provider(_payment_method), do: :KLARNA

  def to_provider_data(payment_method) do
    payment_method
    |> Map.take([:receipt, :transactionId, :redirectUrl, :locale])
    |> Map.put(:order_lines, Jason.encode!(payment_method.order_lines))
  end
end
