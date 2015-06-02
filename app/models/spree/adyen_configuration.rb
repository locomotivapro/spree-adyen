class Spree::AdyenConfiguration < Spree::Preferences::Configuration
  preference :social_security_method, :string, default: 'cpf'
end
