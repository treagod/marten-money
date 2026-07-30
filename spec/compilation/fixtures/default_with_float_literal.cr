require "../../../src/marten_money"

class DefaultWithFloatLiteral < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, default: Money.new(10.5, "EUR")
end
