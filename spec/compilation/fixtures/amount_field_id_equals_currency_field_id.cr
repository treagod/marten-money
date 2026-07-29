require "../../../src/marten_money"

class AmountEqualsCurrency < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, amount_field_id: "shared", currency_field_id: :shared
end
