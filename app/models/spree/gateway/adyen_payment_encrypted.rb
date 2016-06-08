module Spree
  class Gateway::AdyenPaymentEncrypted < Gateway
    include AdyenCommon

    preference :public_key, :string

    def cancel(response_code)
      payment = Spree::Payment.find_by response_code: response_code
      amount = (payment.amount.to_f * 100).to_i
      options = { currency: Spree::Config[:currency] }

      credit(amount, nil, response_code, options)
    end

    def auto_capture?
      false
    end

    def method_type
      'adyen_encrypted'
    end

    def payment_profiles_supported?
      false
    end

    def authorize(amount, source, gateway_options = {})
      card = { encrypted: { json: source.encrypted_data } }
      ship_address = gateway_options[:shipping_address]

      options = {
        installments: { value: source.installments },
        delivery_address: {
          city: ship_address[:city],
          country: ship_address[:country],
          postal_code: ship_address[:zip],
          state_or_province: ship_address[:state],
          street: "#{ship_address[:address1]} #{ship_address[:address2]}"
        }
      }

      # TODO: Make me conditional. Recurring must be true if payment profiles supported
      response = authorize_on_card amount, source, gateway_options, card, options

      # TODO: MOve this to additional_params method to Adyen::API::AuthorisationResponse and merge in params method. 
      # NOTE: Iterate through entry elements nested in the additionalData element of the response (see SOAP Envelope)
      last_digits = response.xml_querier.xpath('//payment:authoriseResponse/payment:paymentResult').text('./payment:additionalData/payment:entry/payment:value')

      # Ensure that this is enabled if using Encrypted Gateway and Payment Profiles supported
      if last_digits.blank? && payment_profiles_supported?
        Exception.new('Please request last digits to be sent back in Adyen response to support payment profiles')
      else
        source.last_digits = last_digits
      end

      response

    end

    # Do a symbolic authorization, e.g. 1 dollar, so that we can grab a recurring token
    #
    # NOTE Ensure that your Adyen account Capture Delay is set to *manual* otherwise
    # this amount might be captured from customers card. See Settings > Merchant Settings
    # in Adyen dashboard
    def create_profile(payment)
      card = { encrypted: { json: payment.source.encrypted_data } }
      create_profile_on_card payment, card
    end

    def add_contract(source, user, shopper_ip)
      card = { encrypted: { json: source.encrypted_data } }
      set_up_contract source, card, user, shopper_ip
    end
  end
end
