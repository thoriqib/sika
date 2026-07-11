<?php require_once __DIR__ . '/config.php'; ?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= isset($pageTitle) ? e($pageTitle) . ' - ' : '' ?>SIKA Mudung Laut</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="assets/style.css" rel="stylesheet">
</head>
<body>
<?php if (isLoggedIn()): $u = currentUser(); ?>
<nav class="navbar navbar-expand-lg navbar-dark app-navbar">
  <div class="container-fluid">
    <a class="navbar-brand fw-semibold" href="dashboard.php" title="Sistem Informasi Keluarga"><i class="bi bi-houses-fill me-2"></i>SIKA <span class="fw-light">Mudung Laut</span></a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navMain">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navMain">
      <ul class="navbar-nav me-auto mb-2 mb-lg-0">
        <li class="nav-item"><a class="nav-link" href="dashboard.php"><i class="bi bi-speedometer2"></i> Dashboard</a></li>
        <li class="nav-item"><a class="nav-link" href="keluarga_list.php"><i class="bi bi-people-fill"></i> Data Keluarga</a></li>
        <li class="nav-item"><a class="nav-link" href="public_dashboard.php" target="_blank"><i class="bi bi-bar-chart-line-fill"></i> Dashboard Publik</a></li>
        <?php if (hasRole(['operator_kelurahan'])): ?>
        <li class="nav-item"><a class="nav-link" href="admin_rt.php"><i class="bi bi-building"></i> Data RT &amp; Bangunan</a></li>
        <li class="nav-item"><a class="nav-link" href="repositori_data.php"><i class="bi bi-archive-fill"></i> Repositori Data</a></li>
        <?php endif; ?>
        <?php if (hasRole(['admin_kelurahan'])): ?>
        <li class="nav-item dropdown">
          <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown"><i class="bi bi-gear-fill"></i> Administrasi</a>
          <ul class="dropdown-menu">
            <li><a class="dropdown-item" href="admin_users.php">Manajemen Pengguna</a></li>
            <li><a class="dropdown-item" href="admin_rt.php">Manajemen RT</a></li>
            <li><a class="dropdown-item" href="admin_fields.php">Manajemen Variabel Tambahan</a></li>
            <li><hr class="dropdown-divider"></li>
            <li><a class="dropdown-item" href="repositori_data.php">Repositori Data</a></li>
          </ul>
        </li>
        <?php endif; ?>
      </ul>
      <ul class="navbar-nav align-items-lg-center">
        <li class="nav-item d-flex align-items-center text-light me-lg-3 mb-2 mb-lg-0">
          <i class="bi bi-person-circle me-1"></i> <?= e($u['nama']) ?>
          <span class="badge bg-light text-dark ms-2"><?= e(roleLabel($u['role'])) ?></span>
        </li>
        <li class="nav-item"><a class="btn btn-outline-light btn-sm" href="logout.php"><i class="bi bi-box-arrow-right"></i> Keluar</a></li>
      </ul>
    </div>
  </div>
</nav>
<?php endif; ?>
<main class="container py-4">
<?php if (!empty($_SESSION['flash_success'])): ?>
  <div class="alert alert-success alert-dismissible fade show"><?= e($_SESSION['flash_success']) ?><button class="btn-close" data-bs-dismiss="alert"></button></div>
  <?php unset($_SESSION['flash_success']); ?>
<?php endif; ?>
<?php if (!empty($_SESSION['flash_error'])): ?>
  <div class="alert alert-danger alert-dismissible fade show"><?= e($_SESSION['flash_error']) ?><button class="btn-close" data-bs-dismiss="alert"></button></div>
  <?php unset($_SESSION['flash_error']); ?>
<?php endif; ?>
