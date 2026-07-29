require "../../../src/marten_money"

abstract class AbstractParentInvoice < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money
end

class AbstractChildInvoice < AbstractParentInvoice
  field :extra, :money, amount_field_id: :total_amount
end
