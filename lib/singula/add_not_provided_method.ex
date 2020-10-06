defmodule Singula.AddNotProvidedPaymentMethod do
  defstruct []

  @type t :: %__MODULE__{}
end

defimpl Singula.AddPaymentMethod, for: Singula.AddNotProvidedPaymentMethod do
  def provider(_payment_method), do: :NOT_PROVIDED
  def to_provider_data(_payment_method), do: %{}
end
