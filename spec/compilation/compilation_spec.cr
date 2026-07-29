require "./spec_helper"

private def compile_fixture(name : String) : {Process::Status, String}
  stderr = IO::Memory.new
  status = Process.run(
    ENV.fetch("CRYSTAL", "crystal"),
    ["build", "--no-codegen", File.join("spec", "compilation", "fixtures", name)],
    chdir: File.expand_path("../..", __DIR__),
    error: stderr
  )
  {status, stderr.to_s}
end

describe "Money field compile-time identifier validation" do
  it "rejects an amount_field_id equal to the implicit currency_field_id", tags: "compilation" do
    status, output = compile_fixture("amount_field_id_equals_implicit_currency.cr")

    status.success?.should be_false
    output.should contain(
      "Money field 'total' resolves amount_field_id and currency_field_id to the same identifier 'total_currency'"
    )
  end

  it "rejects amount_field_id and currency_field_id resolving to the same identifier", tags: "compilation" do
    status, output = compile_fixture("amount_field_id_equals_currency_field_id.cr")

    status.success?.should be_false
    output.should contain(
      "Money field 'total' resolves amount_field_id and currency_field_id to the same identifier 'shared'"
    )
  end

  it "rejects an amount_field_id equal to the money field id", tags: "compilation" do
    status, output = compile_fixture("amount_field_id_equals_money_field_id.cr")

    status.success?.should be_false
    output.should contain(
      "Money field 'total' resolves its amount_field_id to the money field's own identifier 'total'"
    )
  end

  it "rejects an implicit amount identifier colliding with a declared field", tags: "compilation" do
    status, output = compile_fixture("implicit_amount_collides_with_declared_field.cr")

    status.success?.should be_false
    output.should contain(
      "Money field 'total' would define its amount field 'total_amount', which is already defined by " \
      "model 'ImplicitAmountCollidesWithDeclaredField'"
    )
  end

  it "rejects a currency identifier colliding with another money field's generated field", tags: "compilation" do
    status, output = compile_fixture("currency_collides_with_other_money_field.cr")

    status.success?.should be_false
    output.should contain(
      "Money field 'tax' would define its currency field 'total_currency', which is already defined by " \
      "model 'CurrencyCollidesWithOtherMoneyField'"
    )
  end

  it "rejects an amount identifier colliding with an abstract parent's generated field", tags: "compilation" do
    status, output = compile_fixture("amount_collides_with_abstract_parent_field.cr")

    status.success?.should be_false
    output.should contain(
      "Money field 'extra' would define its amount field 'total_amount', which is already defined by " \
      "ancestor model 'AbstractParentInvoice'"
    )
  end

  it "rejects an amount identifier colliding with a concrete parent's generated field", tags: "compilation" do
    status, output = compile_fixture("amount_collides_with_mti_parent_field.cr")

    status.success?.should be_false
    output.should contain(
      "Money field 'extra' would define its amount field 'total_amount', which is already defined by " \
      "ancestor model 'MtiParentInvoice'"
    )
  end
end
