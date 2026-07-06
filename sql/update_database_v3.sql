-- =========================================================
-- SIKA - Skrip Pembaruan Database v3
-- Fitur: Garis Kemiskinan & Status Kemiskinan per Keluarga
-- =========================================================
-- Gunakan file ini jika database Anda sudah pernah dibuat sebelumnya
-- (baik dari database.sql versi lama maupun yang sudah memakai
-- update_database.sql sebelumnya) dan ingin menambahkan fitur
-- Garis Kemiskinan tanpa kehilangan data yang sudah ada.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin (http://localhost/phpmyadmin)
-- 2. Pilih database pemutakhiran_keluarga
-- 3. Buka tab "SQL"
-- 4. Copy-paste seluruh isi file ini, lalu klik "Go"
--
-- Jika Anda BELUM pernah install sebelumnya (install baru), TIDAK PERLU
-- menjalankan file ini — database.sql yang terbaru sudah menyertakan
-- tabel ini secara otomatis.
-- =========================================================

USE pemutakhiran_keluarga;

SET @exist := (SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'garis_kemiskinan');
SET @sql := IF(@exist = 0,
  'CREATE TABLE garis_kemiskinan (
     id INT AUTO_INCREMENT PRIMARY KEY,
     tahun YEAR NOT NULL UNIQUE,
     nilai DECIMAL(15,2) NOT NULL,
     keterangan VARCHAR(255) NULL,
     created_by INT NULL,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
     FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
   ) ENGINE=InnoDB',
  'SELECT ''Tabel garis_kemiskinan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Isi contoh nilai Garis Kemiskinan Kota Jambi 2025, hanya jika tabel
-- masih kosong (tidak menimpa data yang sudah diisi Admin sebelumnya)
SET @jml := (SELECT COUNT(*) FROM garis_kemiskinan);
SET @sql := IF(@jml = 0,
  'INSERT INTO garis_kemiskinan (tahun, nilai, keterangan) VALUES
     (2025, 773124.00, ''Garis Kemiskinan Kota Jambi 2025 (Rp/kapita/bulan) — sumber: BPS Kota Jambi'')',
  'SELECT ''Tabel garis_kemiskinan sudah berisi data, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'Pembaruan database (Garis Kemiskinan) selesai.' AS status;
