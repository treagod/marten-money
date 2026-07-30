require "../../../src/marten_money"

class DefaultWithIntegerLiteral < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, default: Money.new(10_00, "EUR")
end
