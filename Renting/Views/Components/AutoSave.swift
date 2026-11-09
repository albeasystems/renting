//
//  AutoSave.swift
//  Renting
//
//  Editing in place: the detail screens of a home, a room and a tenant show their fields as
//  editable controls, with no "Edit" and "Save" buttons. The screen edits a copy (`draft`) and
//  writes it to the store half a second after the last change (so typing does not rewrite the
//  data on every key), when the screen goes away, when the app leaves the foreground and
//  whenever the screen asks for it (before opening a sheet that saves the same record).
//
//  A change that comes from elsewhere (a rent update applied from its sheet, iCloud) replaces
//  the copy, unless the user has edits that are not saved yet.
//

import SwiftUI

struct AutoSave<Value: Equatable>: ViewModifier {
    @Binding var draft: Value
    /// What the store holds now.
    let stored: Value
    /// Bump it to write pending edits right now.
    let flush: Int
    /// Writes the copy to the store. It must ignore a record that no longer exists (it was deleted
    /// from this screen) and a copy that is not valid yet (an empty name).
    let write: (Value) -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var synced: Value?
    @State private var pending: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onAppear { if synced == nil { synced = stored } }
            .onChange(of: draft) { _, value in
                guard value != synced else { return }
                pending?.cancel()
                pending = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    guard !Task.isCancelled else { return }
                    save()
                }
            }
            .onChange(of: stored) { _, value in
                // Our own write comes back equal to `synced`; anything else is a change from outside.
                guard value != synced, draft == synced else { return }
                draft = value
                synced = value
            }
            .onChange(of: flush) { _, _ in save() }
            .onChange(of: scenePhase) { _, phase in if phase != .active { save() } }
            .onDisappear { save() }
    }

    private func save() {
        pending?.cancel()
        guard draft != synced else { return }
        write(draft)
        synced = draft
    }
}

extension View {
    /// See `AutoSave`.
    func autoSave<Value: Equatable>(_ draft: Binding<Value>, stored: Value, flush: Int = 0, write: @escaping (Value) -> Void) -> some View {
        modifier(AutoSave(draft: draft, stored: stored, flush: flush, write: write))
    }

    /// A "Done" button above the number and phone keyboards, which have no return key.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("common.done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}
