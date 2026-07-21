require "./spec_helper"

describe MartenMoney::DB::Field::Money do
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

    it "does not respond to a currency field if store_currency is set to false" do
      invoice = InvoiceNoCurrency.create!(total: Money.new(10_00, "USD"))

      invoice.responds_to?(:total_amount).should be_true
      invoice.total_amount.should eq(10_00)
      invoice.responds_to?(:total_currency).should be_false
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

  describe "default handling" do
    it "applies the configured default when no value is provided" do
      invoice = InvoiceDefault.new

      invoice.total_amount.should eq 10_00
      invoice.total_currency.should eq "USD"
      invoice.total.should eq Money.new(10_00, "USD")
    end

    it "does not override a Money value provided through the composite field" do
      invoice = InvoiceDefault.new(total: Money.new(25_00, "EUR"))

      invoice.total_amount.should eq 25_00
      invoice.total_currency.should eq "EUR"
      invoice.total.should eq Money.new(25_00, "EUR")
    end

    it "does not override values provided through the generated fields" do
      invoice = InvoiceDefault.new(total_amount: 25_00, total_currency: "EUR")

      invoice.total_amount.should eq 25_00
      invoice.total_currency.should eq "EUR"
      invoice.total.should eq Money.new(25_00, "EUR")
    end

    it "falls back to the field default when only the amount is provided" do
      invoice = InvoiceDefault.new(total_amount: 25_00)

      invoice.total_amount.should eq 25_00
      invoice.total_currency.should eq "USD"
      invoice.total.should eq Money.new(25_00, "USD")
    end

    it "falls back to the field default when only the currency is provided" do
      invoice = InvoiceDefault.new(total_currency: "EUR")

      invoice.total_amount.should eq 10_00
      invoice.total_currency.should eq "EUR"
      invoice.total.should eq Money.new(10_00, "EUR")
    end

    it "persists values provided through the generated fields over the configured default" do
      invoice = InvoiceDefault.create!(total_amount: 25_00, total_currency: "EUR")

      reloaded = InvoiceDefault.get!(id: invoice.id)
      reloaded.total_amount.should eq 25_00
      reloaded.total_currency.should eq "EUR"
      reloaded.total.should eq Money.new(25_00, "EUR")
    end

    it "applies the configured default to renamed underlying fields" do
      invoice = InvoiceRenameDefault.new

      invoice.foo.should eq 10_00
      invoice.bar.should eq "USD"
      invoice.total.should eq Money.new(10_00, "USD")
    end

    it "does not override renamed underlying fields with the configured default" do
      invoice = InvoiceRenameDefault.new(foo: 25_00, bar: "EUR")

      invoice.foo.should eq 25_00
      invoice.bar.should eq "EUR"
      invoice.total.should eq Money.new(25_00, "EUR")
    end
  end

  describe "#default" do
    it "returns nil even when a default is configured" do
      field = MartenMoney::DB::Field::Money.new("total", default: Money.new(10_00, "USD"))

      field.default.should be_nil
    end
  end

  describe "#money_default" do
    it "returns the configured default Money value" do
      field = MartenMoney::DB::Field::Money.new("total", default: Money.new(10_00, "USD"))

      field.money_default.should eq Money.new(10_00, "USD")
    end

    it "returns nil when no default is configured" do
      field = MartenMoney::DB::Field::Money.new("total")

      field.money_default.should be_nil
    end

    it "exposes the configured default of a model field" do
      field = InvoiceDefault.get_field("total").as(MartenMoney::DB::Field::Money)

      field.money_default.should eq Money.new(10_00, "USD")
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

    it "does not override persisted values with defaults on reload" do
      inv = InvoiceDefault.create!(total: Money.new(25_00, "EUR"))

      inv.total_amount.should eq 25_00
      inv.total_currency.should eq "EUR"
      inv.total.should eq Money.new(25_00, "EUR")

      reloaded = InvoiceDefault.get!(id: inv.id)
      reloaded.total_amount.should eq 25_00
      reloaded.total_currency.should eq "EUR"
      reloaded.total.should eq Money.new(25_00, "EUR")
    end
  end

  describe "validation" do
    it "accepts known currency codes" do
      invoice = Invoice.new(total: Money.new(10_00, "USD"), tax: Money.new(0, "EUR"))

      invoice.valid?.should be_true
    end

    it "rejects unknown currency codes" do
      invoice = Invoice.new(total: Money.new(10_00, "USD"), tax: Money.new(0, "EUR"))
      invoice.total_currency = "ZZZ"

      invoice.valid?.should be_false
      invoice.errors[:total_currency].map(&.message).should contain("is not a valid currency")
    end

    it "rejects unknown currency codes on renamed underlying fields" do
      invoice = InvoiceRename.new(total: Money.new(10_00, "USD"))
      invoice.bar = "ZZZ"

      invoice.valid?.should be_false
      invoice.errors[:bar].map(&.message).should contain("is not a valid currency")
    end

    it "rejects an amount without a currency" do
      invoice = InvoiceOptions.new
      invoice.total_amount = 10_00

      invoice.valid?.should be_false
      invoice.errors[:total].map(&.message).should contain(
        "amount and currency must either both be set or both be nil"
      )
    end

    it "rejects a currency without an amount" do
      invoice = InvoiceOptions.new
      invoice.total_currency = "USD"

      invoice.valid?.should be_false
      invoice.errors[:total].map(&.message).should contain(
        "amount and currency must either both be set or both be nil"
      )
    end

    it "does not validate a currency field if store_currency is set to false" do
      invoice = InvoiceNoCurrency.new(total: Money.new(10_00, "USD"))

      invoice.valid?.should be_true
    end
  end
end
