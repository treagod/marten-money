require "../../../src/marten_money"

class DefaultWithMethodCall < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, default: Money.from_amount(10.0, "EUR")
end
