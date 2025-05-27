class InvoiceRename < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, amount_field_id: "foo", currency_field_id: :bar
end
