struct ::Money
  include Marten::Template::Object

  def resolve_template_attribute(key : String)
    case key
    when "amount"
      amount.to_f64
    when "currency"
      currency
    when "fractional"
      fractional.to_i64
    end
  end
end
