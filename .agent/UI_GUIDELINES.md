# UI Guidelines

## Principles

- Native SwiftUI controls first.
- Follow Apple platform conventions unless Cartsyne intentionally differs.
- Keep the interface quiet and task-focused.
- Optimize for one-handed use where practical.
- Support Dynamic Type.
- Provide accessibility labels for icon-only interactive controls.
- Respect safe areas.
- Respect keyboard behavior.
- Check Light and Dark Mode.
- Keep interactive hit targets comfortable.
- Prefer SF Symbols.
- Avoid decorative UI that slows grocery entry.
- Prefer direct manipulation over unnecessary dialogs.
- Common actions should require as few taps as practical.

---

## Product UI philosophy

Cartsyne should feel like:

**a shopping list, not a project-management application.**

The core screen should prioritize:

1. what still needs to be purchased
2. adding another item
3. checking items off

Secondary information should not compete with those actions.

---

## Visual system

### Primary accent

Use **iOS system green** as the initial Cartsyne accent.

SwiftUI:

```swift
Color.green
```

Prefer semantic system color behavior rather than hard-coding separate light and dark variants.

Brand color can be revisited after the Cartsyne visual identity is finalized.

### Typography

Use system typography.

Recommended hierarchy:

- screen title: `.largeTitle` or native navigation title
- section/category title: `.headline`
- grocery item: `.body`
- quantity/note/supporting text: `.subheadline` or `.secondary`
- captions: `.caption`

Avoid fixed font sizes unless a specific design requirement justifies them.

### Corner radius

Prefer native component shapes.

For custom cards or surfaces:

```text
12 pt
```

is the default starting point.

Do not apply rounded cards to every piece of content.

### Spacing

Use a small consistent scale:

```text
4
8
12
16
24
32
```

Prefer these values rather than arbitrary per-screen spacing.

### Icons

Use SF Symbols whenever an appropriate symbol exists.

Examples:

```text
plus
cart
cart.fill
checkmark.circle
checkmark.circle.fill
trash
pencil
ellipsis
magnifyingglass
square.and.pencil
list.bullet
chevron.right
```

Avoid mixing unrelated icon styles.

---

## Main grocery list screen

The shopping list is Cartsyne's most important screen.

Recommended hierarchy:

```text
Navigation title
Progress / remaining count
Category sections
Grocery items
Quick-add control
```

### Grocery item row

A row should make these immediately understandable:

- item name
- quantity if present
- completion state
- category through grouping rather than repeated labels where possible

Optional note should remain visually secondary.

Example:

```text
○ Milk                    2
○ Eggs                   12
○ Greek Yogurt            1
```

Completed:

```text
✓ Milk                    2
```

Completed items should remain readable but visually de-emphasized.

Do not make completed text so faint that accessibility suffers.

---

## Quick Add

Quick Add is a first-class interaction.

It should:

- remain easy to reach
- open the keyboard immediately
- allow Return/Submit to create an item
- clear after successful submission
- preserve focus
- allow rapid sequential entry

Preferred flow:

```text
Milk ↵
Eggs ↵
Bananas ↵
Chicken ↵
```

Avoid forcing users through an item-edit screen for every new grocery.

Advanced details can be edited afterward.

---

## Grocery categories

Categories exist to make physical shopping easier.

They should primarily organize the shopping screen, not add management overhead.

Category headers should be visually distinct without dominating the list.

Avoid excessive category colors.

Initial categories:

- Produce
- Meat & Seafood
- Dairy & Eggs
- Bakery
- Pantry
- Frozen
- Drinks
- Snacks
- Household
- Personal Care
- Other

---

## Completed items

Default behavior:

- keep completed items separated from remaining items
- allow completed section to collapse if useful
- allow user to clear completed items
- allow an item to be restored by tapping it again

The user's remaining shopping tasks should always have stronger visual priority.

---

## Empty states

### No lists

Example concept:

```text
Your grocery lists live here.

Create a list to start shopping.
```

Primary action:

```text
Create List
```

### Empty shopping list

Example concept:

```text
Nothing on the list yet.

Add your first grocery below.
```

Keep the Quick Add input immediately accessible.

Avoid large illustrations that push the primary action off-screen.

---

## Loading states

Because MVP data is local, loading states should be uncommon and brief.

Do not introduce artificial spinners.

If local data requires time to initialize, use native progress presentation only when users can actually perceive the wait.

---

## Error states

Errors should state:

1. what happened
2. what the user can do

Example:

```text
Couldn’t save the item.

Try again.
```

Avoid exposing technical implementation details.

---

## Offline state

MVP does not need an offline warning banner because all core functionality is intentionally offline.

Do not show:

```text
You're offline
```

unless a future online-only feature specifically requires connectivity.

---

## Accessibility

### VoiceOver

Every icon-only button needs an accessibility label.

Example:

```swift
Button {
    deleteItem()
} label: {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete item")
```

Completed state should be communicated semantically, not just visually.

### Dynamic Type

Do not assume grocery item names fit on one line.

Allow text to wrap where necessary.

### Contrast

Use semantic system colors such as:

```swift
.primary
.secondary
Color(uiColor: .systemBackground)
Color(uiColor: .secondarySystemBackground)
```

Avoid arbitrary gray values for important text.

### Motion

Respect Reduce Motion if custom animations are added.

Animations should communicate state changes rather than decorate routine actions.

---

## Haptics

Haptics can reinforce important direct actions.

Appropriate uses:

- completing an item
- restoring an item
- successfully adding an item when useful

Keep feedback subtle.

Do not trigger strong haptics for ordinary scrolling, navigation, or typing.

Provide a future preference to disable optional Cartsyne-specific haptics if needed.

---

## Swipe actions

Native swipe actions are appropriate for grocery items.

Potential trailing actions:

```text
Delete
```

Potential leading action:

```text
Edit
```

Do not overload rows with many hidden actions.

Common actions should remain discoverable.

---

## Destructive actions

### Individual grocery item

Prefer:

```text
delete → Undo available
```

rather than:

```text
delete → confirmation dialog
```

### Entire grocery list

A confirmation is appropriate because the impact is larger.

Example concept:

```text
Delete "Weekly Groceries"?

This will also delete all items in this list.
```

---

## Animation

Use native SwiftUI animation sparingly for:

- item completion
- item insertion
- item removal
- category regrouping

Animations should be short and should not delay interaction.

Avoid elaborate transitions during active shopping.

---

## Search

When search is introduced in the MVP, prefer native searchable behavior:

```swift
.searchable(...)
```

Search should cover grocery items or lists according to screen context.

Avoid building a custom search bar unless native behavior cannot meet the requirement.

---

## Navigation rules

Prefer:

- push navigation for moving deeper into content
- sheets for creation and focused editing
- alerts/confirmation dialogs for important destructive decisions

Avoid full-screen covers unless the task genuinely requires full-screen focus.

---

## States every screen should consider

### Grocery Lists

- empty
- populated
- persistence error

### Shopping List

- empty
- populated
- all items completed
- search with no results
- persistence error

### Item Editor

- valid input
- invalid/empty item name
- save failure

### Settings

- normal state
- unavailable future capability if surfaced

Loading and offline states should only exist where the architecture actually requires them.

---

## App-specific UI rules

### 1. Grocery entry always wins

Nothing should make adding a grocery item unnecessarily difficult.

### 2. Never require category selection during quick entry

Category suggestion happens automatically.

Users can correct it afterward.

### 3. Never require quantity

These are equally valid:

```text
Milk
```

and:

```text
Milk × 2
```

### 4. Never require item notes

Notes are optional metadata.

### 5. Keep shopping mode visually simple

While shopping, avoid showing:

- creation timestamps
- internal identifiers
- unnecessary settings
- analytics
- metadata that does not help purchase the item

### 6. Completion should be one tap

The user should not need to open an item before marking it purchased.

### 7. Keep remaining items prominent

Completed items should never visually dominate items that still need to be purchased.

### 8. Keyboard-first entry

The keyboard experience is part of the product, not an implementation detail.

Test:

- focus
- Submit behavior
- dismissal
- safe-area interaction
- toolbar behavior
- repeated entry

### 9. Use native interaction before custom gestures

Do not create custom gestures when a native tap, swipe action, menu, sheet, or navigation pattern already solves the problem.

### 10. No mandatory onboarding

The first screen should be understandable without a tutorial.

If the interface requires several onboarding screens to explain basic grocery-list functionality, simplify the interface instead.
