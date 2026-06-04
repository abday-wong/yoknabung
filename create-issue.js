import http from 'https';

const token = process.argv[2];
if (!token) {
  console.error('❌ Error: Please provide your GitHub Personal Access Token (PAT) as an argument.');
  console.log('Usage: node create-issue.js YOUR_GITHUB_TOKEN');
  process.exit(1);
}

const data = JSON.stringify({
  title: '[Feature] Integrasi SQLite untuk Riwayat Transaksi & Fitur Ekspor-Impor Data (Backup & Restore)',
  body: `## Deskripsi Masalah / Latar Belakang
Saat ini, aplikasi **YokNabung** mengelola penyimpanan data lokal menggunakan \`shared_preferences\`. Metode ini kurang ideal untuk menyimpan data transaksional seperti **riwayat transaksi** yang akan terus bertambah seiring waktu. 

Menyimpan list data transaksi dengan cara merubahnya menjadi JSON string di \`shared_preferences\` dapat menyebabkan:
1. **Penurunan Performa (Lags):** Aplikasi harus menulis ulang seluruh file JSON setiap kali ada transaksi baru.
2. **Resiko Data Loss:** Jika aplikasi di-uninstall atau dihapus datanya oleh sistem, seluruh data tabungan dan riwayat transaksi pengguna akan hilang secara permanen.

Oleh karena itu, diperlukan migrasi penyimpanan riwayat transaksi ke database relasional lokal (**SQLite**) serta penambahan fitur **Ekspor/Impor data (Backup & Restore)** agar pengguna dapat mengamankan data mereka.

---

## Rencana Implementasi

### 🛠️ Bagian 1: Migrasi Riwayat Transaksi ke SQLite (\`sqflite\`)
1. **Tambahkan Dependensi:** Integrasikan package \`sqflite\` dan \`path\` ke dalam \`pubspec.yaml\`.
2. **Buat Database Helper:** 
   * Buat kelas \`DatabaseHelper\` untuk menginisialisasi database dan mengelola versi database.
   * Definisikan tabel \`transactions\` dengan kolom: \`id\` (TEXT PRIMARY KEY), \`amount\` (REAL), \`type\` (TEXT - masuk/keluar), \`category\` (TEXT), \`date\` (TEXT - ISO8601), dan \`description\` (TEXT).
3. **Refaktor State Management:**
   * Modifikasi kelas \`SavingsProvider\` agar membaca dan menulis riwayat transaksi langsung dari database SQLite daripada menggunakan \`shared_preferences\`.

### 📂 Bagian 2: Fitur Backup & Restore (Ekspor-Impor File JSON)
1. **Ekspor Data (Backup):**
   * Buat fungsi untuk mengumpulkan data profil pengguna dari \`shared_preferences\` dan daftar transaksi dari SQLite.
   * Ekspor data tersebut menjadi format file \`.json\` terstruktur.
   * Gunakan package sharing (seperti \`share_plus\` atau \`file_picker\`) agar pengguna bisa menyimpan file tersebut ke Google Drive atau folder lokal mereka.
2. **Impor Data (Restore):**
   * Sediakan pemilih file agar pengguna bisa mengunggah file \`.json\` backup lama mereka.
   * Validasi struktur JSON untuk memastikan file tidak rusak atau diubah secara tidak sah.
   * Hapus database lama dan timpa dengan data transaksi baru hasil impor dari file JSON tersebut.

---

## Hasil yang Diharapkan
* Performa aplikasi tetap lancar (*smooth*) meskipun riwayat transaksi mencapai ribuan baris.
* Pengguna memiliki kendali penuh atas data mereka dan dapat memulihkan data jika aplikasi di-reinstall atau ganti HP baru.`
});

const options = {
  hostname: 'api.github.com',
  port: 443,
  path: '/repos/abday-wong/yoknabung/issues',
  method: 'POST',
  headers: {
    'User-Agent': 'NodeJS-Script',
    'Authorization': `token ${token}`,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
  }
};

const req = http.request(options, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    if (res.statusCode === 201) {
      const responseData = JSON.parse(body);
      console.log('✅ Success! Issue created successfully.');
      console.log(`🔗 Link: ${responseData.html_url}`);
    } else {
      console.error(`❌ Failed to create issue. Status Code: ${res.statusCode}`);
      console.error('Response:', body);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Request error:', error);
});

req.write(data);
req.end();
