defprotocol Singula.PaymentMethodProvider do
  def name(payment_method)
  def data(payment_method)
end
