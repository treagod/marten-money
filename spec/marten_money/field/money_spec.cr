require "./spec_helper"

describe MartenMoney::Field::Money do
  describe "#create" do
    it "creates an Invoice with all paramters provided" do
      Invoice.create!(total: Money.new(10_00, "USD"), tax: Money.new(20_00, "USD"))

      invoice = Invoice.first!

      invoice.total_amount.should eq(10_00)
      invoice.total_currency.should eq("USD")
      invoice.total.should eq(Money.new(10_00, "USD"))

      invoice.tax_amount.should eq(20_00)
      invoice.tax_currency.should eq("USD")
      invoice.tax.should eq(Money.new(20_00, "USD"))
    end

    it "raises a Marten::DB::Errors::InvalidRecord error when one argument is not given" do
      expect_raises(Marten::DB::Errors::InvalidRecord) do
        Invoice.create!(total: Money.new(10_00, "USD"))
      end
    end

    it "creates an SpecialInvoice with all paramters provided" do
      SpecialInvoice.create!(
        total: Money.new(10_00, "USD"),
        tax: Money.new(20_00, "USD"),
        foo: Money.new(30_00, "EUR")
      )

      invoice = SpecialInvoice.first!

      invoice.total_amount.should eq(10_00)
      invoice.total_currency.should eq("USD")
      invoice.total.should eq(Money.new(10_00, "USD"))

      invoice.tax_amount.should eq(20_00)
      invoice.tax_currency.should eq("USD")
      invoice.tax.should eq(Money.new(20_00, "USD"))

      invoice.foo_amount.should eq(30_00)
      invoice.foo_currency.should eq("EUR")
      invoice.foo.should eq(Money.new(30_00, "EUR"))
    end

    it "create InvoiceOptions with no paramters provided" do
      invoice = InvoiceOptions.new

      invoice.save

      invoice.total_amount.should be_nil
      invoice.total_currency.should be_nil
      invoice.total.should be_nil
    end
  end
end
