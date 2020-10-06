defprotocol Singula.AddPaymentMethod do
  def provider(payment_method)
  def to_provider_data(payment_method)
end
