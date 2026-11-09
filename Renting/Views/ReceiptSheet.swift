//
//  ReceiptSheet.swift
//  Renting
//
//  Preview of a rent receipt, the landlord's details printed on it, and the share
//  button (WhatsApp, Mail, Files…). Receipts are part of the subscription: without it the
//  sheet explains that and opens the plan, and no receipt is made.
//

import SwiftUI
import PDFKit

struct ReceiptSheet: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tenant: Tenant
    let month: MonthKey
    @AppStorage(Landlord.nameKey) private var landlordName = ""
    @AppStorage(Landlord.taxIDKey) private var landlordTaxID = ""
    @State private var url: URL?
    @State private var version = 0
    @State private var plan = StoreManager.shared

    var body: some View {
        NavigationStack {
            Form {
                if plan.hasCloud {
                    Section {
                        TextField("receipt.landlord_name", text: $landlordName).textContentType(.name)
                        TextField("receipt.landlord_tax_id", text: $landlordTaxID)
                            .textInputAutocapitalization(.characters).autocorrectionDisabled()
                    } header: { Text("receipt.landlord") } footer: { Text("receipt.landlord.footer") }
                    Section {
                        if let url {
                            PDFPreview(url: url, version: version)
                                .aspectRatio(420.0 / 595.0, contentMode: .fit)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                } else {
                    Section {
                        PlanLockRow(text: "receipt.locked")
                    }
                }
            }
            .navigationTitle("receipt.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.done") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if let url {
                        ShareLink(item: url, subject: Text("receipt.title"), message: Text("receipt.message \(month.title())")) {
                            Label("receipt.share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .task { regenerate() }
            .onChange(of: landlordName) { _, _ in regenerate() }
            .onChange(of: landlordTaxID) { _, _ in regenerate() }
        }
    }

    private func regenerate() {
        guard plan.hasCloud else { return }
        url = ReceiptService.make(tenant: tenant, month: month, store: store)
        version += 1
    }
}

/// Read-only PDF page; `version` forces a reload when the file is rewritten in place.
struct PDFPreview: UIViewRepresentable {
    let url: URL
    let version: Int

    final class Coordinator { var version = -1 }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.displayMode = .singlePage
        view.backgroundColor = .secondarySystemGroupedBackground
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        guard context.coordinator.version != version else { return }
        context.coordinator.version = version
        view.document = PDFDocument(url: url)
        view.autoScales = true
    }
}
