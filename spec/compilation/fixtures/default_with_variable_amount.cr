require "../../../src/marten_money"

class DefaultWithVariableAmount < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, default: Money.new(amount, "EUR")
end
