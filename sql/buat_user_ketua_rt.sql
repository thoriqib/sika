-- =========================================================
-- SIKA - Buat/Perbarui Akun Ketua RT (data resmi)
-- =========================================================
-- Berisi 9 akun Ketua RT sesuai data resmi Kelurahan Mudung Laut:
--   RT 001 - KAPSUL ANWAR      RT 006 - MARINI
--   RT 002 - M RIDHO           RT 007 - SALAMUDIN
--   RT 003 - DAWIYAH           RT 008 - SIGIT
--   RT 004 - BUKHORI           RT 009 - HADI ISMANTO
--   RT 005 - A SAYUTI
--
-- Username : ketua_rt001 s.d. ketua_rt009 (sesuai nomor RT)
-- Password default: admin123 — SEGERA minta masing-masing Ketua RT
-- mengganti passwordnya setelah login pertama kali.
--
-- Skrip ini AMAN dijalankan berkali-kali: jika username sudah ada,
-- hanya NAMA-nya yang diperbarui (password/status tidak diubah/tidak
-- direset) — supaya tidak menimpa password yang sudah diganti sendiri
-- oleh Ketua RT yang bersangkutan. Jika username belum ada, akun baru
-- dibuat dengan password default di atas.
--
-- Cara pakai:
-- 1. Pastikan tabel `rt` sudah berisi RT 001 s.d. RT 009 (lihat database.sql)
-- 2. Buka phpMyAdmin, pilih database pemutakhiran_keluarga, tab SQL
-- 3. Copy-paste seluruh isi file ini, lalu klik "Go"
-- =========================================================

USE pemutakhiran_keluarga;

-- Hash bcrypt untuk password default "admin123"
SET @HASH := '$2b$12$.XGEn3Z1sA1sYSF9YYtsoeeDKlJJeuc/lCEsZL8n.kmGR/zoLA6QW';

INSERT INTO users (nama, username, password, role, rt_id, status)
SELECT 'KAPSUL ANWAR', 'ketua_rt001', @HASH, 'ketua_rt', id, 'aktif' FROM rt WHERE nomor_rt = '001'
ON DUPLICATE KEY UPDATE nama = VALUES(nama);

INSERT INTO users (nama, username, password, role, rt_id, status)
SELECT 'M RIDHO', 'ketua_rt002', @HASH, 'ketua_rt', id, 'aktif' FROM rt WHERE nomor_rt = '002'
ON DUPLICATE KEY UPDATE nama = VALUES(nama);

INSERT INTO users (nama, username, password, role, rt_id, status)
SELECT 'DAWIYAH', 'ketua_rt003', @HASH, 'ketua_rt', id, 'aktif' FROM rt WHERE nomor_rt = '003'
ON DUPLICATE KEY UPDATE nama = VALUES(nama);

INSERT INTO users (nama, username, password, role, rt_id, status)
SELECT 'BUKHORI', 'ketua_rt004', @HASH, 'ketua_rt', id, 'aktif' FROM rt WHERE nomor_rt = '004'
ON DUPLICATE KEY UPDATE nama = VALUES(nama);

INSERT INTO users (nama, username, password, role, rt_id, status)
SELECT 'A SAYUTI', 'ketua_rt005', @HASH, 'ketua_rt', id, 'aktif' FROM rt WHERE nomor_rt = '005'
ON DUPLICATE KEY UPDATE nama = VALUES(nama);

INSERT INTO users (nama, username, password, role, rt_id, status)
SELECT 'MARINI', 'ketua_rt006', @HASH, 'ketua_rt', id, 'aktif' FROM rt WHERE nomor_rt = '006'
ON DUPLICATE KEY UPDATE nama = VALUES(nama);

INSERT INTO users (nama, username, password, role, rt_id, status)
SELECT 'SALAMUDIN', 'ketua_rt007', @HASH, 'ketua_rt', id, 'aktif' FROM rt WHERE nomor_rt = '007'
ON DUPLICATE KEY UPDATE nama = VALUES(nama);

INSERT INTO users (nama, username, password, role, rt_id, status)
SELECT 'SIGIT', 'ketua_rt008', @HASH, 'ketua_rt', id, 'aktif' FROM rt WHERE nomor_rt = '008'
ON DUPLICATE KEY UPDATE nama = VALUES(nama);

INSERT INTO users (nama, username, password, role, rt_id, status)
SELECT 'HADI ISMANTO', 'ketua_rt009', @HASH, 'ketua_rt', id, 'aktif' FROM rt WHERE nomor_rt = '009'
ON DUPLICATE KEY UPDATE nama = VALUES(nama);

SELECT 'Akun Ketua RT berhasil dibuat/diperbarui.' AS status;
SELECT u.username, u.nama, r.nomor_rt, u.status
FROM users u JOIN rt r ON r.id = u.rt_id
WHERE u.role = 'ketua_rt' ORDER BY r.nomor_rt;
