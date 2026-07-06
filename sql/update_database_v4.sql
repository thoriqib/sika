-- =========================================================
-- SIKA - Skrip Pembaruan Database v4
-- Fitur: Status Pekerjaan terinci, Pengeluaran Makanan/Non-Makanan
-- =========================================================
-- Gunakan file ini jika database Anda sudah pernah dibuat sebelumnya
-- dan ingin menambahkan fitur-fitur ini tanpa kehilangan data.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin (http://localhost/phpmyadmin)
-- 2. Pilih database pemutakhiran_keluarga
-- 3. Buka tab "SQL"
-- 4. Copy-paste seluruh isi file ini, lalu klik "Go"
--
-- Jika Anda BELUM pernah install sebelumnya (install baru), TIDAK PERLU
-- menjalankan file ini — database.sql yang terbaru sudah menyertakan
-- kolom-kolom ini secara otomatis.
-- =========================================================

USE pemutakhiran_keluarga;

-- Tambah kolom status_pekerjaan pada anggota_keluarga (jika belum ada)
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'anggota_keluarga' AND COLUMN_NAME = 'status_pekerjaan');
SET @sql := IF(@exist = 0,
  'ALTER TABLE anggota_keluarga ADD COLUMN status_pekerjaan VARCHAR(60) NULL AFTER pendidikan_terakhir',
  'SELECT ''Kolom status_pekerjaan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Perbesar kolom pekerjaan agar muat deskripsi bebas (jika masih VARCHAR(50))
ALTER TABLE anggota_keluarga MODIFY COLUMN pekerjaan VARCHAR(100) NULL;

-- Tambah kolom pengeluaran_makanan pada keluarga (jika belum ada)
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'keluarga' AND COLUMN_NAME = 'pengeluaran_makanan');
SET @sql := IF(@exist = 0,
  'ALTER TABLE keluarga ADD COLUMN pengeluaran_makanan DECIMAL(15,2) DEFAULT 0 AFTER nomor_kk',
  'SELECT ''Kolom pengeluaran_makanan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Tambah kolom pengeluaran_non_makanan pada keluarga (jika belum ada)
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'keluarga' AND COLUMN_NAME = 'pengeluaran_non_makanan');
SET @sql := IF(@exist = 0,
  'ALTER TABLE keluarga ADD COLUMN pengeluaran_non_makanan DECIMAL(15,2) DEFAULT 0 AFTER pengeluaran_makanan',
  'SELECT ''Kolom pengeluaran_non_makanan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Untuk data lama yang sudah punya pengeluaran_per_bulan tapi belum punya
-- rincian makanan/non-makanan, isi sementara: 60% makanan, 40% non-makanan
-- (silakan sesuaikan/edit manual per keluarga lewat menu Ubah Keluarga)
UPDATE keluarga
SET pengeluaran_makanan = ROUND(pengeluaran_per_bulan * 0.6, 0),
    pengeluaran_non_makanan = ROUND(pengeluaran_per_bulan * 0.4, 0)
WHERE pengeluaran_makanan = 0 AND pengeluaran_non_makanan = 0 AND pengeluaran_per_bulan > 0;

SELECT 'Pembaruan database (Status Pekerjaan & Pengeluaran Makanan/Non-Makanan) selesai.' AS status;
