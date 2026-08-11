# CivicPulse laptop server + phone setup

The laptop stores complaint records in `backend/civicpulse.db` and uploaded
photos in `backend/uploads/`. Phones use the laptop's API; they do not open the
SQLite file directly.

## 1. Configure and start the laptop server

From PowerShell:

```powershell
cd C:\Users\Asus\Downloads\CMS\CivicPulse\backend
Copy-Item .env.example .env
```

Open `backend/.env` and replace the placeholder with a newly generated Gemini
API key. Keep `HOST=0.0.0.0` so other devices can connect. Then run:

```powershell
npm install
npm start
```

The startup output lists the available phone/LAN URLs. Use the address for the
active Wi-Fi adapter. On this laptop at the time of setup it is:

```text
http://10.206.32.193:3000
```

The address can change after reconnecting to Wi-Fi. Run `ipconfig` and use the
`IPv4 Address` under `Wireless LAN adapter WiFi` when needed.

## 2. Check the connection from a phone

Connect the phone and laptop to the same Wi-Fi, then open this in the phone's
browser (replace the address if the laptop IP changed):

```text
http://10.206.32.193:3000/
```

You should see JSON with `status: online`. If it does not open, allow Node.js
through Windows Defender Firewall on **Private networks** and verify that the
Wi-Fi does not have client/AP isolation enabled.

## 3. Run or build the Flutter app for a physical phone

From the `mobile` directory:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.206.32.193:3000
```

Use the same `--dart-define` when building an APK:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://10.206.32.193:3000
```

Each submitted photo is encoded by the phone, saved on the laptop, and returned
as an `/uploads/...` URL. Citizen and admin dashboards refresh from SQLite on
entry, on pull-to-refresh, and every 12 seconds.

## 4. Backups and security

Back up both `backend/civicpulse.db` and `backend/uploads/`; the database alone
does not contain the image bytes. This project currently uses demo credentials
and plain HTTP, so keep it on a trusted LAN. Do not expose port 3000 directly to
the public internet without real authentication and HTTPS.
