class AddBilletFieldsToAlternativePaymentSources < ActiveRecord::Migration
  def change
    add_column :spree_alternative_payment_sources, :billet_url, :text
    add_column :spree_alternative_payment_sources, :billet_expire_at, :date
    add_column :spree_alternative_payment_sources, :billet_due_at, :date
  end
end
