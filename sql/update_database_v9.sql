-- =========================================================
-- SIKA - Skrip Pembaruan Database v9
-- Fitur: Deskripsi Bantuan, Data Disabilitas, Status Keberadaan Keluarga
-- =========================================================
-- Skrip ini AMAN dijalankan berkali-kali dan TIDAK mengubah/menghapus
-- data yang sudah ada — hanya menambah kolom baru.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin (http://localhost/phpmyadmin) atau akses via SSH/CLI
-- 2. Pilih database pemutakhiran_keluarga
-- 3. Buka tab "SQL"
-- 4. Copy-paste seluruh isi file ini, lalu klik "Go"
-- =========================================================

USE pemutakhiran_keluarga;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='deskripsi_bantuan');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN deskripsi_bantuan VARCHAR(255) NULL AFTER pernah_bantuan', 'SELECT ''Kolom deskripsi_bantuan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='ada_disabilitas');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN ada_disabilitas ENUM(''Ya'',''Tidak'') NOT NULL DEFAULT ''Tidak'' AFTER jumlah_anggota_umkm', 'SELECT ''Kolom ada_disabilitas sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='jumlah_disabilitas');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN jumlah_disabilitas INT NULL AFTER ada_disabilitas', 'SELECT ''Kolom jumlah_disabilitas sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='jenis_disabilitas');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN jenis_disabilitas VARCHAR(255) NULL AFTER jumlah_disabilitas', 'SELECT ''Kolom jenis_disabilitas sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='status_keberadaan');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN status_keberadaan ENUM(''Ada'',''Pindah'') NOT NULL DEFAULT ''Ada'' AFTER jenis_disabilitas', 'SELECT ''Kolom status_keberadaan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'Pembaruan database v9 (bantuan, disabilitas, status keberadaan) selesai.' AS status;
