defmodule Singula.DibsPaymentMethod do
  defstruct [:id, :default, :expiry_date, :masked_card]

  @type t :: %__MODULE__{}

  def new(%{"defaultMethod" => default_method, "paymentMethodId" => payment_method_id} = payment_method) do
    %__MODULE__{
      id: payment_method_id,
      default: default_method,
      expiry_date: payment_method["expiryDate"],
      masked_card: payment_method["maskedCard"]
    }
  end
end
