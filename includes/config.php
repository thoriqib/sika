<?php
date_default_timezone_set('Asia/Jakarta'); // WIB (GMT+7) — semua tanggal/jam di aplikasi mengikuti zona ini
session_start();

// ================= Konfigurasi Database =================
// Sesuaikan jika pengaturan MySQL/XAMPP Anda berbeda
define('DB_HOST', 'localhost');
define('DB_NAME', 'pemutakhiran_keluarga');
define('DB_USER', 'root');
define('DB_PASS', '');
// ===========================================================

try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS
    );
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    die(
        "Koneksi database gagal. Pastikan service MySQL di XAMPP sudah aktif " .
        "dan database 'pemutakhiran_keluarga' sudah dibuat (lihat database.sql). " .
        "Detail teknis: " . $e->getMessage()
    );
}

require_once __DIR__ . '/functions.php';

tryAutoLoginFromCookie($pdo);
