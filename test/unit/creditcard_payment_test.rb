require 'test_helper'

class CreditcardPaymentTest < ActiveSupport::TestCase
  fixtures :gateways

  context "instance" do
    setup do           
      creditcard = Factory(:creditcard, :checkout => Factory(:checkout))
      @payment = Factory(:creditcard_payment, :creditcard => creditcard)
      @auth_amount = @payment.authorization.amount
    end
    context "capture" do
      setup { @payment.capture }
      should_change("CreditcardTxn.count", :by => 1) { CreditcardTxn.count }
      should "create a capture transaction" do
        assert_equal CreditcardTxn::TxnType::CAPTURE, CreditcardTxn.last.txn_type
      end
      should_change("@payment.amount", :from => 0, :to => @auth_amount) { @payment.amount }
    end
    context "capture with no authorization" do
      setup do
        @payment.creditcard_txns = []
        @payment.capture
      end
      should_not_change("CreditcardTxn.count") { CreditcardTxn.count }
      should_not_change("@payment.amount") { @payment.amount }
    end
  end
end
