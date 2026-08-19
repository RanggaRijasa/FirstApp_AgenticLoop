# Test Plan

## Build gate

Every change must pass:

```bash
./scripts/build-ios.sh
```

A task is not complete while the application fails to compile.

Warnings introduced by the change should be investigated rather than ignored.

---

## Automated test gate

Every change must pass:

```bash
./scripts/test-ios.sh
```

when:

- the configured scheme has tests
- the configured simulator is available

If tests cannot run because of environment configuration rather than application code, report that explicitly.

Do not represent an unexecuted test suite as passing.

---

## Manual Simulator gate

For user-visible behavior, verify manually in Xcode Simulator:

- launch succeeds
- primary interaction works
- loading/error/empty states as applicable
- layout on the primary test device
- dark mode when relevant
- Dynamic Type when relevant
- keyboard interaction when relevant
- navigation and dismissal behavior
- destructive interactions where relevant

---

## Primary test device

Use a current standard-size iPhone simulator as the main development target.

Also perform targeted checks on:

- a smaller supported iPhone
- a large-screen iPhone

Exact simulator models may change based on the Xcode version installed.

Do not hard-code product assumptions to one simulator size.

---

## Critical journeys

### Journey 1: First launch

1. Launch Cartsyne with an empty database.
2. App opens successfully.
3. Empty state is understandable.
4. User can create their first list.
5. No account or setup is required.

Expected result:

The user can reach a usable grocery list immediately.

---

### Journey 2: Create grocery list

1. Tap create list.
2. Enter a name.
3. Save.
4. New list appears.
5. Open the list.

Verify:

- empty names are handled
- keyboard behaves correctly
- newly created list persists after relaunch

---

### Journey 3: Add grocery items rapidly

1. Open a list.
2. Focus item-entry field.
3. Enter `Milk`.
4. Submit.
5. Enter `Bananas`.
6. Submit.
7. Enter `Chicken`.
8. Submit.

Verify:

- each item appears immediately
- text field clears after submission
- keyboard remains open
- focus stays in the entry field
- no duplicate accidental submissions occur
- data survives app relaunch

---

### Journey 4: Automatic categorization

Add:

```text
Bananas
Milk
Chicken
Bread
```

Verify expected categories:

```text
Bananas → Produce
Milk → Dairy & Eggs
Chicken → Meat & Seafood
Bread → Bakery
```

Verify unknown items safely fall back to:

```text
Other
```

---

### Journey 5: Manual category override

1. Add an item.
2. Change its category manually.
3. Navigate away.
4. Return.
5. Relaunch app.

Verify the selected category persists.

---

### Journey 6: Complete grocery item

1. Tap an incomplete item.
2. Verify it becomes completed.
3. Tap again.
4. Verify it becomes incomplete.

Check:

- visual state
- accessibility state
- haptic behavior if enabled
- persistence

---

### Journey 7: Edit grocery item

Edit:

- item name
- quantity
- unit
- category
- note

Verify all edited fields persist after relaunch.

---

### Journey 8: Delete item

1. Delete an item.
2. Confirm UI updates.
3. Use Undo if available.
4. Verify restored item returns correctly.

---

### Journey 9: Delete list

1. Attempt to delete an entire grocery list.
2. Verify destructive intent is clear.
3. Confirm deletion.
4. Verify its items are not left as orphaned records.

---

### Journey 10: Duplicate detection

1. Add `Milk`.
2. Attempt to add `Milk` again.

Verify:

- Cartsyne identifies the possible duplicate
- user is informed without being blocked unnecessarily
- user can intentionally keep duplicates

---

### Journey 11: Clear completed

1. Add multiple items.
2. Complete some items.
3. Choose Clear Completed.
4. Verify incomplete items remain untouched.

---

### Journey 12: Duplicate list

1. Create a populated grocery list.
2. Duplicate it.
3. Verify items are copied.
4. Verify the new list and its items receive independent identities.
5. Editing the copy must not modify the original.

---

### Journey 13: Offline usage

1. Enable airplane mode.
2. Launch Cartsyne.
3. Create a list.
4. Add items.
5. Complete items.
6. Edit items.
7. Relaunch.

Expected result:

All MVP functionality continues to work normally.

---

### Journey 14: Dark Mode

Verify primary screens in:

- Light Mode
- Dark Mode

Look specifically for:

- unreadable text
- hard-coded backgrounds
- low contrast
- invisible separators
- incorrect icon tinting

---

### Journey 15: Dynamic Type

Verify primary screens using at least:

- default text size
- a large accessibility text size

Critical actions must remain reachable and understandable.

---

## Unit testing priorities

Highest priority:

### Grocery category suggestion

Test:

- known items
- capitalization
- whitespace
- plural/common variations where supported
- unknown items

### Grocery item completion

Test transitions:

```text
incomplete → completed
completed → incomplete
```

### Duplicate detection

Test normalization such as:

```text
Milk
milk
 MILK
```

according to the selected duplicate rules.

### Sorting and grouping

Test:

- category grouping
- manual order
- completed-item positioning
- stable sorting

### List duplication

Verify copied entities are independent from their source.

### Persistence-facing logic

Where repository/service boundaries exist, test business behavior with substitutes rather than depending on SwiftUI.

---

## UI testing priorities

Keep the UI test suite small and focused.

Recommended initial UI tests:

1. Create list
2. Add item
3. Complete item
4. Relaunch and verify persistence

Add more UI tests only where their maintenance cost is justified.

---

## Regression-sensitive areas

### SwiftData schema

Changes to persisted models may affect existing users.

Be careful when:

- renaming fields
- changing property types
- changing relationships
- changing uniqueness behavior
- removing persisted properties

### List/item relationships

Deleting a list must not leave invalid item records.

### Sorting

Changes to category or completion sorting can easily cause unexpected list jumping.

### Quick entry

The following behavior is core product functionality:

```text
type → submit → type
```

Changes to focus handling, keyboard handling, or form layout must not degrade it.

### Completion interaction

Checking an item should remain fast and reliable.

Avoid adding navigation, confirmations, or delays to this action.

### Duplicate handling

Normalization changes may create false positives or stop detecting common duplicates.

### Dark Mode

Avoid hard-coded colors that break appearance switching.

### Dynamic Type

Custom layouts must not clip essential controls.

### Destructive actions

Changes to swipe actions, context menus, Undo, or deletion logic need regression testing.
