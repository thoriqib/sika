-- =========================================================
-- SIKA - Skrip Pembaruan Database v6
-- Fitur: Penyeragaman Nomor RT menjadi 3 digit (mis. "001")
-- =========================================================
-- Sebelumnya nomor RT disimpan 2 digit (mis. "01"). Mulai versi ini,
-- nomor RT diseragamkan menjadi 3 digit (mis. "001") agar konsisten
-- dengan format kode wilayah resmi (SLS). Skrip ini AMAN dijalankan
-- berkali-kali dan TIDAK mengubah data keluarga/anggota — hanya
-- memperbarui teks nomor RT itu sendiri.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin (http://localhost/phpmyadmin)
-- 2. Pilih database pemutakhiran_keluarga
-- 3. Buka tab "SQL"
-- 4. Copy-paste seluruh isi file ini, lalu klik "Go"
-- =========================================================

USE pemutakhiran_keluarga;

UPDATE rt
SET nomor_rt = LPAD(nomor_rt, 3, '0')
WHERE CHAR_LENGTH(nomor_rt) < 3 AND nomor_rt REGEXP '^[0-9]+$';

SELECT 'Pembaruan database (Nomor RT 3 digit) selesai.' AS status;
SELECT id, nomor_rt FROM rt ORDER BY nomor_rt;
