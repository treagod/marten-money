class Invoice < Marten::Model
  include MartenMoney::Field::Money

  field :id, :big_int, primary_key: true, auto: true

  money_field :total
  money_field :tax
end
