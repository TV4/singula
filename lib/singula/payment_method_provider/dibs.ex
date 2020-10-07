defmodule Singula.PaymentMethodProvider.Dibs do
  defstruct [
    :dibs_ccPart,
    :dibs_ccPrefix,
    :dibs_ccType,
    :dibs_expM,
    :dibs_expY,
    :transactionId,
    :receipt,
    defaultMethod: true
  ]

  @type t :: %__MODULE__{}

  def new(transactionId, receipt, dibs_ccPart, dibs_ccPrefix, dibs_ccType, dibs_expM, dibs_expY) do
    %__MODULE__{
      transactionId: transactionId,
      receipt: receipt,
      dibs_ccPart: String.replace(dibs_ccPart, " ", ""),
      dibs_ccPrefix: dibs_ccPrefix,
      dibs_ccType: dibs_ccType,
      dibs_expM: dibs_expM,
      dibs_expY: dibs_expY
    }
  end
end

defimpl Singula.PaymentMethodProvider, for: Singula.PaymentMethodProvider.Dibs do
  def name(_payment_method), do: :DIBS
  def data(payment_method), do: Map.from_struct(payment_method)
end
