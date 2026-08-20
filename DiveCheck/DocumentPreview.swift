import SwiftUI
import QuickLook

/// Displays a single stored document in place -- currently the uploaded
/// WRSTC medical form PDF and a Certification's uploaded PDF, both stored
/// on disk via DocumentStorage and referenced by every call site only as a
/// filename.
///
/// Checks the file actually exists on disk before handing it to
/// QLPreviewController, and shows a "still downloading" fallback instead
/// when it doesn't. That gap is real, not theoretical: a record's filename
/// reference (e.g. wrstcFormFilename/cardDocumentFilename) can reach a
/// second device almost immediately via CloudSync's separate, always-on
/// per-field iCloud key-value sync, while the referenced file's actual
/// bytes only arrive later through the slower Backup & Sync (iCloud Drive)
/// pipeline in SyncManager.swift -- see the doc comment on
/// SyncManager.pull() for the full explanation, including why a device
/// could previously get stuck with a permanently-dangling reference.
/// Without this check, handing QLPreviewController a URL to a file that
/// isn't actually there yet shows little more than the preview item's raw
/// UUID filename -- easy to mistake for garbage/a hex string instead of a
/// clear "this hasn't finished syncing yet" state.
struct DocumentPreview: View {
    let url: URL
    @State private var fileExists: Bool
    @State private var isRetrying = false

    // Property initializers run before `self` exists, so `fileExists`
    // can't be seeded from `url` as a plain default value (that's a
    // property on the same instance) -- an explicit init sidesteps that by
    // building the State wrapper directly via State(initialValue:).
    init(url: URL) {
        self.url = url
        self._fileExists = State(initialValue: FileManager.default.fileExists(atPath: url.path))
    }

    var body: some View {
        Group {
            if fileExists {
                QuickLookPreview(url: url)
            } else {
                stillDownloadingState
            }
        }
    }

    private var stillDownloadingState: some View {
        VStack(spacing: 12) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Still Downloading")
                .font(.headline)
            Text("This file's info synced to this device, but the file itself hasn't finished coming down from iCloud yet. Try syncing again, then check back here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                retry()
            } label: {
                if isRetrying {
                    ProgressView()
                } else {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRetrying)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func retry() {
        isRetrying = true
        Task {
            await SyncManager.shared.syncNow()
            await MainActor.run {
                fileExists = FileManager.default.fileExists(atPath: url.path)
                isRetrying = false
            }
        }
    }
}

/// The actual QLPreviewController wrapper -- split out from DocumentPreview
/// above so that struct can stay a plain SwiftUI View (able to switch
/// between this and the "still downloading" fallback) while every existing
/// call site keeps using `DocumentPreview(url:)` unchanged. Uses the
/// classic UIViewControllerRepresentable + delegate approach (same pattern
/// as CameraCapture.swift) rather than SwiftUI's newer
/// `.quickLookPreview(_:)` modifier, since QLPreviewController has been
/// stable since iOS 4 and this keeps the code unambiguous about iOS 16
/// compatibility.
private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}
