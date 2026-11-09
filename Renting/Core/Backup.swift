//
//  Backup.swift
//  Renting
//
//  A backup of all the data as one file the landlord can keep anywhere: Files, Drive, Dropbox,
//  an e-mail to themselves. It needs no account and no server, so it also works for someone
//  without iCloud, and it is how the data moves to a new phone. It is the same JSON the app
//  keeps on the device, in a small envelope that says what it is and which format it has.
//
//  Restoring replaces everything that is in the app. The file holds the personal data of the
//  tenants, so the screen says where it should be kept.
//

import Foundation

/// The envelope around the data.
struct BackupFile: Codable {
    var app = "renting"
    var format = BackupService.currentFormat
    var exportedAt: Date
    var appVersion: String
    var data: Snapshot
}

/// Just enough of the file to tell whether it is ours and whether this version can read it.
private struct BackupHeader: Codable {
    var app: String
    var format: Int
}

enum BackupError: Error, Equatable {
    /// Not a Renting backup (or damaged).
    case notABackup
    /// Written by a newer version of the app.
    case newerFormat
    /// A backup with nothing in it: restoring it would only erase the data.
    case empty
}

/// What a backup holds, for the "this will replace that" confirmation.
struct BackupSummary: Equatable {
    var homes: Int
    var rooms: Int
    var tenants: Int
    var payments: Int
    var expenses: Int

    var isEmpty: Bool { homes + rooms + tenants + payments + expenses == 0 }

    /// "Homes: 3 · Tenants: 8 · Payments: 120".
    var text: String { isEmpty ? L("backup.none") : L("backup.summary", homes, tenants, payments) }
}

enum BackupService {
    static let currentFormat = 1

    static func summary(of snapshot: Snapshot) -> BackupSummary {
        BackupSummary(homes: snapshot.properties.count, rooms: snapshot.units.count, tenants: snapshot.tenants.count,
                      payments: snapshot.payments.count, expenses: snapshot.expenses.count)
    }

    /// The sample portfolio is never exported (it is not the landlord's data) and neither is an empty app.
    static func canExport(_ snapshot: Snapshot) -> Bool { !snapshot.isDemo && !summary(of: snapshot).isEmpty }

    static func fileName(now: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return "Renting-backup-\(f.string(from: now)).json"
    }

    static func encode(_ snapshot: Snapshot, now: Date = Date()) throws -> Data {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return try JSONEncoder().encode(BackupFile(exportedAt: now, appVersion: version, data: snapshot))
    }

    /// Writes the backup to a temporary file, ready to be shared.
    static func writeFile(_ snapshot: Snapshot, now: Date = Date()) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(now: now))
        try encode(snapshot, now: now).write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    /// Reads a backup. Rejects what is not ours, what is newer than this version and what is empty;
    /// repairs what a damaged or hand-edited file could break (records without a parent, payments
    /// without their fixed id). The result is never the sample portfolio.
    static func decode(_ data: Data) throws -> Snapshot {
        guard let header = try? JSONDecoder().decode(BackupHeader.self, from: data), header.app == "renting" else { throw BackupError.notABackup }
        guard header.format <= currentFormat else { throw BackupError.newerFormat }
        guard var snapshot = (try? JSONDecoder().decode(BackupFile.self, from: data))?.data else { throw BackupError.notABackup }
        snapshot.isDemo = false
        snapshot.pruneOrphans()
        snapshot.normalizePayments()
        guard !summary(of: snapshot).isEmpty else { throw BackupError.empty }
        return snapshot
    }
}
