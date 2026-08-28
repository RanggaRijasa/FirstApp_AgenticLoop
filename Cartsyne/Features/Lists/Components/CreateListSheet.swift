//
//  CreateListSheet.swift
//  Cartsyne
//
//  Created by Rangga Rijasa on 19/08/26.
//

import SwiftUI

/// Sheet for creating a grocery list.
///
/// The name field receives keyboard focus on presentation, rejects empty or
/// whitespace-only input, trims surrounding whitespace before saving, and
/// keeps the typed text and the sheet open when saving fails so the user can
/// correct or retry.
struct CreateListSheet: View {
    @Bindable var model: GroceryListsModel
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
                    if let errorText = model.createError {
                        // VoiceOver announces the actionable message
                        // ("We couldn't create your list. Please try again.")
                        // itself, not a generic label: the text is the
                        // accessible content with no label override.
                        Text(errorText)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        save()
                    }
                }
            }
        }
        .onAppear {
            nameIsFocused = true
        }
    }

    private func save() {
        guard model.createList(named: name) else {
            return
        }
        dismiss()
    }
}
