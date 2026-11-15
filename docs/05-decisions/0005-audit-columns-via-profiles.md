# 0005: Audit columns via profiles and triggers

**Status:** accepted

**Context:** We need to know who created and last changed each record, shown as a username.

**Decision:** A `profiles` table (username from the email prefix, created automatically for each new user) and `created_by` / `updated_by` columns referencing it. Triggers set them from the signed-in user; clients never send them. Imports and other unauthenticated changes are attributed to a `system` profile. Users are deactivated, never deleted. `movements` has only created_by; `stock` has only updated_by.

**Why:** Authors cannot be spoofed, usernames can be renamed in one place, and history survives staff turnover.

**Consequences:** Every new table needs the four audit columns and the audit trigger in its migration.
