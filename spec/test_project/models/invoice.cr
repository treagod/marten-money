class Invoice < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money
  field :tax, :money
end
