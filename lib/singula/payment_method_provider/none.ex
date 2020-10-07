defmodule Singula.PaymentMethodProvider.None do
  defstruct []

  @type t :: %__MODULE__{}
end

defimpl Singula.PaymentMethodProvider, for: Singula.PaymentMethodProvider.None do
  def name(_payment_method), do: :NOT_PROVIDED
  def data(_payment_method), do: %{}
end
