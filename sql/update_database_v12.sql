-- =========================================================
-- SIKA - Skrip Pembaruan Database v12
-- Fitur: Jenis Bantuan (checkbox), UMKM per gender, kategori Bangunan baru
-- =========================================================
-- Perubahan:
-- 1. Kolom `jenis_bantuan` (baru) — daftar jenis bantuan yang dipilih
--    (checkbox, bisa lebih dari satu), disimpan dipisah koma.
--    Kolom `deskripsi_bantuan` yang sudah ada TETAP DIPAKAI, sekarang
--    khusus untuk keterangan saat jenis bantuan "Lainnya" dipilih.
-- 2. Kolom `jumlah_anggota_umkm` (lama, gabungan) diganti menjadi dua
--    kolom terpisah: `jumlah_anggota_umkm_lk` dan `jumlah_anggota_umkm_pr`.
--    CATATAN: karena data lama hanya berupa total gabungan (tidak
--    memisah jenis kelamin), nilai lama TIDAK BISA otomatis dipecah
--    secara akurat — skrip ini memindahkan nilai lama apa adanya ke
--    kolom `jumlah_anggota_umkm_lk` sebagai perkiraan awal (kolom
--    perempuan diisi 0), silakan periksa & perbaiki manual data yang
--    sudah ada bila diperlukan.
-- 3. Kategori Bangunan pada tabel `rt` diubah dari 4 kategori lama
--    (Tempat Tinggal Terisi/Kosong, Khusus Usaha, Bukan Tinggal Non
--    Usaha) menjadi 5 kategori baru (Tempat Tinggal, Rumah Ibadah,
--    Fasilitas Pendidikan, Fasilitas Kesehatan, Kosong). KARENA
--    KATEGORINYA TIDAK SEPADAN 1:1, data lama TIDAK dipetakan otomatis
--    ke kategori baru — Admin/Operator/Ketua RT perlu menginput ulang
--    angka bangunan sesuai kategori baru (data lama tetap bisa dilihat
--    lewat query manual sebelum kolom lama dihapus, lihat catatan di
--    akhir skrip ini).
--
-- Skrip ini AMAN dijalankan berkali-kali dan TIDAK menghapus data
-- keluarga/RT lainnya.
--
-- Cara pakai:
-- 1. Buka phpMyAdmin, pilih database pemutakhiran_keluarga, tab SQL
-- 2. Copy-paste seluruh isi file ini, lalu klik "Go"
-- =========================================================

USE pemutakhiran_keluarga;

-- ===================== 1. Jenis Bantuan (checkbox) =====================
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='jenis_bantuan');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN jenis_bantuan VARCHAR(255) NULL AFTER pernah_bantuan', 'SELECT ''Kolom jenis_bantuan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===================== 2. UMKM per gender =====================
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='jumlah_anggota_umkm_lk');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN jumlah_anggota_umkm_lk INT NULL AFTER ada_umkm', 'SELECT ''Kolom jumlah_anggota_umkm_lk sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='jumlah_anggota_umkm_pr');
SET @sql := IF(@exist=0, 'ALTER TABLE keluarga ADD COLUMN jumlah_anggota_umkm_pr INT NULL AFTER jumlah_anggota_umkm_lk', 'SELECT ''Kolom jumlah_anggota_umkm_pr sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Pindahkan nilai lama (gabungan) ke kolom laki-laki sebagai perkiraan awal
SET @exist_old := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='keluarga' AND COLUMN_NAME='jumlah_anggota_umkm');
SET @sql := IF(@exist_old>0,
  'UPDATE keluarga SET jumlah_anggota_umkm_lk = jumlah_anggota_umkm, jumlah_anggota_umkm_pr = 0 WHERE ada_umkm = ''Ya'' AND jumlah_anggota_umkm_lk IS NULL AND jumlah_anggota_umkm IS NOT NULL',
  'SELECT ''Kolom jumlah_anggota_umkm lama tidak ditemukan, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(@exist_old>0, 'ALTER TABLE keluarga DROP COLUMN jumlah_anggota_umkm', 'SELECT ''Kolom jumlah_anggota_umkm sudah tidak ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ===================== 3. Kategori Bangunan baru pada tabel rt =====================
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_tinggal');
SET @sql := IF(@exist=0, 'ALTER TABLE rt ADD COLUMN jml_bangunan_tinggal INT NOT NULL DEFAULT 0 AFTER keterangan', 'SELECT ''Kolom jml_bangunan_tinggal sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_rumah_ibadah');
SET @sql := IF(@exist=0, 'ALTER TABLE rt ADD COLUMN jml_bangunan_rumah_ibadah INT NOT NULL DEFAULT 0 AFTER jml_bangunan_tinggal', 'SELECT ''Kolom jml_bangunan_rumah_ibadah sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_fasilitas_pendidikan');
SET @sql := IF(@exist=0, 'ALTER TABLE rt ADD COLUMN jml_bangunan_fasilitas_pendidikan INT NOT NULL DEFAULT 0 AFTER jml_bangunan_rumah_ibadah', 'SELECT ''Kolom jml_bangunan_fasilitas_pendidikan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_fasilitas_kesehatan');
SET @sql := IF(@exist=0, 'ALTER TABLE rt ADD COLUMN jml_bangunan_fasilitas_kesehatan INT NOT NULL DEFAULT 0 AFTER jml_bangunan_fasilitas_pendidikan', 'SELECT ''Kolom jml_bangunan_fasilitas_kesehatan sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_kosong');
SET @sql := IF(@exist=0, 'ALTER TABLE rt ADD COLUMN jml_bangunan_kosong INT NOT NULL DEFAULT 0 AFTER jml_bangunan_fasilitas_kesehatan', 'SELECT ''Kolom jml_bangunan_kosong sudah ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Hapus 4 kolom kategori bangunan LAMA (data lama akan hilang permanen —
-- jika perlu diarsipkan dulu, SELECT kolom-kolom ini sebelum menjalankan
-- bagian ini, atau lewati bagian DROP COLUMN di bawah dan hapus manual
-- belakangan setelah yakin tidak diperlukan lagi)
SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_tinggal_terisi');
SET @sql := IF(@exist>0, 'ALTER TABLE rt DROP COLUMN jml_bangunan_tinggal_terisi', 'SELECT ''Kolom jml_bangunan_tinggal_terisi sudah tidak ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_tinggal_kosong');
SET @sql := IF(@exist>0, 'ALTER TABLE rt DROP COLUMN jml_bangunan_tinggal_kosong', 'SELECT ''Kolom jml_bangunan_tinggal_kosong sudah tidak ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_khusus_usaha');
SET @sql := IF(@exist>0, 'ALTER TABLE rt DROP COLUMN jml_bangunan_khusus_usaha', 'SELECT ''Kolom jml_bangunan_khusus_usaha sudah tidak ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @exist := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='rt' AND COLUMN_NAME='jml_bangunan_bukan_tinggal_non_usaha');
SET @sql := IF(@exist>0, 'ALTER TABLE rt DROP COLUMN jml_bangunan_bukan_tinggal_non_usaha', 'SELECT ''Kolom jml_bangunan_bukan_tinggal_non_usaha sudah tidak ada, dilewati.''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'Pembaruan database v12 selesai. PENTING: periksa ulang data UMKM per gender dan input ulang data Bangunan sesuai 5 kategori baru.' AS status;
