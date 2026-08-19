# Architecture

- Native iOS app
- Swift
- SwiftUI
- Default deployment target: **iOS 26.5**
- Fallback deployment target: **iOS 18**
- Xcode project settings are managed by the human in Xcode

The default build targets iOS 26.5. Keep the implementation compatible with iOS 18 so the deployment target can be lowered when broader device support is required. APIs newer than iOS 18 require availability checks or an iOS 18-compatible alternative.

## Default engineering approach

- Feature-oriented source organization
- Swift Observation using `@Observable`
- Structured concurrency using `async/await`
- Task cancellation where asynchronous work can outlive a screen or user action
- Actor isolation where shared mutable state requires it
- Protocol boundaries for services where they improve testability
- Dependency injection using initializers and/or SwiftUI Environment
- `NavigationStack` for hierarchical navigation
- Prefer Apple frameworks over third-party dependencies
- Keep architecture simple until actual product requirements justify additional abstraction

## Suggested source organization

```text
Cartsyne/
├── App/
│   ├── CartsyneApp.swift
│   ├── AppEnvironment.swift
│   └── RootView.swift
│
├── Features/
│   ├── Lists/
│   │   ├── GroceryListsView.swift
│   │   ├── GroceryListsModel.swift
│   │   └── Components/
│   │
│   ├── ShoppingList/
│   │   ├── ShoppingListView.swift
│   │   ├── ShoppingListModel.swift
│   │   ├── AddItemView.swift
│   │   └── Components/
│   │
│   ├── ItemEditor/
│   │   ├── ItemEditorView.swift
│   │   └── ItemEditorModel.swift
│   │
│   └── Settings/
│       └── SettingsView.swift
│
├── Models/
│   ├── GroceryList.swift
│   ├── GroceryItem.swift
│   └── GroceryCategory.swift
│
├── Persistence/
│   ├── GroceryRepository.swift
│   └── SwiftDataGroceryRepository.swift
│
├── Services/
│   ├── CategorySuggestionService.swift
│   └── RecentItemsService.swift
│
├── DesignSystem/
│   ├── CartsyneSpacing.swift
│   └── CartsyneTheme.swift
│
└── Utilities/
```

This is a guideline rather than a requirement. Do not create folders or types solely to match the structure when there is no code that belongs there.

---

## Persistence

### Decision for this app

Use **SwiftData as the primary local persistence layer**.

Use:

- `SwiftData` for grocery lists and grocery items
- `AppStorage` / `UserDefaults` for small preferences
- No Keychain requirement for MVP
- No server-backed source of truth for MVP

### SwiftData models

Primary persisted entities:

#### GroceryList

Suggested properties:

- `id`
- `name`
- `createdAt`
- `updatedAt`
- collection of grocery items

#### GroceryItem

Suggested properties:

- `id`
- `name`
- `quantity`
- `unit`
- `note`
- `category`
- `isCompleted`
- `createdAt`
- `updatedAt`
- optional completion date
- optional manual sort position

### Grocery categories

Prefer a stable Swift enum where possible.

Initial categories:

```text
Produce
Meat & Seafood
Dairy & Eggs
Bakery
Pantry
Frozen
Drinks
Snacks
Household
Personal Care
Other
```

Persist a stable identifier rather than user-facing localized text.

### Preferences

`AppStorage` is appropriate for preferences such as:

- default sorting mode
- show/hide completed items
- haptic feedback preference
- appearance preference if Cartsyne later exposes one
- onboarding completion state if onboarding is introduced

### Persistence rule

The UI should not directly contain persistence business logic.

Where useful, expose persistence through a lightweight repository boundary such as:

```swift
protocol GroceryRepository {
    func fetchLists() throws -> [GroceryList]
    func save() throws
}
```

Do not introduce a repository merely to wrap every individual SwiftData operation if it provides no testing or architectural benefit.

---

## Networking

### Decision for this app

**No networking is required for MVP.**

Cartsyne is local-first and should remain fully usable without an internet connection.

Therefore:

- No API client is required
- No authentication is required
- No server is required
- No background network synchronization is required
- No third-party analytics SDK is required

If networking is introduced later:

- use `URLSession`
- use `Codable`
- use `async/await`
- introduce service protocols where they provide meaningful testability
- keep remote models separate from persisted/domain models when their responsibilities differ

Potential future networking-related feature:

- optional iCloud/CloudKit synchronization

CloudKit should be treated as a separate future architectural decision rather than assumed in the MVP.

---

## Error handling

- User-facing errors should be understandable and recoverable where possible.
- Log technical detail without exposing secrets.
- Do not silently swallow errors.
- Persistence failures must not be ignored.
- Destructive operations should provide an appropriate recovery path.
- Prefer inline error states for contextual failures.
- Use alerts when an error requires immediate user attention.
- Avoid exposing raw Swift errors directly to the user.

Example:

Bad:

```text
NSCocoaErrorDomain Code=134060
```

Better:

```text
We couldn’t save this item. Please try again.
```

### Destructive actions

Actions such as deleting an entire list should require confirmation when accidental loss would be significant.

Deleting or completing an individual grocery item should remain fast and should preferably support Undo rather than requiring confirmation every time.

---

## State management

Use Swift Observation.

Feature state that drives a screen may use:

```swift
@Observable
@MainActor
final class ShoppingListModel {
    // State and actions
}
```

Rules:

- UI-owned transient state stays close to the view
- business logic should not accumulate inside large SwiftUI `body` implementations
- feature models should own meaningful screen logic
- shared state should only exist when multiple features genuinely need it
- do not introduce a global app-state object for convenience
- avoid singletons

Use `@State` for local view state such as:

- text field contents
- sheet presentation
- focus state
- temporary selection

Use environment dependencies for app-wide services only when appropriate.

---

## Concurrency

Most MVP functionality is local and synchronous from the user's perspective.

Use structured concurrency only where appropriate.

Potential asynchronous operations include:

- future CloudKit synchronization
- future intelligent category suggestions
- importing data
- system integrations

Rules:

- UI-facing observable models should normally be `@MainActor`
- cancel tasks that become irrelevant
- avoid detached tasks unless specifically justified
- never block the main actor with expensive work

---

## Navigation

Use `NavigationStack`.

Suggested hierarchy:

```text
Grocery Lists
    ↓
Shopping List
    ↓
Item Editor
```

Sheets are appropriate for:

- creating a new list
- editing an item
- list settings
- template selection

Avoid deeply nested navigation for MVP.

The fastest path from launch to entering groceries should remain the priority.

---

## Dependency management

MVP target:

**Zero third-party runtime dependencies.**

Use:

- SwiftUI
- SwiftData
- Observation
- Foundation

Introduce packages only when a concrete requirement cannot reasonably be solved with system frameworks.

---

## Architecture boundaries

- Do not introduce a third-party architecture framework by default.
- Do not introduce TCA, RxSwift, Combine-based architecture, or similar frameworks unless explicitly justified.
- Do not create a global singleton service layer.
- Avoid generic repositories, coordinators, factories, managers, and service abstractions without an actual need.
- Keep SwiftData implementation details out of unrelated UI code where practical.
- Avoid premature abstraction.
- Prefer small feature-specific types over large shared utility types.
- Avoid a massive `AppViewModel`.
- Avoid a massive `ContentView`.
- Views should render state and communicate user intent rather than contain the entire application's business logic.

---

## App-specific decisions

### 1. Local-first

Cartsyne must work completely offline.

Opening, editing, completing, and deleting grocery items must never depend on network availability.

### 2. No account for MVP

The user can install Cartsyne and immediately create a grocery list.

No:

- login screen
- registration
- email verification
- profile setup

### 3. SwiftData is the source of truth

Persistent grocery state should be stored in SwiftData.

Do not maintain a second independent in-memory copy of the same data unless required for transient editing.

### 4. Completion is state, not deletion

Checking an item means:

```text
isCompleted = true
```

It should not delete the item.

This makes:

- accidental completion recoverable
- completed-item display possible
- future purchase history possible

### 5. Grocery item entry must be optimized for speed

The primary interaction is adding items.

The interface should optimize for:

```text
type → submit → type next item
```

After submitting an item:

- save immediately
- clear the entry field
- keep keyboard focus
- allow the next item to be typed immediately

### 6. Category suggestion is local and deterministic for MVP

Automatic categorization should initially use a lightweight local mapping.

Example:

```text
banana → Produce
apple → Produce
milk → Dairy & Eggs
chicken → Meat & Seafood
bread → Bakery
```

It should not require AI or a remote API.

Users must be able to override a suggested category.

### 7. Manual user choice wins

If the user manually changes an item's category, Cartsyne should respect that selection.

Automatic logic should not unexpectedly overwrite explicit user choices.

### 8. Duplicate detection should assist, not block

If the user enters an item that already exists on the current list, Cartsyne may suggest:

```text
Milk is already on this list.
```

The user should still be able to create the duplicate if desired.

### 9. Deletion should be recoverable where practical

Use SwiftUI's native Undo patterns or an equivalent lightweight mechanism for accidental item deletion.

Do not add confirmation dialogs to routine item-level actions unless necessary.

### 10. No hidden network dependency

The core experience must behave identically in airplane mode.
