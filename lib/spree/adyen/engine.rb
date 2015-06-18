module Spree
  module Adyen
    class Engine < ::Rails::Engine
      engine_name "spree-adyen"

      isolate_namespace Spree::Adyen

      initializer 'spree.adyen.preferences', before: :load_config_initializers do |app|
        Spree::Adyen::Config = Spree::AdyenConfiguration.new
      end

      def self.activate
        source_attrs = Spree::PermittedAttributes.source_attributes

        unless source_attrs.include?(:brand_code) && source_attrs.include?(:installments)
          source_attrs << :brand_code << :installments
        end

        Dir.glob(File.join(File.dirname(__FILE__), '../../app/models/spree/*_decorator.rb')) do |c|
          Rails.configuration.cache_classes ? require(c) : load(c)
        end
      end

      config.to_prepare &method(:activate).to_proc

      initializer "spree.spree-adyen.payment_methods", :after => "spree.register.payment_methods" do |app|
        app.config.spree.payment_methods << Gateway::AdyenPayment
        app.config.spree.payment_methods << Gateway::AdyenHPP
        app.config.spree.payment_methods << Gateway::AdyenPaymentEncrypted
        app.config.spree.payment_methods << Gateway::AdyenBillet
      end

      initializer "spree-adyen.assets.precompile", :group => :all do |app|
        app.config.assets.precompile += %w[
          adyen.encrypt.js
        ]
      end
    end
  end
end
