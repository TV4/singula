defmodule Singula.PaymentMethodProvider.Klarna do
  defstruct [
    :receipt,
    :transactionId,
    redirectUrl: "http://localhost/klarna/transaction",
    order_lines: [],
    locale: "sv-SE"
  ]

  @type t :: %__MODULE__{}

  def new(transaction_id, receipt, order_lines) do
    %__MODULE__{receipt: receipt, transactionId: transaction_id, order_lines: order_lines}
  end
end

defimpl Singula.PaymentMethodProvider, for: Singula.PaymentMethodProvider.Klarna do
  def name(_payment_method), do: :KLARNA

  def data(payment_method) do
    payment_method
    |> Map.take([:receipt, :transactionId, :redirectUrl, :locale])
    |> Map.put(:order_lines, Jason.encode!(payment_method.order_lines))
  end
end
