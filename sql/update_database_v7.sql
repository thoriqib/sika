-- =========================================================
-- SIKA - Skrip Pembaruan Database v7
-- Perbaikan: Duplikat Nomor RT (penyebab error "Subquery returns
-- more than 1 row" saat impor sample_data.sql atau saat sistem mencari RT)
-- =========================================================
-- LATAR BELAKANG:
-- Tabel `rt` sebelumnya tidak memiliki batasan unik pada kolom nomor_rt,
-- sehingga pada kombinasi migrasi tertentu (terutama menjalankan
-- update_database_v5.sql pada database yang nomor RT-nya sudah 3 digit)
-- bisa menghasilkan dua baris RT dengan nomor yang sama persis, misalnya
-- dua baris "009". Ini menyebabkan query seperti
-- "(SELECT id FROM rt WHERE nomor_rt='009')" mengembalikan lebih dari
-- satu baris dan memicu error 1242.
--
-- Skrip ini AMAN dijalankan berkali-kali. Langkah yang dilakukan:
-- 1. Mendeteksi nomor RT yang terdaftar lebih dari sekali.
-- 2. Menggabungkannya: baris dengan id terkecil dipertahankan, seluruh
--    data keluarga & akun pengguna yang menunjuk ke baris duplikat
--    dipindahkan ke baris yang dipertahankan, baru baris duplikat dihapus.
-- 3. Menambahkan batasan UNIK pada kolom nomor_rt agar duplikat tidak
--    bisa terjadi lagi di masa depan.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin (http://localhost/phpmyadmin)
-- 2. Pilih database pemutakhiran_keluarga
-- 3. Buka tab "SQL"
-- 4. Copy-paste seluruh isi file ini, lalu klik "Go"
-- 5. Jalankan skrip ini SEBELUM mengimpor sample_data.sql jika Anda
--    sebelumnya mengalami error "Subquery returns more than 1 row".
-- =========================================================

USE pemutakhiran_keluarga;

-- Tampilkan dulu RT mana saja yang terdeteksi duplikat (untuk referensi Anda)
SELECT nomor_rt, COUNT(*) AS jumlah_baris
FROM rt
GROUP BY nomor_rt
HAVING COUNT(*) > 1;

-- Petakan setiap nomor_rt ke id yang paling kecil (baris yang akan dipertahankan)
DROP TEMPORARY TABLE IF EXISTS tmp_rt_keep;
CREATE TEMPORARY TABLE tmp_rt_keep AS
SELECT nomor_rt, MIN(id) AS keep_id
FROM rt
GROUP BY nomor_rt;

-- Daftar baris duplikat yang akan dihapus, beserta id pengganti yang dipertahankan
DROP TEMPORARY TABLE IF EXISTS tmp_rt_dupe;
CREATE TEMPORARY TABLE tmp_rt_dupe AS
SELECT r.id AS dupe_id, k.keep_id
FROM rt r
JOIN tmp_rt_keep k ON k.nomor_rt = r.nomor_rt
WHERE r.id <> k.keep_id;

-- Pindahkan referensi data keluarga yang menunjuk ke RT duplikat
UPDATE keluarga k
JOIN tmp_rt_dupe d ON d.dupe_id = k.rt_id
SET k.rt_id = d.keep_id;

-- Pindahkan referensi akun pengguna (Ketua RT) yang menunjuk ke RT duplikat
UPDATE users u
JOIN tmp_rt_dupe d ON d.dupe_id = u.rt_id
SET u.rt_id = d.keep_id;

-- Hapus baris RT duplikat yang sudah tidak direferensikan lagi
DELETE r FROM rt r
JOIN tmp_rt_dupe d ON d.dupe_id = r.id;

DROP TEMPORARY TABLE IF EXISTS tmp_rt_keep;
DROP TEMPORARY TABLE IF EXISTS tmp_rt_dupe;

-- Tambahkan batasan UNIK pada nomor_rt, jika belum ada, supaya duplikat
-- tidak bisa terjadi lagi di masa depan
SET @exist := (SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'rt' AND INDEX_NAME = 'nomor_rt');
SET @sql := IF(@exist = 0,
  'ALTER TABLE rt ADD UNIQUE KEY nomor_rt (nomor_rt)',
  'SELECT ''Batasan unik pada nomor_rt sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'Pembersihan RT duplikat & penambahan batasan unik selesai.' AS status;
SELECT id, nomor_rt, keterangan FROM rt ORDER BY nomor_rt;
