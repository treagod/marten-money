# Changelog

## [Unreleased]

### Added

- `:money` fields now support `fixed_currency`, which persists only the fractional amount and always reconstructs
  values with the configured known Money currency, independently of `Money.default_currency`.

### Changed

- Fixed-currency fields reject assignments and defaults using another currency.
- `:money` fields now validate their final resolved amount/currency identifiers at compile time. Definitions
  fail to compile — naming the money field and the conflicting identifier — when both identifiers resolve to
  the same name, when one resolves to the money field's own id, or when one collides with a field already
  defined on the model (including other money fields' generated fields) or inherited from an abstract or
  concrete parent. Previously only identical explicit `amount_field_id`/`currency_field_id` literals were
  caught, and only when written with the same literal type.
- Money `default:` amounts must now be integer literals. Floating-point amounts are rejected during macro
  expansion with a message showing the supported syntax, instead of passing the shard's validation and
  failing later inside the generated big_int field.

### Deprecated

- `store_currency: false` now requires `fixed_currency` and emits a deprecation warning. Using it without an explicit
  fixed currency fails with migration guidance instead of silently relying on `Money.default_currency`.

### Fixed

- `:money` field defaults no longer overwrite explicitly initialized amount/currency fields
  (e.g. `InvoiceDefault.new(total_amount: 25_00, total_currency: "EUR")`). Defaults are applied
  exclusively through the generated fields; the composite field exposes its configured default
  as metadata via `#money_default`, and its `#default` now returns `nil`.
- Money values that cannot be represented exactly as `Int64` minor units — e.g. sub-minor-unit precision
  under `Money.infinite_precision`, or amounts beyond the `Int64` range — now raise an `ArgumentError` on
  assignment instead of being silently truncated when persisted.
- The `:money` field now registers `::Money?` as its exposed field type instead of `Nil`, so Marten's
  field metadata and the generated model annotations reflect the actual accessor type. The database
  conversion methods remain no-ops because values are loaded through the generated fields.
- `:money` fields declared on abstract models no longer fail to compile: the field type is registered
  under a string identifier, matching how Marten resolves inherited field types when contributing an
  abstract parent's fields to its concrete children.
- `require "marten_money"` now works standalone: the shard's entrypoint requires `marten` itself instead of
  relying on the host application having loaded it beforehand.

## [0.1.0] - 2025-05-28

Initial commit
