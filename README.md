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
  dari pemerintah (Ya/Tidak); jika Ya, pilih **jenis bantuan** lewat checkbox
  (bisa lebih dari satu): PKH, BPNT, PIP, KIP, BPJS PBI, Bantuan Pangan,
  Bedah Rumah, Lainnya (dengan deskripsi tambahan jika "Lainnya" dipilih).
- **Pertanyaan UMKM** — apakah ada anggota keluarga yang memiliki UMKM
  (Ya/Tidak), dan jika ya, jumlah anggota pemilik UMKM **dipisah Laki-laki
  dan Perempuan** (tidak boleh melebihi jumlah anggota keluarga per gender).
- **Data Bangunan per RT** (5 kategori: Tempat Tinggal, Rumah Ibadah,
  Fasilitas Pendidikan, Fasilitas Kesehatan, Kosong) — diisi manual oleh
  Admin/Operator/Ketua RT (RT masing-masing), ditampilkan di kedua dashboard.
- **Repositori Data** (Admin/Operator) — rekap resmi per RT bergaya tabel
  publikasi statistik (Tabel 3.1–3.4: penduduk, KK & bangunan, sex ratio,
  bantuan/UMKM/disabilitas), bisa dicetak/disimpan PDF.
- **Login Persisten** — tidak perlu login ulang setiap kunjungan (cookie aman
  30 hari) sampai pengguna benar-benar logout.
- **Impor data keluarga dari Excel** — tambah banyak keluarga sekaligus lewat
  file .xlsx (template tersedia lengkap dengan dropdown & contoh pengisian;
  satu baris = satu keluarga). Fitur ini beserta **Unduh Data (Export)**
  hanya tersedia untuk Operator Kelurahan & Admin Kelurahan.
- **Variabel Tambahan dengan satuan** — Admin bisa menambah kolom baru kapan
  saja (mis. "Luas Tanah" dengan satuan "m2") tanpa mengubah kode.
- **Simpan Sementara (draft otomatis)** — isian formulir tersimpan otomatis di
  localStorage browser, sehingga data tidak hilang jika koneksi terputus atau
  tab tertutup sebelum sempat disimpan ke server.
- **Paginasi** dengan pilihan 10/25/50/100/500 data per halaman.
- Desain responsif — tabel otomatis berubah jadi tampilan kartu di layar HP/tablet.
- 3 peran pengguna: Ketua RT (RT sendiri, langsung ke Data Keluarga setelah
  login), Operator Kelurahan (semua RT), Admin Kelurahan (semua RT +
  manajemen pengguna/RT/variabel tambahan).
- Nomor RT diseragamkan 3 digit (mis. "RT 001"), format tanggal DD-MM-YYYY
  konsisten di seluruh halaman (dd/mm/yyyy wajib di kolom input formulir),
  dan NIK/Nomor KK disamarkan (6 digit awal saja) di tampilan tabel untuk
  menjaga privasi.

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
5. *(Untuk data produksi asli)* Import `sql/buat_user_ketua_rt.sql` untuk
   membuat 9 akun Ketua RT resmi (lihat bagian **Akun Ketua RT** di bawah).
6. **Akses aplikasi**: `http://localhost/sika-mudunglaut/public/`
7. **Login**: username `admin`, password `admin123` — segera ganti password
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

Untuk menambahkan **Data Bangunan per RT** (versi lama: Tempat Tinggal
Terisi/Kosong, Khusus Usaha, Bukan Tinggal Non Usaha), jalankan
**`sql/update_database_v10.sql`**.

Untuk menambahkan fitur **Login Persisten** ("tetap masuk"), jalankan
**`sql/update_database_v11.sql`**.

Untuk memperbarui ke **Jenis Bantuan (checkbox), UMKM per gender, dan 5
kategori Bangunan baru** (Tempat Tinggal, Rumah Ibadah, Fasilitas
Pendidikan, Fasilitas Kesehatan, Kosong — menggantikan 4 kategori lama),
jalankan **`sql/update_database_v12.sql`**. **PENTING**: baca komentar di
awal file tersebut — data UMKM lama tidak bisa otomatis dipecah per gender
secara akurat, dan data Bangunan kategori lama tidak dipetakan otomatis ke
kategori baru (perlu diinput ulang oleh Admin/Operator/Ketua RT).

Untuk menambahkan pertanyaan **Kapan Terakhir Menerima Bantuan**, jalankan
**`sql/update_database_v13.sql`**. Catatan: pilihan Jenis Bantuan "Bantuan
Pangan" sudah diganti menjadi "BLT" mulai versi ini — data lama yang sudah
tersimpan dengan nilai "Bantuan Pangan" tetap utuh apa adanya (tidak diubah
otomatis), hanya pilihan baru di formulir/impor yang berubah.

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

## Login Persisten ("Tetap Masuk")

Mulai versi ini, pengguna **tidak perlu login ulang setiap kunjungan** —
sistem mengingat sesi login lewat cookie aman selama 30 hari, sampai
pengguna benar-benar menekan tombol **Keluar (Logout)**.

- Cookie hanya berisi ID pengguna + token acak; yang tersimpan di database
  adalah **hash** dari token tersebut (bukan token asli), sehingga tetap
  aman meski database bocor.
- Token diperpanjang & diperbarui otomatis (30 hari sejak kunjungan
  terakhir) setiap kali pengguna aktif memakai aplikasi.
- Menekan **Keluar** menghapus cookie DAN token di database sekaligus —
  memastikan sesi benar-benar berakhir di perangkat tersebut.
- Fitur ini otomatis aktif untuk semua peran, tidak perlu centang "Ingat
  Saya" secara manual.

## Halaman Awal Setelah Login

Disesuaikan per peran supaya lebih efisien untuk pekerjaan sehari-hari:

| Peran | Halaman Awal |
|---|---|
| Ketua RT | **Data Keluarga** (agar bisa langsung menambah data keluarga) |
| Operator Kelurahan | Dashboard |
| Admin Kelurahan | Dashboard |

## Pembatasan Fitur Unduh Data & Impor Excel

Fitur **Unduh Data (Export)** dan **Impor dari Excel** hanya tersedia untuk
**Operator Kelurahan** dan **Admin Kelurahan**. Ketua RT tidak melihat kedua
tombol ini di halaman Data Keluarga, dan jika mencoba mengakses URL-nya
secara langsung akan ditolak (halaman 403 - Tidak memiliki akses).

**Unduh Data mengikuti filter yang sedang aktif** — jika Anda sedang
memfilter/mencari data (RT, status bantuan, UMKM, keberadaan, kata kunci),
tombol "Unduh Data" hanya akan mengunduh data yang sesuai filter tersebut.
Jika tidak ada filter aktif, seluruh data akan diunduh. Tombol ini
menampilkan badge kecil yang menunjukkan status & jumlah data yang akan
diunduh — **"Terfilter • N"** (warna teal) atau **"Semua • N"** (abu-abu) —
supaya jelas sebelum benar-benar mengunduh.

## Akun Ketua RT (Data Resmi)

File `sql/buat_user_ketua_rt.sql` membuat 9 akun Ketua RT sesuai data resmi
Kelurahan Mudung Laut:

| Username | Nama | RT |
|---|---|---|
| `ketua_rt001` | KAPSUL ANWAR | 001 |
| `ketua_rt002` | M RIDHO | 002 |
| `ketua_rt003` | DAWIYAH | 003 |
| `ketua_rt004` | BUKHORI | 004 |
| `ketua_rt005` | A SAYUTI | 005 |
| `ketua_rt006` | MARINI | 006 |
| `ketua_rt007` | SALAMUDIN | 007 |
| `ketua_rt008` | SIGIT | 008 |
| `ketua_rt009` | HADI ISMANTO | 009 |

Semua akun memakai password default `admin123` — **segera minta masing-masing
Ketua RT mengganti passwordnya** setelah login pertama kali (lewat Admin
Kelurahan di menu Manajemen Pengguna, karena SIKA belum punya fitur ubah
password mandiri).

Skrip ini **aman dijalankan berkali-kali**: jika username sudah ada, hanya
namanya yang diperbarui (password yang sudah diganti sendiri oleh Ketua RT
TIDAK akan tertimpa/reset).

## Format Tanggal di Formulir (dd/mm/yyyy)

Kolom Tanggal Lahir Kepala Keluarga pada formulir Tambah/Ubah Keluarga
**wajib** diketik dengan format **dd/mm/yyyy** (contoh: `17/05/1990`),
dijamin konsisten di semua browser/perangkat — tidak lagi mengandalkan date
picker bawaan browser yang formatnya bisa berbeda-beda tergantung
pengaturan bahasa/lokasi perangkat pengguna. Garis miring (`/`) otomatis
ditambahkan saat mengetik, dan sistem akan menolak submit jika formatnya
tidak sesuai.



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

Beberapa pertanyaan per keluarga:

- **Pernah Menerima Bantuan Pemerintah** (Ya/Tidak) — jika "Ya", muncul
  **checkbox Jenis Bantuan** yang bisa dipilih lebih dari satu:
  PKH, BPNT, PIP, KIP, BPJS PBI, BLT, Bedah Rumah, Lainnya.
  Jika "Lainnya" dicentang, wajib diisi kolom Deskripsi Bantuan untuk
  menjelaskan jenis bantuan tersebut. Wajib juga diisi **Kapan Terakhir
  Menerima Bantuan** — cukup pilih **Bulan dan Tahun** lewat dropdown
  (tidak perlu tanggal spesifik).
- **Ada Anggota Keluarga dengan UMKM** (Ya/Tidak) — jika "Ya", wajib diisi
  jumlah anggota pemilik UMKM, **dipisah Laki-laki dan Perempuan**. Sistem
  otomatis menolak jika jumlah salah satu jenis kelamin melebihi jumlah
  anggota keluarga laki-laki/perempuan yang tercatat di Data Keluarga.
- **Ada Anggota Keluarga Penyandang Disabilitas** (individu dengan
  keterbatasan fisik, mental, intelektual, atau sensorik jangka panjang) —
  jika "Ya", wajib diisi jumlah orang dan jenis disabilitasnya.

Semuanya dapat difilter di halaman Data Keluarga, ditampilkan di Dashboard
(internal & publik) serta Repositori Data, dan disertakan dalam file CSV
hasil unduhan.

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

**Unduh grafik sebagai gambar:** setiap grafik memiliki tombol unduh
(ikon <i>download</i>) di pojok kanan atas kartu, untuk menyimpan grafik
tersebut sebagai file PNG — berguna untuk ditempel ke laporan/presentasi
tanpa perlu screenshot manual.

### Sumber Peta

- `public/assets/mudunglaut_rt.geojson` — batas wilayah RT resmi Kelurahan
  Mudung Laut (9 RT + 1 kawasan non-permukiman). Properti `nmsls` berisi
  teks seperti "RT 005" untuk mengenali nomor RT.
- `public/assets/leaflet/` — library peta Leaflet.js di-*host* lokal (bukan
  CDN luar) supaya peta tetap berfungsi meski koneksi ke CDN pihak ketiga
  terblokir/lambat.
- `public/assets/vendor/xlsx/` — library SheetJS (di-*host* lokal juga)
  yang dipakai fitur "Unduh Excel" di halaman Repositori Data.

## Struktur Database (ringkas)

| Tabel | Keterangan |
|---|---|
| `rt` | Daftar RT + data jumlah bangunan per RT |
| `users` | Akun pengguna (Ketua RT / Operator / Admin) |
| `keluarga` | Data keluarga + data pribadi Kepala Keluarga + bantuan/UMKM |
| `custom_fields` | Definisi variabel tambahan (+ satuan) |
| `custom_field_values` | Isi nilai dari variabel tambahan per record |

## Data Bangunan per RT

Admin Kelurahan, Operator Kelurahan, **dan Ketua RT** dapat mencatat jumlah
bangunan per RT:

- Jumlah Bangunan Tempat Tinggal
- Jumlah Bangunan Rumah Ibadah
- Jumlah Bangunan Fasilitas Pendidikan
- Jumlah Bangunan Fasilitas Kesehatan
- Jumlah Bangunan Kosong

Data ini murni diisi manual (bukan dihitung otomatis dari data keluarga), dan
ditampilkan sebagai kartu ringkasan serta grafik per RT di Dashboard internal,
Dashboard Publik, dan Repositori Data.

**Pembagian akses:**

| Aksi | Admin Kelurahan | Operator Kelurahan | Ketua RT |
|---|---|---|---|
| Melihat data RT & bangunan (semua RT) | Ya | Ya | Tidak |
| Mengubah data bangunan | Ya | Ya | Hanya RT sendiri |
| Mengubah Nomor RT / Keterangan | Ya | Tidak | Tidak |
| Menambah RT baru | Ya | Tidak | Tidak |
| Menghapus RT | Ya | Tidak | Tidak |

- Admin & Operator Kelurahan mengakses lewat menu **"Data RT & Bangunan"** /
  *Administrasi > Manajemen RT* — melihat & mengelola seluruh RT.
- **Ketua RT** mengakses lewat tombol **"Update Jumlah Bangunan"** di
  halaman Data Keluarga (di sebelah tombol Tambah Keluarga) — hanya bisa
  memperbarui data bangunan RT-nya sendiri lewat jendela pop-up sederhana,
  tidak bisa melihat/mengubah RT lain.

## Repositori Data

Halaman khusus Admin & Operator Kelurahan (menu **"Repositori Data"**) berisi
rekap resmi per RT dalam format tabel bergaya publikasi statistik (mirip
tabel BPS), terdiri dari:

- **Tabel 3.1** — Jumlah Penduduk menurut RT dan Jenis Kelamin
- **Tabel 3.2** — Jumlah Kepala Keluarga dan Bangunan menurut RT
- **Tabel 3.3** — Sex Ratio Penduduk menurut RT
- **Tabel 3.4** — Jumlah Keluarga Penerima Bantuan, Pemilik UMKM, dan
  Penyandang Disabilitas menurut RT

Setiap tabel memiliki baris total "Mudung Laut" di bagian bawah, dan bisa
dicetak/disimpan sebagai PDF lewat tombol "Cetak / Simpan PDF" (memakai
fitur cetak bawaan browser).

**Setiap tabel juga punya tombol "Unduh Excel"** tersendiri — mengunduh
tabel tersebut sebagai file `.xlsx` yang bisa langsung dibuka di Excel,
diproses sepenuhnya di browser (tidak perlu request tambahan ke server).

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
│   ├── update_database_v10.sql       # Migrasi: data bangunan per RT
│   ├── update_database_v11.sql       # Migrasi: login persisten
│   ├── update_database_v12.sql       # Migrasi: jenis bantuan checkbox, UMKM per gender, 5 kategori bangunan
│   ├── update_database_v13.sql       # Migrasi: tanggal terakhir menerima bantuan
│   └── buat_user_ketua_rt.sql        # Buat/perbarui 9 akun Ketua RT resmi
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
│   ├── repositori_data.php    # Rekap resmi per RT (Admin/Operator)
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
