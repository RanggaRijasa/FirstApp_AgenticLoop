//
//  GroceryListsView.swift
//  Cartsyne
//
//  Created by Rangga Rijasa on 19/08/26.
//

import SwiftUI

/// The app's home screen: a navigation root titled Grocery Lists.
///
/// Launches directly into the list of grocery lists with no login, setup,
/// dashboard, or onboarding. Handles the empty, populated, and load-error
/// states.
struct GroceryListsView: View {
    @Bindable var model: GroceryListsModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Grocery Lists")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            model.startCreatingList()
                        } label: {
                            Label("Create List", systemImage: "plus")
                        }
                        .accessibilityLabel("Create List")
                    }
                }
                .sheet(isPresented: $model.isPresentingCreateSheet) {
                    CreateListSheet(model: model)
                }
                .task {
                    model.load()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let errorText = model.loadError {
            VStack(spacing: 12) {
                Text(errorText)
                    .multilineTextAlignment(.center)
                Button("Try Again") {
                    model.load()
                }
            }
            .padding(.horizontal, 24)
        } else if model.lists.isEmpty {
            emptyState
        } else {
            List(model.lists, id: \.id) { list in
                Text(list.name)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Your grocery lists live here.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Create a list to start shopping.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                model.startCreatingList()
            } label: {
                Label("Create List", systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.top, 8)
            .accessibilityLabel("Create List")
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Empty") {
    GroceryListsView(model: GroceryListsModel(repository: PreviewRepository()))
}


@MainActor
private struct PreviewRepository: GroceryRepository {
    func fetchLists() throws -> [GroceryList] {
        []
    }

    func createList(named name: String) throws -> GroceryList {
        throw GroceryListError.emptyName
    }

    func renameList(id: UUID, to name: String) throws {}

    func deleteList(id: UUID) throws {}
}
