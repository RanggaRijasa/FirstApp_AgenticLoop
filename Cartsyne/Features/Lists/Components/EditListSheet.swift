//
//  EditListSheet.swift
//  Cartsyne
//
//  Created by Rangga Rijasa on 19/08/26.
//

import SwiftUI

/// Sheet for renaming a grocery list.
///
/// The name field is prefilled with the list's current name and receives
/// keyboard focus on presentation. Empty or whitespace-only input is rejected,
/// surrounding whitespace is trimmed before saving, and a failed save keeps
/// the typed text and the sheet open so the user can correct or retry while
/// the list keeps its prior name and modification date.
struct EditListSheet: View {
    @Bindable var model: GroceryListsModel
    let list: GroceryList
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameIsFocused: Bool
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List name", text: $name)
                        .focused($nameIsFocused)
                        .submitLabel(.done)
                        .onSubmit(save)
                        .accessibilityLabel("List name")
                    if let errorText = model.editError {
                        // VoiceOver announces the actionable message
                        // ("We couldn't rename your list. Please try again.")
                        // itself, not a generic label: the text is the
                        // accessible content with no label override.
                        Text(errorText)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
        }
        .onAppear {
            name = list.name
            nameIsFocused = true
        }
    }

    private func save() {
        guard model.renameList(list, to: name) else {
            return
        }
        dismiss()
    }
}

#Preview("Edit") {
    EditListSheet(
        model: GroceryListsModel(repository: PreviewRepository()),
        list: GroceryList(name: "Weekly Groceries")
    )
}

@MainActor
private struct PreviewRepository: GroceryRepository {
    func fetchLists() throws -> [GroceryList] {
        []
    }

    func createList(named name: String) throws -> GroceryList {
        throw GroceryListError.emptyName
    }

    func renameList(id: UUID, to name: String) throws -> GroceryList {
        GroceryList(name: name)
    }

    func deleteList(id: UUID) throws {}
}
