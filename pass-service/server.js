import express from "express";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { PKPass } from "passkit-generator";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PORT = process.env.PORT || 3000;
const PASS_TYPE_IDENTIFIER = process.env.PASS_TYPE_IDENTIFIER;
const TEAM_IDENTIFIER = process.env.TEAM_IDENTIFIER;
const SHARED_SECRET = process.env.SHARED_SECRET;

// Certificates are supplied base64-encoded via env vars so nothing sensitive
// ever needs to live in the repo -- see README.md for how to produce these
// from the .p12 Apple hands you after you create a Pass Type ID certificate.
const WWDR_CERT = process.env.WWDR_CERT_BASE64
  ? Buffer.from(process.env.WWDR_CERT_BASE64, "base64")
  : undefined;
const SIGNER_CERT = process.env.SIGNER_CERT_BASE64
  ? Buffer.from(process.env.SIGNER_CERT_BASE64, "base64")
  : undefined;
const SIGNER_KEY = process.env.SIGNER_KEY_BASE64
  ? Buffer.from(process.env.SIGNER_KEY_BASE64, "base64")
  : undefined;
const SIGNER_KEY_PASSPHRASE = process.env.SIGNER_KEY_PASSPHRASE;

const MODEL_PATH = path.join(__dirname, "models", "certification.pass");
const PASS_JSON_PATH = path.join(MODEL_PATH, "pass.json");

// Patches the on-disk pass.json template with the real Pass Type ID / Team
// ID from env vars once at boot, so the deployed service is fully
// self-configuring from Render's dashboard -- no code change or redeploy
// needed once you have your real identifiers, and the per-request override
// below sets them again anyway as a second line of defense.
function patchTemplateIdentifiers() {
  try {
    const passJson = JSON.parse(fs.readFileSync(PASS_JSON_PATH, "utf8"));
    if (PASS_TYPE_IDENTIFIER) passJson.passTypeIdentifier = PASS_TYPE_IDENTIFIER;
    if (TEAM_IDENTIFIER) passJson.teamIdentifier = TEAM_IDENTIFIER;
    fs.writeFileSync(PASS_JSON_PATH, JSON.stringify(passJson, null, 2));
  } catch (err) {
    console.error("Failed to patch pass.json template with env identifiers:", err.message);
  }
}
patchTemplateIdentifiers();

const app = express();
app.use(express.json({ limit: "1mb" }));

app.get("/health", (req, res) => {
  res.json({
    ok: true,
    configured: Boolean(WWDR_CERT && SIGNER_CERT && SIGNER_KEY && PASS_TYPE_IDENTIFIER && TEAM_IDENTIFIER),
  });
});

/// Formats an ISO date string the way Apple Wallet fields read best:
/// "Jan 3, 2027" rather than a raw timestamp. Returns null for missing or
/// unparseable input so callers can skip the field entirely.
function formatDate(iso) {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  return d.toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" });
}

app.post("/sign-certification", async (req, res) => {
  try {
    if (SHARED_SECRET) {
      const provided = req.get("x-divecheck-secret");
      if (provided !== SHARED_SECRET) {
        return res.status(401).json({ error: "unauthorized" });
      }
    }

    if (!WWDR_CERT || !SIGNER_CERT || !SIGNER_KEY) {
      return res.status(500).json({ error: "signing certificates are not configured on the server" });
    }
    if (!PASS_TYPE_IDENTIFIER || !TEAM_IDENTIFIER) {
      return res.status(500).json({ error: "PASS_TYPE_IDENTIFIER / TEAM_IDENTIFIER are not configured on the server" });
    }

    const {
      id,
      courseName,
      agency,
      certificationNumber,
      instructorOrFacility,
      dateCertified,
      expirationDate,
      notes,
    } = req.body || {};

    if (!courseName || !String(courseName).trim()) {
      return res.status(400).json({ error: "courseName is required" });
    }

    const primaryFields = [{ key: "course", label: "CERTIFICATION", value: courseName }];

    const secondaryFields = [];
    if (agency) secondaryFields.push({ key: "agency", label: "AGENCY", value: agency });
    if (certificationNumber) secondaryFields.push({ key: "certNumber", label: "CERT #", value: certificationNumber });

    const auxiliaryFields = [];
    const certifiedDisplay = formatDate(dateCertified);
    if (certifiedDisplay) auxiliaryFields.push({ key: "dateCertified", label: "CERTIFIED", value: certifiedDisplay });
    auxiliaryFields.push({
      key: "expiration",
      label: "EXPIRES",
      value: formatDate(expirationDate) || "No Expiration",
    });

    const backFields = [];
    if (instructorOrFacility) {
      backFields.push({ key: "instructor", label: "Instructor / Facility", value: instructorOrFacility });
    }
    if (notes) backFields.push({ key: "notes", label: "Notes", value: notes });
    backFields.push({ key: "issuedBy", label: "Issued By", value: "DiveCheck" });

    const overrides = {
      passTypeIdentifier: PASS_TYPE_IDENTIFIER,
      teamIdentifier: TEAM_IDENTIFIER,
      serialNumber: id || `divecheck-${Date.now()}`,
      description: `${courseName} certification`,
      generic: {
        primaryFields,
        secondaryFields,
        auxiliaryFields,
        backFields,
      },
    };

    const expirationDateParsed = expirationDate ? new Date(expirationDate) : null;
    if (expirationDateParsed && !Number.isNaN(expirationDateParsed.getTime())) {
      overrides.expirationDate = expirationDateParsed.toISOString();
    }

    const pass = await PKPass.from(
      {
        model: MODEL_PATH,
        certificates: {
          wwdr: WWDR_CERT,
          signerCert: SIGNER_CERT,
          signerKey: SIGNER_KEY,
          signerKeyPassphrase: SIGNER_KEY_PASSPHRASE,
        },
      },
      overrides
    );

    const buffer = pass.getAsBuffer();
    const safeName = String(courseName || "certification").replace(/[^a-z0-9]+/gi, "-");
    res.set("Content-Type", "application/vnd.apple.pkpass");
    res.set("Content-Disposition", `attachment; filename="${safeName}.pkpass"`);
    res.send(buffer);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message || "failed to sign pass" });
  }
});

app.listen(PORT, () => {
  console.log(`DiveCheck pass-signing service listening on :${PORT}`);
});
