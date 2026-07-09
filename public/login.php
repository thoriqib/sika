<?php
require_once __DIR__ . '/../includes/config.php';
if (isLoggedIn()) { header('Location: ' . landingPageFor(currentUser()['role'])); exit; }

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';

    $stmt = $pdo->prepare("SELECT u.*, r.nomor_rt FROM users u LEFT JOIN rt r ON r.id = u.rt_id WHERE u.username = ? AND u.status = 'aktif'");
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password'])) {
        $_SESSION['user'] = [
            'id'        => $user['id'],
            'nama'      => $user['nama'],
            'username'  => $user['username'],
            'role'      => $user['role'],
            'rt_id'     => $user['rt_id'],
            'nomor_rt'  => $user['nomor_rt'],
        ];
        setRememberCookie($pdo, $user['id']);
        header('Location: ' . landingPageFor($user['role']));
        exit;
    } else {
        $error = 'Username atau password salah, atau akun tidak aktif.';
    }
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Masuk - SIKA Mudung Laut</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="assets/style.css" rel="stylesheet">
</head>
<body class="login-body d-flex align-items-center">
<div class="container">
  <div class="row justify-content-center">
    <div class="col-md-5 col-lg-4">
      <div class="card login-card shadow-lg border-0">
        <div class="card-body p-4">
          <div class="text-center mb-4">
            <i class="bi bi-houses-fill display-5 text-teal"></i>
            <h4 class="mt-2 mb-0 fw-bold">SIKA</h4>
            <div class="text-muted small">Sistem Informasi Keluarga</div>
            <div class="text-muted small">Kelurahan Mudung Laut &mdash; Kec. Pelayangan</div>
          </div>
          <?php if ($error): ?><div class="alert alert-danger py-2"><?= e($error) ?></div><?php endif; ?>
          <form method="post">
            <div class="mb-3">
              <label class="form-label">Username</label>
              <input type="text" name="username" class="form-control" required autofocus>
            </div>
            <div class="mb-3">
              <label class="form-label">Password</label>
              <input type="password" name="password" class="form-control" required>
            </div>
            <button type="submit" class="btn btn-teal w-100">Masuk</button>
          </form>
          <div class="text-center mt-3">
            <a href="public_dashboard.php" class="small"><i class="bi bi-bar-chart-line-fill"></i> Lihat Dashboard Publik (tanpa login)</a>
          </div>
        </div>
      </div>
      <p class="text-center text-white-50 small mt-3">Sistem Informasi Keluarga</p>
    </div>
  </div>
</div>
</body>
</html>
