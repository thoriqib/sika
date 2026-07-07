-- =========================================================
-- SIKA - Skrip Pembaruan Database v10
-- Fitur: Data Bangunan per RT
-- =========================================================
-- Menambahkan 4 kolom baru pada tabel `rt` untuk mencatat jumlah
-- bangunan per RT, diisi oleh Admin Kelurahan lewat menu Manajemen RT:
--   - Jumlah Bangunan Tempat Tinggal Terisi
--   - Jumlah Bangunan Tempat Tinggal Kosong
--   - Jumlah Bangunan Khusus Usaha
--   - Jumlah Bangunan Bukan Tempat Tinggal Non Usaha
--
-- Skrip ini AMAN dijalankan berkali-kali dan TIDAK menghapus data yang
-- sudah ada. Nilai default 0 untuk RT yang belum diisi datanya.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin, pilih database pemutakhiran_keluarga, tab SQL
-- 2. Copy-paste seluruh isi file ini, lalu klik "Go"
-- =========================================================

USE pemutakhiran_keluarga;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_tinggal_terisi');
SET @sql := IF(@exist=0, 'ALTER TABLE rt ADD COLUMN jml_bangunan_tinggal_terisi INT NOT NULL DEFAULT 0 AFTER keterangan', 'SELECT ''Kolom jml_bangunan_tinggal_terisi sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_tinggal_kosong');
SET @sql := IF(@exist=0, 'ALTER TABLE rt ADD COLUMN jml_bangunan_tinggal_kosong INT NOT NULL DEFAULT 0 AFTER jml_bangunan_tinggal_terisi', 'SELECT ''Kolom jml_bangunan_tinggal_kosong sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_khusus_usaha');
SET @sql := IF(@exist=0, 'ALTER TABLE rt ADD COLUMN jml_bangunan_khusus_usaha INT NOT NULL DEFAULT 0 AFTER jml_bangunan_tinggal_kosong', 'SELECT ''Kolom jml_bangunan_khusus_usaha sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_bukan_tinggal_non_usaha');
SET @sql := IF(@exist=0, 'ALTER TABLE rt ADD COLUMN jml_bangunan_bukan_tinggal_non_usaha INT NOT NULL DEFAULT 0 AFTER jml_bangunan_khusus_usaha', 'SELECT ''Kolom jml_bangunan_bukan_tinggal_non_usaha sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'Pembaruan database v10 (data bangunan per RT) selesai.' AS status;
