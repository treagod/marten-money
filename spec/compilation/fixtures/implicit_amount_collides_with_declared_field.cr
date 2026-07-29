require "../../../src/marten_money"

class ImplicitAmountCollidesWithDeclaredField < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total_amount, :big_int
  field :total, :money
end
