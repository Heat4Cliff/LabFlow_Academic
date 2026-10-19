# LabFlow

> **Laboratory Asset & Service Management System** untuk pengelolaan laboratorium kampus berbasis Flutter dan Firebase.

LabFlow adalah aplikasi mobile yang dirancang untuk membantu pengelolaan aktivitas laboratorium secara terpusat, mulai dari autentikasi berbasis role, manajemen pengguna dan laboratorium, membership Lab Admin, activity log, hingga fondasi untuk peminjaman aset, laporan insiden, maintenance, dan notifikasi.

Project ini dikembangkan sebagai aplikasi akademik dengan fokus pada arsitektur yang rapi, role-based access, keamanan Firebase, reusable UI state, dan kemudahan pengujian.

---

## Fitur Saat Ini

### Authentication & Authorization
- Login menggunakan **Firebase Authentication**.
- Profile pengguna disimpan pada **Cloud Firestore**.
- Role yang didukung:
  - `student`
  - `lab_admin`
  - `superadmin`
- Validasi status akun `active` / `suspended`.
- Protected route menggunakan account status gate.
- Role guard untuk seluruh area Superadmin.
- Auto sign-out untuk akun suspended.

### Superadmin
- Dashboard ringkasan sistem.
- Manajemen pengguna.
- Tambah dan edit pengguna.
- Suspend / aktifkan kembali akun.
- Manajemen laboratorium.
- Tambah, edit, aktif/nonaktif, dan hapus laboratorium dengan safe-delete rule.
- Lab Membership untuk assignment Lab Admin ke laboratorium.
- Activity Log.
- Profile Superadmin.
- Logout dengan confirmation dialog.

### Student & Lab Admin
- Login dan validasi role.
- Dashboard dasar berdasarkan role.
- Penanganan akun suspended.
- Penanganan access denied.

> Fitur operasional Student dan Lab Admin masih dikembangkan secara bertahap.

### Shared UI System
LabFlow menggunakan komponen reusable agar feedback aplikasi konsisten:

- Confirmation Dialog
- Floating Notification
- Loading State
- Connection Error State
- No Search Results State
- Suspended Account State
- Access Denied State

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter |
| Language | Dart |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Navigation | GoRouter |
| State / App Foundation | Riverpod |
| Android Target | Android API 36 |
| Testing | Flutter Test |

---

## Project Structure

```text
lib/
├── app/
│   ├── router/
│   └── theme/
├── core/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── lab_admin/
│   ├── laboratory/
│   ├── onboarding/
│   ├── splash/
│   ├── student/
│   └── superadmin/
├── shared/
│   └── presentation/
│       ├── dialogs/
│       ├── notifications/
│       └── states/
├── firebase_options.dart
└── main.dart
```

Project menggunakan pendekatan **feature-first structure**, sehingga domain, data, dan presentation dipisahkan berdasarkan fitur.

---

## Role Flow

```text
Login
  ↓
Firebase Authentication
  ↓
Get User Profile from Firestore
  ↓
Check Account Status
  ├── Suspended → Sign Out → Suspended Account State
  └── Active
        ↓
      Check Role
        ├── Student → Student Area
        ├── Lab Admin → Lab Admin Area
        └── Superadmin → Superadmin Area
```

Area Superadmin juga dilindungi oleh `LabFlowAccountStatusGate` sehingga halaman protected hanya dapat dirender ketika session, status akun, dan role telah tervalidasi.

---

## Menjalankan Project

### Prasyarat

Pastikan sudah terpasang:

- Flutter SDK
- Dart SDK
- Android SDK
- Android Emulator atau perangkat Android fisik
- Firebase project yang sudah dikonfigurasi untuk aplikasi

Cek environment:

```bash
flutter doctor
```

Install dependency:

```bash
flutter pub get
```

Jalankan aplikasi:

```bash
flutter run
```

Atau pilih emulator tertentu:

```bash
flutter run -d emulator-5554
```

---

## Menjalankan Android Emulator Tanpa Android Studio

Lihat daftar emulator:

```bash
flutter emulators
```

Jalankan emulator:

```bash
flutter emulators --launch <emulator-id>
```

Setelah emulator aktif:

```bash
flutter devices
flutter run -d emulator-5554
```

Dengan workflow ini, Android Studio tidak perlu dibuka hanya untuk menjalankan emulator.

---

## Firebase

LabFlow menggunakan Firebase Authentication dan Cloud Firestore.

Hal yang perlu diperhatikan:

- Jangan menyimpan service-account key atau credential sensitif di repository publik.
- Firestore Rules harus tetap menjadi lapisan proteksi utama di sisi backend.
- UI role guard bukan pengganti security rules.
- Akun suspended divalidasi melalui profile Firestore sebelum protected page diberikan.

Contoh dokumen pengguna:

```json
{
  "uid": "firebase-user-uid",
  "fullName": "Nama Pengguna",
  "email": "user@example.com",
  "role": "student",
  "status": "active"
}
```

---

## Testing

Format source:

```bash
dart format lib
```

Static analysis:

```bash
flutter analyze
```

Unit / widget test:

```bash
flutter test
```

Baseline saat ini:

```text
flutter analyze → No issues found
flutter test    → All tests passed
```

Manual UAT juga dilakukan untuk beberapa flow penting seperti:

- Superadmin Profile dan bottom navigation.
- Logout confirmation.
- No Search Results.
- Loading State.
- Offline action handling.
- Suspended Account.
- Access Denied / role guard.

---

## Status Pengembangan

### Sudah tersedia
- Authentication dan role routing
- User Management
- Laboratory Management
- Lab Membership
- Activity Log
- Shared UI states & dialogs
- Superadmin Profile
- Suspended account handling
- Role-based protected routes

### Dalam pengembangan
- Student operational flow
- Lab Admin operational flow
- Asset inventory
- Borrowing workflow
- Incident / damage reporting
- Maintenance workflow
- Notifications
- QR-based asset interaction

---

## Design Language

LabFlow menggunakan visual yang sederhana dan konsisten:

- Lime accent: `#B9F33D`
- Dark surface: `#111111`
- Background: `#F6F9EF`
- Soft lime: `#EAFBCB`
- Muted text: `#6B7280`
- Danger: `#BD3232`
- Rounded cards, pills, dan floating bottom navigation

---

## Security Notes

Repository publik tidak boleh berisi:

- Firebase Admin service account JSON
- Private API keys dari layanan backend sensitif
- Password akun test / production
- Credential UAT
- File environment yang berisi secret

Sebelum push, selalu cek perubahan:

```bash
git status
git diff
```

---

## Roadmap

```text
Authentication & Role Foundation      ✅
Superadmin Core Management            ✅
Shared States & Dialogs               ✅
Superadmin Profile                    ✅
Student Operational Features          🚧
Lab Admin Operational Features        🚧
Asset & Borrowing Workflow            🚧
Reports & Maintenance                 🚧
Notifications & QR Integration        🚧
Final UAT & Release Hardening         🚧
```

---

## Author

**Mohammad Alwan Abbas Abdillah**
Informatika — Universitas Nahdlatul Ulama Al-Ghazali (UNUGHA) Cilacap

---
