const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");

const testRoot = fs.mkdtempSync(path.join(os.tmpdir(), "civicpulse-lan-"));
process.env.NODE_ENV = "test";
process.env.SQLITE_DB_PATH = path.join(testRoot, "test.db");
process.env.UPLOAD_DIR = path.join(testRoot, "uploads");
delete process.env.GEMINI_API_KEY;

const app = require("./server");
const db = require("./config/db");

const onePixelPng =
  "data:image/png;base64," +
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl8pZ8AAAAASUVORK5CYII=";

async function run() {
  const server = app.listen(0, "127.0.0.1");
  await new Promise((resolve, reject) => {
    server.once("listening", resolve);
    server.once("error", reject);
  });

  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    const healthResponse = await fetch(`${baseUrl}/`);
    const health = await healthResponse.json();
    assert.equal(health.status, "online");

    const createResponse = await fetch(`${baseUrl}/complaints`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        title: "Integration test pothole",
        description: "A large pothole is blocking the road",
        userId: "user_citizen",
        location: { lat: 8.2, lng: 77.3, address: "Integration test" },
        photoData: onePixelPng
      })
    });
    assert.equal(createResponse.status, 201);
    const created = await createResponse.json();
    assert.equal(created.userId, "user_citizen");
    assert.match(created.photoUrl, new RegExp(`^${baseUrl}/uploads/`));

    const imageResponse = await fetch(created.photoUrl);
    assert.equal(imageResponse.status, 200);
    assert.match(imageResponse.headers.get("content-type") || "", /^image\/png/);

    const listResponse = await fetch(`${baseUrl}/complaints`);
    const complaints = await listResponse.json();
    assert.equal(complaints.length, 1);
    assert.equal(complaints[0].id, created.id);
    assert.equal(complaints[0].photoUrl, created.photoUrl);

    console.log("LAN integration test passed:", {
      complaintId: created.id,
      userId: created.userId,
      photoUrl: created.photoUrl,
      imageStatus: imageResponse.status
    });
  } finally {
    await new Promise(resolve => server.close(resolve));
    await db.close();
    fs.rmSync(testRoot, { recursive: true, force: true });
  }
}

run().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
