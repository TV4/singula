defmodule Singula.KlarnaPaymentMethod do
  defstruct [:id, :default]

  def new(%{"defaultMethod" => default_method, "paymentMethodId" => payment_method_id}) do
    %__MODULE__{id: payment_method_id, default: default_method}
  end
end
