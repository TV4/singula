defmodule Singula.DibsPaymentMethod do
  defstruct [:id, :default, :expiry_date, :masked_card]

  def new(%{
        "defaultMethod" => default_method,
        "expiryDate" => expiry_date,
        "maskedCard" => masked_card,
        "paymentMethodId" => payment_method_id
      }) do
    %__MODULE__{id: payment_method_id, default: default_method, expiry_date: expiry_date, masked_card: masked_card}
  end
end
