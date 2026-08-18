# DiveCheck Pass Signing Service

DiveCheck's "Add to Apple Wallet" button (on a Certification) needs a signed
`.pkpass` file, and iOS has no public API for the PKCS#7/CMS signature that
requires -- Apple's own guidance is to sign passes on a backend, not
on-device. This is that backend: a small Express service using
[passkit-generator](https://github.com/alexandercerutti/passkit-generator)
that takes certification data over HTTP and returns a signed `.pkpass`.

It holds no certification data of its own -- every request is stateless. The
only secrets it needs are your Apple Pass Type ID certificate/key and (if you
set one) a shared secret so random people on the internet can't use your
signing service to mint passes.

## 1. Get a Pass Type ID + certificate from Apple

You need a paid Apple Developer Program membership for this (Pass Type ID
certificates aren't available on the free tier).

1. Go to [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers/list)
   → **Identifiers** → **+** → **Pass Type IDs** → register a new one, e.g.
   `pass.com.krakendiveworks.divecheck.certification`. Note your **Team ID**
   too (top right of the Membership page, or Account → Membership).
2. Open **Keychain Access** on your Mac → menu **Keychain Access** →
   **Certificate Assistant** → **Request a Certificate From a Certificate
   Authority** → fill in your email, leave "saved to disk" checked, save the
   `.certSigningRequest` file.
3. Back on developer.apple.com → **Certificates** → **+** → under Services,
   choose **Pass Type ID Certificate** → select the Pass Type ID you just
   created → upload the `.certSigningRequest` file → download the resulting
   `.cer` file.
4. Double-click the downloaded `.cer` to install it into Keychain Access. In
   Keychain Access, find it under **My Certificates** (it'll be paired with
   the private key from step 2), right-click → **Export** → save as
   `Certificates.p12`, set a password when prompted (remember it -- you'll
   need it below).
5. Download Apple's WWDR (Worldwide Developer Relations) intermediate
   certificate from [Apple's PKI page](https://www.apple.com/certificateauthority/)
   -- get the current "Worldwide Developer Relations - G4" (or whatever the
   current one is named) `.cer` file.

## 2. Convert the certificates to what the service expects

Run these in Terminal on your Mac, in the folder where you saved the files
from step 1 (replace `YOUR_P12_PASSWORD` with the password you set):

```bash
# WWDR intermediate cert: DER -> PEM
openssl x509 -inform der -in AppleWWDRCAG4.cer -out wwdr.pem

# Your signer certificate (public half) out of the .p12
openssl pkcs12 -in Certificates.p12 -clcerts -nokeys -legacy \
  -out signerCert.pem -passin pass:YOUR_P12_PASSWORD

# Your signer private key out of the .p12 -- this sets a NEW passphrase
# (used as SIGNER_KEY_PASSPHRASE below) to protect the exported key file
openssl pkcs12 -in Certificates.p12 -nocerts -legacy \
  -out signerKey.pem -passin pass:YOUR_P12_PASSWORD -passout pass:YOUR_NEW_KEY_PASSPHRASE
```

(Drop `-legacy` if your `openssl` version doesn't recognize the flag --
that's only needed on newer OpenSSL builds against older-style .p12 files.)

Then base64-encode each PEM so it can be pasted into a single-line env var:

```bash
base64 -i wwdr.pem | pbcopy        # paste into WWDR_CERT_BASE64
base64 -i signerCert.pem | pbcopy  # paste into SIGNER_CERT_BASE64
base64 -i signerKey.pem | pbcopy   # paste into SIGNER_KEY_BASE64
```

(`pbcopy` puts it straight on your clipboard -- paste directly into Render's
env var value field, no intermediate file needed.)

## 3. Deploy to Render (free tier)

1. Push this repo to GitHub (already done if you're reading this from the
   `divecheck` repo).
2. On [render.com](https://render.com), **New** → **Web Service** → connect
   the `divecheck` GitHub repo.
3. Set **Root Directory** to `pass-service`.
4. Build command: `npm install`. Start command: `npm start`. Plan: **Free**.
5. Under **Environment**, add:
   - `PASS_TYPE_IDENTIFIER` -- the Pass Type ID string from step 1.1 (e.g.
     `pass.com.krakendiveworks.divecheck.certification`)
   - `TEAM_IDENTIFIER` -- your 10-character Team ID from step 1.1
   - `WWDR_CERT_BASE64`, `SIGNER_CERT_BASE64`, `SIGNER_KEY_BASE64` -- the
     base64 strings from step 2
   - `SIGNER_KEY_PASSPHRASE` -- the `YOUR_NEW_KEY_PASSPHRASE` you chose above
   - `SHARED_SECRET` -- any random string you make up; the app sends this
     back on every request so only DiveCheck can use your signing service
6. Deploy. Once it's live, `GET https://<your-service>.onrender.com/health`
   should return `{"ok":true,"configured":true}`. If `configured` is
   `false`, double check every env var above is set.

Render's free tier spins the service down after inactivity, so the first
request after a while takes 20-50 seconds to wake up -- fine for an
occasional "add to Wallet" tap, not something to build a time-critical flow
on.

## API

`POST /sign-certification`

Headers: `Content-Type: application/json`, and `X-DiveCheck-Secret: <SHARED_SECRET>`
if you set one.

Body:

```json
{
  "id": "the certification's UUID, used as the pass serial number",
  "courseName": "Advanced Open Water Diver",
  "agency": "PADI",
  "certificationNumber": "12345678",
  "instructorOrFacility": "Ocean Dive Center",
  "dateCertified": "2024-06-01T00:00:00Z",
  "expirationDate": null,
  "notes": "Deep specialty included"
}
```

Only `courseName` is required. Response is the raw `.pkpass` binary
(`application/vnd.apple.pkpass`) on success, or a JSON `{"error": "..."}`
with a 4xx/5xx status on failure.
