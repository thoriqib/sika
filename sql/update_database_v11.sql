-- =========================================================
-- SIKA - Skrip Pembaruan Database v11
-- Fitur: Login Persisten ("Ingat Saya" via cookie)
-- =========================================================
-- Menambahkan 2 kolom baru pada tabel `users` untuk menyimpan token
-- login persisten, supaya pengguna tidak perlu login ulang setiap
-- kunjungan (sampai mereka benar-benar logout).
--
-- Skrip ini AMAN dijalankan berkali-kali dan TIDAK menghapus data
-- yang sudah ada.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin, pilih database pemutakhiran_keluarga, tab SQL
-- 2. Copy-paste seluruh isi file ini, lalu klik "Go"
-- =========================================================

USE pemutakhiran_keluarga;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='users' AND COLUMN_NAME='remember_token_hash');
SET @sql := IF(@exist=0, 'ALTER TABLE users ADD COLUMN remember_token_hash VARCHAR(255) NULL AFTER status', 'SELECT ''Kolom remember_token_hash sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='users' AND COLUMN_NAME='remember_token_expires');
SET @sql := IF(@exist=0, 'ALTER TABLE users ADD COLUMN remember_token_expires DATETIME NULL AFTER remember_token_hash', 'SELECT ''Kolom remember_token_expires sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'Pembaruan database v11 (login persisten) selesai.' AS status;
