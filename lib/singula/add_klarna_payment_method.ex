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

  def to_provider_data(%__MODULE__{} = struct) do
    struct
    |> Map.take([:receipt, :transactionId, :redirectUrl, :locale])
    |> Map.put(:order_lines, Jason.encode!(struct.order_lines))
  end
end
