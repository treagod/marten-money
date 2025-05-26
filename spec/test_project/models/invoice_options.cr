class InvoiceOptions < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, blank: true, null: true
end
