# Marten Money

Money is two values: an amount and a currency. Storing it in a database usually means two columns, plus the plumbing
to turn them back into something you can do arithmetic with.

Marten Money adds a `:money` field type to the [Marten web framework](https://martenframework.com/). It manages both
columns for you and puts a single [Money](https://github.com/crystal-money/money) accessor on top of them.

## Installation

Add the shard to your `shard.yml`:

```yml
dependencies:
  marten_money:
    github: treagod/marten-money
```

Install it:

```bash
shards install
```

And require it in `src/project.cr`:

```crystal
require "marten_money"
```

The require pulls in Marten itself, so it also works in a plain Crystal program without a Marten project around it.

## Getting started

```crystal
class Invoice < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money
end
```

That single declaration generates two ordinary Marten fields:

| Generated field  | Marten type            | Holds                                    |
|------------------|------------------------|------------------------------------------|
| `total_amount`   | `:big_int`             | The amount in minor units (e.g. cents)   |
| `total_currency` | `:string, max_size: 3` | The ISO 4217 currency code               |

Nothing about them is special, so `marten gen migration` and `marten migrate` treat them like any other pair of
columns.

## Working with money values

Assign a `Money` object, or write the generated fields directly:

```crystal
invoice = Invoice.create!(total: Money.new(10_00, "USD"))

# Equivalent
invoice = Invoice.create!(total_amount: 10_00, total_currency: "USD")
```

Reading gives you a `Money` back. The accessor is nilable, because either column can be `NULL` — use `total!` when you
know the value is set:

```crystal
invoice.total                # => Money?
invoice.total!.amount        # => 10.0
invoice.total!.fractional    # => 1000
invoice.total!.currency.code # => "USD"

invoice.total == Money.new(10_00, "USD") # => true
invoice.total!.to_s                      # => "$10.00"

# The generated fields stay available
invoice.total_amount   # => 1000
invoice.total_currency # => "USD"
```

Assigning `nil` clears both columns:

```crystal
invoice.total = nil
```

Two small differences from built-in Marten fields: there is no `total?` predicate method — use `total.nil?` — and
`get_field_value("total")` returns the composite `Money`, which is also what shows up in `inspect` output.

## Field options

| Option              | Type                        | Default              | Description                       |
|---------------------|-----------------------------|----------------------|-----------------------------------|
| `blank`             | `Bool`                      | `false`              | Allow blank values.               |
| `null`              | `Bool`                      | `false`              | Allow `NULL` columns.             |
| `default`           | literal `Money.new` call    | none                 | Default value. See below.         |
| `amount_field_id`   | `String` / `Symbol`         | `"<field>_amount"`   | Renames the amount field/column.  |
| `currency_field_id` | `String` / `Symbol`         | `"<field>_currency"` | Renames the currency field/column.|
| `fixed_currency`    | `String` / `Symbol` literal | none                 | Store only the amount. See below. |
| `store_currency`    | `Bool`                      | derived              | Deprecated. See below.            |

`blank` and `null` are forwarded to both generated fields. Other Marten field options — `index`, `unique`,
`db_column`, `primary_key` — are not supported and fail to compile.

Because a money field owns two identifiers besides its own, name conflicts are caught during compilation. A field
fails to compile when its amount and currency identifiers resolve to the same name, when either resolves to the money
field's own id, or when either collides with a field already defined on the model or inherited from a parent:

```
Money field 'total' would define its amount field 'total_amount', which is already defined by model 'Invoice'
```

Inherited money fields are exempt — redeclaring a parent's money field on a child model is not a collision.

## Defaults

```crystal
class Invoice < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, default: Money.new(10_00, "USD"), blank: true
end
```

The default has to be a literal `Money.new` call with an integer amount and a string currency, because it is split at
compile time into a default per generated field. Anything else — a float amount, a symbol currency, a constant,
`Money.from_amount(...)` — is rejected:

```
Money field 'total' default: must be a literal Money.new call with an integer amount and a string currency,
e.g. default: Money.new(10_00, "EUR")
```

Splitting the default has a consequence worth knowing: defaults apply **per component**, not all or nothing. Set only
the amount and the currency still falls back to its default, and the other way round:

```crystal
Invoice.new.total                        # => Money.new(10_00, "USD")
Invoice.new(total_amount: 25_00).total   # => Money.new(25_00, "USD")
Invoice.new(total_currency: "EUR").total # => Money.new(10_00, "EUR")
```

## Fixed-currency fields

When every value in a field uses the same currency, `fixed_currency` skips the currency column entirely and stores
only the amount:

```crystal
class Invoice < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money, fixed_currency: "EUR"
end
```

This generates `total_amount` and no `total_currency`. The code must be a currency Money knows about; lookup is
case-insensitive and symbols work too, so `"EUR"`, `"eur"` and `:eur` are the same thing.

Values always come back in the configured currency, regardless of what `Money.default_currency` happens to be:

```crystal
invoice.total # => Money.new(invoice.total_amount, "EUR")
```

Assigning another currency raises, and the previous value is left untouched:

```crystal
invoice.total = Money.new(5_00, "USD")
# => ArgumentError: Money field 'total' requires currency EUR, got USD
```

Any configured `default` must use the fixed currency as well.

Switching an existing two-column field over to `fixed_currency` drops the generated currency field, so generate a
migration to remove that column.

> **Deprecated:** `store_currency: false` used to fall back to `Money.default_currency`. It now requires an explicit
> `fixed_currency` alongside it and emits a deprecation warning; without one it fails to compile. Drop
> `store_currency` and keep `fixed_currency` on its own.

## Validation

Beyond the `null` and `blank` rules of the generated fields, a money field checks that its two columns agree.

An amount without a currency (or the reverse) is invalid, and the error is attached to the money field:

```crystal
invoice = Invoice.new(total_amount: 10_00)
invoice.valid? # => false
# total: amount and currency must either both be set or both be nil
```

An unknown currency code is invalid too, attached to the currency field:

```crystal
invoice = Invoice.new(total_amount: 10_00, total_currency: "ZZZ")
invoice.valid? # => false
# total_currency: is not a valid currency
```

Codes are matched case-insensitively, so `"usd"` passes.

Two things to keep in mind when rendering errors:

- `null` and `blank` errors come from the generated fields, so they are attached to `total_amount` and
  `total_currency` — not to `total`.
- A nullable money field needs both options. `null: true` on its own still fails validation with
  `This field cannot be blank.`, so write `null: true, blank: true`.

Fixed-currency fields skip these checks entirely — with no currency column, there is nothing to disagree about.

## Precision

Amounts are persisted as a whole number of minor units in the generated `big_int` column, so sub-minor-unit precision
cannot be stored. Rather than truncating silently, assignment raises:

```crystal
Money.infinite_precision = true

invoice.total = Money.from_amount(10.005, "EUR")
# => ArgumentError: Money field 'total' cannot store 10.005 EUR exactly:
#    1000.5 is not a whole number of minor units
```

Amounts outside the `Int64` range are rejected the same way. In both cases the field keeps its previous value.

In practice this only comes up with `Money.infinite_precision = true` (or a currency with unusual subunits). With
infinite precision off, Money has already rounded the amount to the currency's exponent before it reaches the field.

## Model inheritance

Money fields work on abstract models and on multi-table inheritance:

```crystal
abstract class BaseInvoice < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :total, :money
end

class Invoice < BaseInvoice
end

class SpecialInvoice < Invoice
  field :discount, :money
end
```

The child gets the parent's money accessors, and can add money fields of its own.

## Templates

`Money` values are template-friendly out of the box:

```html
{{ invoice.total }}            {# $10.00 #}
{{ invoice.total.amount }}     {# 10.0 #}
{{ invoice.total.fractional }} {# 1000 #}
{{ invoice.total.currency }}   {# USD #}
```

## Configuration

Money itself is configured through a Marten initializer:

```crystal
# config/initializers/money.cr

Money.default_currency = :cad
Money.infinite_precision = true
```

See the [Money shard documentation](https://github.com/crystal-money/money) for the full list of options.

## What this shard does not do

- **No schema field.** There is no `:money` field for `Marten::Schema`, so forms bind `total_amount` and
  `total_currency` as two separate fields.
- **No querying by the money field.** The money field owns no column of its own, so `Invoice.filter(total: ...)`
  builds an invalid query and fails at the database. Filter and order by the generated fields instead:
  `Invoice.filter(total_amount__gt: 10_00)`.
- **No cross-currency arithmetic in SQL.** Amounts are minor units of each row's own currency, and minor units differ
  between currencies — summing the raw column across mixed currencies is meaningless.

## Requirements

Tested against Crystal 1.18 and later (CI covers 1.18, 1.19, 1.20 and nightly), Marten 0.5 and Money 1.x.

## Contributing

Contributions are welcome — fork the repository and open a pull request.

Before submitting, run the suite and the QA checks:

```bash
crystal spec
crystal tool format
bin/ameba
```

Note that the specs under `spec/compilation` shell out to `crystal build --no-codegen` once per fixture to assert that
invalid field definitions are rejected, which makes them slow. They are tagged `compilation`, so
`crystal spec --tag ~compilation` skips them while iterating.
