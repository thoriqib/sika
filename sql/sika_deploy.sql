-- =========================================================
-- SIKA (Sistem Informasi Keluarga) - Dump Database Deploy
-- Kelurahan Mudung Laut, Kecamatan Pelayangan, Kota Jambi
-- File TUNGGAL untuk deploy ke server baru — sudah mencakup seluruh
-- pembaruan struktur s.d. saat ini (keluarga, bantuan/UMKM/disabilitas,
-- status keberadaan, data bangunan per RT, login persisten).
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
  keterangan VARCHAR(100) NULL,
  jml_bangunan_tinggal_terisi INT NOT NULL DEFAULT 0,      -- Jumlah Bangunan Tempat Tinggal Terisi
  jml_bangunan_tinggal_kosong INT NOT NULL DEFAULT 0,      -- Jumlah Bangunan Tempat Tinggal Kosong
  jml_bangunan_khusus_usaha INT NOT NULL DEFAULT 0,        -- Jumlah Bangunan Khusus Usaha
  jml_bangunan_bukan_tinggal_non_usaha INT NOT NULL DEFAULT 0 -- Jumlah Bangunan Bukan Tempat Tinggal Non Usaha
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
  remember_token_hash VARCHAR(255) NULL,     -- untuk fitur "tetap masuk" (login persisten)
  remember_token_expires DATETIME NULL,
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
  deskripsi_bantuan VARCHAR(255) NULL,                        -- diisi jika pernah_bantuan = 'Ya'
  ada_umkm ENUM('Ya','Tidak') NOT NULL DEFAULT 'Tidak',       -- ada anggota keluarga yang memiliki UMKM?
  jumlah_anggota_umkm INT NULL,                               -- diisi jika ada_umkm = 'Ya'
  ada_disabilitas ENUM('Ya','Tidak') NOT NULL DEFAULT 'Tidak', -- ada anggota keluarga penyandang disabilitas?
  jumlah_disabilitas INT NULL,                                -- diisi jika ada_disabilitas = 'Ya'
  jenis_disabilitas VARCHAR(255) NULL,                        -- diisi jika ada_disabilitas = 'Ya'
  status_keberadaan ENUM('Ada','Pindah') NOT NULL DEFAULT 'Ada', -- status keberadaan keluarga saat ini

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
