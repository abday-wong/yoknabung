# YokNabung 💰

**YokNabung** adalah aplikasi pencatatan dan pelacakan target tabungan (*savings tracker*) berbasis *local-first* yang dibangun menggunakan Flutter. Aplikasi ini dirancang dengan gaya desain **Neo-Brutalist** yang khas: warna kontras tinggi, garis luar tebal (*thick borders*), bayangan tajam (*hard shadows*), sudut siku tanpa pembulatan (*no border radius*), dan tipografi *bold*.

Aplikasi ini menggunakan **Provider** untuk manajemen status (*state management*), **SharedPreferences** untuk penyimpanan data lokal secara instan, serta terintegrasi penuh dengan lokalisasi bahasa dan format mata uang **Rupiah (Rp)** Indonesia.

---

## 📱 Download Aplikasi (Android)

Kamu dapat mengunduh aplikasi **YokNabung** langsung ke HP Android kamu melalui halaman **Releases** di GitHub ini:

👉 **[Unduh YokNabung APK Terbaru](https://github.com/abday-wong/yoknabung/releases)**

### Cara Instalasi di Handphone:
1. Buka link di atas dari HP kamu, lalu unduh file berkode **`app-release.apk`** di bagian bawah versi rilis terbaru.
2. Setelah unduhan selesai, ketuk file APK tersebut untuk memulai proses instalasi.
3. Jika HP kamu menampilkan peringatan keamanan tentang instalasi dari sumber tidak dikenal (*Install Unknown Apps*), berikan izin (*Allow/Izinkan*) pada browser atau file manager kamu untuk melanjutkan.
4. Aplikasi akan terinstal, dan kamu bisa langsung mulai membuat target tabunganmu!

---

## 🎨 Karakteristik Desain (Neo-Brutalisme)
Semua komponen antarmuka didesain mengikuti panduan visual Neo-Brutalist yang ketat:
*   **Warna Latar**: Warm Cream (`#FFFDE7`).
*   **Warna Aksen**: Kuning (`#FFE500`), Hijau Toska (`#00C49A`), Biru (`#4361EE`), dan Jingga-Merah (`#FF5733`).
*   **Garis Batas (Borders)**: Tebal hitam solid (`#111111`, ketebalan `2.5px`).
*   **Efek Sudut**: Sudut tegak lurus sempurna tanpa pembulatan (`BorderRadius.zero`).
*   **Efek Bayangan (Hard Shadows)**: Menggunakan bayangan solid offset hitam tanpa blur (`BoxShadow(color: Color(0xFF111111), offset: Offset(X, Y), blurRadius: 0)`).
*   **Umpan Balik Taktil**: Tombol interaktif bergeser secara fisik ke arah bayangan saat ditekan untuk mensimulasikan penekanan nyata.

---

## 🚀 Fitur Utama
1.  **Dasbor Ringkasan Real-Time**:
    *   Widget jam digital real-time dengan pembaruan detik (*timer-periodic*) beserta nama hari dan tanggal dalam format Bahasa Indonesia.
    *   Panel ringkasan akumulasi: Total target aktif, jumlah dana terkumpul, dan sisa target tabungan keseluruhan.
2.  **Pembuatan & Pengeditan Goal Tabungan**:
    *   Pembuat Emoji bawaan untuk memberikan simbol unik pada setiap goal.
    *   Selektor kategori cepat (Liburan, Gadget, Dana Darurat, Pendidikan, Kendaraan, Properti, Lainnya).
    *   Validasi form yang ketat (Target nominal > 0, tanggal selesai harus setelah tanggal mulai).
3.  **Kalkulator & Proyeksi Finansial Otomatis**:
    *   Melacak sisa hari menuju target secara real-time.
    *   Menghitung otomatis nominal harian dan bulanan yang harus disisihkan berdasarkan sisa durasi.
    *   Menampilkan status kelayakan target serta pesan motivasi dinamis berbahasa Indonesia yang berubah sesuai tingkat progres tabungan.
4.  **Milestones Roadmap**:
    *   Memecah target tabungan menjadi 4 milestone pencapaian (25%, 50%, 75%, 100%).
    *   Menandai pencapaian secara otomatis beserta proyeksi tanggal ketercapaian berdasarkan rata-rata setoran historis pengguna.
5.  **Pencatatan Transaksi Interaktif**:
    *   Mendukung deposit (setoran masuk) dan penarikan (dana keluar).
    *   Tautan tombol nominal cepat (`+100rb`, `+500rb`, `+1jt`, `+5jt`) untuk pengisian angka instan.
    *   Pengisian nominal dengan format pemisah ribuan otomatis (*thousands separator*).
    *   Validasi penarikan dana agar tidak melebih saldo yang tersedia.
    *   Fitur geser untuk menghapus (*swipe-to-delete*) riwayat transaksi lengkap dengan opsi pemulihan instan (*Undo Snackbar*).
6.  **Visualisasi Data (Grafik)**:
    *   **Grafik Batang (Bar Chart)**: Menunjukkan rincian total setoran bulanan pengguna secara historis.
    *   **Grafik Garis (Line Chart)**: Menampilkan tren pertumbuhan dana secara kumulatif dibandingkan dengan batas garis putus-putus target tabungan.

---

## 🛠️ Arsitektur & Teknologi
Aplikasi ini menerapkan pemisahan lapisan (layer) yang bersih untuk menjaga keterbacaan kode:

```
lib/
├── models/
│   ├── transaction.dart         # Model transaksi (deposit/withdrawal)
│   ├── milestone.dart           # Model pencapaian persentase goal
│   └── saving_goal.dart         # Model utama target tabungan
├── providers/
│   └── savings_provider.dart    # Logika bisnis, kalkulasi & local persistence
├── widgets/
│   ├── neo_card.dart            # Kontainer dasar Neo-Brutalist
│   ├── neo_button.dart          # Tombol interaktif taktil
│   ├── neo_dialog.dart          # Dialog konfirmasi, BottomSheet & Snackbar
│   ├── progress_bar_widget.dart # Progress bar flat tebal
│   ├── roadmap_widget.dart      # Garis waktu milestone vertikal
│   ├── realtime_clock_widget.dart # Tampilan jam sistem live
│   └── savings_calculator_widget.dart # Kalkulator alokasi harian/bulanan
├── screens/
│   ├── home_screen.dart         # Halaman utama daftar goal & ringkasan
│   ├── add_edit_goal_screen.dart # Form input target tabungan & kalkulasi live
│   ├── goal_detail_screen.dart  # Detil goal, daftar transaksi & visualisasi grafik
│   └── add_edit_transaction_screen.dart # Form setoran & penarikan dana
└── main.dart                    # Inisialisasi program & lokalisasi
```

---

## 📦 Dependensi Pubspec
Berikut adalah daftar library utama yang digunakan pada `pubspec.yaml`:
*   `provider`: State management terpusat.
*   `shared_preferences`: Penyimpanan data lokal (*local key-value persistence*).
*   `google_fonts`: Pemuatan font sans-serif tebal *Space Grotesk*.
*   `fl_chart`: Menggambar grafik batang dan garis kustom.
*   `intl`: Pemformatan mata uang Rupiah dan tanggal hari Indonesia.
*   `uuid`: Pembuatan pengenal ID transaksi dan goal yang unik.
*   `flutter_localizations`: Penyesuaian bahasa dasar sistem kalender dan kalender pemilih.

---

## 🏁 Cara Menjalankan Project

### Prasyarat
Pastikan komputer Anda telah terpasang **Flutter SDK** versi terbaru.

1.  **Clone Repository**
    ```bash
    git clone https://github.com/abday-wong/yoknabung.git
    cd yoknabung
    ```

2.  **Ambil Dependensi**
    ```bash
    flutter pub get
    ```

3.  **Jalankan Pengujian Unit & Widget**
    ```bash
    flutter test
    ```

4.  **Jalankan Aplikasi**
    *   Menjalankan di perangkat emulator / fisik Android/iOS:
        ```bash
        flutter run
        ```
    *   Menjalankan di Web Browser (Chrome/Edge):
        ```bash
        flutter run -d chrome
        ```
    *   Menjalankan di Desktop Windows:
        ```bash
        flutter run -d windows
        ```
