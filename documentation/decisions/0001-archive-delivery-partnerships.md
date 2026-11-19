# 0001. Archive delivery partnerships instead of deleting them

## Status

Accepted

## Context

Super admins need to remove a delivery partner from a lead provider's course. Declarations
reference delivery partners, finance statements derive from declarations, and contract
managers need to know who changed what. Hard-deleting a partnership loses history, and the
unique index on delivery partner + lead provider + course would make re-adding awkward to audit.

## Decision

- Add nullable `delivery_partnerships.archived_at`. "Removing" a partnership archives it.
  The row, and the `DeliveryPartner`, are kept.
- Read paths for "available" partners use the `active` scope (API, declaration validation,
  admin lists, model associations). Declarations already saved are not revalidated, so history
  is unaffected.
- Re-adding an archived partner **unarchives the existing row** rather than inserting a new
  one. The unique index is unchanged and the row's PaperTrail history stays in one place.
- Changes are audited with PaperTrail on `DeliveryPartnership` and `DeliveryPartner`, so no
  bulk writes (`update_all`, `insert_all`) are used.
- The API does not expose archive status; archived partnerships are simply omitted.
- At least one active partnership must remain per course + lead provider.

## Consequences

- Lead providers lose access to archived partners immediately; notify them of removals.
- Any new query for available partners must use `DeliveryPartnership.active`.
- Audit history is recorded but not yet viewable in the admin UI.
