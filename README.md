# Marten Money

**Marten Money** is a Crystal shard that integrates the [Money library](https://github.com/crystal-money/money) with the [Marten web framework](https://martenframework.com/) providing a new money field for handling monetary values in your models.

## Features

- Drop-in `:money` field type for Marten models
- Accurate handling of monetary values using the Money type.
- Automatic generation of database fields for amount and currency.
- Support for multiple currencies with ISO 4217 codes.
- Built-in validations via the `Money` class to ensure data integrity.

## Installation

Add the shard to your shard.yml:

```yml
dependencies:
  marten_money:
    github: treagod/marten-money
````

Then, install the dependencies:

```bash
shards install
```

And require it in your `src/project.cr`:

```crystal
require "marten_money"
```

## Usage

```crystal
class Invoice < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, blank: false, null: false
end
```

## Creating and Accessing the Money Field

You can create a new `Invoice` record with a Money object:

```crystal
invoice = Invoice.create!(total: Money.new(10_00, "USD"))
# Or
invoice = Invoice.create!(
  total_amount: 10_00,
  total_currency: "USD"
)


# underlying columns
puts invoice.total_amount    # => 1000
puts invoice.total_currency  # => "USD"
```

Accessing the total field:

```crystal
puts invoice.total.amount     # => 10.0
puts invoice.total.fractional # => 1000
puts invoice.total.currency   # => "USD"

puts invoice.total == Money.new(1000, "USD") # => true
```

## Configuration

To configure the Money shard (e.g., set default currency, enable infinite precision), create a Marten initializer:

```crystal
# config/initializers/money.cr

Money.default_currency = :cad
Money.infinite_precision = true
```

For more configuration options, refer to the [Money shard documentation](https://github.com/crystal-money/money).

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your enhancements.
