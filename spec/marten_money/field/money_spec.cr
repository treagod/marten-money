require "./spec_helper"

describe MartenMoney::Field::Money do
  describe "::contribute_to_model" do
    it "creates an Invoice when all parameters are provided" do
      invoice = Invoice.create!(total: Money.new(10_00, "USD"), tax: Money.new(20_00, "USD"))

      invoice.total_amount.should eq(10_00)
      invoice.total_currency.should eq("USD")
      invoice.total.should eq(Money.new(10_00, "USD"))

      invoice.tax_amount.should eq(20_00)
      invoice.tax_currency.should eq("USD")
      invoice.tax.should eq(Money.new(20_00, "USD"))
    end

    it "creates an Invoice with renamed underlying Money fields" do
      invoice = InvoiceRename.create!(total: Money.new(10_00, "USD"))

      invoice.foo.should eq(10_00)
      invoice.bar.should eq("USD")
    end

    it "creates an Invoice with default total value when no parameters are provided" do
      invoice = InvoiceDefault.create!

      invoice.total_amount.should eq(10_00)
      invoice.total_currency.should eq("USD")
      invoice.total.should eq(Money.new(10_00, "USD"))
    end

    it "raises a Marten::DB::Errors::InvalidRecord error if a required argument is missing" do
      expect_raises(Marten::DB::Errors::InvalidRecord) do
        Invoice.create!(total: Money.new(10_00, "USD"))
      end
    end

    it "creates a SpecialInvoice when all parameters are provided" do
      invoice = SpecialInvoice.create!(
        total: Money.new(10_00, "USD"),
        tax: Money.new(20_00, "USD"),
        foo: Money.new(30_00, "EUR")
      )

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

    it "creates an InvoiceOptions instance without any parameters" do
      invoice = InvoiceOptions.new

      invoice.save

      invoice.total_amount.should be_nil
      invoice.total_currency.should be_nil
      invoice.total.should be_nil
    end
  end

  describe "assignment and retrieval" do
    it "allows reassignment of a Money field and persists the change" do
      invoice = Invoice.create!(total: Money.new(10_00, "USD"), tax: Money.new(0, "USD"))

      invoice.total = Money.new(25_00, "USD")
      invoice.save!

      reloaded = Invoice.first!
      reloaded.total_amount.should eq 25_00
      reloaded.total_currency.should eq "USD"
      reloaded.total.should eq Money.new(25_00, "USD")
    end

    it "allows reassignment via the underlying fields of a Money field and persists the change" do
      invoice = Invoice.create!(total: Money.new(10_00, "USD"), tax: Money.new(0, "USD"))

      invoice.total_amount = 25_00
      invoice.total_currency = "EUR"
      invoice.save!

      reloaded = Invoice.first!
      reloaded.total_amount.should eq 25_00
      reloaded.total_currency.should eq "EUR"
      reloaded.total.should eq Money.new(25_00, "EUR")
    end
  end
end
