-- =========================================================
-- SIKA - Skrip Pembaruan Database (Migration)
-- =========================================================
-- Gunakan file ini HANYA jika Anda sudah pernah install aplikasi ini
-- sebelumnya dan sudah memiliki data yang ingin dipertahankan.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin (http://localhost/phpmyadmin)
-- 2. Pilih database pemutakhiran_keluarga
-- 3. Buka tab "SQL"
-- 4. Copy-paste seluruh isi file ini, lalu klik "Go"
--
-- Jika Anda BELUM pernah install sebelumnya (install baru), TIDAK PERLU
-- menjalankan file ini — cukup import database.sql saja.
-- =========================================================

USE pemutakhiran_keluarga;

-- Tambah kolom keberadaan pada tabel anggota_keluarga (jika belum ada)
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'anggota_keluarga' AND COLUMN_NAME = 'keberadaan');
SET @sql := IF(@exist = 0,
  'ALTER TABLE anggota_keluarga ADD COLUMN keberadaan ENUM(''Ada'',''Pindah'',''Meninggal'') NOT NULL DEFAULT ''Ada'' AFTER pekerjaan',
  'SELECT ''Kolom keberadaan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'anggota_keluarga' AND COLUMN_NAME = 'keterangan_keberadaan');
SET @sql := IF(@exist = 0,
  'ALTER TABLE anggota_keluarga ADD COLUMN keterangan_keberadaan VARCHAR(255) NULL AFTER keberadaan',
  'SELECT ''Kolom keterangan_keberadaan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'anggota_keluarga' AND COLUMN_NAME = 'tanggal_keberadaan');
SET @sql := IF(@exist = 0,
  'ALTER TABLE anggota_keluarga ADD COLUMN tanggal_keberadaan DATE NULL AFTER keterangan_keberadaan',
  'SELECT ''Kolom tanggal_keberadaan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Tambah kolom satuan (field_unit) pada tabel custom_fields (jika belum ada)
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'custom_fields' AND COLUMN_NAME = 'field_unit');
SET @sql := IF(@exist = 0,
  'ALTER TABLE custom_fields ADD COLUMN field_unit VARCHAR(20) NULL AFTER field_options',
  'SELECT ''Kolom field_unit sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Hitung ulang jumlah_lk / jumlah_pr / jumlah_total agar hanya menghitung
-- anggota dengan status keberadaan = 'Ada' (mengikuti aturan baru)
UPDATE keluarga k
SET
  jumlah_lk = (SELECT COUNT(*) FROM anggota_keluarga a WHERE a.keluarga_id = k.id AND a.jenis_kelamin = 'Laki-laki' AND a.keberadaan = 'Ada'),
  jumlah_pr = (SELECT COUNT(*) FROM anggota_keluarga a WHERE a.keluarga_id = k.id AND a.jenis_kelamin = 'Perempuan' AND a.keberadaan = 'Ada');
UPDATE keluarga SET jumlah_total = jumlah_lk + jumlah_pr;

SELECT 'Pembaruan database selesai.' AS status;
