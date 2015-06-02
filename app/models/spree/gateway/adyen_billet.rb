module Spree
  class Gateway::AdyenBillet < Gateway
    include AdyenCommon

    preference :public_key, :string
    preference :bank_brand, :string
    preference :due_days, :integer
    #preference :shopper_statement

    def source_required?
      true
    end

    def payment_source_class
      Spree::AlternativePaymentSource
    end

    def auto_capture?
      false
    end

    def actions
      %w{capture void authorize}
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      !payment.void?
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      payment.pending? || payment.checkout?
    end

    def method_type
      'adyen_billet'
    end

    def payment_profiles_supported?
      false
    end

    def authorize(amount, source, gateway_options = {})
      reference = [Spree.t(:billet_reference), gateway_options[:order_id]].join(' ')
      amount = { currency: gateway_options[:currency], value: amount }
      name_array = gateway_options[:billing_address][:name].split(' ')
      shopper_name = { first_name: name_array.slice!(0),
                       last_name: name_array.join(' ') }

      ss_method = Spree::Adyen::Config[:social_security_method]
      user = Spree.user_class.find(gateway_options[:customer_id])

      social_security_number = user.send(ss_method)
      delivery_date = (Time.now + self.preferences[:due_days]).utc.iso8601

      response = provider.generate_billet reference, amount, shopper_name, social_security_number, self.preferences[:bank_brand], delivery_date

      if response.success?
        record_billet_source(response, source)
        def response.authorization; psp_reference; end
        def response.avs_result; {}; end
        def response.cvv_result; { 'code' => result_code }; end
      else
        def response.to_s
          "#{result_code} - #{http_response}"
        end
      end

      response
    end

    private
    def record_billet_source(response, source)
        parsed_response = parse_billet_response(response)
        expire_at = parsed_response['boletobancario.expirationDate'].to_date
        due_at = parsed_response['boletobancario.dueDate'].to_date
        url = parsed_response['boletobancario.url'].strip
        source.update_attributes(billet_expire_at: expire_at, billet_due_at: due_at, billet_url: url)
    end

    def parse_billet_response(response)
      data = response.xml_querier.xpath('//payment:authoriseResponse/payment:paymentResult/payment:additionalData').children.map
      parsed_response = {}
      data.each do |node|
        key = node.children.first.text
        value = node.children.last.text
        parsed_response["#{key}"] = value
      end

      parsed_response
    end

  end
end
