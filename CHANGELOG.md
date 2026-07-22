# Changelog

## [Unreleased]

### Added

- `:money` fields now support `fixed_currency`, which persists only the fractional amount and always reconstructs
  values with the configured known Money currency, independently of `Money.default_currency`.

### Changed

- Fixed-currency fields reject assignments and defaults using another currency.

### Deprecated

- `store_currency: false` now requires `fixed_currency` and emits a deprecation warning. Using it without an explicit
  fixed currency fails with migration guidance instead of silently relying on `Money.default_currency`.

### Fixed

- `:money` field defaults no longer overwrite explicitly initialized amount/currency fields
  (e.g. `InvoiceDefault.new(total_amount: 25_00, total_currency: "EUR")`). Defaults are applied
  exclusively through the generated fields; the composite field exposes its configured default
  as metadata via `#money_default`, and its `#default` now returns `nil`.

## [0.1.0] - 2025-05-28

Initial commit
