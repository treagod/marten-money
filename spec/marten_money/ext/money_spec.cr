require "./spec_helper"

describe Money do
  describe "#resolve_template_attribute" do
    it "resolves the amount as a Float64" do
      Money.new(10_00, "USD").resolve_template_attribute("amount").should eq(10.0)
    end

    it "resolves the fractional value as an Int64" do
      Money.new(10_00, "USD").resolve_template_attribute("fractional").should eq(1000_i64)
    end

    it "resolves the currency as its code" do
      Money.new(10_00, "USD").resolve_template_attribute("currency").should eq("USD")
    end

    it "returns nil for unknown attributes" do
      Money.new(10_00, "USD").resolve_template_attribute("unknown").should be_nil
    end
  end

  describe "template rendering" do
    it "renders money attributes" do
      template = Marten::Template::Template.new(
        "{{ total }}|{{ total.amount }}|{{ total.fractional }}|{{ total.currency }}"
      )

      template.render({"total" => Money.new(10_00, "USD")}).should eq("$10.00|10.0|1000|USD")
    end
  end
end
