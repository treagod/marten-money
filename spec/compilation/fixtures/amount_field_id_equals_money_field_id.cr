require "../../../src/marten_money"

class AmountEqualsMoneyFieldId < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, amount_field_id: :total
end
