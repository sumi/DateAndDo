class CreditcardLastFourDigits < ActiveRecord::Migration
  def self.up
    rename_column :creditcards, :display_number, :last_digits
    Creditcard.reset_column_information
    Creditcard.all.each do |card|
      card.update_attribute(:last_digits, card.last_digits.gsub("XXXX-XXXX-XXXX-", "")) if card.last_digits.present?
    end 
  end

  def self.down
    rename_column :creditcards, :last_digits, :display_number 
  end
end
