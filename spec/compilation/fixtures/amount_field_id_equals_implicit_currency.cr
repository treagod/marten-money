require "../../../src/marten_money"

class AmountEqualsImplicitCurrency < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, amount_field_id: :total_currency
end
