# Changelog

## [Unreleased]

### Fixed

- `:money` field defaults no longer overwrite explicitly initialized amount/currency fields
  (e.g. `InvoiceDefault.new(total_amount: 25_00, total_currency: "EUR")`). Defaults are applied
  exclusively through the generated fields; the composite field exposes its configured default
  as metadata via `#money_default`, and its `#default` now returns `nil`.

## [0.1.0] - 2025-05-28

Initial commit
