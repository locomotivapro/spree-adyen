require 'adyen'

Adyen::API.module_eval do

  def authorise_payment_with_installments(reference, amount, shopper, card, installments, enable_recurring_contract = false, fraud_offset = nil, instant_capture = false)
    params = { :reference    => reference,
               :amount       => amount,
               :shopper      => shopper,
               :card         => card,
               :installments => installments,
               :recurring    => enable_recurring_contract,
               :fraud_offset => fraud_offset,
               :instant_capture => instant_capture }
    Adyen::API::PaymentService.new(params).authorise_payment
  end

end
