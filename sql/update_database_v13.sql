-- =========================================================
-- SIKA - Skrip Pembaruan Database v13
-- Fitur: Tanggal Terakhir Menerima Bantuan
-- =========================================================
-- Menambahkan kolom `tanggal_terakhir_bantuan` pada tabel `keluarga`,
-- diisi jika keluarga pernah menerima bantuan pemerintah (pernah_bantuan
-- = 'Ya').
--
-- CATATAN: pilihan Jenis Bantuan "Bantuan Pangan" diganti menjadi "BLT"
-- mulai versi ini. Kolom `jenis_bantuan` berupa teks bebas (bukan ENUM),
-- jadi data lama yang sudah tersimpan dengan nilai "Bantuan Pangan" TETAP
-- UTUH apa adanya (tidak diubah otomatis oleh skrip ini) — hanya pilihan
-- baru yang ditawarkan di formulir/impor yang berubah menjadi "BLT".
--
-- Skrip ini AMAN dijalankan berkali-kali dan TIDAK menghapus data yang
-- sudah ada.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin, pilih database pemutakhiran_keluarga, tab SQL
-- 2. Copy-paste seluruh isi file ini, lalu klik "Go"
-- =========================================================

USE pemutakhiran_keluarga;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='tanggal_terakhir_bantuan');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN tanggal_terakhir_bantuan DATE NULL AFTER jenis_bantuan', 'SELECT ''Kolom tanggal_terakhir_bantuan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'Pembaruan database v13 selesai.' AS status;
