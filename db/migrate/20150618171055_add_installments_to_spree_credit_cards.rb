class AddInstallmentsToSpreeCreditCards < ActiveRecord::Migration
  def change
    add_column :spree_credit_cards, :installments, :integer
  end
end
