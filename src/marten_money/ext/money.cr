class ::Money
  include Marten::Template::Object

  def resolve_template_attribute(key : String)
    case key
    when "amount"
      amount
    when "currency"
      currency
    when "fractional"
      fractional
    end
  end
end
