## v0_2_1 - 2024-09-24

### Fixed

- Errored Subscriptions will no longer throw duplicate warnings.

## v0_2_0 - 2024-09-24

### Fixed

- Converted Indexes to use BTree to force deterministic ordering.  Lookup occurs in index for every query with a prev argument. The query selects the next minimum payment or subscription by ID if the specified item has been deleted
- The label for the productId field has been fixed for the 79subCreate block.

### Updates

- productId, account, targetAccount, and service added to the Service.Product type as a convenience field as it reduces a call to get subscription to retrieve those values.