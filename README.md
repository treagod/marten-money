# Marten Money

**Marten Money** is a Crystal shard that integrates the [Money library](https://github.com/crystal-money/money) with the [Marten web framework](https://martenframework.com/) providing a new money field for handling monetary values in your models.

## Features

- Drop-in `:money` field type for Marten models
- Accurate handling of monetary values using the Money type.
- Automatic generation of database fields for amount and currency.
- Optional fixed-currency storage using only an amount column.
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

### Field Options

| Option              | Type                 | Default                         | Description                                                                                                    |
|---------------------|----------------------|---------------------------------|----------------------------------------------------------------------------------------------------------------|
| `blank`             | `Bool`               | `false`                         | Whether the field allows blank (empty) values.                                                                 |
| `null`              | `Bool`               | `false`                         | Whether the field allows `NULL` values in the database.                                                        |
| `default`           | `Money`              | `nil`                           | Default value written as a literal, e.g. `Money.new(1000, "USD")`. Explicitly provided values take precedence. |
| `amount_field_id`   | `String` / `Symbol`  | `:"<field>_amount"`             | Overrides the name of the amount column.                                                                       |
| `currency_field_id` | `String` / `Symbol`  | `:"<field>_currency"`           | Overrides the name of the currency column.                                                                     |
| `fixed_currency`    | `String` / `Symbol`  | `nil`                           | Stores only the amount and always reconstructs values using this known Money currency.                         |
| `store_currency`    | `Bool`               | `true`                          | Deprecated. `false` is accepted only with `fixed_currency` during the deprecation period.                      |

### Fixed-Currency Storage

Use `fixed_currency` when every value in a field uses the same currency and the database should store only the
fractional amount:

```crystal
class Invoice < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, fixed_currency: "EUR"
end
```

This generates `total_amount` without a `total_currency` column. Loaded values always use EUR, regardless of
`Money.default_currency`:

```crystal
invoice.total # => Money.new(invoice.total_amount, "EUR")
```

The configured code must be a known Money currency. Assigning a `Money` value in another currency raises an
`ArgumentError`, and any configured `default` must use the fixed currency.

`store_currency: false` is deprecated and no longer falls back to `Money.default_currency`. During the deprecation
period, it compiles only when paired with `fixed_currency` and emits a warning; remove `store_currency` to migrate:

```crystal
# Deprecated compatibility form
field :total, :money, fixed_currency: "EUR", store_currency: false

# Preferred form
field :total, :money, fixed_currency: "EUR"
```

Changing an existing two-column field to `fixed_currency` removes the generated currency field. Generate a Marten
migration to remove that database column. Existing `store_currency: false` schemas require no database change.

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
