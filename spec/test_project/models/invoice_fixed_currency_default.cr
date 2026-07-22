class InvoiceFixedCurrencyDefault < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, fixed_currency: "EUR", default: Money.new(10_00, "EUR"), blank: true
end
