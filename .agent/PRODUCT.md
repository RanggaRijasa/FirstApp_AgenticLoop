# Product Definition

## App name

**Cartsyne**

## One-sentence purpose

Cartsyne is a fast, simple grocery list app that helps people capture what they need, organize it automatically, and check off items while shopping with as little friction as possible.

## Target users

- Individuals who regularly shop for groceries.
- Couples and families managing recurring household purchases.
- Users who want something faster and simpler than a full meal-planning or inventory app.
- People who frequently forget items while shopping.
- Users who prefer a clean, native iPhone experience without unnecessary setup.

## Core user journey

1. **Create a list**  
   The user opens Cartsyne and quickly creates a grocery list or starts adding items immediately.

2. **Add and organize items**  
   The user types items such as "Milk", "Bananas", or "Chicken". Cartsyne groups them into useful categories such as Dairy, Produce, Meat, Frozen, Household, and Others.

3. **Shop and complete the list**  
   While shopping, the user taps items to mark them as purchased. Completed items move out of the way while remaining easy to restore if tapped accidentally.

## MVP features

- Create, rename, and delete grocery lists.
- Add grocery items quickly.
- Mark items as purchased or unpurchased.
- Edit and delete items.
- Quantity support.
  - Example: `2 Milk`
  - Example: `1 kg Chicken`
- Optional item notes.
- Grocery categories.
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
- Automatic category suggestion based on item name.
- Manual category editing.
- Group shopping list by category.
- Show completed and remaining item counts.
- Recent items for faster re-entry.
- Frequently purchased items.
- Search existing items.
- Duplicate-item detection.
- Reorder items manually.
- Clear completed items.
- Duplicate an existing list.
- Basic list templates such as:
  - Weekly Groceries
  - Household
  - Party
  - Essentials
- Native iOS interface using SwiftUI.
- Light and Dark Mode.
- Haptic feedback for common actions.
- Offline-first operation.
- Local persistence using SwiftData.
- No account required.

## Non-goals for MVP

The first version of Cartsyne will **not** include:

- Meal planning.
- Recipe management.
- Calorie or nutrition tracking.
- Barcode scanning.
- Receipt scanning.
- Grocery-store price comparison.
- Grocery delivery integration.
- Online grocery ordering.
- Store inventory information.
- Location-based supermarket detection.
- Advanced household inventory management.
- AI-generated meal plans.
- Social feeds.
- Public profiles.
- Advertising.
- Android or web versions.
- Complex account systems.
- Real-time collaborative editing.

These features may be considered after the core grocery-list experience is validated.

## Data and privacy

### What user data is stored?

For the MVP, Cartsyne stores:

- Grocery lists.
- Grocery item names.
- Item quantities.
- Item notes.
- Item categories.
- Purchased/completed state.
- List creation and modification dates.
- Recently used items.
- Frequently purchased items.
- Basic app preferences.

### Is any sensitive data involved?

Cartsyne is not designed to collect sensitive personal information.

Users may voluntarily type personal information into item names or notes, but the app does not require:

- Real names.
- Email addresses.
- Phone numbers.
- Location.
- Health information.
- Payment information.
- Contacts.

### What stays on-device vs server-side?

**MVP: Local-first.**

All grocery-list data remains on the user's device.

No Cartsyne server account is required.

Recommended storage:

- **SwiftData** for lists and grocery items.
- **UserDefaults / AppStorage** for lightweight preferences.

Future versions may optionally support private iCloud synchronization between the user's Apple devices.

Cartsyne should not sell user data or use grocery-list contents for advertising.

## External services

**None required for MVP.**

The application should work completely offline.

Potential future Apple services:

- CloudKit / iCloud sync.
- Sign in with Apple if accounts ever become necessary.
- App Store In-App Purchase for premium features.
- Siri / App Intents.
- Widgets.

The MVP should avoid third-party SDK dependencies unless there is a clear technical requirement.

## Monetization

**MVP: Free.**

The initial release should focus on validating whether users enjoy the core shopping experience.

Potential future model:

### Cartsyne Free

- Unlimited basic grocery lists.
- Grocery categories.
- Recent items.
- Frequently purchased items.
- Offline storage.

### Cartsyne Plus

Possible future premium features:

- iCloud synchronization.
- Shared household lists.
- Smart suggestions.
- Advanced templates.
- Widgets.
- Siri / Shortcuts integration.
- List history.
- Custom categories.
- Custom app icons.
- Advanced recurring-item features.

Prefer a simple subscription or one-time purchase rather than advertising.

No monetization is required for the first MVP release.

## Minimum iOS version

**iOS 18**

### Reasoning

iOS 18 provides a good balance between:

- Supporting a broad range of active iPhone users.
- Modern SwiftUI APIs.
- SwiftData support.
- App Intents integration potential.
- Modern navigation and observation patterns.
- Reduced need for compatibility code.

The architecture should avoid depending unnecessarily on newer APIs so that the minimum deployment target can remain iOS 18.

## Success criteria

The MVP is successful if users can go from opening Cartsyne to having a useful grocery list in **under 30 seconds**.

Additional success criteria:

- Adding an item should normally require no more than a few taps.
- Users can operate the entire core app without creating an account.
- Grocery lists remain available offline.
- Existing lists load instantly during normal use.
- Checking off an item feels immediate.
- Automatic category suggestions are correct often enough to reduce manual organization.
- Users can easily recover from accidentally completing or deleting an item.
- The interface remains understandable without onboarding.
- A first-time user can create, use, and complete a shopping list without instructions.
- The MVP has no critical crashes or data-loss bugs.
- Core flows have automated tests.
- The app feels like a focused grocery tool rather than a general productivity app.

## MVP product principle

**Open. Add. Shop. Done.**

Every feature in the MVP should support one of those four actions. If a feature makes grocery shopping slower or introduces unnecessary setup, it should probably not be part of the first version.