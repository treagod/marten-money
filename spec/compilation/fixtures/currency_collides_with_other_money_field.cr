require "marten"
require "../../../src/marten_money"

class CurrencyCollidesWithOtherMoneyField < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money
  field :tax, :money, currency_field_id: "total_currency"
end
