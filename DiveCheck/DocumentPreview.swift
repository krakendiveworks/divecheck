import SwiftUI
import QuickLook

/// Thin SwiftUI wrapper around QLPreviewController for viewing a single
/// document in place -- currently just the uploaded WRSTC medical form
/// PDF. Uses the classic UIViewControllerRepresentable + delegate approach
/// (same pattern as CameraCapture.swift) rather than SwiftUI's newer
/// `.quickLookPreview(_:)` modifier, since QLPreviewController has been
/// stable since iOS 4 and this keeps the code unambiguous about iOS 16
/// compatibility.
struct DocumentPreview: UIViewControllerRepresentable {
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
