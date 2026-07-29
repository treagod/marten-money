require "../../../src/marten_money"

class MtiParentInvoice < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money
end

class MtiChildInvoice < MtiParentInvoice
  field :extra, :money, amount_field_id: :total_amount
end
