-- =========================================================
-- SIKA - Skrip Pembaruan Database v5
-- Fitur: Tambah RT 09 & Peta Tematik berbasis Batas Wilayah Resmi
-- =========================================================
-- Berdasarkan data batas wilayah (SLS) resmi yang diunggah, Kelurahan
-- Mudung Laut memiliki 9 RT (RT 001 s.d. RT 009), sedangkan instalasi
-- sebelumnya hanya mendaftarkan 8 RT. Skrip ini menambahkan RT 09 jika
-- belum ada, TANPA mengubah/menghapus data RT/keluarga yang sudah ada.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin (http://localhost/phpmyadmin)
-- 2. Pilih database pemutakhiran_keluarga
-- 3. Buka tab "SQL"
-- 4. Copy-paste seluruh isi file ini, lalu klik "Go"
--
-- Setelah itu, salin juga file assets/mudunglaut_rt.geojson dari paket ini
-- ke folder assets/ pada instalasi Anda agar peta tematik pada Dashboard
-- Publik dapat menampilkan batas wilayah RT yang sebenarnya.
-- =========================================================

USE pemutakhiran_keluarga;

SET @exist := (SELECT COUNT(*) FROM rt WHERE nomor_rt IN ('09', '009'));
SET @sql := IF(@exist = 0,
  'INSERT INTO rt (nomor_rt, keterangan) VALUES (''009'', NULL)',
  'SELECT ''RT 09/009 sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'Pembaruan database (RT 09) selesai. Jangan lupa salin assets/mudunglaut_rt.geojson.' AS status;
