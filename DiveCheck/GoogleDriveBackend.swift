import Foundation
import UIKit
import GoogleSignIn

/// Syncs DiveCheck's data to the signed-in user's Google Drive, in a
/// dedicated "DiveCheck" folder their account can see in Drive (not a
/// hidden app-data folder) -- uses the `drive.file` scope, which only ever
/// grants this app access to files it creates itself, not the user's whole
/// Drive.
///
/// NOT included in the Xcode project by default. Adding it requires:
/// 1. A Google Cloud OAuth Client ID (iOS type) -- see GOOGLE_DRIVE_SETUP.md.
/// 2. The GoogleSignIn-iOS Swift Package added via Xcode (File > Add
///    Package Dependencies > https://github.com/google/GoogleSignIn-iOS).
/// 3. This file added to the DiveCheck target (drag it into Xcode's
///    Project Navigator, or File > Add Files to "DiveCheck"...).
/// 4. A line added to DiveCheckApp.swift to configure it at launch --
///    see GOOGLE_DRIVE_SETUP.md for the exact snippet.
/// 5. The reversed Client ID added as a URL scheme in Info.plist, and
///    `.onOpenURL { GIDSignIn.sharedInstance.handle($0) }` added to
///    DiveCheckApp.swift's WindowGroup, so the sign-in redirect completes.
///
/// Until all of that's done, Settings' Google Drive option shows "not set
/// up yet" instead of a broken sign-in button -- see
/// SyncManager.googleDriveFactory's doc comment for how that degrades
/// gracefully.
@objc(GoogleDriveBackend)
final class GoogleDriveBackend: NSObject, CloudSyncBackend {
    private static let folderName = "DiveCheck"
    private static let folderMimeType = "application/vnd.google-apps.folder"
    private static let apiBase = "https://www.googleapis.com/drive/v3/files"
    private static let uploadBase = "https://www.googleapis.com/upload/drive/v3/files"

    override init() {
        super.init()
    }

    var accountLabel: String {
        GIDSignIn.sharedInstance.currentUser?.profile?.email ?? "Google Drive"
    }

    // MARK: - Auth

    private func accessToken() async throws -> String {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw SyncBackendError.notSignedIn
        }
        return try await withCheckedThrowingContinuation { continuation in
            user.refreshTokensIfNeeded { refreshedUser, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token = refreshedUser?.accessToken.tokenString {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: SyncBackendError.notSignedIn)
                }
            }
        }
    }

    // MARK: - Folder / file lookup

    /// Finds (or creates, on first use) the "DiveCheck" folder this app
    /// keeps every synced file in.
    private func folderID(token: String) async throws -> String {
        let query = "mimeType='\(Self.folderMimeType)' and name='\(Self.folderName)' and trashed=false"
        if let existing = try await findFile(query: query, token: token) {
            return existing.id
        }
        var request = URLRequest(url: URL(string: Self.apiBase)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["name": Self.folderName, "mimeType": Self.folderMimeType])
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(DriveFile.self, from: data).id
    }

    private func fileID(named name: String, folderID: String, token: String) async throws -> String? {
        let query = "'\(folderID)' in parents and name='\(name)' and trashed=false"
        return try await findFile(query: query, token: token)?.id
    }

    private func findFile(query: String, token: String) async throws -> DriveFile? {
        var components = URLComponents(string: Self.apiBase)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "spaces", value: "drive"),
            URLQueryItem(name: "fields", value: "files(id,name)"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(DriveFileList.self, from: data).files.first
    }

    // MARK: - CloudSyncBackend

    func upload(_ data: Data, remoteName: String) async throws {
        let token = try await accessToken()
        let folderID = try await folderID(token: token)
        if let existingID = try await fileID(named: remoteName, folderID: folderID, token: token) {
            var request = URLRequest(url: URL(string: "\(Self.uploadBase)/\(existingID)?uploadType=media")!)
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            _ = try await URLSession.shared.data(for: request)
        } else {
            let boundary = UUID().uuidString
            var request = URLRequest(url: URL(string: "\(Self.uploadBase)?uploadType=multipart")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            let metadata = try JSONSerialization.data(withJSONObject: ["name": remoteName, "parents": [folderID]])
            request.httpBody = Self.multipartBody(boundary: boundary, metadataJSON: metadata, fileData: data)
            _ = try await URLSession.shared.data(for: request)
        }
    }

    func download(remoteName: String) async throws -> Data? {
        let token = try await accessToken()
        let folderID = try await folderID(token: token)
        guard let id = try await fileID(named: remoteName, folderID: folderID, token: token) else { return nil }
        var components = URLComponents(string: "\(Self.apiBase)/\(id)")!
        components.queryItems = [URLQueryItem(name: "alt", value: "media")]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    func listRemoteFilenames() async throws -> Set<String> {
        let token = try await accessToken()
        let folderID = try await folderID(token: token)
        var components = URLComponents(string: Self.apiBase)!
        components.queryItems = [
            URLQueryItem(name: "q", value: "'\(folderID)' in parents and trashed=false"),
            URLQueryItem(name: "fields", value: "files(id,name)"),
            URLQueryItem(name: "pageSize", value: "1000"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        let list = try JSONDecoder().decode(DriveFileList.self, from: data)
        return Set(list.files.compactMap { $0.name })
    }

    func delete(remoteName: String) async throws {
        let token = try await accessToken()
        let folderID = try await folderID(token: token)
        guard let id = try await fileID(named: remoteName, folderID: folderID, token: token) else { return }
        var request = URLRequest(url: URL(string: "\(Self.apiBase)/\(id)")!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Multipart body

    private static func multipartBody(boundary: String, metadataJSON: Data, fileData: Data) -> Data {
        var body = Data()
        func append(_ string: String) { body.append(string.data(using: .utf8)!) }
        append("--\(boundary)\r\n")
        append("Content-Type: application/json; charset=UTF-8\r\n\r\n")
        body.append(metadataJSON)
        append("\r\n--\(boundary)\r\n")
        append("Content-Type: application/octet-stream\r\n\r\n")
        body.append(fileData)
        append("\r\n--\(boundary)--")
        return body
    }
}

private struct DriveFile: Codable {
    let id: String
    let name: String?
}

private struct DriveFileList: Codable {
    let files: [DriveFile]
}

// MARK: - Sign-in / SyncManager wiring

extension GoogleDriveBackend {
    static func signIn(presenting viewController: UIViewController, completion: @escaping (Result<Void, Error>) -> Void) {
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    static func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    static var isSignedIn: Bool {
        GIDSignIn.sharedInstance.currentUser != nil
    }
}

extension SyncManager {
    /// Call once at launch (see GOOGLE_DRIVE_SETUP.md for exactly where)
    /// with your Google Cloud OAuth Client ID. Configures GoogleSignIn and
    /// registers this backend with SyncManager -- once this has run,
    /// Settings' Google Drive option lights up automatically.
    static func registerGoogleDrive(clientID: String) {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        googleDriveFactory = { GoogleDriveBackend() }
        googleSignInHandler = { viewController, completion in
            GoogleDriveBackend.signIn(presenting: viewController, completion: completion)
        }
        googleSignOutHandler = { GoogleDriveBackend.signOut() }
        googleIsSignedInHandler = { GoogleDriveBackend.isSignedIn }
    }
}
