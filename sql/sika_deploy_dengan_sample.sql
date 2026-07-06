-- =========================================================
-- SIKA (Sistem Informasi Keluarga) - Dump Database Deploy
-- Kelurahan Mudung Laut, Kecamatan Pelayangan, Kota Jambi
-- File TUNGGAL untuk deploy ke server baru — sudah mencakup seluruh
-- pembaruan struktur s.d. saat ini (pendataan level keluarga saja).
-- Cara pakai:
-- 1. Buka phpMyAdmin (http://localhost/phpmyadmin)
-- 2. Buat database baru bernama: pemutakhiran_keluarga
-- 3. Pilih database tsb, buka tab "Import", pilih file ini, lalu klik "Go"
--    (atau copy-paste seluruh isi file ini ke tab "SQL" lalu jalankan)
--
-- Catatan: jika Anda sudah pernah install versi sebelumnya dan sudah
-- punya data, JANGAN import file ini (akan membuat ulang tabel dari nol).
-- Gunakan file update_database_v8.sql untuk memperbarui struktur tanpa
-- kehilangan data.
--
-- CATATAN PROSES BISNIS: mulai versi ini, pendataan HANYA sampai level
-- KELUARGA (termasuk data pribadi Kepala Keluarga). Data per-anggota
-- keluarga (selain Kepala Keluarga) TIDAK LAGI didata. Fitur Garis
-- Kemiskinan & Status Kemiskinan juga sudah tidak digunakan.
-- =========================================================

CREATE DATABASE IF NOT EXISTS pemutakhiran_keluarga CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pemutakhiran_keluarga;

-- =========================================================
-- Tabel RT
-- =========================================================
CREATE TABLE rt (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nomor_rt VARCHAR(10) NOT NULL UNIQUE,
  keterangan VARCHAR(100) NULL
) ENGINE=InnoDB;

-- =========================================================
-- Tabel Pengguna (Ketua RT, Operator Kelurahan, Admin Kelurahan)
-- =========================================================
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('admin_kelurahan','operator_kelurahan','ketua_rt') NOT NULL,
  rt_id INT NULL,
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (rt_id) REFERENCES rt(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =========================================================
-- Tabel Keluarga
-- Mencakup data keluarga SEKALIGUS data pribadi Kepala Keluarga
-- (tidak ada lagi tabel anggota_keluarga terpisah).
-- =========================================================
CREATE TABLE keluarga (
  id INT AUTO_INCREMENT PRIMARY KEY,

  -- Data Keluarga
  nama_kepala_keluarga VARCHAR(100) NOT NULL,
  alamat TEXT NOT NULL,
  rt_id INT NOT NULL,
  nomor_kk VARCHAR(20) UNIQUE NOT NULL,
  jumlah_lk INT NOT NULL DEFAULT 0,   -- jumlah anggota keluarga laki-laki (diisi langsung)
  jumlah_pr INT NOT NULL DEFAULT 0,   -- jumlah anggota keluarga perempuan (diisi langsung)
  jumlah_total INT NOT NULL DEFAULT 0, -- = jumlah_lk + jumlah_pr, dihitung otomatis oleh aplikasi

  -- Data pribadi Kepala Keluarga
  nik_kepala_keluarga VARCHAR(20) NOT NULL UNIQUE,
  jenis_kelamin_kepala_keluarga ENUM('Laki-laki','Perempuan') NOT NULL,
  tanggal_lahir_kepala_keluarga DATE NOT NULL,
  agama_kepala_keluarga VARCHAR(30) NULL,
  status_perkawinan_kepala_keluarga VARCHAR(30) NULL,
  pendidikan_kepala_keluarga VARCHAR(50) NULL,
  status_pekerjaan_kepala_keluarga VARCHAR(60) NULL,
  pekerjaan_kepala_keluarga VARCHAR(100) NULL, -- deskripsi pekerjaan (jika status bukan Pelajar/Mahasiswa atau Tidak Bekerja)

  -- Pertanyaan tambahan
  pernah_bantuan ENUM('Ya','Tidak') NOT NULL DEFAULT 'Tidak', -- pernah menerima bantuan pemerintah?
  ada_umkm ENUM('Ya','Tidak') NOT NULL DEFAULT 'Tidak',       -- ada anggota keluarga yang memiliki UMKM?
  jumlah_anggota_umkm INT NULL,                               -- diisi jika ada_umkm = 'Ya'

  created_by INT NULL,
  updated_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (rt_id) REFERENCES rt(id),
  FOREIGN KEY (created_by) REFERENCES users(id),
  FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- =========================================================
-- Tabel Variabel Tambahan (agar variabel bisa ditambah sesuai kebutuhan
-- tanpa mengubah struktur/kode aplikasi). Hanya berlaku untuk Data Keluarga.
-- =========================================================
CREATE TABLE custom_fields (
  id INT AUTO_INCREMENT PRIMARY KEY,
  target_table ENUM('keluarga') NOT NULL DEFAULT 'keluarga',
  field_key VARCHAR(60) NOT NULL,
  field_label VARCHAR(100) NOT NULL,
  field_type ENUM('text','number','date','select','textarea') DEFAULT 'text',
  field_options TEXT NULL,
  field_unit VARCHAR(20) NULL,
  is_required TINYINT(1) DEFAULT 0,
  urutan INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE custom_field_values (
  id INT AUTO_INCREMENT PRIMARY KEY,
  custom_field_id INT NOT NULL,
  record_id INT NOT NULL,
  value TEXT NULL,
  FOREIGN KEY (custom_field_id) REFERENCES custom_fields(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =========================================================
-- Data awal (seed)
-- =========================================================

-- RT default, silakan sesuaikan/tambah lewat menu Administrasi > Manajemen RT
-- Kelurahan Mudung Laut memiliki 9 RT sesuai data batas wilayah (SLS) resmi
INSERT INTO rt (nomor_rt, keterangan) VALUES
('001', NULL), ('002', NULL), ('003', NULL), ('004', NULL),
('005', NULL), ('006', NULL), ('007', NULL), ('008', NULL), ('009', NULL);

-- Akun Admin Kelurahan default
-- username : admin
-- password : admin123
-- SEGERA GANTI PASSWORD INI setelah login pertama kali (lewat menu Manajemen Pengguna)
INSERT INTO users (nama, username, password, role, rt_id, status) VALUES
('Administrator Kelurahan', 'admin', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'admin_kelurahan', NULL, 'aktif');

-- =========================================================
-- BAGIAN DATA SIMULASI (OPSIONAL)
-- Hapus/lewati bagian di bawah ini jika Anda ingin database
-- yang benar-benar kosong untuk data produksi asli.
-- =========================================================

-- =========================================================
-- SIKA - Data Simulasi / Dummy untuk Uji Coba (skala besar)
-- =========================================================
-- File ini berisi data contoh (BUKAN data asli warga) untuk keperluan
-- uji coba aplikasi dalam skala lebih besar (520 keluarga):
-- dashboard, pencarian, filter RT, filter bantuan/UMKM, export, paginasi, dsb.
--
-- CATATAN: Mulai versi ini pendataan hanya sampai level KELUARGA
-- (termasuk data pribadi Kepala Keluarga). Tidak ada lagi tabel anggota_keluarga.
--
-- CARA PAKAI:
-- 1. Import database.sql terlebih dahulu (database kosong/baru).
-- 2. Baru import file ini (sample_data.sql) lewat phpMyAdmin > tab Import.
--
-- PENTING: Jalankan di database yang MASIH KOSONG datanya (baru selesai
-- install). Skrip ini memakai ID eksplisit sehingga TIDAK COCOK dijalankan
-- di database yang sudah berisi data asli.
--
-- Akun contoh yang ditambahkan (semua password: admin123):
--   - ketua_rt001 s.d. ketua_rt009  (Ketua RT 001-009)
--   - operator1                     (Operator Kelurahan)
-- =========================================================

USE pemutakhiran_keluarga;

-- =========================================================
-- Pengguna contoh
-- =========================================================
INSERT INTO users (nama, username, password, role, rt_id, status) VALUES
('Ahmad Sutrisno', 'ketua_rt001', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'ketua_rt', (SELECT id FROM rt WHERE nomor_rt='001'), 'aktif'),
('Bambang Wijaya', 'ketua_rt002', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'ketua_rt', (SELECT id FROM rt WHERE nomor_rt='002'), 'aktif'),
('Cahyo Prasetyo', 'ketua_rt003', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'ketua_rt', (SELECT id FROM rt WHERE nomor_rt='003'), 'aktif'),
('Darmadi Yusuf', 'ketua_rt004', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'ketua_rt', (SELECT id FROM rt WHERE nomor_rt='004'), 'aktif'),
('Eka Firmansyah', 'ketua_rt005', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'ketua_rt', (SELECT id FROM rt WHERE nomor_rt='005'), 'aktif'),
('Fauzi Rahman', 'ketua_rt006', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'ketua_rt', (SELECT id FROM rt WHERE nomor_rt='006'), 'aktif'),
('Gunawan Hakim', 'ketua_rt007', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'ketua_rt', (SELECT id FROM rt WHERE nomor_rt='007'), 'aktif'),
('Hendra Saputra', 'ketua_rt008', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'ketua_rt', (SELECT id FROM rt WHERE nomor_rt='008'), 'aktif'),
('Indra Kusnadi', 'ketua_rt009', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'ketua_rt', (SELECT id FROM rt WHERE nomor_rt='009'), 'aktif'),
('Siti Rahayu Operator', 'operator1', '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW', 'operator_kelurahan', NULL, 'aktif');

-- =========================================================
-- Variabel tambahan contoh
-- =========================================================
INSERT INTO custom_fields (target_table, field_key, field_label, field_type, field_options, field_unit, is_required, urutan) VALUES
('keluarga', 'luas_tanah', 'Luas Tanah', 'number', NULL, 'm2', 0, 1),
('keluarga', 'kepemilikan_rumah', 'Kepemilikan Rumah', 'select', 'Milik Sendiri,Sewa,Menumpang', NULL, 0, 2);

-- =========================================================
-- Data Keluarga (520 keluarga, tersebar di RT 001-009 proporsional
-- terhadap luas wilayah tiap RT — RT sempit mendapat lebih sedikit keluarga,
-- RT luas mendapat lebih banyak, bukan dibagi rata)
-- =========================================================
INSERT INTO keluarga (id, nama_kepala_keluarga, alamat, rt_id, nomor_kk, jumlah_lk, jumlah_pr, jumlah_total, nik_kepala_keluarga, jenis_kelamin_kepala_keluarga, tanggal_lahir_kepala_keluarga, agama_kepala_keluarga, status_perkawinan_kepala_keluarga, pendidikan_kepala_keluarga, status_pekerjaan_kepala_keluarga, pekerjaan_kepala_keluarga, pernah_bantuan, ada_umkm, jumlah_anggota_umkm, created_by, updated_by) VALUES
(1, 'Gani Kusnadi', 'Jl. Pasar Baru No. 47, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000010001', 5, 1, 6, '1571010000011001', 'Laki-laki', '1994-01-30', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Pegawai bank', 'Tidak', 'Tidak', NULL, 1, 1),
(2, 'Taufik Basuki', 'Jl. Pasar Baru No. 28, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010000020001', 3, 2, 5, '1571010000021001', 'Laki-laki', '1958-05-08', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Sopir angkot', 'Tidak', 'Ya', 2, 1, 1),
(3, 'Rudi Amin', 'Jl. Ujung Tanjung No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010000030001', 2, 2, 4, '1571010000031001', 'Laki-laki', '1982-08-04', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Pegawai bank', 'Tidak', 'Tidak', NULL, 1, 1),
(4, 'Taufik Purnomo', 'Jl. Batanghari Indah No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000040001', 3, 0, 3, '1571010000041001', 'Laki-laki', '1986-11-20', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Bidan desa', 'Ya', 'Tidak', NULL, 1, 1),
(5, 'Fajar Hartono', 'Gg. Mawar No. 32, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000050001', 1, 2, 3, '1571010000051001', 'Laki-laki', '1995-03-12', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Ya', 'Ya', 2, 1, 1),
(6, 'Firman Alamsyah', 'Gg. Flamboyan No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010000060001', 2, 3, 5, '1571010000061001', 'Laki-laki', '1972-06-11', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Karyawan toko', 'Tidak', 'Tidak', NULL, 1, 1),
(7, 'Rizal Yusuf', 'Jl. Batanghari Indah No. 16, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000070001', 1, 1, 2, '1571010000071001', 'Laki-laki', '1995-05-22', 'Islam', 'Kawin', 'SD', 'Wirausaha', 'Karyawan pabrik', 'Tidak', 'Tidak', NULL, 1, 1),
(8, 'Yusuf Wibowo', 'Gg. Mawar No. 58, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000080001', 4, 2, 6, '1571010000081001', 'Laki-laki', '1970-01-07', 'Islam', 'Cerai Hidup', 'S2', 'Karyawan Swasta', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(9, 'Anwar Darmawan', 'Gg. Kenanga No. 28, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010000090001', 4, 1, 5, '1571010000091001', 'Laki-laki', '1959-11-27', 'Islam', 'Cerai Mati', 'S2', 'Buruh harian lepas', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(10, 'Joko Suryadi', 'Gg. Nusa Indah No. 56, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010000100001', 2, 1, 3, '1571010000101001', 'Laki-laki', '1976-12-01', 'Islam', 'Cerai Hidup', 'S1', 'PNS/ASN/TNI/Polri', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(11, 'Muhammad Kurniawan', 'Jl. Kuala Tungkal No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000110001', 1, 4, 5, '1571010000111001', 'Laki-laki', '1985-07-24', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(12, 'Puspita Apriliani', 'Jl. Ujung Tanjung No. 39, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000120001', 0, 2, 2, '1571010000121001', 'Perempuan', '1990-11-15', 'Kristen', 'Kawin', 'S1', 'Wirausaha', 'Sopir truk', 'Ya', 'Tidak', NULL, 1, 1),
(13, 'Zulkifli Maulana', 'Jl. Tepian Sungai No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010000130001', 2, 2, 4, '1571010000131001', 'Laki-laki', '1979-06-30', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 2, 1, 1),
(14, 'Lukman Yusuf', 'Gg. Nusa Indah No. 28, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010000140001', 2, 2, 4, '1571010000141001', 'Laki-laki', '1971-04-22', 'Islam', 'Kawin', 'SD', 'PNS/ASN/TNI/Polri', 'Tukang bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(15, 'Sahrul Kusuma', 'Gg. Cempaka No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000150001', 2, 1, 3, '1571010000151001', 'Laki-laki', '1969-08-06', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Karyawan Swasta', 'Karyawan toko', 'Tidak', 'Ya', 2, 1, 1),
(16, 'Ibrahim Kurniawan', 'Jl. Angso Duo No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000160001', 1, 2, 3, '1571010000161001', 'Laki-laki', '1995-10-29', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Karyawan toko', 'Tidak', 'Tidak', NULL, 1, 1),
(17, 'Qomar Suryadi', 'Jl. Pasar Baru No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000170001', 3, 2, 5, '1571010000171001', 'Laki-laki', '1986-05-04', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Perawat', 'Tidak', 'Tidak', NULL, 1, 1),
(18, 'Galih Ramadhan', 'Jl. Tepian Sungai No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000180001', 1, 0, 1, '1571010000181001', 'Laki-laki', '1989-11-06', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Sopir truk', 'Tidak', 'Tidak', NULL, 1, 1),
(19, 'Nasrul Salim', 'Jl. Tepian Sungai No. 56, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000190001', 3, 0, 3, '1571010000191001', 'Laki-laki', '1971-03-28', 'Islam', 'Belum Kawin', 'SD', 'Wirausaha', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(20, 'Iwan Abidin', 'Gg. Dahlia No. 20, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010000200001', 3, 1, 4, '1571010000201001', 'Laki-laki', '1966-03-03', 'Islam', 'Kawin', 'S1', 'PNS/ASN/TNI/Polri', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1),
(21, 'Arif Saputra', 'Jl. Ujung Tanjung No. 48, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010000210001', 2, 0, 2, '1571010000211001', 'Laki-laki', '1985-11-07', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Wirausaha', 'Sopir truk', 'Tidak', 'Tidak', NULL, 1, 1),
(22, 'Maya Marlinda', 'Jl. Batanghari Indah No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000220001', 4, 1, 5, '1571010000221001', 'Perempuan', '1986-09-28', 'Islam', 'Cerai Hidup', 'SD', 'Karyawan Swasta', 'Peternak ayam', 'Ya', 'Tidak', NULL, 1, 1),
(23, 'Nasrul Perkasa', 'Jl. Pelayangan Raya No. 11, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010000230001', 2, 3, 5, '1571010000231001', 'Laki-laki', '1994-04-25', 'Kristen', 'Kawin', 'S1', 'Wirausaha', 'Pengrajin anyaman', 'Ya', 'Tidak', NULL, 1, 1),
(24, 'Yusuf Hakim', 'Jl. Sungai Duren No. 6, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000240001', 4, 1, 5, '1571010000241001', 'Laki-laki', '1964-02-11', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1),
(25, 'Bambang Wijaya', 'Jl. Pasar Baru No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000250001', 3, 2, 5, '1571010000251001', 'Laki-laki', '1980-02-26', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Pedagang sembako', 'Ya', 'Tidak', NULL, 1, 1),
(26, 'Gita Maharani', 'Gg. Teratai No. 53, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000260001', 1, 1, 2, '1571010000261001', 'Perempuan', '1974-02-25', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Guru SD', 'Ya', 'Ya', 2, 1, 1),
(27, 'Yulia Ramadhani', 'Jl. Tepian Sungai No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010000270001', 3, 1, 4, '1571010000271001', 'Perempuan', '1990-11-15', 'Islam', 'Belum Kawin', 'S1', 'Lainnya', 'Peternak ayam', 'Tidak', 'Tidak', NULL, 1, 1),
(28, 'Munir Salim', 'Gg. Teratai No. 46, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000280001', 1, 3, 4, '1571010000281001', 'Laki-laki', '1986-04-13', 'Islam', 'Kawin', 'SMP', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(29, 'Oktavia Fitriani', 'Gg. Teratai No. 18, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010000290001', 3, 1, 4, '1571010000291001', 'Perempuan', '1982-08-25', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(30, 'Darma Maulana', 'Jl. Kuala Tungkal No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000300001', 2, 3, 5, '1571010000301001', 'Laki-laki', '1981-04-29', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Petani karet', 'Ya', 'Tidak', NULL, 1, 1),
(31, 'Jamal Hartono', 'Gg. Flamboyan No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000310001', 5, 1, 6, '1571010000311001', 'Laki-laki', '1992-02-24', 'Islam', 'Cerai Hidup', 'D1/D2/D3', 'Karyawan Swasta', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(32, 'Najib Yusuf', 'Gg. Cempaka No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000320001', 1, 1, 2, '1571010000321001', 'Laki-laki', '1999-09-25', 'Khonghucu', 'Kawin', 'S1', 'Lainnya', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(33, 'Sahrul Santoso', 'Jl. Batanghari Indah No. 58, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010000330001', 3, 0, 3, '1571010000331001', 'Laki-laki', '1983-01-03', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(34, 'Galih Nurdin', 'Jl. Angso Duo No. 59, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010000340001', 4, 0, 4, '1571010000341001', 'Laki-laki', '1960-09-17', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Tukang ojek', 'Ya', 'Tidak', NULL, 1, 1),
(35, 'Pandu Firmansyah', 'Jl. Simpang Rimbo No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000350001', 1, 1, 2, '1571010000351001', 'Laki-laki', '1977-05-09', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Wirausaha kuliner', 'Tidak', 'Tidak', NULL, 1, 1),
(36, 'Nasrul Nugroho', 'Jl. Ujung Tanjung No. 48, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010000360001', 3, 0, 3, '1571010000361001', 'Laki-laki', '1962-12-27', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Operator mesin', 'Tidak', 'Ya', 2, 1, 1),
(37, 'Amelia Fitriani', 'Gg. Nusa Indah No. 6, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000370001', 2, 1, 3, '1571010000371001', 'Perempuan', '1974-06-29', 'Islam', 'Kawin', 'S2', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(38, 'Puspita Maharani', 'Jl. Batanghari Indah No. 48, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000380001', 1, 4, 5, '1571010000381001', 'Perempuan', '1996-05-24', 'Islam', 'Kawin', 'S1', 'Lainnya', 'Pegawai bank', 'Tidak', 'Ya', 2, 1, 1),
(39, 'Karim Wibowo', 'Jl. Gentala Arasy No. 8, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000390001', 2, 0, 2, '1571010000391001', 'Laki-laki', '1961-01-15', 'Islam', 'Kawin', 'S2', 'Wirausaha', 'Pengrajin anyaman', 'Ya', 'Ya', 2, 1, 1),
(40, 'Hendra Amin', 'Jl. Simpang Rimbo No. 8, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000400001', 2, 0, 2, '1571010000401001', 'Laki-laki', '1969-04-29', 'Islam', 'Kawin', 'S2', 'Wirausaha', 'Perawat', 'Tidak', 'Tidak', NULL, 1, 1),
(41, 'Marwan Maulana', 'Jl. Angso Duo No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000410001', 2, 1, 3, '1571010000411001', 'Laki-laki', '1957-01-14', 'Katolik', 'Belum Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Peternak ayam', 'Tidak', 'Tidak', NULL, 1, 1),
(42, 'Yusuf Santoso', 'Gg. Flamboyan No. 6, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010000420001', 1, 6, 7, '1571010000421001', 'Laki-laki', '1979-09-07', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(43, 'Fajar Setiawan', 'Jl. Ujung Tanjung No. 1, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010000430001', 5, 0, 5, '1571010000431001', 'Laki-laki', '1966-09-14', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Wirausaha', 'Pegawai bank', 'Ya', 'Tidak', NULL, 1, 1),
(44, 'Herman Gunawan', 'Jl. Pelayangan Raya No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000440001', 1, 4, 5, '1571010000441001', 'Laki-laki', '1971-04-05', 'Islam', 'Kawin', 'SMA/SMK', 'Lainnya', 'Petani karet', 'Tidak', 'Tidak', NULL, 1, 1),
(45, 'Ratna Oktaviani', 'Gg. Flamboyan No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010000450001', 3, 2, 5, '1571010000451001', 'Perempuan', '1976-03-12', 'Islam', 'Kawin', 'SD', 'Wirausaha', 'Nelayan', 'Ya', 'Tidak', NULL, 1, 1),
(46, 'Jamal Kusnadi', 'Gg. Mawar No. 39, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010000460001', 2, 0, 2, '1571010000461001', 'Laki-laki', '1963-03-17', 'Islam', 'Kawin', 'S2', 'Karyawan Swasta', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(47, 'Ahmad Basuki', 'Gg. Flamboyan No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000470001', 2, 2, 4, '1571010000471001', 'Laki-laki', '1973-11-17', 'Katolik', 'Kawin', 'S1', 'Buruh harian lepas', 'Wirausaha kuliner', 'Ya', 'Tidak', NULL, 1, 1),
(48, 'Taufik Abidin', 'Gg. Nusa Indah No. 36, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010000480001', 3, 3, 6, '1571010000481001', 'Laki-laki', '1974-12-29', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Buruh bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(49, 'Yanto Abidin', 'Jl. Kuala Tungkal No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000490001', 2, 1, 3, '1571010000491001', 'Laki-laki', '1984-08-10', 'Islam', 'Cerai Mati', 'S2', 'Buruh harian lepas', 'Kasir minimarket', 'Tidak', 'Tidak', NULL, 1, 1),
(50, 'Umar Effendi', 'Gg. Kenanga No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010000500001', 2, 4, 6, '1571010000501001', 'Laki-laki', '2000-07-04', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Karyawan toko', 'Ya', 'Tidak', NULL, 1, 1),
(51, 'Bagus Santoso', 'Jl. Pasar Baru No. 20, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000510001', 5, 0, 5, '1571010000511001', 'Laki-laki', '1991-06-11', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Tukang bangunan', 'Tidak', 'Ya', 1, 1, 1),
(52, 'Najib Permana', 'Jl. Tepian Sungai No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000520001', 1, 0, 1, '1571010000521001', 'Laki-laki', '1958-11-12', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(53, 'Gani Kusuma', 'Jl. Tepian Sungai No. 1, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000530001', 3, 1, 4, '1571010000531001', 'Laki-laki', '1993-01-24', 'Islam', 'Cerai Hidup', 'SD', 'Wirausaha', 'Perawat', 'Ya', 'Ya', 1, 1, 1),
(54, 'Erwin Sofyan', 'Gg. Dahlia No. 28, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000540001', 1, 0, 1, '1571010000541001', 'Laki-laki', '1994-02-19', 'Islam', 'Cerai Mati', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 1, 1, 1),
(55, 'Bahtiar Amin', 'Gg. Dahlia No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000550001', 3, 0, 3, '1571010000551001', 'Laki-laki', '1979-08-15', 'Islam', 'Kawin', 'S2', 'Karyawan Swasta', 'Operator mesin', 'Tidak', 'Tidak', NULL, 1, 1),
(56, 'Dian Kusuma', 'Jl. Kuala Tungkal No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010000560001', 5, 0, 5, '1571010000561001', 'Laki-laki', '1962-06-06', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1),
(57, 'Latif Perkasa', 'Gg. Cempaka No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000570001', 1, 4, 5, '1571010000571001', 'Laki-laki', '1960-11-06', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Petani karet', 'Ya', 'Tidak', NULL, 1, 1),
(58, 'Kadir Alamsyah', 'Jl. Ujung Tanjung No. 39, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000580001', 2, 4, 6, '1571010000581001', 'Laki-laki', '1999-04-06', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Petani karet', 'Tidak', 'Tidak', NULL, 1, 1),
(59, 'Muhammad Iskandar', 'Gg. Melati No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000590001', 3, 4, 7, '1571010000591001', 'Laki-laki', '1956-03-24', 'Islam', 'Kawin', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(60, 'Anwar Sofyan', 'Gg. Cempaka No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000600001', 3, 4, 7, '1571010000601001', 'Laki-laki', '1985-11-03', 'Islam', 'Kawin', 'SMP', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(61, 'Bagus Amin', 'Gg. Nusa Indah No. 39, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000610001', 2, 2, 4, '1571010000611001', 'Laki-laki', '1966-01-21', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Buruh pelabuhan', 'Tidak', 'Tidak', NULL, 1, 1),
(62, 'Eko Darmawan', 'Jl. Pasar Baru No. 20, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000620001', 3, 0, 3, '1571010000621001', 'Laki-laki', '1969-07-16', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(63, 'Syamsuddin Wibowo', 'Jl. Pelayangan Raya No. 43, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000630001', 2, 0, 2, '1571010000631001', 'Laki-laki', '1991-06-16', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Guru SMP', 'Tidak', 'Tidak', NULL, 1, 1),
(64, 'Qomar Salim', 'Gg. Flamboyan No. 15, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010000640001', 1, 3, 4, '1571010000641001', 'Laki-laki', '1989-01-11', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(65, 'Sri Setiawati', 'Jl. Ujung Tanjung No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000650001', 0, 4, 4, '1571010000651001', 'Perempuan', '1971-01-16', 'Islam', 'Kawin', 'SD', 'PNS/ASN/TNI/Polri', 'Bidan desa', 'Ya', 'Tidak', NULL, 1, 1),
(66, 'Sari Puspita', 'Gg. Teratai No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000660001', 3, 3, 6, '1571010000661001', 'Perempuan', '1972-12-23', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Pedagang sembako', 'Tidak', 'Ya', 1, 1, 1),
(67, 'Hendra Sofyan', 'Gg. Cempaka No. 51, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000670001', 2, 3, 5, '1571010000671001', 'Laki-laki', '1971-12-14', 'Islam', 'Kawin', 'SD', 'Buruh harian lepas', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(68, 'Nasrul Iskandar', 'Jl. Ujung Tanjung No. 34, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000680001', 1, 0, 1, '1571010000681001', 'Laki-laki', '1981-05-05', 'Islam', 'Cerai Hidup', 'SD', 'Buruh harian lepas', 'Operator mesin', 'Tidak', 'Tidak', NULL, 1, 1),
(69, 'Fajar Sofyan', 'Gg. Teratai No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000690001', 3, 1, 4, '1571010000691001', 'Laki-laki', '1973-01-02', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Buruh bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(70, 'Wati Rahayu', 'Gg. Teratai No. 51, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000700001', 2, 2, 4, '1571010000701001', 'Perempuan', '1970-02-14', 'Islam', 'Kawin', 'SD', 'Wirausaha', 'Perawat', 'Tidak', 'Ya', 2, 1, 1),
(71, 'Umar Kusuma', 'Gg. Nusa Indah No. 3, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000710001', 4, 3, 7, '1571010000711001', 'Laki-laki', '1958-04-21', 'Islam', 'Belum Kawin', 'S1', 'Buruh harian lepas', 'Guru SD', 'Ya', 'Ya', 1, 1, 1),
(72, 'Bahtiar Yusuf', 'Gg. Cempaka No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000720001', 1, 0, 1, '1571010000721001', 'Laki-laki', '1970-09-17', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 1, 1, 1),
(73, 'Halim Wibowo', 'Jl. Simpang Rimbo No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010000730001', 1, 3, 4, '1571010000731001', 'Laki-laki', '1979-07-11', 'Islam', 'Cerai Hidup', 'SD', 'Karyawan Swasta', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(74, 'Bambang Purnomo', 'Jl. Mudung Laut Ujung No. 35, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000740001', 2, 1, 3, '1571010000741001', 'Laki-laki', '1981-11-07', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Petani karet', 'Tidak', 'Tidak', NULL, 1, 1),
(75, 'Slamet Gunawan', 'Jl. Ujung Tanjung No. 28, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000750001', 1, 2, 3, '1571010000751001', 'Laki-laki', '1959-10-15', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Pengrajin anyaman', 'Tidak', 'Tidak', NULL, 1, 1),
(76, 'Xaverius Ramadhan', 'Gg. Nusa Indah No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000760001', 1, 0, 1, '1571010000761001', 'Laki-laki', '1977-08-03', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Bidan desa', 'Ya', 'Ya', 1, 1, 1),
(77, 'Iwan Abidin', 'Gg. Mawar No. 21, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000770001', 1, 3, 4, '1571010000771001', 'Laki-laki', '1999-07-10', 'Kristen', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(78, 'Wahyu Perkasa', 'Jl. Angso Duo No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000780001', 1, 6, 7, '1571010000781001', 'Laki-laki', '1990-04-01', 'Islam', 'Cerai Hidup', 'D1/D2/D3', 'Karyawan Swasta', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(79, 'Hasan Ramadhan', 'Jl. Mudung Laut Ujung No. 46, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000790001', 2, 0, 2, '1571010000791001', 'Laki-laki', '1968-08-17', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(80, 'Irwan Gunawan', 'Jl. Gentala Arasy No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000800001', 2, 5, 7, '1571010000801001', 'Laki-laki', '1982-02-12', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(81, 'Vino Setiawan', 'Gg. Melati No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010000810001', 3, 1, 4, '1571010000811001', 'Laki-laki', '1966-10-18', 'Islam', 'Belum Kawin', 'SD', 'Karyawan Swasta', 'Sopir angkot', 'Ya', 'Tidak', NULL, 1, 1),
(82, 'Devi Wulandari', 'Jl. Kuala Tungkal No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000820001', 1, 1, 2, '1571010000821001', 'Perempuan', '1995-09-14', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Peternak ayam', 'Ya', 'Tidak', NULL, 1, 1),
(83, 'Umar Maulana', 'Gg. Nusa Indah No. 11, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010000830001', 1, 0, 1, '1571010000831001', 'Laki-laki', '1999-03-25', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Penjahit', 'Tidak', 'Ya', 1, 1, 1),
(84, 'Candra Amin', 'Jl. Batanghari Indah No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000840001', 4, 1, 5, '1571010000841001', 'Laki-laki', '1971-03-16', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Nelayan', 'Ya', 'Tidak', NULL, 1, 1),
(85, 'Yanto Kusnadi', 'Jl. Pasar Baru No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000850001', 2, 1, 3, '1571010000851001', 'Laki-laki', '1965-04-19', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Sopir angkot', 'Tidak', 'Tidak', NULL, 1, 1),
(86, 'Nurhayati Anggraini', 'Jl. Simpang Rimbo No. 16, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000860001', 0, 2, 2, '1571010000861001', 'Perempuan', '1964-11-16', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 2, 1, 1),
(87, 'Wulandari Damayanti', 'Gg. Teratai No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000870001', 0, 1, 1, '1571010000871001', 'Perempuan', '1978-02-19', 'Islam', 'Cerai Mati', 'S1', 'PNS/ASN/TNI/Polri', 'Petani sawit', 'Tidak', 'Tidak', NULL, 1, 1),
(88, 'Candra Ramadhan', 'Gg. Kenanga No. 47, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000880001', 1, 0, 1, '1571010000881001', 'Laki-laki', '1999-02-15', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Karyawan toko', 'Tidak', 'Tidak', NULL, 1, 1),
(89, 'Syamsuddin Riyadi', 'Jl. Ujung Tanjung No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000890001', 3, 2, 5, '1571010000891001', 'Laki-laki', '1976-01-18', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Karyawan toko', 'Tidak', 'Ya', 1, 1, 1),
(90, 'Latif Permana', 'Gg. Nusa Indah No. 46, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000900001', 3, 1, 4, '1571010000901001', 'Laki-laki', '1971-06-02', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Pengrajin anyaman', 'Tidak', 'Tidak', NULL, 1, 1),
(91, 'Farida Oktaviani', 'Gg. Cempaka No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000910001', 0, 3, 3, '1571010000911001', 'Perempuan', '1956-07-30', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Pegawai bank', 'Tidak', 'Tidak', NULL, 1, 1),
(92, 'Galih Santoso', 'Jl. Sungai Duren No. 39, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010000920001', 1, 1, 2, '1571010000921001', 'Laki-laki', '1964-05-06', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Sopir truk', 'Ya', 'Ya', 2, 1, 1),
(93, 'Arif Syarif', 'Jl. Simpang Rimbo No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010000930001', 1, 5, 6, '1571010000931001', 'Laki-laki', '1969-09-18', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Karyawan pabrik', 'Tidak', 'Tidak', NULL, 1, 1),
(94, 'Umi Purnamasari', 'Gg. Mawar No. 21, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010000940001', 2, 1, 3, '1571010000941001', 'Perempuan', '1980-07-13', 'Islam', 'Cerai Hidup', 'S1', 'Buruh harian lepas', 'Guru SMP', 'Ya', 'Tidak', NULL, 1, 1),
(95, 'Arif Hidayat', 'Jl. Batanghari Indah No. 50, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010000950001', 1, 2, 3, '1571010000951001', 'Laki-laki', '1981-05-06', 'Islam', 'Kawin', 'S2', 'Wirausaha', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(96, 'Bagus Effendi', 'Gg. Nusa Indah No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010000960001', 2, 1, 3, '1571010000961001', 'Laki-laki', '1973-11-02', 'Islam', 'Cerai Hidup', 'S2', 'Karyawan Swasta', 'Nelayan', 'Ya', 'Tidak', NULL, 1, 1),
(97, 'Fauzan Nugroho', 'Jl. Kuala Tungkal No. 16, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000970001', 1, 2, 3, '1571010000971001', 'Laki-laki', '1997-04-13', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Satpam', 'Tidak', 'Ya', 2, 1, 1),
(98, 'Nasrul Basuki', 'Jl. Angso Duo No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010000980001', 1, 0, 1, '1571010000981001', 'Laki-laki', '1983-10-24', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Perawat', 'Tidak', 'Ya', 1, 1, 1),
(99, 'Ani Rahayu', 'Jl. Simpang Rimbo No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010000990001', 2, 4, 6, '1571010000991001', 'Perempuan', '1969-07-10', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(100, 'Rahmat Kusnadi', 'Jl. Gentala Arasy No. 34, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001000001', 2, 0, 2, '1571010001001001', 'Laki-laki', '1971-10-07', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Petani sawit', 'Tidak', 'Tidak', NULL, 1, 1);
INSERT INTO keluarga (id, nama_kepala_keluarga, alamat, rt_id, nomor_kk, jumlah_lk, jumlah_pr, jumlah_total, nik_kepala_keluarga, jenis_kelamin_kepala_keluarga, tanggal_lahir_kepala_keluarga, agama_kepala_keluarga, status_perkawinan_kepala_keluarga, pendidikan_kepala_keluarga, status_pekerjaan_kepala_keluarga, pekerjaan_kepala_keluarga, pernah_bantuan, ada_umkm, jumlah_anggota_umkm, created_by, updated_by) VALUES
(101, 'Hasan Halim', 'Gg. Dahlia No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010001010001', 2, 1, 3, '1571010001011001', 'Laki-laki', '1974-06-12', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Kasir minimarket', 'Ya', 'Tidak', NULL, 1, 1),
(102, 'Taufik Amin', 'Jl. Kuala Tungkal No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001020001', 1, 0, 1, '1571010001021001', 'Laki-laki', '1964-08-09', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Tukang bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(103, 'Suryani Ramadhani', 'Gg. Teratai No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010001030001', 2, 4, 6, '1571010001031001', 'Perempuan', '1994-10-17', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Tukang bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(104, 'Latif Yusuf', 'Jl. Simpang Rimbo No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010001040001', 1, 4, 5, '1571010001041001', 'Laki-laki', '1958-08-12', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Buruh bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(105, 'Dian Yusuf', 'Jl. Pelayangan Raya No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001050001', 1, 2, 3, '1571010001051001', 'Laki-laki', '1991-06-18', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Karyawan toko', 'Tidak', 'Ya', 1, 1, 1),
(106, 'Slamet Alamsyah', 'Gg. Teratai No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001060001', 5, 0, 5, '1571010001061001', 'Laki-laki', '1972-11-19', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Karyawan Swasta', 'Petani karet', 'Tidak', 'Tidak', NULL, 1, 1),
(107, 'Fitri Oktaviani', 'Jl. Gentala Arasy No. 4, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001070001', 0, 3, 3, '1571010001071001', 'Perempuan', '1998-10-21', 'Islam', 'Cerai Mati', 'S1', 'Wirausaha', 'Operator mesin', 'Tidak', 'Tidak', NULL, 1, 1),
(108, 'Rahmat Effendi', 'Gg. Mawar No. 25, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001080001', 4, 3, 7, '1571010001081001', 'Laki-laki', '1993-07-02', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(109, 'Firman Yusuf', 'Gg. Flamboyan No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001090001', 2, 1, 3, '1571010001091001', 'Laki-laki', '1976-08-23', 'Islam', 'Kawin', 'SD', 'Buruh harian lepas', 'Buruh pelabuhan', 'Tidak', 'Tidak', NULL, 1, 1),
(110, 'Ahmad Maulana', 'Jl. Sungai Duren No. 16, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001100001', 4, 0, 4, '1571010001101001', 'Laki-laki', '1973-09-04', 'Islam', 'Kawin', 'S1', 'PNS/ASN/TNI/Polri', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(111, 'Anita Fitriani', 'Gg. Nusa Indah No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001110001', 2, 2, 4, '1571010001111001', 'Perempuan', '1964-11-22', 'Islam', 'Cerai Mati', 'S2', 'PNS/ASN/TNI/Polri', 'Sopir angkot', 'Ya', 'Tidak', NULL, 1, 1),
(112, 'Hasan Wardana', 'Gg. Dahlia No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001120001', 1, 0, 1, '1571010001121001', 'Laki-laki', '1966-05-23', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(113, 'Latif Iskandar', 'Gg. Nusa Indah No. 20, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010001130001', 4, 1, 5, '1571010001131001', 'Laki-laki', '1986-11-04', 'Islam', 'Cerai Mati', 'S1', 'Lainnya', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(114, 'Bagus Perkasa', 'Gg. Kenanga No. 14, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001140001', 3, 1, 4, '1571010001141001', 'Laki-laki', '1977-04-05', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(115, 'Taufik Amin', 'Jl. Gentala Arasy No. 14, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010001150001', 1, 5, 6, '1571010001151001', 'Laki-laki', '2000-08-04', 'Islam', 'Cerai Hidup', 'SMA/SMK', 'Karyawan Swasta', 'Sopir truk', 'Ya', 'Tidak', NULL, 1, 1),
(116, 'Zaki Nurdin', 'Jl. Gentala Arasy No. 21, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001160001', 2, 1, 3, '1571010001161001', 'Laki-laki', '1967-10-27', 'Islam', 'Cerai Hidup', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(117, 'Rizal Syarif', 'Gg. Cempaka No. 59, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001170001', 1, 5, 6, '1571010001171001', 'Laki-laki', '1999-07-31', 'Islam', 'Kawin', 'S1', 'PNS/ASN/TNI/Polri', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(118, 'Umar Suryadi', 'Jl. Kuala Tungkal No. 32, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010001180001', 2, 3, 5, '1571010001181001', 'Laki-laki', '1970-10-20', 'Islam', 'Belum Kawin', 'SMP', 'Karyawan Swasta', 'Pedagang kaki lima', 'Ya', 'Tidak', NULL, 1, 1),
(119, 'Wahyu Santoso', 'Jl. Pelayangan Raya No. 34, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001190001', 2, 0, 2, '1571010001191001', 'Laki-laki', '2001-02-26', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Buruh bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(120, 'Najib Kurniawan', 'Jl. Ujung Tanjung No. 59, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001200001', 4, 0, 4, '1571010001201001', 'Laki-laki', '2001-06-28', 'Islam', 'Kawin', 'S2', 'Lainnya', 'Petani sawit', 'Tidak', 'Tidak', NULL, 1, 1),
(121, 'Fatimah Utami', 'Jl. Simpang Rimbo No. 52, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001210001', 0, 2, 2, '1571010001211001', 'Perempuan', '1995-06-21', 'Islam', 'Kawin', 'D1/D2/D3', 'PNS/ASN/TNI/Polri', 'PNS Kelurahan', 'Ya', 'Tidak', NULL, 1, 1),
(122, 'Fauzan Amin', 'Gg. Flamboyan No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001220001', 4, 0, 4, '1571010001221001', 'Laki-laki', '1957-03-24', 'Islam', 'Kawin', 'S2', 'Wirausaha', 'Peternak ayam', 'Ya', 'Ya', 2, 1, 1),
(123, 'Ahmad Permana', 'Jl. Simpang Rimbo No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001230001', 1, 2, 3, '1571010001231001', 'Laki-laki', '1998-08-24', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(124, 'Hasan Basuki', 'Jl. Gentala Arasy No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001240001', 1, 3, 4, '1571010001241001', 'Laki-laki', '1999-08-01', 'Kristen', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Tukang kayu', 'Tidak', 'Tidak', NULL, 1, 1),
(125, 'Rahmat Purnomo', 'Gg. Cempaka No. 25, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001250001', 1, 0, 1, '1571010001251001', 'Laki-laki', '1968-12-20', 'Islam', 'Cerai Hidup', 'S1', 'Lainnya', 'Karyawan pabrik', 'Ya', 'Tidak', NULL, 1, 1),
(126, 'Zaki Wardana', 'Gg. Flamboyan No. 32, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001260001', 1, 3, 4, '1571010001261001', 'Laki-laki', '1990-11-28', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Pedagang sembako', 'Ya', 'Tidak', NULL, 1, 1),
(127, 'Xaverius Riyadi', 'Gg. Nusa Indah No. 48, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001270001', 3, 3, 6, '1571010001271001', 'Laki-laki', '1995-01-06', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(128, 'Wawan Alamsyah', 'Jl. Simpang Rimbo No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001280001', 2, 2, 4, '1571010001281001', 'Laki-laki', '1996-09-03', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(129, 'Zaki Wijaya', 'Jl. Kuala Tungkal No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010001290001', 2, 1, 3, '1571010001291001', 'Laki-laki', '1992-10-02', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Pedagang kaki lima', 'Tidak', 'Tidak', NULL, 1, 1),
(130, 'Dian Nurdin', 'Jl. Kuala Tungkal No. 47, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010001300001', 2, 1, 3, '1571010001301001', 'Laki-laki', '1994-05-19', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(131, 'Dian Salim', 'Jl. Ujung Tanjung No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001310001', 5, 2, 7, '1571010001311001', 'Laki-laki', '1980-06-30', 'Islam', 'Kawin', 'S1', 'Lainnya', 'Pegawai bank', 'Ya', 'Tidak', NULL, 1, 1),
(132, 'Dian Yusuf', 'Gg. Mawar No. 24, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001320001', 5, 0, 5, '1571010001321001', 'Laki-laki', '1990-11-30', 'Katolik', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Sopir angkot', 'Tidak', 'Ya', 2, 1, 1),
(133, 'Hadi Suryadi', 'Jl. Angso Duo No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001330001', 2, 3, 5, '1571010001331001', 'Laki-laki', '1958-06-07', 'Islam', 'Cerai Hidup', 'S1', 'Karyawan Swasta', 'Kasir minimarket', 'Tidak', 'Tidak', NULL, 1, 1),
(134, 'Xaverius Yusuf', 'Jl. Gentala Arasy No. 3, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010001340001', 6, 0, 6, '1571010001341001', 'Laki-laki', '1963-10-16', 'Islam', 'Kawin', 'D1/D2/D3', 'Buruh harian lepas', 'Pengrajin anyaman', 'Ya', 'Tidak', NULL, 1, 1),
(135, 'Gani Riyadi', 'Gg. Mawar No. 49, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001350001', 1, 2, 3, '1571010001351001', 'Laki-laki', '2000-04-10', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(136, 'Agus Salim', 'Gg. Teratai No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001360001', 3, 0, 3, '1571010001361001', 'Laki-laki', '1994-10-30', 'Islam', 'Belum Kawin', 'D1/D2/D3', 'Wirausaha', 'Tukang bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(137, 'Ibrahim Basuki', 'Jl. Pasar Baru No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001370001', 1, 0, 1, '1571010001371001', 'Laki-laki', '1996-11-03', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Buruh pelabuhan', 'Tidak', 'Tidak', NULL, 1, 1),
(138, 'Doni Darmawan', 'Jl. Kuala Tungkal No. 34, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001380001', 6, 1, 7, '1571010001381001', 'Laki-laki', '1966-03-13', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(139, 'Anwar Hartono', 'Gg. Anggrek No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001390001', 1, 2, 3, '1571010001391001', 'Laki-laki', '1955-08-08', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(140, 'Najib Permana', 'Gg. Anggrek No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001400001', 1, 3, 4, '1571010001401001', 'Laki-laki', '1960-11-16', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Wirausaha kuliner', 'Tidak', 'Tidak', NULL, 1, 1),
(141, 'Rahmat Basuki', 'Jl. Ujung Tanjung No. 38, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001410001', 3, 0, 3, '1571010001411001', 'Laki-laki', '1993-09-02', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Nelayan', 'Tidak', 'Tidak', NULL, 1, 1),
(142, 'Hasan Alamsyah', 'Jl. Angso Duo No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001420001', 3, 0, 3, '1571010001421001', 'Laki-laki', '1991-05-17', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(143, 'Omar Syarif', 'Gg. Anggrek No. 53, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001430001', 2, 1, 3, '1571010001431001', 'Laki-laki', '1958-05-19', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Ya', 'Ya', 1, 1, 1),
(144, 'Jamal Hidayat', 'Jl. Gentala Arasy No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010001440001', 2, 0, 2, '1571010001441001', 'Laki-laki', '1966-06-08', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Bidan desa', 'Ya', 'Tidak', NULL, 1, 1),
(145, 'Rahma Fitriani', 'Jl. Gentala Arasy No. 14, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010001450001', 0, 3, 3, '1571010001451001', 'Perempuan', '1959-09-11', 'Islam', 'Kawin', 'SD', 'Wirausaha', 'Pedagang sayur', 'Tidak', 'Tidak', NULL, 1, 1),
(146, 'Firman Wijaya', 'Gg. Dahlia No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001460001', 4, 1, 5, '1571010001461001', 'Laki-laki', '1961-05-23', 'Islam', 'Kawin', 'S2', 'PNS/ASN/TNI/Polri', 'Satpam', 'Ya', 'Tidak', NULL, 1, 1),
(147, 'Ahmad Setiawan', 'Jl. Batanghari Indah No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001470001', 1, 6, 7, '1571010001471001', 'Laki-laki', '1974-03-02', 'Islam', 'Kawin', 'SMP', 'PNS/ASN/TNI/Polri', 'Sopir truk', 'Tidak', 'Tidak', NULL, 1, 1),
(148, 'Lukman Syarif', 'Gg. Mawar No. 32, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001480001', 2, 0, 2, '1571010001481001', 'Laki-laki', '1977-04-07', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Pedagang kaki lima', 'Tidak', 'Ya', 1, 1, 1),
(149, 'Wawan Gunawan', 'Gg. Flamboyan No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001490001', 2, 1, 3, '1571010001491001', 'Laki-laki', '1967-02-12', 'Islam', 'Kawin', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(150, 'Umar Santoso', 'Gg. Dahlia No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001500001', 1, 3, 4, '1571010001501001', 'Laki-laki', '1998-04-12', 'Islam', 'Belum Kawin', 'S1', 'Wirausaha', 'Penjahit', 'Ya', 'Tidak', NULL, 1, 1),
(151, 'Doni Hakim', 'Gg. Nusa Indah No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001510001', 3, 0, 3, '1571010001511001', 'Laki-laki', '1996-11-01', 'Islam', 'Belum Kawin', 'Tidak/Belum Sekolah', 'Wirausaha', 'Sopir angkot', 'Tidak', 'Tidak', NULL, 1, 1),
(152, 'Ahmad Hartono', 'Jl. Simpang Rimbo No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001520001', 2, 0, 2, '1571010001521001', 'Laki-laki', '1988-05-03', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Wirausaha kuliner', 'Ya', 'Tidak', NULL, 1, 1),
(153, 'Anwar Purnomo', 'Gg. Nusa Indah No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001530001', 2, 1, 3, '1571010001531001', 'Laki-laki', '1994-04-16', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Buruh pelabuhan', 'Ya', 'Tidak', NULL, 1, 1),
(154, 'Halim Effendi', 'Jl. Sungai Duren No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001540001', 2, 3, 5, '1571010001541001', 'Laki-laki', '1988-10-05', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Pedagang sayur', 'Ya', 'Ya', 2, 1, 1),
(155, 'Rahmat Iskandar', 'Jl. Pasar Baru No. 28, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001550001', 1, 1, 2, '1571010001551001', 'Laki-laki', '1984-10-22', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Pengrajin anyaman', 'Tidak', 'Tidak', NULL, 1, 1),
(156, 'Hadi Hidayat', 'Jl. Batanghari Indah No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010001560001', 1, 2, 3, '1571010001561001', 'Laki-laki', '1976-04-25', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Lainnya', 'Kasir minimarket', 'Ya', 'Tidak', NULL, 1, 1),
(157, 'Hasan Salim', 'Gg. Dahlia No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001570001', 4, 0, 4, '1571010001571001', 'Laki-laki', '1996-01-18', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Lainnya', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(158, 'Candra Purnomo', 'Gg. Teratai No. 50, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001580001', 3, 1, 4, '1571010001581001', 'Laki-laki', '1961-07-03', 'Islam', 'Kawin', 'S2', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 2, 1, 1),
(159, 'Zainal Amin', 'Gg. Mawar No. 38, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001590001', 4, 1, 5, '1571010001591001', 'Laki-laki', '1957-03-23', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Pengrajin anyaman', 'Tidak', 'Tidak', NULL, 1, 1),
(160, 'Rahmat Hartono', 'Jl. Mudung Laut Ujung No. 8, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001600001', 3, 4, 7, '1571010001601001', 'Laki-laki', '1991-05-24', 'Islam', 'Cerai Hidup', 'SMP', 'Wirausaha', 'Perawat', 'Tidak', 'Tidak', NULL, 1, 1),
(161, 'Salsabila Kartika', 'Jl. Tepian Sungai No. 50, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001610001', 0, 2, 2, '1571010001611001', 'Perempuan', '1984-06-20', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Wirausaha', 'Montir bengkel', 'Ya', 'Ya', 1, 1, 1),
(162, 'Galih Kusnadi', 'Gg. Dahlia No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001620001', 5, 0, 5, '1571010001621001', 'Laki-laki', '2000-02-15', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(163, 'Erwin Nugroho', 'Jl. Pelayangan Raya No. 36, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001630001', 1, 2, 3, '1571010001631001', 'Laki-laki', '1980-09-11', 'Islam', 'Cerai Mati', 'D1/D2/D3', 'Buruh harian lepas', 'Buruh pelabuhan', 'Tidak', 'Ya', 1, 1, 1),
(164, 'Oktavia Apriliani', 'Gg. Mawar No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010001640001', 1, 1, 2, '1571010001641001', 'Perempuan', '1981-12-02', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Guru SMP', 'Tidak', 'Tidak', NULL, 1, 1),
(165, 'Iwan Prasetyo', 'Jl. Angso Duo No. 50, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001650001', 1, 0, 1, '1571010001651001', 'Laki-laki', '2001-02-23', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Lainnya', 'Petani sawit', 'Tidak', 'Tidak', NULL, 1, 1),
(166, 'Hadi Syarif', 'Jl. Batanghari Indah No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001660001', 6, 1, 7, '1571010001661001', 'Laki-laki', '1969-03-03', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(167, 'Indah Damayanti', 'Jl. Pasar Baru No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001670001', 1, 1, 2, '1571010001671001', 'Perempuan', '1995-06-02', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Nelayan', 'Ya', 'Tidak', NULL, 1, 1),
(168, 'Sahrul Basuki', 'Gg. Cempaka No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001680001', 3, 0, 3, '1571010001681001', 'Laki-laki', '1972-10-05', 'Islam', 'Kawin', 'SD', 'Buruh harian lepas', 'Tukang ojek', 'Tidak', 'Tidak', NULL, 1, 1),
(169, 'Arif Perkasa', 'Jl. Tepian Sungai No. 35, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001690001', 3, 0, 3, '1571010001691001', 'Laki-laki', '1982-04-20', 'Islam', 'Cerai Hidup', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Tukang kayu', 'Tidak', 'Ya', 1, 1, 1),
(170, 'Pandu Suryadi', 'Jl. Pasar Baru No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001700001', 1, 6, 7, '1571010001701001', 'Laki-laki', '1989-02-01', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Pedagang sayur', 'Tidak', 'Ya', 1, 1, 1),
(171, 'Fauzan Setiawan', 'Jl. Pelayangan Raya No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001710001', 1, 2, 3, '1571010001711001', 'Laki-laki', '1989-02-14', 'Kristen', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(172, 'Syamsuddin Purnomo', 'Gg. Anggrek No. 58, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001720001', 1, 0, 1, '1571010001721001', 'Laki-laki', '1979-05-06', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 1, 1, 1),
(173, 'Ridwan Hakim', 'Jl. Mudung Laut Ujung No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010001730001', 6, 0, 6, '1571010001731001', 'Laki-laki', '1984-04-01', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Operator mesin', 'Tidak', 'Ya', 2, 1, 1),
(174, 'Iwan Yusuf', 'Gg. Mawar No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001740001', 3, 2, 5, '1571010001741001', 'Laki-laki', '2000-01-27', 'Islam', 'Cerai Hidup', 'S2', 'Wirausaha', 'Wiraswasta warung', 'Ya', 'Tidak', NULL, 1, 1),
(175, 'Widyawati Ningsih', 'Jl. Kuala Tungkal No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010001750001', 2, 1, 3, '1571010001751001', 'Perempuan', '1971-06-27', 'Khonghucu', 'Belum Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Wiraswasta warung', 'Tidak', 'Tidak', NULL, 1, 1),
(176, 'Ningsih Damayanti', 'Jl. Pelayangan Raya No. 49, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001760001', 1, 5, 6, '1571010001761001', 'Perempuan', '1976-12-29', 'Islam', 'Kawin', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(177, 'Yudi Hidayat', 'Gg. Dahlia No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001770001', 2, 0, 2, '1571010001771001', 'Laki-laki', '1966-11-13', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Pedagang kaki lima', 'Ya', 'Tidak', NULL, 1, 1),
(178, 'Hasan Basuki', 'Gg. Anggrek No. 52, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001780001', 2, 0, 2, '1571010001781001', 'Laki-laki', '1997-01-23', 'Islam', 'Cerai Hidup', 'SD', 'Wirausaha', 'Buruh pelabuhan', 'Tidak', 'Ya', 2, 1, 1),
(179, 'Ratih Setiawati', 'Gg. Cempaka No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001790001', 2, 1, 3, '1571010001791001', 'Perempuan', '1970-10-27', 'Katolik', 'Kawin', 'D1/D2/D3', 'PNS/ASN/TNI/Polri', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1),
(180, 'Rudi Halim', 'Jl. Batanghari Indah No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001800001', 1, 1, 2, '1571010001801001', 'Laki-laki', '1964-02-03', 'Kristen', 'Belum Kawin', 'SD', 'Lainnya', 'Nelayan', 'Tidak', 'Ya', 2, 1, 1),
(181, 'Irwan Darmawan', 'Gg. Cempaka No. 11, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010001810001', 3, 0, 3, '1571010001811001', 'Laki-laki', '1972-01-12', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Petani karet', 'Tidak', 'Tidak', NULL, 1, 1),
(182, 'Zaki Effendi', 'Jl. Mudung Laut Ujung No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010001820001', 1, 1, 2, '1571010001821001', 'Laki-laki', '1967-01-20', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Pedagang sembako', 'Tidak', 'Ya', 1, 1, 1),
(183, 'Maya Anggraini', 'Gg. Cempaka No. 17, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001830001', 0, 2, 2, '1571010001831001', 'Perempuan', '1991-01-20', 'Islam', 'Belum Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Pengrajin anyaman', 'Tidak', 'Tidak', NULL, 1, 1),
(184, 'Gani Wijaya', 'Jl. Simpang Rimbo No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010001840001', 3, 0, 3, '1571010001841001', 'Laki-laki', '1997-04-14', 'Islam', 'Kawin', 'S2', 'PNS/ASN/TNI/Polri', 'Sopir angkot', 'Ya', 'Ya', 2, 1, 1),
(185, 'Rosnani Ningsih', 'Gg. Dahlia No. 36, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001850001', 2, 2, 4, '1571010001851001', 'Perempuan', '1977-01-04', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Petani sawit', 'Ya', 'Tidak', NULL, 1, 1),
(186, 'Suryani Rahayu', 'Gg. Melati No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001860001', 2, 4, 6, '1571010001861001', 'Perempuan', '1971-05-16', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(187, 'Fauzan Hakim', 'Gg. Kenanga No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001870001', 2, 0, 2, '1571010001871001', 'Laki-laki', '1964-03-04', 'Islam', 'Kawin', 'S2', 'Wirausaha', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(188, 'Latif Iskandar', 'Gg. Mawar No. 53, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010001880001', 2, 0, 2, '1571010001881001', 'Laki-laki', '1970-11-03', 'Islam', 'Cerai Mati', 'SMP', 'Buruh harian lepas', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(189, 'Syamsuddin Maulana', 'Jl. Mudung Laut Ujung No. 14, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010001890001', 4, 3, 7, '1571010001891001', 'Laki-laki', '1973-03-22', 'Islam', 'Belum Kawin', 'SMA/SMK', 'Wirausaha', 'Perawat', 'Tidak', 'Ya', 2, 1, 1),
(190, 'Marwan Permana', 'Jl. Gentala Arasy No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001900001', 1, 4, 5, '1571010001901001', 'Laki-laki', '1971-01-13', 'Islam', 'Belum Kawin', 'S1', 'Buruh harian lepas', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1),
(191, 'Ahmad Sofyan', 'Jl. Tepian Sungai No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010001910001', 4, 2, 6, '1571010001911001', 'Laki-laki', '1966-12-19', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Wiraswasta warung', 'Tidak', 'Tidak', NULL, 1, 1),
(192, 'Taufik Iskandar', 'Gg. Mawar No. 3, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001920001', 4, 2, 6, '1571010001921001', 'Laki-laki', '1998-05-02', 'Islam', 'Cerai Hidup', 'SMA/SMK', 'PNS/ASN/TNI/Polri', 'Pedagang kaki lima', 'Tidak', 'Tidak', NULL, 1, 1),
(193, 'Halim Basuki', 'Jl. Kuala Tungkal No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010001930001', 4, 0, 4, '1571010001931001', 'Laki-laki', '1984-03-02', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(194, 'Zainal Amin', 'Jl. Pelayangan Raya No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010001940001', 1, 2, 3, '1571010001941001', 'Laki-laki', '1956-06-02', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Ya', 'Ya', 1, 1, 1),
(195, 'Utami Susanti', 'Gg. Flamboyan No. 4, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010001950001', 0, 4, 4, '1571010001951001', 'Perempuan', '1978-04-21', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Tukang ojek', 'Tidak', 'Tidak', NULL, 1, 1),
(196, 'Karim Purnomo', 'Jl. Gentala Arasy No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001960001', 3, 0, 3, '1571010001961001', 'Laki-laki', '1982-01-29', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(197, 'Yusuf Hartono', 'Gg. Kenanga No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010001970001', 4, 0, 4, '1571010001971001', 'Laki-laki', '1970-05-16', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Sopir truk', 'Tidak', 'Tidak', NULL, 1, 1),
(198, 'Johan Saputra', 'Gg. Mawar No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010001980001', 1, 3, 4, '1571010001981001', 'Laki-laki', '1971-11-06', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Pengrajin anyaman', 'Tidak', 'Tidak', NULL, 1, 1),
(199, 'Marwan Basuki', 'Jl. Tepian Sungai No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010001990001', 2, 2, 4, '1571010001991001', 'Laki-laki', '1983-09-25', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(200, 'Rahmat Kurniawan', 'Jl. Ujung Tanjung No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002000001', 5, 2, 7, '1571010002001001', 'Laki-laki', '1960-05-24', 'Kristen', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1);
INSERT INTO keluarga (id, nama_kepala_keluarga, alamat, rt_id, nomor_kk, jumlah_lk, jumlah_pr, jumlah_total, nik_kepala_keluarga, jenis_kelamin_kepala_keluarga, tanggal_lahir_kepala_keluarga, agama_kepala_keluarga, status_perkawinan_kepala_keluarga, pendidikan_kepala_keluarga, status_pekerjaan_kepala_keluarga, pekerjaan_kepala_keluarga, pernah_bantuan, ada_umkm, jumlah_anggota_umkm, created_by, updated_by) VALUES
(201, 'Latif Effendi', 'Jl. Kuala Tungkal No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002010001', 1, 4, 5, '1571010002011001', 'Laki-laki', '1968-11-03', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Perawat', 'Tidak', 'Tidak', NULL, 1, 1),
(202, 'Sari Puspita', 'Jl. Mudung Laut Ujung No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010002020001', 2, 3, 5, '1571010002021001', 'Perempuan', '1978-08-17', 'Islam', 'Cerai Hidup', 'SMA/SMK', 'Karyawan Swasta', 'Tukang bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(203, 'Maya Oktaviani', 'Gg. Dahlia No. 38, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002030001', 1, 1, 2, '1571010002031001', 'Perempuan', '1989-05-27', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(204, 'Ridwan Purnomo', 'Gg. Flamboyan No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002040001', 3, 1, 4, '1571010002041001', 'Laki-laki', '1969-12-07', 'Islam', 'Kawin', 'S1', 'PNS/ASN/TNI/Polri', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(205, 'Irwan Setiawan', 'Jl. Mudung Laut Ujung No. 32, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002050001', 1, 3, 4, '1571010002051001', 'Laki-laki', '1962-03-21', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(206, 'Kartika Rahmawati', 'Gg. Cempaka No. 49, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002060001', 1, 3, 4, '1571010002061001', 'Perempuan', '1957-01-05', 'Islam', 'Cerai Hidup', 'SMP', 'Buruh harian lepas', 'Karyawan toko', 'Tidak', 'Ya', 1, 1, 1),
(207, 'Umar Wardana', 'Jl. Batanghari Indah No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002070001', 2, 1, 3, '1571010002071001', 'Laki-laki', '1957-05-18', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Guru SMP', 'Tidak', 'Ya', 1, 1, 1),
(208, 'Xaverius Maulana', 'Gg. Dahlia No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002080001', 1, 2, 3, '1571010002081001', 'Laki-laki', '1977-10-17', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Peternak ayam', 'Tidak', 'Ya', 1, 1, 1),
(209, 'Johan Salim', 'Jl. Simpang Rimbo No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002090001', 1, 2, 3, '1571010002091001', 'Laki-laki', '1956-06-05', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Wiraswasta warung', 'Tidak', 'Tidak', NULL, 1, 1),
(210, 'Citra Fitriani', 'Jl. Simpang Rimbo No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002100001', 0, 3, 3, '1571010002101001', 'Perempuan', '1961-05-01', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(211, 'Omar Saputra', 'Jl. Simpang Rimbo No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002110001', 3, 0, 3, '1571010002111001', 'Laki-laki', '1957-05-07', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 1, 1, 1),
(212, 'Ahmad Suryadi', 'Gg. Teratai No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002120001', 2, 2, 4, '1571010002121001', 'Laki-laki', '1959-08-25', 'Islam', 'Kawin', 'SMP', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(213, 'Ahmad Maulana', 'Gg. Cempaka No. 28, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002130001', 3, 1, 4, '1571010002131001', 'Laki-laki', '2000-05-21', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(214, 'Jamal Hakim', 'Jl. Mudung Laut Ujung No. 8, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002140001', 2, 3, 5, '1571010002141001', 'Laki-laki', '1977-12-07', 'Islam', 'Belum Kawin', 'SMP', 'Karyawan Swasta', 'Petani karet', 'Tidak', 'Tidak', NULL, 1, 1),
(215, 'Yanti Damayanti', 'Jl. Tepian Sungai No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002150001', 1, 1, 2, '1571010002151001', 'Perempuan', '1958-03-25', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Pedagang kaki lima', 'Ya', 'Tidak', NULL, 1, 1),
(216, 'Rizal Hartono', 'Jl. Pelayangan Raya No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010002160001', 3, 1, 4, '1571010002161001', 'Laki-laki', '1956-11-25', 'Buddha', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Sopir truk', 'Tidak', 'Ya', 1, 1, 1),
(217, 'Anwar Prasetyo', 'Jl. Angso Duo No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002170001', 1, 0, 1, '1571010002171001', 'Laki-laki', '1966-09-20', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 1, 1, 1),
(218, 'Marwan Santoso', 'Gg. Cempaka No. 16, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010002180001', 1, 3, 4, '1571010002181001', 'Laki-laki', '1968-08-16', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1),
(219, 'Omar Kurniawan', 'Gg. Flamboyan No. 21, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010002190001', 1, 2, 3, '1571010002191001', 'Laki-laki', '1995-02-18', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(220, 'Joko Nugroho', 'Gg. Flamboyan No. 22, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002200001', 1, 3, 4, '1571010002201001', 'Laki-laki', '1971-12-06', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Bidan desa', 'Tidak', 'Ya', 2, 1, 1),
(221, 'Bambang Maulana', 'Jl. Batanghari Indah No. 36, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002210001', 1, 1, 2, '1571010002211001', 'Laki-laki', '1991-05-20', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Tukang kayu', 'Tidak', 'Tidak', NULL, 1, 1),
(222, 'Erwin Maulana', 'Gg. Anggrek No. 46, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002220001', 1, 3, 4, '1571010002221001', 'Laki-laki', '1961-11-19', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Pedagang kaki lima', 'Ya', 'Tidak', NULL, 1, 1),
(223, 'Munir Kusnadi', 'Jl. Gentala Arasy No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002230001', 3, 1, 4, '1571010002231001', 'Laki-laki', '1990-12-10', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(224, 'Umar Sofyan', 'Jl. Kuala Tungkal No. 18, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010002240001', 1, 1, 2, '1571010002241001', 'Laki-laki', '1972-05-16', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Kasir minimarket', 'Tidak', 'Ya', 1, 1, 1),
(225, 'Vino Setiawan', 'Jl. Ujung Tanjung No. 46, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002250001', 6, 1, 7, '1571010002251001', 'Laki-laki', '1956-10-27', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(226, 'Nasrul Wardana', 'Gg. Dahlia No. 43, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002260001', 1, 1, 2, '1571010002261001', 'Laki-laki', '2001-06-19', 'Islam', 'Kawin', 'SMA/SMK', 'PNS/ASN/TNI/Polri', 'Pegawai bank', 'Ya', 'Tidak', NULL, 1, 1),
(227, 'Novita Lestari', 'Gg. Kenanga No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002270001', 1, 2, 3, '1571010002271001', 'Perempuan', '1966-02-03', 'Islam', 'Cerai Mati', 'S2', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(228, 'Nasrul Santoso', 'Jl. Kuala Tungkal No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002280001', 1, 2, 3, '1571010002281001', 'Laki-laki', '1977-01-31', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(229, 'Yanto Yusuf', 'Gg. Flamboyan No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002290001', 4, 1, 5, '1571010002291001', 'Laki-laki', '1962-07-21', 'Islam', 'Kawin', 'SD', 'Buruh harian lepas', 'Tukang ojek', 'Tidak', 'Ya', 1, 1, 1),
(230, 'Syamsuddin Wijaya', 'Jl. Simpang Rimbo No. 18, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002300001', 1, 0, 1, '1571010002301001', 'Laki-laki', '1963-09-19', 'Islam', 'Belum Kawin', 'SMP', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(231, 'Najib Alamsyah', 'Jl. Ujung Tanjung No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010002310001', 3, 2, 5, '1571010002311001', 'Laki-laki', '1978-03-16', 'Islam', 'Cerai Mati', 'SD', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(232, 'Eko Darmawan', 'Gg. Mawar No. 6, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002320001', 1, 2, 3, '1571010002321001', 'Laki-laki', '1980-01-05', 'Islam', 'Cerai Mati', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Buruh bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(233, 'Muhammad Basuki', 'Jl. Ujung Tanjung No. 59, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002330001', 1, 2, 3, '1571010002331001', 'Laki-laki', '1976-04-26', 'Islam', 'Kawin', 'S2', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(234, 'Yudi Basuki', 'Gg. Flamboyan No. 32, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002340001', 5, 1, 6, '1571010002341001', 'Laki-laki', '1968-03-25', 'Buddha', 'Kawin', 'S2', 'Buruh harian lepas', 'Pedagang sembako', 'Ya', 'Tidak', NULL, 1, 1),
(235, 'Bambang Saputra', 'Gg. Anggrek No. 56, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002350001', 1, 5, 6, '1571010002351001', 'Laki-laki', '1967-12-21', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Nelayan', 'Ya', 'Tidak', NULL, 1, 1),
(236, 'Hasan Suryadi', 'Jl. Pelayangan Raya No. 6, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002360001', 3, 1, 4, '1571010002361001', 'Laki-laki', '1965-03-14', 'Kristen', 'Kawin', 'S1', 'Karyawan Swasta', 'Penjahit', 'Ya', 'Tidak', NULL, 1, 1),
(237, 'Zainal Maulana', 'Jl. Tepian Sungai No. 35, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002370001', 1, 2, 3, '1571010002371001', 'Laki-laki', '1956-03-15', 'Islam', 'Cerai Hidup', 'SD', 'PNS/ASN/TNI/Polri', 'Kasir minimarket', 'Tidak', 'Tidak', NULL, 1, 1),
(238, 'Fauzan Setiawan', 'Jl. Sungai Duren No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002380001', 1, 2, 3, '1571010002381001', 'Laki-laki', '1976-07-12', 'Islam', 'Kawin', 'D1/D2/D3', 'Lainnya', 'Petani sawit', 'Tidak', 'Tidak', NULL, 1, 1),
(239, 'Bahtiar Yusuf', 'Jl. Tepian Sungai No. 3, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002390001', 1, 2, 3, '1571010002391001', 'Laki-laki', '1965-03-29', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Peternak ayam', 'Tidak', 'Ya', 1, 1, 1),
(240, 'Kartika Utami', 'Jl. Kuala Tungkal No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002400001', 0, 5, 5, '1571010002401001', 'Perempuan', '1990-11-19', 'Islam', 'Cerai Mati', 'S1', 'Karyawan Swasta', 'Pedagang sembako', 'Ya', 'Ya', 1, 1, 1),
(241, 'Taufik Effendi', 'Gg. Anggrek No. 47, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002410001', 4, 0, 4, '1571010002411001', 'Laki-laki', '1993-11-18', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Tukang bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(242, 'Xaverius Basuki', 'Gg. Dahlia No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002420001', 1, 0, 1, '1571010002421001', 'Laki-laki', '1973-06-22', 'Islam', 'Kawin', 'S1', 'PNS/ASN/TNI/Polri', 'Buruh bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(243, 'Qomar Hidayat', 'Jl. Angso Duo No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010002430001', 2, 0, 2, '1571010002431001', 'Laki-laki', '1965-04-22', 'Islam', 'Belum Kawin', 'S2', 'Buruh harian lepas', 'Perawat', 'Tidak', 'Ya', 1, 1, 1),
(244, 'Agus Halim', 'Jl. Sungai Duren No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002440001', 2, 4, 6, '1571010002441001', 'Laki-laki', '1963-08-06', 'Islam', 'Cerai Mati', 'S1', 'Karyawan Swasta', 'Nelayan', 'Tidak', 'Tidak', NULL, 1, 1),
(245, 'Marlina Maharani', 'Gg. Dahlia No. 47, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002450001', 1, 1, 2, '1571010002451001', 'Perempuan', '1969-06-06', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Nelayan', 'Tidak', 'Ya', 1, 1, 1),
(246, 'Najib Nugroho', 'Jl. Angso Duo No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010002460001', 3, 0, 3, '1571010002461001', 'Laki-laki', '1996-09-27', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Kasir minimarket', 'Tidak', 'Ya', 2, 1, 1),
(247, 'Widyawati Fitriani', 'Jl. Tepian Sungai No. 46, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002470001', 1, 3, 4, '1571010002471001', 'Perempuan', '1985-08-15', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(248, 'Vino Hidayat', 'Gg. Mawar No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010002480001', 1, 0, 1, '1571010002481001', 'Laki-laki', '1971-09-11', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Peternak ayam', 'Ya', 'Ya', 1, 1, 1),
(249, 'Zulkifli Nugroho', 'Jl. Pasar Baru No. 39, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002490001', 2, 3, 5, '1571010002491001', 'Laki-laki', '1974-12-05', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Penjahit', 'Ya', 'Ya', 1, 1, 1),
(250, 'Fajar Santoso', 'Gg. Nusa Indah No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002500001', 2, 4, 6, '1571010002501001', 'Laki-laki', '1990-09-22', 'Katolik', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(251, 'Latif Salim', 'Gg. Melati No. 14, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002510001', 1, 4, 5, '1571010002511001', 'Laki-laki', '1990-08-13', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Karyawan toko', 'Ya', 'Tidak', NULL, 1, 1),
(252, 'Zainal Nugroho', 'Gg. Cempaka No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002520001', 2, 0, 2, '1571010002521001', 'Laki-laki', '1977-01-29', 'Islam', 'Cerai Mati', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 1, 1, 1),
(253, 'Irwan Salim', 'Jl. Gentala Arasy No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002530001', 2, 4, 6, '1571010002531001', 'Laki-laki', '1958-05-14', 'Islam', 'Cerai Mati', 'S1', 'Karyawan Swasta', 'Buruh bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(254, 'Yanti Apriliani', 'Jl. Simpang Rimbo No. 15, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010002540001', 0, 4, 4, '1571010002541001', 'Perempuan', '1976-12-24', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(255, 'Rudi Hartono', 'Jl. Gentala Arasy No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002550001', 2, 0, 2, '1571010002551001', 'Laki-laki', '1965-06-19', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Pedagang sayur', 'Ya', 'Tidak', NULL, 1, 1),
(256, 'Qori Damayanti', 'Gg. Kenanga No. 17, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010002560001', 2, 1, 3, '1571010002561001', 'Perempuan', '1978-09-19', 'Islam', 'Kawin', 'S2', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(257, 'Qomar Effendi', 'Jl. Gentala Arasy No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002570001', 5, 0, 5, '1571010002571001', 'Laki-laki', '1956-02-12', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Karyawan toko', 'Tidak', 'Tidak', NULL, 1, 1),
(258, 'Joko Wijaya', 'Jl. Gentala Arasy No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002580001', 1, 0, 1, '1571010002581001', 'Laki-laki', '1977-10-13', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Wiraswasta warung', 'Ya', 'Ya', 1, 1, 1),
(259, 'Devi Wulandari', 'Gg. Mawar No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002590001', 0, 1, 1, '1571010002591001', 'Perempuan', '1956-09-03', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(260, 'Galih Wijaya', 'Gg. Teratai No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002600001', 1, 2, 3, '1571010002601001', 'Laki-laki', '1957-02-06', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Buruh bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(261, 'Zainal Purnomo', 'Gg. Anggrek No. 34, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002610001', 1, 4, 5, '1571010002611001', 'Laki-laki', '1965-10-19', 'Kristen', 'Kawin', 'SMA/SMK', 'PNS/ASN/TNI/Polri', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(262, 'Bambang Alamsyah', 'Jl. Sungai Duren No. 17, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002620001', 3, 0, 3, '1571010002621001', 'Laki-laki', '1997-05-30', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Karyawan Swasta', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(263, 'Jamal Kurniawan', 'Gg. Cempaka No. 50, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002630001', 2, 1, 3, '1571010002631001', 'Laki-laki', '1970-04-30', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(264, 'Karim Iskandar', 'Jl. Gentala Arasy No. 1, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002640001', 1, 2, 3, '1571010002641001', 'Laki-laki', '1982-04-06', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Buruh bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(265, 'Yudi Hidayat', 'Jl. Mudung Laut Ujung No. 48, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002650001', 3, 2, 5, '1571010002651001', 'Laki-laki', '1988-08-28', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(266, 'Omar Hartono', 'Jl. Tepian Sungai No. 59, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002660001', 3, 2, 5, '1571010002661001', 'Laki-laki', '1966-02-13', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(267, 'Joko Permana', 'Jl. Kuala Tungkal No. 49, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002670001', 6, 0, 6, '1571010002671001', 'Laki-laki', '1974-05-05', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Pedagang sayur', 'Tidak', 'Tidak', NULL, 1, 1),
(268, 'Zaki Riyadi', 'Jl. Sungai Duren No. 1, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002680001', 2, 2, 4, '1571010002681001', 'Laki-laki', '1981-01-05', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Pengrajin anyaman', 'Tidak', 'Ya', 2, 1, 1),
(269, 'Yanto Ramadhan', 'Gg. Anggrek No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002690001', 3, 1, 4, '1571010002691001', 'Laki-laki', '1975-10-14', 'Buddha', 'Kawin', 'SD', 'Karyawan Swasta', 'Pegawai bank', 'Ya', 'Tidak', NULL, 1, 1),
(270, 'Andi Salim', 'Gg. Mawar No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002700001', 3, 1, 4, '1571010002701001', 'Laki-laki', '2000-06-29', 'Khonghucu', 'Cerai Mati', 'S2', 'Karyawan Swasta', 'Pegawai bank', 'Tidak', 'Tidak', NULL, 1, 1),
(271, 'Doni Santoso', 'Gg. Dahlia No. 4, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002710001', 4, 0, 4, '1571010002711001', 'Laki-laki', '1987-09-18', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(272, 'Dian Yusuf', 'Jl. Sungai Duren No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010002720001', 1, 2, 3, '1571010002721001', 'Laki-laki', '1989-10-19', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(273, 'Umar Syarif', 'Gg. Nusa Indah No. 56, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002730001', 4, 0, 4, '1571010002731001', 'Laki-laki', '1961-09-19', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Sopir angkot', 'Tidak', 'Tidak', NULL, 1, 1),
(274, 'Puji Fitriani', 'Gg. Mawar No. 18, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002740001', 3, 4, 7, '1571010002741001', 'Perempuan', '1964-06-17', 'Islam', 'Belum Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Perawat', 'Tidak', 'Ya', 1, 1, 1),
(275, 'Latif Alamsyah', 'Gg. Mawar No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002750001', 1, 4, 5, '1571010002751001', 'Laki-laki', '1997-01-27', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(276, 'Nasrul Perkasa', 'Jl. Batanghari Indah No. 15, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010002760001', 2, 0, 2, '1571010002761001', 'Laki-laki', '1960-05-09', 'Islam', 'Kawin', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(277, 'Hasan Nurdin', 'Gg. Kenanga No. 36, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002770001', 3, 3, 6, '1571010002771001', 'Laki-laki', '1961-10-13', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(278, 'Darma Suryadi', 'Gg. Melati No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010002780001', 1, 0, 1, '1571010002781001', 'Laki-laki', '1991-11-07', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Pedagang kaki lima', 'Tidak', 'Tidak', NULL, 1, 1),
(279, 'Dedi Wardana', 'Jl. Angso Duo No. 49, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002790001', 3, 0, 3, '1571010002791001', 'Laki-laki', '1983-09-04', 'Islam', 'Kawin', 'S2', 'Wirausaha', 'Guru SMP', 'Ya', 'Tidak', NULL, 1, 1),
(280, 'Karim Purnomo', 'Gg. Mawar No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010002800001', 1, 2, 3, '1571010002801001', 'Laki-laki', '1974-10-03', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(281, 'Herman Nurdin', 'Gg. Melati No. 12, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010002810001', 1, 2, 3, '1571010002811001', 'Laki-laki', '1962-04-09', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Satpam', 'Ya', 'Tidak', NULL, 1, 1),
(282, 'Halim Hartono', 'Jl. Batanghari Indah No. 18, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010002820001', 1, 1, 2, '1571010002821001', 'Laki-laki', '1986-04-03', 'Islam', 'Kawin', 'S1', 'Lainnya', 'Tukang bangunan', 'Tidak', 'Ya', 1, 1, 1),
(283, 'Bahtiar Gunawan', 'Gg. Nusa Indah No. 4, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002830001', 1, 1, 2, '1571010002831001', 'Laki-laki', '1967-04-27', 'Islam', 'Belum Kawin', 'SMA/SMK', 'Wirausaha', 'Tukang bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(284, 'Ahmad Permana', 'Gg. Anggrek No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002840001', 2, 2, 4, '1571010002841001', 'Laki-laki', '1958-08-02', 'Kristen', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(285, 'Joko Saputra', 'Jl. Batanghari Indah No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002850001', 2, 2, 4, '1571010002851001', 'Laki-laki', '1993-08-30', 'Islam', 'Cerai Mati', 'SD', 'Wirausaha', 'Guru SMP', 'Ya', 'Ya', 2, 1, 1),
(286, 'Irwan Iskandar', 'Jl. Ujung Tanjung No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010002860001', 1, 1, 2, '1571010002861001', 'Laki-laki', '1991-05-27', 'Kristen', 'Cerai Mati', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Peternak ayam', 'Ya', 'Tidak', NULL, 1, 1),
(287, 'Rizal Alamsyah', 'Jl. Tepian Sungai No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010002870001', 2, 3, 5, '1571010002871001', 'Laki-laki', '1959-12-22', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Nelayan', 'Ya', 'Ya', 2, 1, 1),
(288, 'Najib Firmansyah', 'Jl. Gentala Arasy No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002880001', 2, 2, 4, '1571010002881001', 'Laki-laki', '1964-07-10', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Karyawan toko', 'Ya', 'Tidak', NULL, 1, 1),
(289, 'Rudi Kusnadi', 'Gg. Kenanga No. 35, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002890001', 2, 4, 6, '1571010002891001', 'Laki-laki', '1976-07-08', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(290, 'Omar Alamsyah', 'Gg. Mawar No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002900001', 2, 1, 3, '1571010002901001', 'Laki-laki', '1992-09-19', 'Islam', 'Kawin', 'S2', 'Karyawan Swasta', 'Petani karet', 'Tidak', 'Ya', 1, 1, 1),
(291, 'Ahmad Maulana', 'Gg. Anggrek No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002910001', 2, 3, 5, '1571010002911001', 'Laki-laki', '1965-10-19', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Guru SMP', 'Tidak', 'Ya', 1, 1, 1),
(292, 'Indah Maharani', 'Jl. Angso Duo No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002920001', 2, 1, 3, '1571010002921001', 'Perempuan', '1960-03-03', 'Kristen', 'Kawin', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(293, 'Pandu Gunawan', 'Gg. Teratai No. 3, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002930001', 2, 0, 2, '1571010002931001', 'Laki-laki', '1988-06-15', 'Islam', 'Kawin', 'S2', 'Karyawan Swasta', 'Montir bengkel', 'Tidak', 'Ya', 2, 1, 1),
(294, 'Wawan Nurdin', 'Jl. Tepian Sungai No. 50, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002940001', 4, 0, 4, '1571010002941001', 'Laki-laki', '1957-11-12', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Buruh pelabuhan', 'Ya', 'Tidak', NULL, 1, 1),
(295, 'Rizal Alamsyah', 'Gg. Flamboyan No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002950001', 1, 2, 3, '1571010002951001', 'Laki-laki', '1981-01-15', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(296, 'Tuti Rahayu', 'Gg. Kenanga No. 24, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010002960001', 4, 3, 7, '1571010002961001', 'Perempuan', '2000-02-05', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Guru SMP', 'Ya', 'Tidak', NULL, 1, 1),
(297, 'Andi Riyadi', 'Gg. Kenanga No. 59, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010002970001', 3, 0, 3, '1571010002971001', 'Laki-laki', '1999-04-17', 'Islam', 'Belum Kawin', 'SMA/SMK', 'PNS/ASN/TNI/Polri', 'Sopir angkot', 'Ya', 'Tidak', NULL, 1, 1),
(298, 'Sahrul Salim', 'Gg. Anggrek No. 47, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010002980001', 1, 4, 5, '1571010002981001', 'Laki-laki', '1990-05-15', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Pegawai bank', 'Tidak', 'Ya', 1, 1, 1),
(299, 'Ratih Kartika', 'Gg. Cempaka No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010002990001', 4, 1, 5, '1571010002991001', 'Perempuan', '1993-08-21', 'Kristen', 'Kawin', 'S1', 'Buruh harian lepas', 'Karyawan toko', 'Ya', 'Tidak', NULL, 1, 1),
(300, 'Fauzan Prasetyo', 'Gg. Nusa Indah No. 21, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003000001', 2, 3, 5, '1571010003001001', 'Laki-laki', '1998-11-21', 'Buddha', 'Kawin', 'S2', 'Buruh harian lepas', 'Penjahit', 'Ya', 'Tidak', NULL, 1, 1);
INSERT INTO keluarga (id, nama_kepala_keluarga, alamat, rt_id, nomor_kk, jumlah_lk, jumlah_pr, jumlah_total, nik_kepala_keluarga, jenis_kelamin_kepala_keluarga, tanggal_lahir_kepala_keluarga, agama_kepala_keluarga, status_perkawinan_kepala_keluarga, pendidikan_kepala_keluarga, status_pekerjaan_kepala_keluarga, pekerjaan_kepala_keluarga, pernah_bantuan, ada_umkm, jumlah_anggota_umkm, created_by, updated_by) VALUES
(301, 'Joko Alamsyah', 'Gg. Nusa Indah No. 22, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003010001', 1, 1, 2, '1571010003011001', 'Laki-laki', '1975-09-26', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(302, 'Iwan Iskandar', 'Gg. Anggrek No. 36, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003020001', 3, 2, 5, '1571010003021001', 'Laki-laki', '1996-09-29', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Penjahit', 'Tidak', 'Ya', 2, 1, 1),
(303, 'Qomar Wijaya', 'Jl. Ujung Tanjung No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003030001', 2, 3, 5, '1571010003031001', 'Laki-laki', '1979-09-24', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Buruh bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(304, 'Iwan Prasetyo', 'Gg. Melati No. 8, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003040001', 3, 0, 3, '1571010003041001', 'Laki-laki', '1982-01-15', 'Islam', 'Kawin', 'D1/D2/D3', 'Buruh harian lepas', 'Satpam', 'Ya', 'Tidak', NULL, 1, 1),
(305, 'Fajar Kurniawan', 'Gg. Kenanga No. 36, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003050001', 2, 4, 6, '1571010003051001', 'Laki-laki', '1977-08-19', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Sopir truk', 'Tidak', 'Ya', 1, 1, 1),
(306, 'Xaverius Riyadi', 'Gg. Melati No. 25, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003060001', 1, 5, 6, '1571010003061001', 'Laki-laki', '1999-10-27', 'Islam', 'Cerai Mati', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(307, 'Jamal Alamsyah', 'Gg. Melati No. 12, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003070001', 1, 0, 1, '1571010003071001', 'Laki-laki', '1955-01-23', 'Kristen', 'Kawin', 'S1', 'Wirausaha', 'Tukang ojek', 'Ya', 'Tidak', NULL, 1, 1),
(308, 'Marwan Santoso', 'Jl. Pasar Baru No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003080001', 6, 0, 6, '1571010003081001', 'Laki-laki', '1960-09-20', 'Kristen', 'Belum Kawin', 'SMP', 'Wirausaha', 'PNS Kelurahan', 'Tidak', 'Ya', 2, 1, 1),
(309, 'Galih Syarif', 'Gg. Teratai No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003090001', 1, 1, 2, '1571010003091001', 'Laki-laki', '1986-08-10', 'Kristen', 'Kawin', 'S2', 'Buruh harian lepas', 'Peternak ayam', 'Ya', 'Tidak', NULL, 1, 1),
(310, 'Rahmat Wardana', 'Gg. Anggrek No. 56, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010003100001', 5, 1, 6, '1571010003101001', 'Laki-laki', '1992-11-02', 'Islam', 'Kawin', 'SD', 'Buruh harian lepas', 'Wirausaha kuliner', 'Tidak', 'Tidak', NULL, 1, 1),
(311, 'Olivia Wulandari', 'Gg. Cempaka No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003110001', 2, 4, 6, '1571010003111001', 'Perempuan', '1973-10-14', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(312, 'Galih Nugroho', 'Jl. Ujung Tanjung No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010003120001', 1, 2, 3, '1571010003121001', 'Laki-laki', '1957-01-27', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Buruh bangunan', 'Ya', 'Tidak', NULL, 1, 1),
(313, 'Fauzan Maulana', 'Jl. Angso Duo No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010003130001', 3, 3, 6, '1571010003131001', 'Laki-laki', '1974-01-16', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Pedagang sembako', 'Ya', 'Tidak', NULL, 1, 1),
(314, 'Sahrul Nurdin', 'Gg. Flamboyan No. 56, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003140001', 3, 0, 3, '1571010003141001', 'Laki-laki', '1986-03-14', 'Islam', 'Cerai Mati', 'D1/D2/D3', 'Wirausaha', 'Perawat', 'Tidak', 'Tidak', NULL, 1, 1),
(315, 'Jamal Maulana', 'Jl. Pelayangan Raya No. 34, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003150001', 4, 0, 4, '1571010003151001', 'Laki-laki', '1986-06-16', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Tukang bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(316, 'Oscar Santoso', 'Jl. Batanghari Indah No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010003160001', 3, 3, 6, '1571010003161001', 'Laki-laki', '1957-06-13', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(317, 'Sahrul Perkasa', 'Jl. Gentala Arasy No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003170001', 3, 1, 4, '1571010003171001', 'Laki-laki', '1999-07-03', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Kasir minimarket', 'Tidak', 'Ya', 1, 1, 1),
(318, 'Xaverius Purnomo', 'Gg. Melati No. 8, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010003180001', 1, 2, 3, '1571010003181001', 'Laki-laki', '1968-12-25', 'Islam', 'Kawin', 'S2', 'Wirausaha', 'Bidan desa', 'Ya', 'Tidak', NULL, 1, 1),
(319, 'Fatimah Apriliani', 'Gg. Nusa Indah No. 11, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003190001', 1, 2, 3, '1571010003191001', 'Perempuan', '1955-02-22', 'Islam', 'Cerai Hidup', 'SMP', 'Buruh harian lepas', 'Nelayan', 'Tidak', 'Ya', 2, 1, 1),
(320, 'Omar Yusuf', 'Jl. Sungai Duren No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003200001', 5, 1, 6, '1571010003201001', 'Laki-laki', '2001-09-14', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Pedagang sembako', 'Tidak', 'Ya', 2, 1, 1),
(321, 'Arif Santoso', 'Jl. Ujung Tanjung No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010003210001', 1, 0, 1, '1571010003211001', 'Laki-laki', '1989-06-01', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Wirausaha kuliner', 'Tidak', 'Tidak', NULL, 1, 1),
(322, 'Hasan Wijaya', 'Gg. Melati No. 4, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003220001', 3, 1, 4, '1571010003221001', 'Laki-laki', '1957-10-19', 'Katolik', 'Kawin', 'D1/D2/D3', 'Lainnya', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(323, 'Firman Alamsyah', 'Gg. Mawar No. 53, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010003230001', 4, 0, 4, '1571010003231001', 'Laki-laki', '1996-10-26', 'Islam', 'Kawin', 'S2', 'Wirausaha', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(324, 'Irwan Salim', 'Jl. Tepian Sungai No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003240001', 1, 5, 6, '1571010003241001', 'Laki-laki', '1957-09-11', 'Islam', 'Kawin', 'D1/D2/D3', 'PNS/ASN/TNI/Polri', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1),
(325, 'Omar Hidayat', 'Gg. Nusa Indah No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010003250001', 2, 1, 3, '1571010003251001', 'Laki-laki', '1990-09-17', 'Buddha', 'Kawin', 'Tidak/Belum Sekolah', 'Wirausaha', 'Pegawai bank', 'Ya', 'Tidak', NULL, 1, 1),
(326, 'Taufik Effendi', 'Jl. Ujung Tanjung No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003260001', 1, 2, 3, '1571010003261001', 'Laki-laki', '1966-10-15', 'Islam', 'Kawin', 'SD', 'Wirausaha', 'Karyawan toko', 'Tidak', 'Tidak', NULL, 1, 1),
(327, 'Bahtiar Kurniawan', 'Jl. Tepian Sungai No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003270001', 2, 1, 3, '1571010003271001', 'Laki-laki', '1989-07-18', 'Kristen', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(328, 'Salsabila Maharani', 'Gg. Flamboyan No. 58, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003280001', 2, 3, 5, '1571010003281001', 'Perempuan', '1974-02-27', 'Islam', 'Kawin', 'S2', 'Karyawan Swasta', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(329, 'Widyawati Rahmawati', 'Jl. Pasar Baru No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010003290001', 1, 3, 4, '1571010003291001', 'Perempuan', '1980-01-20', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(330, 'Darma Purnomo', 'Gg. Cempaka No. 46, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003300001', 2, 1, 3, '1571010003301001', 'Laki-laki', '1969-09-01', 'Islam', 'Kawin', 'SD', 'Wirausaha', 'Petani karet', 'Tidak', 'Tidak', NULL, 1, 1),
(331, 'Munir Kusnadi', 'Gg. Flamboyan No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003310001', 2, 1, 3, '1571010003311001', 'Laki-laki', '1991-07-14', 'Islam', 'Kawin', 'D1/D2/D3', 'Buruh harian lepas', 'Tukang kayu', 'Ya', 'Tidak', NULL, 1, 1),
(332, 'Susanti Fitriani', 'Gg. Teratai No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003320001', 2, 1, 3, '1571010003321001', 'Perempuan', '1999-04-16', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Pengrajin anyaman', 'Tidak', 'Tidak', NULL, 1, 1),
(333, 'Qomar Kurniawan', 'Jl. Pelayangan Raya No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003330001', 3, 1, 4, '1571010003331001', 'Laki-laki', '1964-11-15', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Bidan desa', 'Tidak', 'Ya', 1, 1, 1),
(334, 'Bambang Saputra', 'Jl. Mudung Laut Ujung No. 18, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003340001', 2, 2, 4, '1571010003341001', 'Laki-laki', '1966-12-25', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Tukang ojek', 'Ya', 'Tidak', NULL, 1, 1),
(335, 'Syamsuddin Kurniawan', 'Gg. Cempaka No. 35, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010003350001', 1, 0, 1, '1571010003351001', 'Laki-laki', '1971-11-23', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Pengrajin anyaman', 'Tidak', 'Tidak', NULL, 1, 1),
(336, 'Taufik Firmansyah', 'Gg. Flamboyan No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003360001', 5, 0, 5, '1571010003361001', 'Laki-laki', '1956-11-17', 'Buddha', 'Kawin', 'S1', 'Karyawan Swasta', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(337, 'Kadir Salim', 'Gg. Flamboyan No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003370001', 1, 1, 2, '1571010003371001', 'Laki-laki', '1986-08-18', 'Kristen', 'Kawin', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(338, 'Vino Salim', 'Jl. Sungai Duren No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003380001', 2, 1, 3, '1571010003381001', 'Laki-laki', '1971-06-24', 'Islam', 'Kawin', 'SD', 'Wirausaha', 'Sopir truk', 'Tidak', 'Tidak', NULL, 1, 1),
(339, 'Kadir Halim', 'Gg. Melati No. 51, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003390001', 3, 0, 3, '1571010003391001', 'Laki-laki', '1964-02-28', 'Islam', 'Cerai Hidup', 'SD', 'Wirausaha', 'Wirausaha kuliner', 'Tidak', 'Tidak', NULL, 1, 1),
(340, 'Hadi Kusuma', 'Jl. Simpang Rimbo No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003400001', 1, 1, 2, '1571010003401001', 'Laki-laki', '1959-11-17', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Wirausaha kuliner', 'Tidak', 'Tidak', NULL, 1, 1),
(341, 'Zaki Basuki', 'Gg. Mawar No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003410001', 4, 0, 4, '1571010003411001', 'Laki-laki', '1970-10-23', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Buruh pelabuhan', 'Ya', 'Tidak', NULL, 1, 1),
(342, 'Dian Saputra', 'Gg. Mawar No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010003420001', 1, 2, 3, '1571010003421001', 'Laki-laki', '1957-11-21', 'Islam', 'Cerai Hidup', 'D1/D2/D3', 'Lainnya', 'Montir bengkel', 'Ya', 'Tidak', NULL, 1, 1),
(343, 'Oscar Santoso', 'Gg. Mawar No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010003430001', 7, 0, 7, '1571010003431001', 'Laki-laki', '1978-07-17', 'Islam', 'Cerai Hidup', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(344, 'Zaki Halim', 'Gg. Dahlia No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003440001', 3, 1, 4, '1571010003441001', 'Laki-laki', '1977-03-21', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(345, 'Rahmat Hartono', 'Jl. Batanghari Indah No. 56, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003450001', 1, 0, 1, '1571010003451001', 'Laki-laki', '1997-10-25', 'Islam', 'Kawin', 'S1', 'Lainnya', 'Nelayan', 'Ya', 'Tidak', NULL, 1, 1),
(346, 'Firman Kusuma', 'Jl. Simpang Rimbo No. 56, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010003460001', 1, 3, 4, '1571010003461001', 'Laki-laki', '1972-06-05', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1),
(347, 'Xaverius Maulana', 'Gg. Teratai No. 18, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003470001', 2, 2, 4, '1571010003471001', 'Laki-laki', '1999-08-05', 'Islam', 'Kawin', 'SD', 'Buruh harian lepas', 'Perawat', 'Tidak', 'Tidak', NULL, 1, 1),
(348, 'Irwan Iskandar', 'Gg. Kenanga No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003480001', 5, 0, 5, '1571010003481001', 'Laki-laki', '1971-10-08', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Operator mesin', 'Tidak', 'Tidak', NULL, 1, 1),
(349, 'Latif Darmawan', 'Jl. Angso Duo No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003490001', 1, 6, 7, '1571010003491001', 'Laki-laki', '1974-12-28', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Montir bengkel', 'Ya', 'Tidak', NULL, 1, 1),
(350, 'Oscar Kurniawan', 'Gg. Dahlia No. 11, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003500001', 2, 0, 2, '1571010003501001', 'Laki-laki', '1983-05-12', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Wiraswasta warung', 'Tidak', 'Ya', 1, 1, 1),
(351, 'Rosnani Marlinda', 'Jl. Ujung Tanjung No. 12, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010003510001', 2, 3, 5, '1571010003511001', 'Perempuan', '1973-01-13', 'Islam', 'Kawin', 'SMP', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(352, 'Andi Hidayat', 'Gg. Melati No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003520001', 2, 1, 3, '1571010003521001', 'Laki-laki', '1975-01-28', 'Islam', 'Kawin', 'D1/D2/D3', 'Buruh harian lepas', 'Wiraswasta warung', 'Tidak', 'Ya', 1, 1, 1),
(353, 'Latif Yusuf', 'Gg. Flamboyan No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003530001', 2, 3, 5, '1571010003531001', 'Laki-laki', '1987-01-24', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Kasir minimarket', 'Tidak', 'Tidak', NULL, 1, 1),
(354, 'Muhammad Riyadi', 'Gg. Cempaka No. 34, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003540001', 2, 1, 3, '1571010003541001', 'Laki-laki', '1967-10-15', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Wiraswasta warung', 'Tidak', 'Tidak', NULL, 1, 1),
(355, 'Hadi Firmansyah', 'Gg. Dahlia No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010003550001', 3, 1, 4, '1571010003551001', 'Laki-laki', '1967-12-12', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Ya', 'Ya', 1, 1, 1),
(356, 'Nasrul Suryadi', 'Gg. Flamboyan No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003560001', 1, 0, 1, '1571010003561001', 'Laki-laki', '1988-02-04', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Lainnya', 'Peternak ayam', 'Ya', 'Tidak', NULL, 1, 1),
(357, 'Zaki Kusuma', 'Gg. Melati No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003570001', 1, 1, 2, '1571010003571001', 'Laki-laki', '1994-12-14', 'Islam', 'Cerai Mati', 'S1', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(358, 'Wahyu Hakim', 'Gg. Cempaka No. 17, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003580001', 3, 0, 3, '1571010003581001', 'Laki-laki', '1998-01-27', 'Islam', 'Belum Kawin', 'S1', 'Buruh harian lepas', 'Kasir minimarket', 'Ya', 'Tidak', NULL, 1, 1),
(359, 'Gani Saputra', 'Jl. Angso Duo No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003590001', 1, 1, 2, '1571010003591001', 'Laki-laki', '1962-10-21', 'Islam', 'Kawin', 'SD', 'Buruh harian lepas', 'Perawat', 'Ya', 'Tidak', NULL, 1, 1),
(360, 'Rudi Maulana', 'Jl. Angso Duo No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003600001', 1, 2, 3, '1571010003601001', 'Laki-laki', '1959-02-04', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(361, 'Anwar Salim', 'Gg. Melati No. 35, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010003610001', 2, 2, 4, '1571010003611001', 'Laki-laki', '1994-08-04', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Peternak ayam', 'Ya', 'Tidak', NULL, 1, 1),
(362, 'Novita Setiawati', 'Gg. Cempaka No. 6, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010003620001', 3, 1, 4, '1571010003621001', 'Perempuan', '1988-06-29', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(363, 'Yudi Setiawan', 'Gg. Melati No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010003630001', 1, 0, 1, '1571010003631001', 'Laki-laki', '1998-07-17', 'Khonghucu', 'Kawin', 'S1', 'Buruh harian lepas', 'Satpam', 'Tidak', 'Tidak', NULL, 1, 1),
(364, 'Slamet Darmawan', 'Gg. Flamboyan No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003640001', 1, 1, 2, '1571010003641001', 'Laki-laki', '1999-02-20', 'Kristen', 'Cerai Mati', 'SMP', 'Karyawan Swasta', 'Guru SMP', 'Tidak', 'Ya', 1, 1, 1),
(365, 'Muhammad Iskandar', 'Jl. Angso Duo No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003650001', 2, 0, 2, '1571010003651001', 'Laki-laki', '1957-10-26', 'Islam', 'Belum Kawin', 'S1', 'Karyawan Swasta', 'Wirausaha kuliner', 'Tidak', 'Tidak', NULL, 1, 1),
(366, 'Fauzan Gunawan', 'Jl. Tepian Sungai No. 8, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003660001', 1, 2, 3, '1571010003661001', 'Laki-laki', '1989-03-12', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Wirausaha kuliner', 'Tidak', 'Ya', 1, 1, 1),
(367, 'Zulkifli Hakim', 'Gg. Dahlia No. 12, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003670001', 1, 1, 2, '1571010003671001', 'Laki-laki', '1992-03-01', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Pegawai bank', 'Tidak', 'Tidak', NULL, 1, 1),
(368, 'Indah Rahmawati', 'Jl. Mudung Laut Ujung No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010003680001', 5, 1, 6, '1571010003681001', 'Perempuan', '2000-07-02', 'Islam', 'Cerai Hidup', 'S1', 'Karyawan Swasta', 'Guru SD', 'Ya', 'Tidak', NULL, 1, 1),
(369, 'Hasan Maulana', 'Gg. Flamboyan No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003690001', 1, 4, 5, '1571010003691001', 'Laki-laki', '1962-07-04', 'Katolik', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Petani sawit', 'Tidak', 'Ya', 1, 1, 1),
(370, 'Gita Yuliana', 'Jl. Ujung Tanjung No. 24, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003700001', 1, 4, 5, '1571010003701001', 'Perempuan', '1987-04-21', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Kasir minimarket', 'Tidak', 'Ya', 1, 1, 1),
(371, 'Arif Wardana', 'Jl. Pelayangan Raya No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010003710001', 1, 3, 4, '1571010003711001', 'Laki-laki', '1984-12-08', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Pegawai bank', 'Ya', 'Tidak', NULL, 1, 1),
(372, 'Halim Basuki', 'Gg. Melati No. 58, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010003720001', 3, 2, 5, '1571010003721001', 'Laki-laki', '1974-07-23', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Perawat', 'Tidak', 'Ya', 1, 1, 1),
(373, 'Joko Wardana', 'Gg. Melati No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003730001', 3, 3, 6, '1571010003731001', 'Laki-laki', '1991-08-10', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Peternak ayam', 'Tidak', 'Tidak', NULL, 1, 1),
(374, 'Slamet Hakim', 'Gg. Cempaka No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003740001', 2, 3, 5, '1571010003741001', 'Laki-laki', '1992-04-23', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(375, 'Galih Purnomo', 'Jl. Ujung Tanjung No. 58, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003750001', 3, 1, 4, '1571010003751001', 'Laki-laki', '1975-06-19', 'Islam', 'Cerai Hidup', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Perawat', 'Tidak', 'Tidak', NULL, 1, 1),
(376, 'Andi Hartono', 'Jl. Simpang Rimbo No. 38, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003760001', 1, 0, 1, '1571010003761001', 'Laki-laki', '1974-02-15', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Wirausaha', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(377, 'Bagus Alamsyah', 'Jl. Tepian Sungai No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010003770001', 4, 1, 5, '1571010003771001', 'Laki-laki', '2001-12-10', 'Islam', 'Kawin', 'SD', 'Buruh harian lepas', 'Buruh pelabuhan', 'Ya', 'Tidak', NULL, 1, 1),
(378, 'Jamal Nurdin', 'Gg. Dahlia No. 48, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003780001', 2, 1, 3, '1571010003781001', 'Laki-laki', '1993-12-21', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(379, 'Firman Hakim', 'Gg. Cempaka No. 34, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003790001', 3, 1, 4, '1571010003791001', 'Laki-laki', '1957-09-19', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Petani karet', 'Tidak', 'Tidak', NULL, 1, 1),
(380, 'Anwar Ramadhan', 'Jl. Pasar Baru No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003800001', 1, 0, 1, '1571010003801001', 'Laki-laki', '1972-09-25', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Bidan desa', 'Ya', 'Tidak', NULL, 1, 1),
(381, 'Munir Saputra', 'Jl. Kuala Tungkal No. 35, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003810001', 2, 1, 3, '1571010003811001', 'Laki-laki', '1986-11-25', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Buruh bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(382, 'Oscar Perkasa', 'Jl. Tepian Sungai No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003820001', 5, 0, 5, '1571010003821001', 'Laki-laki', '1962-01-12', 'Islam', 'Belum Kawin', 'SD', 'Wirausaha', 'Tukang ojek', 'Ya', 'Tidak', NULL, 1, 1),
(383, 'Fajar Hidayat', 'Jl. Tepian Sungai No. 11, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003830001', 4, 0, 4, '1571010003831001', 'Laki-laki', '1991-07-29', 'Islam', 'Cerai Mati', 'SMP', 'Wirausaha', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(384, 'Galih Permana', 'Jl. Batanghari Indah No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003840001', 2, 1, 3, '1571010003841001', 'Laki-laki', '1959-12-10', 'Islam', 'Cerai Hidup', 'S2', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(385, 'Budi Suryadi', 'Gg. Nusa Indah No. 58, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003850001', 2, 1, 3, '1571010003851001', 'Laki-laki', '1987-05-11', 'Islam', 'Kawin', 'D1/D2/D3', 'PNS/ASN/TNI/Polri', 'Tukang ojek', 'Tidak', 'Ya', 2, 1, 1),
(386, 'Rosnani Wahyuni', 'Jl. Mudung Laut Ujung No. 12, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003860001', 0, 1, 1, '1571010003861001', 'Perempuan', '1985-04-30', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Guru SD', 'Tidak', 'Ya', 1, 1, 1),
(387, 'Doni Yusuf', 'Jl. Pasar Baru No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003870001', 3, 3, 6, '1571010003871001', 'Laki-laki', '1981-05-05', 'Kristen', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(388, 'Oscar Salim', 'Jl. Gentala Arasy No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010003880001', 1, 3, 4, '1571010003881001', 'Laki-laki', '1983-08-11', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(389, 'Fauzan Perkasa', 'Jl. Batanghari Indah No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003890001', 1, 2, 3, '1571010003891001', 'Laki-laki', '1978-04-05', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 1, 1, 1),
(390, 'Irwan Kusnadi', 'Jl. Gentala Arasy No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003900001', 4, 0, 4, '1571010003901001', 'Laki-laki', '1975-07-19', 'Kristen', 'Kawin', 'SMP', 'Karyawan Swasta', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(391, 'Ibrahim Alamsyah', 'Jl. Batanghari Indah No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003910001', 2, 3, 5, '1571010003911001', 'Laki-laki', '1995-08-09', 'Islam', 'Kawin', 'S1', 'PNS/ASN/TNI/Polri', 'Pegawai bank', 'Tidak', 'Tidak', NULL, 1, 1),
(392, 'Sari Handayani', 'Jl. Simpang Rimbo No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003920001', 2, 2, 4, '1571010003921001', 'Perempuan', '1987-11-07', 'Islam', 'Cerai Hidup', 'SD', 'Buruh harian lepas', 'Peternak ayam', 'Tidak', 'Tidak', NULL, 1, 1),
(393, 'Rahmat Firmansyah', 'Jl. Gentala Arasy No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003930001', 2, 1, 3, '1571010003931001', 'Laki-laki', '1990-01-26', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Wirausaha', 'Perawat', 'Tidak', 'Ya', 1, 1, 1),
(394, 'Latif Abidin', 'Gg. Nusa Indah No. 17, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003940001', 3, 3, 6, '1571010003941001', 'Laki-laki', '1960-11-12', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Buruh harian lepas', 'Bidan desa', 'Ya', 'Tidak', NULL, 1, 1),
(395, 'Munir Wardana', 'Gg. Melati No. 39, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003950001', 5, 0, 5, '1571010003951001', 'Laki-laki', '1985-10-05', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Ya', 'Ya', 2, 1, 1),
(396, 'Wawan Wijaya', 'Gg. Flamboyan No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003960001', 1, 2, 3, '1571010003961001', 'Laki-laki', '1997-10-07', 'Kristen', 'Kawin', 'SMA/SMK', 'PNS/ASN/TNI/Polri', 'Peternak ayam', 'Tidak', 'Tidak', NULL, 1, 1),
(397, 'Budi Yusuf', 'Jl. Mudung Laut Ujung No. 49, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010003970001', 3, 2, 5, '1571010003971001', 'Laki-laki', '1980-11-19', 'Islam', 'Kawin', 'D1/D2/D3', 'Buruh harian lepas', 'Montir bengkel', 'Tidak', 'Ya', 1, 1, 1),
(398, 'Najib Syarif', 'Gg. Teratai No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010003980001', 2, 0, 2, '1571010003981001', 'Laki-laki', '1979-06-16', 'Islam', 'Cerai Mati', 'S2', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(399, 'Wahyu Abidin', 'Jl. Tepian Sungai No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010003990001', 2, 2, 4, '1571010003991001', 'Laki-laki', '1992-01-18', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(400, 'Agus Abidin', 'Gg. Cempaka No. 12, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010004000001', 4, 1, 5, '1571010004001001', 'Laki-laki', '1986-05-12', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1);
INSERT INTO keluarga (id, nama_kepala_keluarga, alamat, rt_id, nomor_kk, jumlah_lk, jumlah_pr, jumlah_total, nik_kepala_keluarga, jenis_kelamin_kepala_keluarga, tanggal_lahir_kepala_keluarga, agama_kepala_keluarga, status_perkawinan_kepala_keluarga, pendidikan_kepala_keluarga, status_pekerjaan_kepala_keluarga, pekerjaan_kepala_keluarga, pernah_bantuan, ada_umkm, jumlah_anggota_umkm, created_by, updated_by) VALUES
(401, 'Munir Wardana', 'Jl. Tepian Sungai No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004010001', 2, 0, 2, '1571010004011001', 'Laki-laki', '1998-07-21', 'Islam', 'Belum Kawin', 'SD', 'Wirausaha', 'Petani sawit', 'Tidak', 'Tidak', NULL, 1, 1),
(402, 'Dian Kusuma', 'Jl. Ujung Tanjung No. 14, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004020001', 1, 0, 1, '1571010004021001', 'Laki-laki', '1958-12-26', 'Islam', 'Kawin', 'SMA/SMK', 'Lainnya', 'Buruh bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(403, 'Zainal Riyadi', 'Jl. Ujung Tanjung No. 16, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010004030001', 3, 1, 4, '1571010004031001', 'Laki-laki', '1963-01-15', 'Katolik', 'Kawin', 'S2', 'Buruh harian lepas', 'Perawat', 'Ya', 'Ya', 2, 1, 1),
(404, 'Halim Riyadi', 'Jl. Pasar Baru No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004040001', 4, 3, 7, '1571010004041001', 'Laki-laki', '1989-12-30', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Karyawan pabrik', 'Ya', 'Ya', 1, 1, 1),
(405, 'Nasrul Alamsyah', 'Jl. Angso Duo No. 49, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004050001', 3, 0, 3, '1571010004051001', 'Laki-laki', '1998-03-26', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Wirausaha kuliner', 'Tidak', 'Tidak', NULL, 1, 1),
(406, 'Zainal Salim', 'Jl. Batanghari Indah No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010004060001', 1, 1, 2, '1571010004061001', 'Laki-laki', '1958-01-12', 'Islam', 'Kawin', 'S2', 'Karyawan Swasta', 'Pedagang sembako', 'Ya', 'Tidak', NULL, 1, 1),
(407, 'Budi Gunawan', 'Gg. Dahlia No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004070001', 1, 2, 3, '1571010004071001', 'Laki-laki', '1977-07-23', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(408, 'Candra Effendi', 'Gg. Dahlia No. 38, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004080001', 1, 3, 4, '1571010004081001', 'Laki-laki', '1971-11-14', 'Hindu', 'Kawin', 'SMP', 'Karyawan Swasta', 'Pedagang sayur', 'Ya', 'Tidak', NULL, 1, 1),
(409, 'Dewi Utami', 'Jl. Kuala Tungkal No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010004090001', 0, 4, 4, '1571010004091001', 'Perempuan', '1997-03-11', 'Buddha', 'Kawin', 'D1/D2/D3', 'Buruh harian lepas', 'Pengrajin anyaman', 'Tidak', 'Tidak', NULL, 1, 1),
(410, 'Kadir Firmansyah', 'Gg. Teratai No. 50, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004100001', 2, 2, 4, '1571010004101001', 'Laki-laki', '1983-11-09', 'Islam', 'Cerai Mati', 'S2', 'Buruh harian lepas', 'Bidan desa', 'Ya', 'Tidak', NULL, 1, 1),
(411, 'Zaki Perkasa', 'Jl. Tepian Sungai No. 25, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004110001', 1, 0, 1, '1571010004111001', 'Laki-laki', '1971-02-06', 'Islam', 'Cerai Hidup', 'SMP', 'Wirausaha', 'Nelayan', 'Ya', 'Tidak', NULL, 1, 1),
(412, 'Latif Salim', 'Jl. Tepian Sungai No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004120001', 1, 3, 4, '1571010004121001', 'Laki-laki', '1965-06-10', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Buruh bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(413, 'Syamsuddin Ramadhan', 'Jl. Pelayangan Raya No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004130001', 1, 0, 1, '1571010004131001', 'Laki-laki', '1979-08-21', 'Islam', 'Kawin', 'SD', 'Wirausaha', 'Buruh bangunan', 'Tidak', 'Ya', 1, 1, 1),
(414, 'Bagus Gunawan', 'Jl. Kuala Tungkal No. 16, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004140001', 3, 0, 3, '1571010004141001', 'Laki-laki', '1981-04-28', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Operator mesin', 'Tidak', 'Ya', 2, 1, 1),
(415, 'Yani Damayanti', 'Gg. Dahlia No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004150001', 3, 1, 4, '1571010004151001', 'Perempuan', '1976-11-26', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Pegawai bank', 'Tidak', 'Tidak', NULL, 1, 1),
(416, 'Gani Firmansyah', 'Jl. Ujung Tanjung No. 20, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010004160001', 5, 0, 5, '1571010004161001', 'Laki-laki', '1970-10-13', 'Islam', 'Kawin', 'SMA/SMK', 'PNS/ASN/TNI/Polri', 'Sopir angkot', 'Tidak', 'Tidak', NULL, 1, 1),
(417, 'Irwan Riyadi', 'Jl. Kuala Tungkal No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004170001', 1, 2, 3, '1571010004171001', 'Laki-laki', '1963-12-11', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(418, 'Rizal Firmansyah', 'Jl. Batanghari Indah No. 28, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004180001', 1, 2, 3, '1571010004181001', 'Laki-laki', '1975-02-16', 'Islam', 'Kawin', 'SMP', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(419, 'Kadir Hakim', 'Jl. Mudung Laut Ujung No. 37, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004190001', 2, 3, 5, '1571010004191001', 'Laki-laki', '1961-06-29', 'Kristen', 'Kawin', 'Tidak/Belum Sekolah', 'Karyawan Swasta', 'Buruh bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(420, 'Rizal Gunawan', 'Jl. Batanghari Indah No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004200001', 3, 2, 5, '1571010004201001', 'Laki-laki', '1960-07-27', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Guru SMP', 'Tidak', 'Ya', 1, 1, 1),
(421, 'Qomar Nurdin', 'Jl. Sungai Duren No. 16, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004210001', 4, 3, 7, '1571010004211001', 'Laki-laki', '1970-07-28', 'Islam', 'Kawin', 'SMP', 'PNS/ASN/TNI/Polri', 'Petani sawit', 'Ya', 'Tidak', NULL, 1, 1),
(422, 'Muhammad Hidayat', 'Jl. Gentala Arasy No. 12, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004220001', 5, 0, 5, '1571010004221001', 'Laki-laki', '1999-02-26', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(423, 'Marlina Puspita', 'Gg. Melati No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010004230001', 0, 5, 5, '1571010004231001', 'Perempuan', '1994-08-08', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Wirausaha', 'Pedagang sembako', 'Ya', 'Ya', 2, 1, 1),
(424, 'Anwar Iskandar', 'Gg. Cempaka No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004240001', 2, 0, 2, '1571010004241001', 'Laki-laki', '1973-08-12', 'Islam', 'Kawin', 'S1', 'PNS/ASN/TNI/Polri', 'Montir bengkel', 'Ya', 'Tidak', NULL, 1, 1),
(425, 'Latif Iskandar', 'Jl. Tepian Sungai No. 21, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010004250001', 1, 2, 3, '1571010004251001', 'Laki-laki', '1983-05-29', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(426, 'Qomar Ramadhan', 'Jl. Kuala Tungkal No. 17, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004260001', 3, 1, 4, '1571010004261001', 'Laki-laki', '1957-05-05', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(427, 'Doni Perkasa', 'Jl. Kuala Tungkal No. 20, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004270001', 1, 5, 6, '1571010004271001', 'Laki-laki', '1960-11-20', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(428, 'Qori Utami', 'Jl. Simpang Rimbo No. 60, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004280001', 0, 3, 3, '1571010004281001', 'Perempuan', '1991-12-17', 'Islam', 'Kawin', 'S2', 'Karyawan Swasta', 'Tukang bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(429, 'Rahmat Hartono', 'Jl. Mudung Laut Ujung No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004290001', 2, 2, 4, '1571010004291001', 'Laki-laki', '1975-07-24', 'Islam', 'Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Bidan desa', 'Tidak', 'Tidak', NULL, 1, 1),
(430, 'Rizal Perkasa', 'Jl. Ujung Tanjung No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004300001', 1, 2, 3, '1571010004301001', 'Laki-laki', '1970-05-17', 'Islam', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(431, 'Ningsih Rahmawati', 'Gg. Mawar No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004310001', 1, 3, 4, '1571010004311001', 'Perempuan', '2000-07-25', 'Kristen', 'Belum Kawin', 'SMA/SMK', 'Karyawan Swasta', 'Tukang ojek', 'Ya', 'Tidak', NULL, 1, 1),
(432, 'Yanto Wijaya', 'Jl. Ujung Tanjung No. 17, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004320001', 1, 0, 1, '1571010004321001', 'Laki-laki', '1964-04-30', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(433, 'Astuti Wulandari', 'Gg. Anggrek No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004330001', 0, 2, 2, '1571010004331001', 'Perempuan', '1970-01-27', 'Islam', 'Cerai Hidup', 'SMA/SMK', 'Wirausaha', 'Penjahit', 'Tidak', 'Ya', 2, 1, 1),
(434, 'Iwan Ramadhan', 'Jl. Kuala Tungkal No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004340001', 4, 0, 4, '1571010004341001', 'Laki-laki', '1964-12-01', 'Islam', 'Kawin', 'D1/D2/D3', 'Lainnya', 'PNS Kelurahan', 'Tidak', 'Tidak', NULL, 1, 1),
(435, 'Wahyu Riyadi', 'Jl. Simpang Rimbo No. 48, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004350001', 1, 0, 1, '1571010004351001', 'Laki-laki', '1965-03-02', 'Kristen', 'Kawin', 'D1/D2/D3', 'Lainnya', 'Buruh pelabuhan', 'Tidak', 'Tidak', NULL, 1, 1),
(436, 'Zaki Amin', 'Jl. Pelayangan Raya No. 1, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004360001', 1, 2, 3, '1571010004361001', 'Laki-laki', '1976-11-18', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Kasir minimarket', 'Tidak', 'Tidak', NULL, 1, 1),
(437, 'Gani Prasetyo', 'Gg. Melati No. 21, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004370001', 3, 0, 3, '1571010004371001', 'Laki-laki', '1984-04-29', 'Islam', 'Cerai Hidup', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(438, 'Karim Permana', 'Jl. Ujung Tanjung No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004380001', 4, 2, 6, '1571010004381001', 'Laki-laki', '1981-03-22', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Kasir minimarket', 'Tidak', 'Tidak', NULL, 1, 1),
(439, 'Galih Kusuma', 'Jl. Pelayangan Raya No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004390001', 1, 2, 3, '1571010004391001', 'Laki-laki', '1999-04-27', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Buruh bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(440, 'Fajar Abidin', 'Gg. Flamboyan No. 32, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004400001', 2, 1, 3, '1571010004401001', 'Laki-laki', '1978-04-06', 'Islam', 'Kawin', 'S2', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(441, 'Siti Yuliana', 'Gg. Anggrek No. 38, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004410001', 0, 3, 3, '1571010004411001', 'Perempuan', '1964-07-03', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(442, 'Bambang Basuki', 'Jl. Tepian Sungai No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004420001', 1, 1, 2, '1571010004421001', 'Laki-laki', '1991-01-30', 'Islam', 'Cerai Mati', 'Tidak/Belum Sekolah', 'Wirausaha', 'Petani karet', 'Tidak', 'Tidak', NULL, 1, 1),
(443, 'Handayani Lestari', 'Gg. Cempaka No. 47, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010004430001', 0, 3, 3, '1571010004431001', 'Perempuan', '1998-10-22', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Wiraswasta warung', 'Ya', 'Tidak', NULL, 1, 1),
(444, 'Arif Wijaya', 'Gg. Mawar No. 6, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010004440001', 1, 2, 3, '1571010004441001', 'Laki-laki', '1977-02-16', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Kasir minimarket', 'Ya', 'Tidak', NULL, 1, 1),
(445, 'Yanto Kusnadi', 'Gg. Nusa Indah No. 23, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010004450001', 1, 3, 4, '1571010004451001', 'Laki-laki', '1989-05-16', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(446, 'Muhammad Kusnadi', 'Jl. Simpang Rimbo No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004460001', 3, 1, 4, '1571010004461001', 'Laki-laki', '1980-04-19', 'Kristen', 'Kawin', 'S2', 'Buruh harian lepas', 'Tukang bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(447, 'Syamsuddin Amin', 'Jl. Angso Duo No. 20, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004470001', 4, 0, 4, '1571010004471001', 'Laki-laki', '1986-06-20', 'Islam', 'Cerai Mati', 'SD', 'Karyawan Swasta', 'Penjahit', 'Ya', 'Tidak', NULL, 1, 1),
(448, 'Johan Purnomo', 'Gg. Dahlia No. 53, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004480001', 1, 1, 2, '1571010004481001', 'Laki-laki', '1968-01-17', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(449, 'Ibrahim Suryadi', 'Gg. Dahlia No. 47, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010004490001', 3, 0, 3, '1571010004491001', 'Laki-laki', '1979-07-11', 'Islam', 'Kawin', 'SD', 'Wirausaha', 'Petani sawit', 'Ya', 'Ya', 1, 1, 1),
(450, 'Najib Amin', 'Jl. Angso Duo No. 30, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010004500001', 1, 2, 3, '1571010004501001', 'Laki-laki', '1962-09-24', 'Katolik', 'Kawin', 'SMA/SMK', 'Buruh harian lepas', 'Nelayan', 'Ya', 'Ya', 1, 1, 1),
(451, 'Munir Prasetyo', 'Gg. Anggrek No. 55, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004510001', 3, 1, 4, '1571010004511001', 'Laki-laki', '1959-09-05', 'Islam', 'Kawin', 'SMP', 'Wirausaha', 'Petani sawit', 'Ya', 'Tidak', NULL, 1, 1),
(452, 'Ibrahim Iskandar', 'Gg. Flamboyan No. 32, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004520001', 1, 3, 4, '1571010004521001', 'Laki-laki', '1988-10-28', 'Islam', 'Kawin', 'S1', 'Lainnya', 'Tukang kayu', 'Tidak', 'Tidak', NULL, 1, 1),
(453, 'Candra Hidayat', 'Jl. Gentala Arasy No. 19, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004530001', 2, 3, 5, '1571010004531001', 'Laki-laki', '1969-08-28', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Wirausaha', 'Karyawan pabrik', 'Tidak', 'Tidak', NULL, 1, 1),
(454, 'Omar Effendi', 'Jl. Simpang Rimbo No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004540001', 3, 1, 4, '1571010004541001', 'Laki-laki', '1973-12-15', 'Islam', 'Kawin', 'D1/D2/D3', 'Wirausaha', 'Karyawan toko', 'Ya', 'Tidak', NULL, 1, 1),
(455, 'Kadir Setiawan', 'Gg. Cempaka No. 59, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010004550001', 2, 1, 3, '1571010004551001', 'Laki-laki', '1983-12-30', 'Islam', 'Kawin', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(456, 'Irwan Salim', 'Jl. Ujung Tanjung No. 14, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010004560001', 1, 1, 2, '1571010004561001', 'Laki-laki', '1992-06-26', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(457, 'Doni Kusuma', 'Jl. Pasar Baru No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004570001', 3, 2, 5, '1571010004571001', 'Laki-laki', '1968-02-02', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Pedagang kaki lima', 'Ya', 'Tidak', NULL, 1, 1),
(458, 'Lukman Prasetyo', 'Jl. Pasar Baru No. 50, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004580001', 4, 0, 4, '1571010004581001', 'Laki-laki', '1957-06-11', 'Islam', 'Cerai Hidup', 'S1', 'Lainnya', 'Bidan desa', 'Ya', 'Ya', 1, 1, 1),
(459, 'Budi Abidin', 'Jl. Gentala Arasy No. 3, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004590001', 1, 1, 2, '1571010004591001', 'Laki-laki', '1988-01-06', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Pedagang sayur', 'Ya', 'Tidak', NULL, 1, 1),
(460, 'Sinta Kartika', 'Gg. Nusa Indah No. 8, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='003'), '1571010004600001', 3, 2, 5, '1571010004601001', 'Perempuan', '2000-09-08', 'Islam', 'Kawin', 'SD', 'PNS/ASN/TNI/Polri', 'Sopir truk', 'Tidak', 'Tidak', NULL, 1, 1),
(461, 'Erwin Nugroho', 'Jl. Kuala Tungkal No. 10, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004610001', 2, 1, 3, '1571010004611001', 'Laki-laki', '1993-03-15', 'Islam', 'Cerai Mati', 'D1/D2/D3', 'Lainnya', 'Tukang bangunan', 'Ya', 'Ya', 1, 1, 1),
(462, 'Budi Wardana', 'Gg. Melati No. 22, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010004620001', 4, 1, 5, '1571010004621001', 'Laki-laki', '1998-02-07', 'Kristen', 'Kawin', 'S2', 'Lainnya', 'Penjahit', 'Tidak', 'Tidak', NULL, 1, 1),
(463, 'Rizal Effendi', 'Jl. Gentala Arasy No. 56, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004630001', 2, 4, 6, '1571010004631001', 'Laki-laki', '2000-10-13', 'Kristen', 'Kawin', 'S1', 'Karyawan Swasta', 'Operator mesin', 'Tidak', 'Tidak', NULL, 1, 1),
(464, 'Candra Firmansyah', 'Gg. Flamboyan No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004640001', 1, 0, 1, '1571010004641001', 'Laki-laki', '1981-03-28', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Satpam', 'Ya', 'Ya', 1, 1, 1),
(465, 'Doni Kurniawan', 'Gg. Teratai No. 22, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004650001', 3, 1, 4, '1571010004651001', 'Laki-laki', '2000-07-06', 'Islam', 'Kawin', 'S1', 'Lainnya', 'Pedagang sayur', 'Tidak', 'Tidak', NULL, 1, 1),
(466, 'Zulkifli Santoso', 'Gg. Kenanga No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004660001', 4, 0, 4, '1571010004661001', 'Laki-laki', '1959-05-08', 'Islam', 'Cerai Mati', 'S2', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(467, 'Zaki Permana', 'Gg. Dahlia No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004670001', 1, 2, 3, '1571010004671001', 'Laki-laki', '1985-04-18', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Sopir truk', 'Tidak', 'Tidak', NULL, 1, 1),
(468, 'Syamsuddin Salim', 'Gg. Melati No. 4, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010004680001', 1, 1, 2, '1571010004681001', 'Laki-laki', '1988-04-01', 'Islam', 'Kawin', 'S1', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(469, 'Zulaikha Fitriani', 'Gg. Flamboyan No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004690001', 0, 2, 2, '1571010004691001', 'Perempuan', '1974-06-16', 'Islam', 'Kawin', 'S2', 'Tidak Bekerja', NULL, 'Ya', 'Ya', 2, 1, 1),
(470, 'Yanto Abidin', 'Jl. Pelayangan Raya No. 48, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004700001', 1, 1, 2, '1571010004701001', 'Laki-laki', '1963-02-23', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Sopir angkot', 'Tidak', 'Tidak', NULL, 1, 1),
(471, 'Fajar Syarif', 'Jl. Angso Duo No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004710001', 5, 1, 6, '1571010004711001', 'Laki-laki', '1997-11-09', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Buruh bangunan', 'Ya', 'Ya', 2, 1, 1),
(472, 'Umar Wibowo', 'Gg. Dahlia No. 20, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004720001', 2, 0, 2, '1571010004721001', 'Laki-laki', '1971-09-13', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Nelayan', 'Tidak', 'Tidak', NULL, 1, 1),
(473, 'Anwar Nugroho', 'Jl. Ujung Tanjung No. 43, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010004730001', 1, 3, 4, '1571010004731001', 'Laki-laki', '1975-12-14', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Montir bengkel', 'Tidak', 'Tidak', NULL, 1, 1),
(474, 'Bagus Firmansyah', 'Jl. Batanghari Indah No. 36, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004740001', 4, 0, 4, '1571010004741001', 'Laki-laki', '1962-07-09', 'Katolik', 'Kawin', 'S1', 'Karyawan Swasta', 'Petani sawit', 'Ya', 'Tidak', NULL, 1, 1),
(475, 'Arif Iskandar', 'Jl. Mudung Laut Ujung No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004750001', 2, 2, 4, '1571010004751001', 'Laki-laki', '1956-08-16', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Wirausaha', 'Tukang ojek', 'Tidak', 'Tidak', NULL, 1, 1),
(476, 'Herman Riyadi', 'Gg. Cempaka No. 25, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004760001', 3, 0, 3, '1571010004761001', 'Laki-laki', '1966-06-22', 'Islam', 'Kawin', 'SMA/SMK', 'Lainnya', 'Buruh pelabuhan', 'Ya', 'Tidak', NULL, 1, 1),
(477, 'Slamet Amin', 'Gg. Cempaka No. 12, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004770001', 2, 1, 3, '1571010004771001', 'Laki-laki', '1976-04-11', 'Islam', 'Kawin', 'SD', 'Buruh harian lepas', 'Guru SMP', 'Tidak', 'Tidak', NULL, 1, 1),
(478, 'Anwar Abidin', 'Jl. Angso Duo No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004780001', 1, 2, 3, '1571010004781001', 'Laki-laki', '1983-03-04', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Kasir minimarket', 'Tidak', 'Tidak', NULL, 1, 1),
(479, 'Syamsuddin Amin', 'Gg. Dahlia No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004790001', 3, 1, 4, '1571010004791001', 'Laki-laki', '1965-02-20', 'Islam', 'Kawin', 'S2', 'Lainnya', 'Pegawai bank', 'Ya', 'Tidak', NULL, 1, 1),
(480, 'Kadir Sofyan', 'Jl. Gentala Arasy No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004800001', 1, 0, 1, '1571010004801001', 'Laki-laki', '1959-06-21', 'Kristen', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(481, 'Oktavia Ningsih', 'Gg. Anggrek No. 38, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004810001', 2, 2, 4, '1571010004811001', 'Perempuan', '1991-07-01', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Wiraswasta warung', 'Tidak', 'Ya', 2, 1, 1),
(482, 'Ibrahim Hakim', 'Gg. Cempaka No. 41, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004820001', 5, 2, 7, '1571010004821001', 'Laki-laki', '1986-11-10', 'Islam', 'Cerai Hidup', 'Tidak/Belum Sekolah', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(483, 'Dedi Kusuma', 'Jl. Ujung Tanjung No. 31, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004830001', 1, 5, 6, '1571010004831001', 'Laki-laki', '1975-07-24', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Ya', 1, 1, 1),
(484, 'Zaki Effendi', 'Gg. Flamboyan No. 44, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='006'), '1571010004840001', 5, 0, 5, '1571010004841001', 'Laki-laki', '1976-06-30', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Guru SMP', 'Tidak', 'Tidak', NULL, 1, 1),
(485, 'Pandu Nugroho', 'Jl. Pasar Baru No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004850001', 7, 0, 7, '1571010004851001', 'Laki-laki', '1987-05-21', 'Islam', 'Cerai Mati', 'SMA/SMK', 'Buruh harian lepas', 'Wirausaha kuliner', 'Tidak', 'Ya', 2, 1, 1),
(486, 'Yudi Kusuma', 'Gg. Dahlia No. 33, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004860001', 2, 0, 2, '1571010004861001', 'Laki-laki', '1997-08-25', 'Islam', 'Belum Kawin', 'S2', 'Karyawan Swasta', 'Wiraswasta warung', 'Ya', 'Tidak', NULL, 1, 1),
(487, 'Jamal Hartono', 'Jl. Gentala Arasy No. 40, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004870001', 4, 0, 4, '1571010004871001', 'Laki-laki', '1974-10-19', 'Islam', 'Kawin', 'S1', 'PNS/ASN/TNI/Polri', 'Buruh pelabuhan', 'Tidak', 'Tidak', NULL, 1, 1),
(488, 'Fauzan Santoso', 'Gg. Teratai No. 49, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004880001', 2, 2, 4, '1571010004881001', 'Laki-laki', '1984-03-06', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(489, 'Wahyu Iskandar', 'Jl. Kuala Tungkal No. 45, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004890001', 3, 0, 3, '1571010004891001', 'Laki-laki', '1988-06-17', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Petani sawit', 'Tidak', 'Tidak', NULL, 1, 1),
(490, 'Bambang Salim', 'Gg. Cempaka No. 54, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010004900001', 3, 2, 5, '1571010004901001', 'Laki-laki', '1985-12-15', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Pengrajin anyaman', 'Tidak', 'Ya', 2, 1, 1),
(491, 'Slamet Maulana', 'Gg. Dahlia No. 8, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010004910001', 1, 5, 6, '1571010004911001', 'Laki-laki', '1976-11-16', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Pengrajin anyaman', 'Tidak', 'Ya', 1, 1, 1),
(492, 'Zaki Halim', 'Jl. Gentala Arasy No. 4, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004920001', 4, 1, 5, '1571010004921001', 'Laki-laki', '1995-09-25', 'Islam', 'Cerai Mati', 'Tidak/Belum Sekolah', 'Wirausaha', 'Tukang bangunan', 'Tidak', 'Tidak', NULL, 1, 1),
(493, 'Agus Nurdin', 'Jl. Ujung Tanjung No. 7, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='001'), '1571010004930001', 4, 0, 4, '1571010004931001', 'Laki-laki', '1967-12-03', 'Islam', 'Kawin', 'SD', 'Karyawan Swasta', 'Wirausaha kuliner', 'Ya', 'Tidak', NULL, 1, 1),
(494, 'Munir Perkasa', 'Gg. Teratai No. 17, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004940001', 2, 0, 2, '1571010004941001', 'Laki-laki', '1989-09-06', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Peternak ayam', 'Tidak', 'Tidak', NULL, 1, 1),
(495, 'Latif Amin', 'Jl. Gentala Arasy No. 50, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004950001', 3, 0, 3, '1571010004951001', 'Laki-laki', '1962-12-18', 'Islam', 'Kawin', 'SMP', 'Buruh harian lepas', 'Karyawan toko', 'Tidak', 'Tidak', NULL, 1, 1),
(496, 'Dian Firmansyah', 'Jl. Pelayangan Raya No. 28, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010004960001', 1, 1, 2, '1571010004961001', 'Laki-laki', '1996-12-15', 'Islam', 'Cerai Mati', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(497, 'Bambang Nurdin', 'Jl. Batanghari Indah No. 27, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004970001', 3, 0, 3, '1571010004971001', 'Laki-laki', '1999-05-23', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Guru SMP', 'Tidak', 'Tidak', NULL, 1, 1),
(498, 'Arif Halim', 'Gg. Cempaka No. 52, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010004980001', 3, 0, 3, '1571010004981001', 'Laki-laki', '1989-01-07', 'Islam', 'Kawin', 'SMP', 'PNS/ASN/TNI/Polri', 'Guru SD', 'Tidak', 'Tidak', NULL, 1, 1),
(499, 'Utami Lestari', 'Jl. Pasar Baru No. 3, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010004990001', 1, 2, 3, '1571010004991001', 'Perempuan', '1982-06-28', 'Islam', 'Kawin', 'S2', 'PNS/ASN/TNI/Polri', 'Guru SD', 'Ya', 'Tidak', NULL, 1, 1),
(500, 'Marlina Rahayu', 'Jl. Tepian Sungai No. 2, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010005000001', 0, 3, 3, '1571010005001001', 'Perempuan', '1959-04-24', 'Islam', 'Kawin', 'D1/D2/D3', 'Karyawan Swasta', 'Karyawan toko', 'Tidak', 'Tidak', NULL, 1, 1);
INSERT INTO keluarga (id, nama_kepala_keluarga, alamat, rt_id, nomor_kk, jumlah_lk, jumlah_pr, jumlah_total, nik_kepala_keluarga, jenis_kelamin_kepala_keluarga, tanggal_lahir_kepala_keluarga, agama_kepala_keluarga, status_perkawinan_kepala_keluarga, pendidikan_kepala_keluarga, status_pekerjaan_kepala_keluarga, pekerjaan_kepala_keluarga, pernah_bantuan, ada_umkm, jumlah_anggota_umkm, created_by, updated_by) VALUES
(501, 'Zulkifli Prasetyo', 'Jl. Simpang Rimbo No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='004'), '1571010005010001', 1, 1, 2, '1571010005011001', 'Laki-laki', '1992-07-13', 'Islam', 'Kawin', 'S1', 'Lainnya', 'Guru SMP', 'Tidak', 'Tidak', NULL, 1, 1),
(502, 'Novita Handayani', 'Gg. Dahlia No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010005020001', 0, 1, 1, '1571010005021001', 'Perempuan', '1980-09-10', 'Islam', 'Cerai Mati', 'S1', 'Buruh harian lepas', 'Pedagang sembako', 'Tidak', 'Tidak', NULL, 1, 1),
(503, 'Anwar Kusnadi', 'Jl. Ujung Tanjung No. 5, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010005030001', 3, 1, 4, '1571010005031001', 'Laki-laki', '1978-05-26', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Pedagang kaki lima', 'Tidak', 'Tidak', NULL, 1, 1),
(504, 'Fauzan Firmansyah', 'Gg. Dahlia No. 42, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010005040001', 2, 1, 3, '1571010005041001', 'Laki-laki', '1972-08-28', 'Islam', 'Kawin', 'SMP', 'Lainnya', 'Buruh bangunan', 'Ya', 'Ya', 1, 1, 1),
(505, 'Galih Maulana', 'Jl. Batanghari Indah No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010005050001', 1, 3, 4, '1571010005051001', 'Laki-laki', '1972-06-08', 'Islam', 'Kawin', 'D1/D2/D3', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(506, 'Wahyu Effendi', 'Jl. Mudung Laut Ujung No. 29, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010005060001', 1, 4, 5, '1571010005061001', 'Laki-laki', '1995-10-29', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Ya', 'Ya', 1, 1, 1),
(507, 'Taufik Suryadi', 'Jl. Gentala Arasy No. 13, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010005070001', 4, 1, 5, '1571010005071001', 'Laki-laki', '1982-12-01', 'Islam', 'Cerai Mati', 'S2', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(508, 'Nabila Damayanti', 'Jl. Pasar Baru No. 51, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010005080001', 1, 3, 4, '1571010005081001', 'Perempuan', '1959-01-13', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Karyawan toko', 'Tidak', 'Tidak', NULL, 1, 1),
(509, 'Umar Purnomo', 'Gg. Flamboyan No. 47, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010005090001', 1, 3, 4, '1571010005091001', 'Laki-laki', '1980-07-11', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Nelayan', 'Tidak', 'Ya', 1, 1, 1),
(510, 'Wawan Darmawan', 'Jl. Angso Duo No. 52, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010005100001', 1, 3, 4, '1571010005101001', 'Laki-laki', '1987-03-06', 'Islam', 'Kawin', 'SMA/SMK', 'Wirausaha', 'Petani sawit', 'Tidak', 'Ya', 1, 1, 1),
(511, 'Bahtiar Wibowo', 'Gg. Nusa Indah No. 22, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='005'), '1571010005110001', 1, 1, 2, '1571010005111001', 'Laki-laki', '1988-02-05', 'Islam', 'Kawin', 'S1', 'Karyawan Swasta', 'Sopir angkot', 'Ya', 'Ya', 1, 1, 1),
(512, 'Najib Kurniawan', 'Jl. Pelayangan Raya No. 53, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='002'), '1571010005120001', 1, 1, 2, '1571010005121001', 'Laki-laki', '1989-07-23', 'Islam', 'Kawin', 'S2', 'Buruh harian lepas', 'Petani karet', 'Tidak', 'Ya', 2, 1, 1),
(513, 'Herman Setiawan', 'Jl. Simpang Rimbo No. 26, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010005130001', 4, 0, 4, '1571010005131001', 'Laki-laki', '1967-03-05', 'Islam', 'Belum Kawin', 'SMP', 'Tidak Bekerja', NULL, 'Ya', 'Tidak', NULL, 1, 1),
(514, 'Qomar Firmansyah', 'Jl. Angso Duo No. 11, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010005140001', 3, 1, 4, '1571010005141001', 'Laki-laki', '1969-12-02', 'Islam', 'Kawin', 'SD', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(515, 'Najib Nurdin', 'Gg. Cempaka No. 59, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010005150001', 1, 0, 1, '1571010005151001', 'Laki-laki', '1972-08-12', 'Islam', 'Kawin', 'S1', 'Wirausaha', 'Wirausaha kuliner', 'Tidak', 'Tidak', NULL, 1, 1),
(516, 'Hasan Syarif', 'Jl. Ujung Tanjung No. 53, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010005160001', 1, 5, 6, '1571010005161001', 'Laki-laki', '1985-07-03', 'Islam', 'Kawin', 'SMP', 'Karyawan Swasta', 'Pedagang sayur', 'Tidak', 'Tidak', NULL, 1, 1),
(517, 'Widyawati Setiawati', 'Jl. Kuala Tungkal No. 57, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010005170001', 0, 4, 4, '1571010005171001', 'Perempuan', '1966-10-26', 'Islam', 'Kawin', 'SMA/SMK', 'Tidak Bekerja', NULL, 'Tidak', 'Tidak', NULL, 1, 1),
(518, 'Bambang Kusnadi', 'Jl. Tepian Sungai No. 24, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='009'), '1571010005180001', 2, 2, 4, '1571010005181001', 'Laki-laki', '1981-02-23', 'Islam', 'Kawin', 'Tidak/Belum Sekolah', 'Buruh harian lepas', 'Sopir truk', 'Tidak', 'Tidak', NULL, 1, 1),
(519, 'Yudi Halim', 'Gg. Cempaka No. 48, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='007'), '1571010005190001', 1, 2, 3, '1571010005191001', 'Laki-laki', '1998-01-11', 'Kristen', 'Kawin', 'S1', 'Wirausaha', 'Pedagang sembako', 'Ya', 'Tidak', NULL, 1, 1),
(520, 'Marwan Wijaya', 'Gg. Flamboyan No. 9, Mudung Laut', (SELECT id FROM rt WHERE nomor_rt='008'), '1571010005200001', 3, 1, 4, '1571010005201001', 'Laki-laki', '1990-01-19', 'Islam', 'Kawin', 'S1', 'Buruh harian lepas', 'Buruh pelabuhan', 'Tidak', 'Tidak', NULL, 1, 1);

-- =========================================================
-- Nilai Variabel Tambahan (contoh, sebagian data saja)
-- =========================================================
INSERT INTO custom_field_values (custom_field_id, record_id, value)
SELECT cf.id, v.record_id, v.value FROM custom_fields cf
JOIN (
SELECT 1 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 1 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 2 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 2 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 3 AS record_id, 'luas_tanah' AS fkey, '72' AS value
  UNION ALL
SELECT 3 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 4 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 4 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 5 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 5 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 6 AS record_id, 'luas_tanah' AS fkey, '100' AS value
  UNION ALL
SELECT 6 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 7 AS record_id, 'luas_tanah' AS fkey, '72' AS value
  UNION ALL
SELECT 7 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 8 AS record_id, 'luas_tanah' AS fkey, '100' AS value
  UNION ALL
SELECT 8 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 9 AS record_id, 'luas_tanah' AS fkey, '60' AS value
  UNION ALL
SELECT 9 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 10 AS record_id, 'luas_tanah' AS fkey, '60' AS value
  UNION ALL
SELECT 10 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 11 AS record_id, 'luas_tanah' AS fkey, '90' AS value
  UNION ALL
SELECT 11 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 12 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 12 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 13 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 13 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 14 AS record_id, 'luas_tanah' AS fkey, '120' AS value
  UNION ALL
SELECT 14 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 15 AS record_id, 'luas_tanah' AS fkey, '100' AS value
  UNION ALL
SELECT 15 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 16 AS record_id, 'luas_tanah' AS fkey, '120' AS value
  UNION ALL
SELECT 16 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 17 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 17 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 18 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 18 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 19 AS record_id, 'luas_tanah' AS fkey, '72' AS value
  UNION ALL
SELECT 19 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 20 AS record_id, 'luas_tanah' AS fkey, '120' AS value
  UNION ALL
SELECT 20 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 21 AS record_id, 'luas_tanah' AS fkey, '72' AS value
  UNION ALL
SELECT 21 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 22 AS record_id, 'luas_tanah' AS fkey, '72' AS value
  UNION ALL
SELECT 22 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 23 AS record_id, 'luas_tanah' AS fkey, '90' AS value
  UNION ALL
SELECT 23 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 24 AS record_id, 'luas_tanah' AS fkey, '60' AS value
  UNION ALL
SELECT 24 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 25 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 25 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 26 AS record_id, 'luas_tanah' AS fkey, '100' AS value
  UNION ALL
SELECT 26 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 27 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 27 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 28 AS record_id, 'luas_tanah' AS fkey, '100' AS value
  UNION ALL
SELECT 28 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 29 AS record_id, 'luas_tanah' AS fkey, '90' AS value
  UNION ALL
SELECT 29 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 30 AS record_id, 'luas_tanah' AS fkey, '90' AS value
  UNION ALL
SELECT 30 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 31 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 31 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 32 AS record_id, 'luas_tanah' AS fkey, '100' AS value
  UNION ALL
SELECT 32 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 33 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 33 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 34 AS record_id, 'luas_tanah' AS fkey, '120' AS value
  UNION ALL
SELECT 34 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 35 AS record_id, 'luas_tanah' AS fkey, '120' AS value
  UNION ALL
SELECT 35 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 36 AS record_id, 'luas_tanah' AS fkey, '60' AS value
  UNION ALL
SELECT 36 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 37 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 37 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 38 AS record_id, 'luas_tanah' AS fkey, '60' AS value
  UNION ALL
SELECT 38 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 39 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 39 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 40 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 40 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 41 AS record_id, 'luas_tanah' AS fkey, '72' AS value
  UNION ALL
SELECT 41 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 42 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 42 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 43 AS record_id, 'luas_tanah' AS fkey, '72' AS value
  UNION ALL
SELECT 43 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 44 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 44 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 45 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 45 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 46 AS record_id, 'luas_tanah' AS fkey, '100' AS value
  UNION ALL
SELECT 46 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 47 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 47 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 48 AS record_id, 'luas_tanah' AS fkey, '72' AS value
  UNION ALL
SELECT 48 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 49 AS record_id, 'luas_tanah' AS fkey, '60' AS value
  UNION ALL
SELECT 49 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 50 AS record_id, 'luas_tanah' AS fkey, '90' AS value
  UNION ALL
SELECT 50 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 51 AS record_id, 'luas_tanah' AS fkey, '90' AS value
  UNION ALL
SELECT 51 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 52 AS record_id, 'luas_tanah' AS fkey, '90' AS value
  UNION ALL
SELECT 52 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 53 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 53 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 54 AS record_id, 'luas_tanah' AS fkey, '72' AS value
  UNION ALL
SELECT 54 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
  UNION ALL
SELECT 55 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 55 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 56 AS record_id, 'luas_tanah' AS fkey, '120' AS value
  UNION ALL
SELECT 56 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 57 AS record_id, 'luas_tanah' AS fkey, '60' AS value
  UNION ALL
SELECT 57 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 58 AS record_id, 'luas_tanah' AS fkey, '200' AS value
  UNION ALL
SELECT 58 AS record_id, 'kepemilikan_rumah' AS fkey, 'Sewa' AS value
  UNION ALL
SELECT 59 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 59 AS record_id, 'kepemilikan_rumah' AS fkey, 'Milik Sendiri' AS value
  UNION ALL
SELECT 60 AS record_id, 'luas_tanah' AS fkey, '150' AS value
  UNION ALL
SELECT 60 AS record_id, 'kepemilikan_rumah' AS fkey, 'Menumpang' AS value
) v ON v.fkey = cf.field_key AND cf.target_table = 'keluarga';

SELECT 'Data simulasi berhasil dimuat: 520 keluarga.' AS status;