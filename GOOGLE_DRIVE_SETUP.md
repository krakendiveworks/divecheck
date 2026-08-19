# Setting up Google Drive backup for DiveCheck

DiveCheck's Backup & Sync (Settings > Backup & Sync) already works with
iCloud Drive out of the box -- no setup needed there. Google Drive needs a
few one-time steps first, because it requires your own Google Sign-In
credentials (Google doesn't let an app use anyone else's).

`GoogleDriveBackend.swift` (already in your DiveCheck folder on your Mac,
alongside this file) has the actual sync code fully written -- it's just
not part of the Xcode project yet, since it depends on a package and
credentials only you can provide. Once you've done the steps below, it
switches on automatically -- Settings' Google Drive option will go from
"not set up yet" to a working sign-in button with no further code changes.

This takes about 10-15 minutes, once.

## 1. Create a Google Cloud OAuth Client ID

1. Go to [console.cloud.google.com](https://console.cloud.google.com/) and
   sign in with any Google account (this doesn't have to be the same
   account you'll back up DiveCheck data to later).
2. Create a new project (top left, "Select a project" > "New Project") --
   name it anything, e.g. "DiveCheck". Wait for it to finish creating.
3. In the search bar, search for **"Google Drive API"** and open it, then
   click **Enable**.
4. Go to **APIs & Services > OAuth consent screen**. Choose **External**,
   fill in an app name (e.g. "DiveCheck"), your email for the support and
   developer contact fields, and save through the remaining steps (Scopes
   and Test users can be left as-is -- you'll add yourself as a test user
   in the next step, which is enough since this is for your own personal
   use, not public distribution).
5. On the **Audience** or **Test users** section of the consent screen,
   add the Google account(s) you'll actually sign into DiveCheck with.
   While the app is in "Testing" mode (the default, and totally fine to
   stay in indefinitely for personal use), only accounts listed here can
   sign in -- everyone else gets blocked, which is a feature, not a bug,
   for an app only you use.
6. Go to **APIs & Services > Credentials** > **+ Create Credentials** >
   **OAuth client ID**. Application type: **iOS**. Bundle ID: enter
   DiveCheck's exact bundle identifier (open the project in Xcode, select
   the DiveCheck target > General tab, copy the "Bundle Identifier" value
   exactly).
7. Click Create. You'll get a **Client ID** that looks like
   `123456789-abc...xyz.apps.googleusercontent.com` -- copy it, you'll
   need it twice below.

## 2. Add the GoogleSignIn package in Xcode

1. Open the DiveCheck project in Xcode.
2. **File > Add Package Dependencies...**
3. Paste in the URL: `https://github.com/google/GoogleSignIn-iOS`
4. Choose **Up to Next Major Version**, starting at **7.0.0** (or just
   accept Xcode's default, which will be recent enough).
5. When Xcode asks which products to add to the DiveCheck target, check
   both **GoogleSignIn** and **GoogleSignInSwift**.

## 3. Add GoogleDriveBackend.swift to the project

`GoogleDriveBackend.swift` is already sitting in your DiveCheck folder on
your Mac (delivered alongside this file) -- it just isn't part of the
Xcode project's file list yet.

1. In Xcode's Project Navigator (left sidebar), right-click the
   **DiveCheck** group (the yellow folder icon, not the blue project
   icon) and choose **Add Files to "DiveCheck"...**
2. Navigate to and select `GoogleDriveBackend.swift`.
3. Make sure **"Copy items if needed"** is unchecked (it's already in the
   right folder) and the **DiveCheck** target is checked, then click Add.

## 4. Configure it at launch

Open `DiveCheckApp.swift` and update it to look like this (only the
highlighted parts are new -- everything else stays the same):

```swift
import SwiftUI
import GoogleSignIn

@main
struct DiveCheckApp: App {
    init() {
        SyncManager.registerGoogleDrive(clientID: "YOUR_CLIENT_ID.apps.googleusercontent.com")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
```

Replace `YOUR_CLIENT_ID.apps.googleusercontent.com` with the real Client ID
from step 1.7.

## 5. Add the URL scheme to Info.plist

Google's sign-in flow redirects back into DiveCheck through a custom URL
scheme -- the **reversed** version of your Client ID (swap the
dot-separated parts around). If your Client ID is
`123456789-abc.apps.googleusercontent.com`, the reversed form is
`com.googleusercontent.apps.123456789-abc`.

1. In Xcode, select DiveCheck's `Info.plist` (or the target's **Info**
   tab if it's using the generated-Info.plist build setting -- either
   way, add a **URL Types** entry).
2. Add a new URL Type with:
   - **URL Schemes**: the reversed Client ID from above
   - **Identifier**: anything, e.g. `google-signin`

## 6. Build and test

Build and run. In DiveCheck, go to **Settings > Backup & Sync**, switch
the provider to **Google Drive** -- you should now see a working
"Sign in with Google" button instead of the "not set up yet" message.
Sign in, and DiveCheck will create a "DiveCheck" folder in your Google
Drive and start backing up to it (checklists, equipment, dive log,
certifications including uploaded photos/PDFs, EAPs, Diver Medical ID, and
training records -- see AppStoreSnapshot.swift for the exact list).

### If something doesn't work

- **Sign-in button does nothing / crashes**: double check the URL scheme
  in step 5 exactly matches your reversed Client ID, character for
  character.
- **"redirect_uri_mismatch" or similar during sign-in**: the Bundle ID
  entered in step 1.6 doesn't match DiveCheck's actual bundle identifier --
  fix it on the OAuth client in Google Cloud Console (Credentials > your
  iOS client > edit).
- **Sign-in works but syncing fails with a network/permission error**:
  confirm the Google Drive API is enabled (step 1.3) and that the Google
  account you signed in with is listed as a test user (step 1.5) if the
  OAuth consent screen is still in Testing mode.
- Paste any Xcode build error or in-app error message back and it can be
  debugged from there -- the sync code itself (GoogleDriveBackend.swift)
  shouldn't need changes for any of the above; it's almost always a
  credentials/configuration mismatch.
