class InvoiceFixedCurrencyRename < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, fixed_currency: :eur, amount_field_id: "foo"
end
