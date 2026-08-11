const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const UPLOAD_DIR = path.resolve(
  process.env.UPLOAD_DIR || path.join(__dirname, "..", "uploads")
);
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;

const MIME_TYPES = {
  "image/jpeg": {
    extension: "jpg",
    isValid: buffer =>
      buffer.length >= 3 &&
      buffer[0] === 0xff &&
      buffer[1] === 0xd8 &&
      buffer[2] === 0xff
  },
  "image/png": {
    extension: "png",
    isValid: buffer =>
      buffer.length >= 8 &&
      buffer.subarray(0, 8).equals(
        Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
      )
  },
  "image/webp": {
    extension: "webp",
    isValid: buffer =>
      buffer.length >= 12 &&
      buffer.subarray(0, 4).toString("ascii") === "RIFF" &&
      buffer.subarray(8, 12).toString("ascii") === "WEBP"
  }
};

class ImageStorageError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.name = "ImageStorageError";
    this.statusCode = statusCode;
  }
}

function ensureUploadDirectory() {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  return UPLOAD_DIR;
}

function parseImageDataUri(imageData) {
  if (typeof imageData !== "string") {
    throw new ImageStorageError("photoData must be a base64 image data URI");
  }

  const match = imageData.match(/^data:(image\/[a-zA-Z0-9.+-]+);base64,([a-zA-Z0-9+/=\r\n]+)$/);
  if (!match) {
    throw new ImageStorageError(
      "photoData must use data:image/jpeg, data:image/png, or data:image/webp"
    );
  }

  const mimeType = match[1].toLowerCase();
  const type = MIME_TYPES[mimeType];
  if (!type) {
    throw new ImageStorageError("Only JPEG, PNG, and WebP images are supported");
  }

  const buffer = Buffer.from(match[2].replace(/\s/g, ""), "base64");
  if (buffer.length === 0) {
    throw new ImageStorageError("Uploaded image is empty");
  }
  if (buffer.length > MAX_IMAGE_BYTES) {
    throw new ImageStorageError("Uploaded image exceeds the 8 MB limit", 413);
  }
  if (!type.isValid(buffer)) {
    throw new ImageStorageError("Uploaded file contents do not match its image type");
  }

  return { buffer, extension: type.extension };
}

async function saveImageData(imageData, complaintId, label = "complaint") {
  const { buffer, extension } = parseImageDataUri(imageData);
  ensureUploadDirectory();

  const safeComplaintId = String(complaintId || "complaint")
    .replace(/[^a-zA-Z0-9_-]/g, "-")
    .slice(0, 80);
  const safeLabel = String(label)
    .replace(/[^a-zA-Z0-9_-]/g, "-")
    .slice(0, 30);
  const suffix = crypto.randomBytes(6).toString("hex");
  const fileName = `${safeComplaintId}-${safeLabel}-${Date.now()}-${suffix}.${extension}`;

  await fs.promises.writeFile(path.join(UPLOAD_DIR, fileName), buffer, { flag: "wx" });
  return `/uploads/${encodeURIComponent(fileName)}`;
}

function toPublicMediaUrl(req, value) {
  if (typeof value !== "string" || !value.startsWith("/uploads/")) {
    return value || "";
  }

  return `${req.protocol}://${req.get("host")}${value}`;
}

function toAnalysisImageInput(value) {
  if (typeof value !== "string" || !value.startsWith("/uploads/")) {
    return value || "";
  }

  const fileName = path.basename(decodeURIComponent(value.slice("/uploads/".length)));
  return path.join(UPLOAD_DIR, fileName);
}

function toPublicComplaint(req, complaint) {
  if (!complaint) return complaint;

  const result = {
    ...complaint,
    photoUrl: toPublicMediaUrl(req, complaint.photoUrl)
  };

  if (complaint.resolution && typeof complaint.resolution === "object") {
    result.resolution = {
      ...complaint.resolution,
      photoUrl: toPublicMediaUrl(req, complaint.resolution.photoUrl)
    };
  }

  return result;
}

module.exports = {
  ImageStorageError,
  MAX_IMAGE_BYTES,
  UPLOAD_DIR,
  ensureUploadDirectory,
  saveImageData,
  toAnalysisImageInput,
  toPublicComplaint,
  toPublicMediaUrl
};
