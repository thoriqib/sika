# SIKA — Sistem Informasi Keluarga
Kelurahan Mudung Laut, Kecamatan Pelayangan, Kota Jambi

Aplikasi web (PHP native + MySQL, tanpa framework/Composer) untuk pemutakhiran
data keluarga di tingkat kelurahan, dengan pembagian akses per RT. Tampilan
responsif untuk desktop, tablet, dan smartphone.

> **Catatan Proses Bisnis:** Mulai versi ini, pendataan hanya dilakukan
> **sampai level KELUARGA** (termasuk data pribadi Kepala Keluarga). Data
> per-anggota keluarga lain (selain Kepala Keluarga) **tidak lagi didata**.
> Fitur Garis Kemiskinan/Status Kemiskinan juga sudah dihapus dari aplikasi.

## Fitur

- **Dashboard Publik (tanpa login)** — halaman statistik terbuka untuk warga &
  pemerintah: KPI kependudukan, berbagai grafik (profil Kepala Keluarga,
  bantuan pemerintah, UMKM, dst), dan **peta tematik (choropleth)** per RT
  berdasarkan batas wilayah RT resmi. Seluruh data ditampilkan sebagai
  **agregat/rekap** — tidak ada nama, NIK, nomor KK, atau alamat perorangan
  yang ditampilkan.
- **CRUD Data Keluarga**, termasuk data pribadi Kepala Keluarga (NIK, jenis
  kelamin, tanggal lahir, agama, status perkawinan, pendidikan, status
  pekerjaan) dalam satu formulir.
- **Jumlah anggota keluarga (laki-laki/perempuan)** diisi langsung oleh
  petugas, tidak lagi dihitung dari data anggota per-individu.
- **Status Pekerjaan Kepala Keluarga** — dropdown 7 kategori (Buruh harian
  lepas, PNS/ASN/TNI/Polri, Wirausaha, Karyawan Swasta, Pelajar/Mahasiswa,
  Tidak Bekerja, Lainnya); deskripsi pekerjaan bebas hanya diminta jika
  status bukan "Pelajar/Mahasiswa" atau "Tidak Bekerja".
- **Pertanyaan Bantuan Pemerintah** — apakah keluarga pernah menerima bantuan
  dari pemerintah (Ya/Tidak).
- **Pertanyaan UMKM** — apakah ada anggota keluarga yang memiliki UMKM
  (Ya/Tidak), dan jika ya, berapa jumlah anggota yang memilikinya.
- **Impor data keluarga dari Excel** — tambah banyak keluarga sekaligus lewat
  file .xlsx (template tersedia lengkap dengan dropdown & contoh pengisian;
  satu baris = satu keluarga).
- **Variabel Tambahan dengan satuan** — Admin bisa menambah kolom baru kapan
  saja (mis. "Luas Tanah" dengan satuan "m2") tanpa mengubah kode.
- **Simpan Sementara (draft otomatis)** — isian formulir tersimpan otomatis di
  localStorage browser, sehingga data tidak hilang jika koneksi terputus atau
  tab tertutup sebelum sempat disimpan ke server.
- **Paginasi** dengan pilihan 10/25/50/100/500 data per halaman.
- Unduh (export) data keluarga ke CSV (bisa dibuka di Excel).
- Desain responsif — tabel otomatis berubah jadi tampilan kartu di layar HP/tablet.
- 3 peran pengguna: Ketua RT (RT sendiri), Operator Kelurahan (semua RT), Admin
  Kelurahan (semua RT + manajemen pengguna/RT/variabel tambahan).
- Nomor RT diseragamkan 3 digit (mis. "RT 001"), format tanggal DD-MM-YYYY
  konsisten di seluruh halaman, dan NIK/Nomor KK disamarkan (6 digit awal
  saja) di tampilan tabel untuk menjaga privasi.

## Kebutuhan

- Server dengan PHP 8.0+ dan MySQL/MariaDB (XAMPP untuk lokal, atau nginx +
  PHP-FPM + MySQL untuk VPS)
- Tidak perlu Composer/Node.js, murni PHP native
- Ekstensi PHP `zip` dan `SimpleXML` aktif (dipakai fitur Impor Excel) — pada
  instalasi standar keduanya sudah aktif secara default

## Struktur Direktori (Penting Dibaca Sebelum Deploy)

Folder aplikasi dipisah menjadi tiga bagian demi keamanan:

```
sika-mudunglaut/
├── public/       <-- HANYA folder ini yang boleh diakses lewat web server
│   ├── *.php       (seluruh halaman: login, dashboard, keluarga_*, dst)
│   ├── template_import_keluarga.xlsx
│   └── assets/     (css, js, leaflet, geojson)
├── includes/     <-- TIDAK BOLEH bisa diakses lewat browser sama sekali
│   ├── config.php          (kredensial database ada di sini)
│   ├── functions.php
│   ├── partials_header.php
│   └── partials_footer.php
├── sql/          <-- TIDAK BOLEH bisa diakses lewat browser sama sekali
│   ├── sika_deploy.sql, sika_deploy_dengan_sample.sql
│   └── database.sql, sample_data.sql, update_database_v*.sql
└── README.md
```

**Alasan keamanan:** `config.php` (berisi password database) dan seluruh file
`.sql` TIDAK diletakkan di dalam `public/`. Siapa pun yang membuka
`namadomain.com/config.php` akan selalu mendapat **404 Not Found**.

**Konsekuensinya:** web server (Apache/nginx) HARUS diarahkan (document root /
`root` directive) ke folder **`public/`**, bukan ke folder induk.

## Cara Instalasi Baru (XAMPP di Windows, untuk uji coba lokal)

1. **Copy folder aplikasi** ke `C:\xampp\htdocs\sika-mudunglaut`
2. **Jalankan Apache & MySQL** di XAMPP Control Panel
3. **Buat database**: buka `http://localhost/phpmyadmin` → tab **Import** →
   pilih `sql/database.sql` → **Go**
4. *(Opsional, untuk uji coba)* Import juga `sql/sample_data.sql` dengan cara
   yang sama, untuk mengisi 520 keluarga contoh. Lihat bagian **Data
   Simulasi** di bawah untuk detail akun contoh.
5. **Akses aplikasi**: `http://localhost/sika-mudunglaut/public/`
6. **Login**: username `admin`, password `admin123` — segera ganti password
   setelah login pertama (menu *Administrasi > Manajemen Pengguna > Ubah*)

**Supaya tidak perlu mengetik `/public/` setiap saat (opsional):** buat
Virtual Host Apache yang document root-nya langsung menunjuk ke folder
`public/`.

## Deploy ke Server Produksi — VPS Ubuntu + Nginx

Ringkasan langkah (asumsi nginx & PHP-FPM & MySQL/MariaDB sudah terpasang):

1. Upload & ekstrak project ke `/var/www/sika` (sehingga ada `/var/www/sika/public`,
   `/var/www/sika/includes`, `/var/www/sika/sql`).
2. Import database: `sudo mysql < /var/www/sika/sql/sika_deploy.sql`
3. Sesuaikan kredensial di `/var/www/sika/includes/config.php`.
4. Atur kepemilikan: `sudo chown -R www-data:www-data /var/www/sika`
5. Konfigurasi nginx dengan **root mengarah ke `/var/www/sika/public`**:

```nginx
server {
    listen 80;
    server_name domain-anda.com;

    root /var/www/sika/public;
    index login.php index.php;

    client_max_body_size 10M;   # perlu besar untuk fitur impor Excel

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;   # sesuaikan versi PHP
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~ /\. {
        deny all;
    }
}
```

6. Aktifkan & reload: `sudo ln -s /etc/nginx/sites-available/sika /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl reload nginx`
7. Naikkan limit upload PHP di `php.ini`: `upload_max_filesize = 10M`, `post_max_size = 12M`.
8. Matikan `display_errors` di produksi, pastikan `log_errors = On`.
9. Pasang SSL: `sudo certbot --nginx -d domain-anda.com`

### Jika aplikasi perlu diakses di subpath (mis. `domain.com/sika/`)

Jika domain sudah dipakai untuk situs lain dan SIKA perlu ditempatkan di
subfolder URL, **jangan** gunakan `alias` biasa (rawan bug "Primary script
unknown" pada PHP-FPM). Gunakan salah satu dari dua pola berikut yang sudah
terbukti bekerja:

**Pola A — Symlink (paling sederhana):**
```bash
ln -sfn /var/www/sika/public /var/www/domain-anda.com/sika
```
lalu pakai `root /var/www/domain-anda.com;` di level server dengan satu
`location ~ \.php$` global (tanpa blok khusus untuk `/sika/`).

**Pola B — `alias` dengan perbaikan SCRIPT_FILENAME:**
```nginx
location ^~ /sika/ {
    alias /var/www/sika/public/;
    index login.php index.php;
    try_files $uri $uri/ =404;

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
    }
}
```
Kuncinya adalah `fastcgi_param SCRIPT_FILENAME $request_filename;` (bukan
`$document_root$fastcgi_script_name`) — variabel ini yang benar menghitung
path fisik saat memakai `alias`.

## Deploy: Satu File Dump

Untuk deploy ke server baru, gunakan salah satu file dump berikut dari folder
`sql/` — cukup satu file:

| File | Isi | Kapan Dipakai |
|---|---|---|
| **`sql/sika_deploy.sql`** | Struktur database terkini + akun admin default + daftar 9 RT | **Server produksi** — mulai dari data kosong |
| **`sql/sika_deploy_dengan_sample.sql`** | Sama seperti di atas, ditambah 520 keluarga data simulasi | Server staging/demo/uji coba |

```bash
mysql -u root pemutakhiran_keluarga < sql/sika_deploy.sql
```

## Jika Sudah Pernah Install Versi Lama (Update)

Jika Anda sudah punya data asli dari versi aplikasi sebelumnya (yang masih
memiliki data per-anggota keluarga & Garis Kemiskinan), jalankan
**`sql/update_database_v8.sql`** lewat phpMyAdmin tab SQL. Skrip ini:

1. Menambahkan kolom-kolom baru di tabel `keluarga` untuk data pribadi Kepala
   Keluarga, jumlah anggota, bantuan pemerintah, dan UMKM.
2. **Menyalin (bukan memindahkan)** data Kepala Keluarga yang sebelumnya ada
   di tabel `anggota_keluarga` ke kolom-kolom baru tersebut — tidak ada data
   yang hilang.
3. Menghapus kolom pengeluaran (sudah tidak dipakai).
4. **TIDAK menghapus** tabel `anggota_keluarga` maupun `garis_kemiskinan` —
   keduanya tetap ada sebagai arsip data historis, hanya sudah tidak dibaca
   aplikasi. Boleh dihapus manual jika Anda yakin tidak memerlukannya lagi
   (instruksi ada di dalam file skrip).

Migrasi versi-versi sebelumnya (`update_database.sql` s.d. `update_database_v7.sql`)
tetap disertakan sebagai arsip riwayat perubahan struktur, dan hanya relevan
untuk instalasi yang belum pernah menjalankan migrasi tersebut sebelumnya.

Jika instalasi Anda sudah menjalankan v8 namun belum memiliki kolom Deskripsi
Bantuan, Disabilitas, dan Status Keberadaan Keluarga, jalankan juga
**`sql/update_database_v9.sql`** (aman dijalankan berkali-kali, tidak
menghapus data).

Untuk menambahkan **Data Bangunan per RT** (Tempat Tinggal Terisi/Kosong,
Khusus Usaha, Bukan Tinggal Non Usaha), jalankan **`sql/update_database_v10.sql`**.

## Data Simulasi (Sample Data)

`sql/sample_data.sql` berisi **520 keluarga contoh** (bukan data asli warga),
tersebar di **RT 001–009** secara **proporsional terhadap luas wilayah tiap
RT** (dihitung otomatis dari `public/assets/mudunglaut_rt.geojson`) — RT yang
sempit mendapat lebih sedikit keluarga, RT yang luas mendapat lebih banyak.
Data mencakup variasi status pekerjaan, status bantuan pemerintah, dan UMKM
untuk keperluan uji dashboard.

Akun contoh yang ikut ditambahkan (semua password: `admin123`):

| Username | Role | Cakupan Akses |
|---|---|---|
| `admin` | Admin Kelurahan | Semua data + administrasi |
| `ketua_rt001` s.d. `ketua_rt009` | Ketua RT | RT 001 s.d. RT 009 (sesuai nomor) |
| `operator1` | Operator Kelurahan | Semua RT |

**Catatan:** `sample_data.sql` memakai ID eksplisit, jadi hanya aman
dijalankan di database yang masih kosong.

## Aturan Data Kepala Keluarga

Setiap keluarga wajib memiliki data pribadi Kepala Keluarga yang lengkap
(NIK, jenis kelamin, tanggal lahir, status pekerjaan) — ini diisi dalam
formulir yang sama dengan Data Keluarga, bukan formulir terpisah. NIK Kepala
Keluarga bersifat unik di seluruh sistem (tidak boleh sama dengan NIK Kepala
Keluarga lain).

## Status Pekerjaan Kepala Keluarga

7 kategori baku: Buruh harian lepas, PNS/ASN/TNI/Polri, Wirausaha, Karyawan
Swasta, Pelajar/Mahasiswa, Tidak Bekerja, Lainnya. Kolom **Deskripsi
Pekerjaan** otomatis muncul dan wajib diisi hanya jika status yang dipilih
BUKAN "Pelajar/Mahasiswa" atau "Tidak Bekerja".

## Bantuan Pemerintah, UMKM & Disabilitas

Beberapa pertanyaan Ya/Tidak per keluarga:

- **Pernah Menerima Bantuan Pemerintah** — jika "Ya", wajib diisi
  **Deskripsi Bantuan** (contoh: Bantuan Langsung Tunai/BLT, PKH, Sembako).
- **Ada Anggota Keluarga dengan UMKM** — jika "Ya", wajib diisi jumlah
  anggota keluarga yang memiliki UMKM tersebut.
- **Ada Anggota Keluarga Penyandang Disabilitas** (individu dengan
  keterbatasan fisik, mental, intelektual, atau sensorik jangka panjang) —
  jika "Ya", wajib diisi jumlah orang dan jenis disabilitasnya.

Semuanya dapat difilter di halaman Data Keluarga, ditampilkan di Dashboard
(internal & publik), dan disertakan dalam file CSV hasil unduhan.

## Status Keberadaan Keluarga

Setiap keluarga memiliki status **Ada** atau **Pindah**, menggantikan konsep
keberadaan yang dulu ada di level anggota (kini di level keluarga karena
pendataan per-anggota sudah tidak dilakukan). Statistik utama di Dashboard
(internal maupun publik) **hanya menghitung keluarga berstatus "Ada"** —
keluarga berstatus "Pindah" tetap tersimpan datanya untuk riwayat, dengan
tautan terpisah untuk melihat daftarnya, dan tidak ikut dihitung dalam
statistik populasi aktif.

## Simpan Sementara (Draft)

Saat mengisi formulir Tambah/Ubah Keluarga, isian otomatis tersimpan ke
localStorage browser secara berkala. Jika koneksi terputus atau tab tertutup
sebelum sempat menekan "Simpan", sistem akan menawarkan untuk memuat kembali
draft tersebut saat formulir dibuka lagi.

## Menambah Variabel Baru (dengan Satuan)

Login sebagai Admin Kelurahan → *Administrasi > Manajemen Variabel Tambahan*
→ isi nama variabel, tipe data, dan satuan jika relevan (contoh: "kg", "m2").
Variabel baru otomatis muncul di formulir Data Keluarga dan disertakan pada
hasil unduhan CSV.

## Penyamaran NIK & Nomor KK

Tabel Data Keluarga dan halaman Detail Keluarga hanya menampilkan 6 digit
pertama NIK/Nomor KK — sisanya diganti tanda bintang. Data lengkap tetap
bisa dilihat/diedit lewat formulir Ubah, dan tetap ditampilkan utuh pada file
CSV hasil unduhan (karena ditujukan untuk pelaporan resmi oleh pengguna yang
sudah login).

## Impor Data Keluarga dari Excel

Menu **Impor dari Excel** di halaman Data Keluarga memungkinkan menambah
banyak keluarga sekaligus:

1. Unduh **template Excel** dari halaman impor — sudah dilengkapi dropdown
   untuk kolom berkode dan 2 baris contoh pengisian.
2. **Satu baris = satu keluarga** (data Kepala Keluarga langsung digabung
   pada baris yang sama, tidak perlu baris terpisah).
3. Tanggal ditulis dengan format **DD-MM-YYYY** (contoh: 17-05-1990).
4. Setelah file diunggah, sistem menampilkan laporan hasil impor per baris:
   berhasil atau gagal beserta alasannya. Baris yang gagal tidak
   mempengaruhi baris lain yang valid.
5. Nomor KK/NIK yang sudah terdaftar akan otomatis ditolak (gunakan menu
   Ubah Data Keluarga untuk keluarga yang sudah ada, bukan impor).
6. Ketua RT hanya dapat mengimpor data untuk RT-nya sendiri.

Fitur ini memakai pembaca file .xlsx ringan bawaan PHP (`ZipArchive` +
`SimpleXML`), sehingga tidak memerlukan Composer/library tambahan.

## Paginasi

Halaman Data Keluarga memakai paginasi: 10/25/50/100/500 data per halaman
(default 25), dengan info "Menampilkan X–Y dari Z data" dan navigasi nomor
halaman. Filter yang aktif tetap terjaga saat berpindah halaman. Fitur
"Unduh Data" tetap mengekspor seluruh data sesuai filter, bukan hanya
halaman yang sedang dibuka.

## Format Tanggal & Penomoran RT

Seluruh tanggal yang ditampilkan memakai format **DD-MM-YYYY** (dan
DD-MM-YYYY HH:mm untuk yang menyertakan jam), kecuali kolom input tanggal
di formulir (`<input type="date">`) yang memakai format YYYY-MM-DD sesuai
standar HTML5 (tidak memengaruhi tampilan bagi pengguna). Seluruh jam
ditampilkan dalam **zona waktu WIB (Asia/Jakarta, GMT+7)**, diatur secara
eksplisit di `includes/config.php` (`date_default_timezone_set`) agar tidak
mengikuti zona waktu default server (biasanya UTC pada VPS). Nomor RT
diseragamkan 3 digit (mis. "RT 001") di seluruh aplikasi; saat menambah RT
baru cukup ketik angkanya saja, sistem otomatis menyimpannya dalam format
3 digit.

## Dashboard Publik & Peta Tematik

Halaman `public_dashboard.php` dapat diakses **siapa saja tanpa login**.
Berisi KPI kependudukan, peta tematik (choropleth) per RT berdasarkan batas
wilayah RT resmi (diwarnai berdasarkan persentase keluarga yang pernah
menerima bantuan pemerintah), serta grafik profil Kepala Keluarga (usia,
status perkawinan, pendidikan, status pekerjaan, agama) dan statistik
bantuan/UMKM per RT.

**Perlindungan data pribadi:** seluruh query pada halaman ini murni agregat
(`COUNT`/`SUM`/`GROUP BY`) — tidak pernah mengambil kolom nama, NIK, nomor
KK, atau alamat.

### Sumber Peta

- `public/assets/mudunglaut_rt.geojson` — batas wilayah RT resmi Kelurahan
  Mudung Laut (9 RT + 1 kawasan non-permukiman). Properti `nmsls` berisi
  teks seperti "RT 005" untuk mengenali nomor RT.
- `public/assets/leaflet/` — library peta Leaflet.js di-*host* lokal (bukan
  CDN luar) supaya peta tetap berfungsi meski koneksi ke CDN pihak ketiga
  terblokir/lambat.

## Struktur Database (ringkas)

| Tabel | Keterangan |
|---|---|
| `rt` | Daftar RT + data jumlah bangunan per RT |
| `users` | Akun pengguna (Ketua RT / Operator / Admin) |
| `keluarga` | Data keluarga + data pribadi Kepala Keluarga + bantuan/UMKM |
| `custom_fields` | Definisi variabel tambahan (+ satuan) |
| `custom_field_values` | Isi nilai dari variabel tambahan per record |

## Data Bangunan per RT

Admin Kelurahan **dan Operator Kelurahan** dapat mencatat jumlah bangunan per
RT lewat menu *Manajemen RT* (tombol Ubah pada tiap baris RT):

- Jumlah Bangunan Tempat Tinggal Terisi
- Jumlah Bangunan Kosong
- Jumlah Bangunan Khusus Usaha
- Jumlah Bangunan Bukan Tempat Tinggal Non Usaha

Data ini murni diisi manual (bukan dihitung otomatis dari data keluarga), dan
ditampilkan sebagai kartu ringkasan serta grafik per RT baik di Dashboard
internal maupun Dashboard Publik.

**Pembagian akses di halaman Manajemen RT:**

| Aksi | Admin Kelurahan | Operator Kelurahan |
|---|---|---|
| Melihat data RT & bangunan | Ya | Ya |
| Mengubah data bangunan | Ya | Ya |
| Mengubah Nomor RT / Keterangan | Ya | Tidak |
| Menambah RT baru | Ya | Tidak |
| Menghapus RT | Ya | Tidak |

Operator Kelurahan mengakses halaman ini lewat menu **"Data RT & Bangunan"**
pada navbar (terpisah dari menu "Administrasi" yang khusus Admin).

## Struktur Folder

```
sika-mudunglaut/
├── sql/
│   ├── sika_deploy.sql              # SATU FILE untuk deploy ke server produksi
│   ├── sika_deploy_dengan_sample.sql  # Sama + 520 keluarga simulasi
│   ├── database.sql                 # Skema + data awal (install baru)
│   ├── sample_data.sql               # Data simulasi (520 keluarga)
│   ├── update_database.sql           # Migrasi arsip (riwayat versi lama)
│   ├── update_database_v3.sql        # s.d.
│   ├── update_database_v7.sql        # (arsip riwayat migrasi versi lama)
│   ├── update_database_v8.sql        # Migrasi: pendataan level keluarga saja
│   ├── update_database_v9.sql        # Migrasi: deskripsi bantuan, disabilitas, status keberadaan
│   └── update_database_v10.sql       # Migrasi: data bangunan per RT
├── includes/
│   ├── config.php
│   ├── functions.php
│   ├── partials_header.php
│   └── partials_footer.php
├── public/
│   ├── index.php / login.php / logout.php
│   ├── dashboard.php
│   ├── public_dashboard.php
│   ├── keluarga_list.php / keluarga_create.php / keluarga_edit.php
│   ├── keluarga_view.php / keluarga_delete.php / keluarga_export.php
│   ├── keluarga_import.php
│   ├── admin_users.php / admin_users_form.php
│   ├── admin_rt.php
│   ├── admin_fields.php
│   ├── template_import_keluarga.xlsx
│   └── assets/
│       ├── style.css
│       ├── draft.js
│       ├── mudunglaut_rt.geojson
│       └── leaflet/
└── README.md
```

## Catatan Keamanan

- Seluruh query database memakai prepared statement (PDO) untuk mencegah SQL injection.
- Password disimpan dengan hash bcrypt, bukan teks biasa.
- Akses data dibatasi per role di level server, bukan hanya disembunyikan di tampilan.
- File internal (`config.php`, seluruh `.sql`) berada di luar folder yang
  dilayani web server (`public/`), sehingga tidak bisa diakses lewat URL
  apa pun.
- NIK/Nomor KK disamarkan di tampilan tabel untuk menjaga privasi warga.

## Saran Fitur Tambahan (opsional, belum diimplementasikan)

1. **Cetak/PDF Kartu Keluarga & Laporan Rekap** — cetak profil satu keluarga
   atau rekap jumlah penduduk per RT dalam format PDF siap print.
2. **Riwayat perubahan (audit log)** — mencatat siapa mengubah data apa dan
   kapan.
3. **Notifikasi data belum lengkap** — menandai keluarga yang datanya masih
   kosong/kurang.
4. **Grafik/statistik lanjutan** di dashboard (tren jumlah keluarga per
   bulan, dsb).
5. **Backup database sekali klik** dari menu Admin.
6. **Verifikasi berjenjang** — Ketua RT input data, lalu perlu "disetujui"
   Operator/Admin sebelum dianggap final.
7. **Laporan realisasi bantuan** — pencatatan jenis/tanggal bantuan yang
   diterima (bukan hanya Ya/Tidak), untuk pelaporan by-name-by-address ke
   program bantuan sosial pemerintah.
