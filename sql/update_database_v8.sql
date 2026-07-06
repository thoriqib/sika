-- =========================================================
-- SIKA - Skrip Pembaruan Database v8
-- PERUBAHAN PROSES BISNIS: Pendataan hanya sampai level KELUARGA
-- =========================================================
-- Ringkasan perubahan:
-- 1. Data pribadi Kepala Keluarga (NIK, jenis kelamin, tanggal lahir, agama,
--    status perkawinan, pendidikan, status pekerjaan) dipindahkan LANGSUNG
--    ke tabel `keluarga` (sebelumnya tersimpan di `anggota_keluarga`).
-- 2. Jumlah anggota laki-laki/perempuan sekarang diisi LANGSUNG oleh
--    petugas (bukan dihitung otomatis dari data anggota).
-- 3. Kolom pengeluaran (makanan/non-makanan/total) DIHAPUS.
-- 4. Tabel `garis_kemiskinan` TIDAK DIHAPUS (data historis tetap aman),
--    namun sudah tidak dipakai aplikasi.
-- 5. Tabel `anggota_keluarga` TIDAK DIHAPUS (data historis per-anggota
--    yang sudah pernah diinput tetap tersimpan, hanya sudah tidak
--    ditampilkan/dipakai di aplikasi mulai versi ini).
-- 6. Kolom baru: pernah_bantuan, ada_umkm, jumlah_anggota_umkm.
--
-- Skrip ini AMAN dijalankan berkali-kali (idempoten) dan TIDAK menghapus
-- data yang sudah ada — data Kepala Keluarga dari anggota_keluarga akan
-- disalin (bukan dipindah) ke kolom baru di tabel keluarga.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin (http://localhost/phpmyadmin) atau akses via SSH/CLI
-- 2. Pilih database pemutakhiran_keluarga
-- 3. Buka tab "SQL"
-- 4. Copy-paste seluruh isi file ini, lalu klik "Go"
-- =========================================================

USE pemutakhiran_keluarga;

-- ===================== 1. Tambah kolom baru di tabel keluarga =====================
-- Semua kolom baru dibuat NULLable dulu supaya ALTER TABLE tidak gagal pada
-- data yang sudah ada, lalu diisi lewat backfill di langkah berikutnya.

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='nik_kepala_keluarga');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN nik_kepala_keluarga VARCHAR(20) NULL AFTER jumlah_total', 'SELECT ''Kolom nik_kepala_keluarga sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='jenis_kelamin_kepala_keluarga');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN jenis_kelamin_kepala_keluarga ENUM(''Laki-laki'',''Perempuan'') NULL AFTER nik_kepala_keluarga', 'SELECT ''Kolom jenis_kelamin_kepala_keluarga sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='tanggal_lahir_kepala_keluarga');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN tanggal_lahir_kepala_keluarga DATE NULL AFTER jenis_kelamin_kepala_keluarga', 'SELECT ''Kolom tanggal_lahir_kepala_keluarga sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='agama_kepala_keluarga');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN agama_kepala_keluarga VARCHAR(30) NULL AFTER tanggal_lahir_kepala_keluarga', 'SELECT ''Kolom agama_kepala_keluarga sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='status_perkawinan_kepala_keluarga');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN status_perkawinan_kepala_keluarga VARCHAR(30) NULL AFTER agama_kepala_keluarga', 'SELECT ''Kolom status_perkawinan_kepala_keluarga sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='pendidikan_kepala_keluarga');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN pendidikan_kepala_keluarga VARCHAR(50) NULL AFTER status_perkawinan_kepala_keluarga', 'SELECT ''Kolom pendidikan_kepala_keluarga sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='status_pekerjaan_kepala_keluarga');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN status_pekerjaan_kepala_keluarga VARCHAR(60) NULL AFTER pendidikan_kepala_keluarga', 'SELECT ''Kolom status_pekerjaan_kepala_keluarga sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='pekerjaan_kepala_keluarga');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN pekerjaan_kepala_keluarga VARCHAR(100) NULL AFTER status_pekerjaan_kepala_keluarga', 'SELECT ''Kolom pekerjaan_kepala_keluarga sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='pernah_bantuan');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN pernah_bantuan ENUM(''Ya'',''Tidak'') NOT NULL DEFAULT ''Tidak'' AFTER pekerjaan_kepala_keluarga', 'SELECT ''Kolom pernah_bantuan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='ada_umkm');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN ada_umkm ENUM(''Ya'',''Tidak'') NOT NULL DEFAULT ''Tidak'' AFTER pernah_bantuan', 'SELECT ''Kolom ada_umkm sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='jumlah_anggota_umkm');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN jumlah_anggota_umkm INT NULL AFTER ada_umkm', 'SELECT ''Kolom jumlah_anggota_umkm sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===================== 2. Backfill data Kepala Keluarga dari anggota_keluarga =====================
-- Hanya mengisi baris yang datanya masih kosong (aman dijalankan berkali-kali)
SET @exist_tbl := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='anggota_keluarga');
SET @sql := IF(@exist_tbl > 0,
  'UPDATE keluarga k
   JOIN anggota_keluarga a ON a.keluarga_id = k.id AND a.hubungan = ''Kepala Keluarga''
   SET k.nik_kepala_keluarga = COALESCE(k.nik_kepala_keluarga, a.nik),
       k.jenis_kelamin_kepala_keluarga = COALESCE(k.jenis_kelamin_kepala_keluarga, a.jenis_kelamin),
       k.tanggal_lahir_kepala_keluarga = COALESCE(k.tanggal_lahir_kepala_keluarga, a.tanggal_lahir),
       k.agama_kepala_keluarga = COALESCE(k.agama_kepala_keluarga, a.agama),
       k.status_perkawinan_kepala_keluarga = COALESCE(k.status_perkawinan_kepala_keluarga, a.status_perkawinan),
       k.pendidikan_kepala_keluarga = COALESCE(k.pendidikan_kepala_keluarga, a.pendidikan_terakhir),
       k.status_pekerjaan_kepala_keluarga = COALESCE(k.status_pekerjaan_kepala_keluarga, a.status_pekerjaan),
       k.pekerjaan_kepala_keluarga = COALESCE(k.pekerjaan_kepala_keluarga, a.pekerjaan)
   WHERE k.nik_kepala_keluarga IS NULL',
  'SELECT ''Tabel anggota_keluarga tidak ditemukan, backfill dilewati (kemungkinan instalasi baru).''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Untuk keluarga yang TIDAK punya data Kepala Keluarga sama sekali (jarang
-- terjadi), isi NIK sementara dengan placeholder unik supaya kolom UNIQUE
-- tidak bentrok — Admin WAJIB memperbaiki data ini secara manual kemudian.
SET @i := 0;
UPDATE keluarga
SET nik_kepala_keluarga = CONCAT('0000000000', LPAD(id, 6, '0')),
    jenis_kelamin_kepala_keluarga = 'Laki-laki',
    tanggal_lahir_kepala_keluarga = '1970-01-01'
WHERE nik_kepala_keluarga IS NULL;

-- Baru sekarang kolom-kolom wajib boleh diperketat jadi NOT NULL
ALTER TABLE keluarga
  MODIFY COLUMN nik_kepala_keluarga VARCHAR(20) NOT NULL,
  MODIFY COLUMN jenis_kelamin_kepala_keluarga ENUM('Laki-laki','Perempuan') NOT NULL,
  MODIFY COLUMN tanggal_lahir_kepala_keluarga DATE NOT NULL;

-- Tambahkan batasan UNIK pada NIK Kepala Keluarga jika belum ada
SET @exist := (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND INDEX_NAME='nik_kepala_keluarga');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD UNIQUE KEY nik_kepala_keluarga (nik_kepala_keluarga)', 'SELECT ''Batasan unik NIK Kepala Keluarga sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===================== 3. Hapus kolom pengeluaran (sudah tidak dipakai) =====================
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='pengeluaran_makanan');
SET @sql := IF(@exist>0, 'ALTER TABLE keluarga DROP COLUMN pengeluaran_makanan', 'SELECT ''Kolom pengeluaran_makanan sudah tidak ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='pengeluaran_non_makanan');
SET @sql := IF(@exist>0, 'ALTER TABLE keluarga DROP COLUMN pengeluaran_non_makanan', 'SELECT ''Kolom pengeluaran_non_makanan sudah tidak ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='pengeluaran_per_bulan');
SET @sql := IF(@exist>0, 'ALTER TABLE keluarga DROP COLUMN pengeluaran_per_bulan', 'SELECT ''Kolom pengeluaran_per_bulan sudah tidak ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===================== 4. Catatan tentang tabel yang sudah tidak dipakai =====================
-- Tabel `anggota_keluarga` dan `garis_kemiskinan` SENGAJA TIDAK DIHAPUS oleh
-- skrip ini, supaya data historis yang sudah pernah diinput tetap aman.
-- Aplikasi mulai versi ini tidak lagi membaca/menulis ke kedua tabel tsb.
-- Jika Anda YAKIN tidak memerlukan data historisnya sama sekali, kedua
-- tabel ini boleh dihapus manual (opsional, TIDAK WAJIB):
--   DROP TABLE IF EXISTS anggota_keluarga;
--   DROP TABLE IF EXISTS garis_kemiskinan;

SELECT 'Pembaruan database v8 (pendataan level keluarga) selesai.' AS status;
SELECT COUNT(*) AS jml_keluarga_dengan_data_kk_placeholder
FROM keluarga WHERE nik_kepala_keluarga LIKE '0000000000%';
