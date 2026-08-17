import SwiftUI
import UIKit

/// Presents `UIActivityViewController` the way UIKit actually expects it --
/// via an imperative `present(_:animated:)` call from a real view
/// controller already in the hierarchy -- instead of handing the activity
/// controller to SwiftUI's `.sheet` as its content. `UIActivityViewController`
/// assumes it has been properly *presented*: activities that need to
/// present something further of their own (Print's AirPrint panel, Mail's
/// compose sheet, Messages) lose that presentation context when SwiftUI
/// instead adds it as a *child* view controller inside its own hosting
/// sheet, and can come up as a blank screen instead of doing anything --
/// this is exactly what broke "print the EAP" (Print needs to present its
/// own AirPrint UI on top of the activity sheet).
///
/// Usage: attach `.background(ShareSheetPresenter(items: $shareItems))`
/// anywhere in the view, then set `shareItems` to a non-nil array to
/// present the share sheet. It resets itself to `nil` once the user
/// dismisses it (via a completed/cancelled activity), so re-tapping the
/// share button always starts fresh.
struct ShareSheetPresenter: UIViewControllerRepresentable {
    @Binding var items: [Any]?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let items, uiViewController.presentedViewController == nil {
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                self.items = nil
            }
            // iPad presents this as a popover and requires an anchor, or it
            // throws at presentation time -- anchoring to the middle of
            // this (invisible) host view is a reasonable default since the
            // toolbar button that triggered this isn't available here.
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = uiViewController.view
                popover.sourceRect = CGRect(x: uiViewController.view.bounds.midX, y: uiViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            uiViewController.present(activityVC, animated: true)
        } else if items == nil, uiViewController.presentedViewController is UIActivityViewController {
            uiViewController.dismiss(animated: true)
        }
    }
}
