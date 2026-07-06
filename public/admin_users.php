<?php
require_once __DIR__ . '/../includes/config.php';
requireRole('admin_kelurahan');
$pageTitle = 'Manajemen Pengguna';

if (isset($_GET['toggle'])) {
    $uid = (int)$_GET['toggle'];
    $stmt = $pdo->prepare("SELECT status FROM users WHERE id = ?");
    $stmt->execute([$uid]);
    $u = $stmt->fetch();
    if ($u) {
        $new = $u['status'] === 'aktif' ? 'nonaktif' : 'aktif';
        $pdo->prepare("UPDATE users SET status = ? WHERE id = ?")->execute([$new, $uid]);
        $_SESSION['flash_success'] = 'Status pengguna berhasil diubah.';
    }
    header('Location: admin_users.php'); exit;
}

if (isset($_GET['delete'])) {
    $uid = (int)$_GET['delete'];
    if ($uid === currentUser()['id']) {
        $_SESSION['flash_error'] = 'Anda tidak dapat menghapus akun Anda sendiri.';
    } else {
        $pdo->prepare("DELETE FROM users WHERE id = ?")->execute([$uid]);
        $_SESSION['flash_success'] = 'Pengguna berhasil dihapus.';
    }
    header('Location: admin_users.php'); exit;
}

$users = $pdo->query("SELECT u.*, r.nomor_rt FROM users u LEFT JOIN rt r ON r.id=u.rt_id ORDER BY u.role, u.nama")->fetchAll();

require __DIR__ . '/../includes/partials_header.php';
?>
<div class="d-flex justify-content-between align-items-center mb-3">
  <h4 class="fw-semibold mb-0">Manajemen Pengguna</h4>
  <a href="admin_users_form.php" class="btn btn-teal"><i class="bi bi-plus-lg"></i> Tambah Pengguna</a>
</div>
<div class="card border-0 shadow-sm">
<div class="table-responsive">
<table class="table table-hover mb-0 align-middle table-mobile-cards">
<thead class="table-light"><tr><th>Nama</th><th>Username</th><th>Role</th><th>RT</th><th>Status</th><th class="text-end">Aksi</th></tr></thead>
<tbody>
<?php foreach ($users as $u): ?>
<tr>
  <td data-label="Nama"><?= e($u['nama']) ?></td>
  <td data-label="Username"><?= e($u['username']) ?></td>
  <td data-label="Role"><span class="badge bg-info text-dark"><?= e(roleLabel($u['role'])) ?></span></td>
  <td data-label="RT"><?= $u['nomor_rt'] ? 'RT '.e($u['nomor_rt']) : '-' ?></td>
  <td data-label="Status"><span class="badge <?= $u['status']=='aktif'?'bg-success':'bg-secondary' ?>"><?= e(ucfirst($u['status'])) ?></span></td>
  <td data-label="Aksi" class="text-end td-action">
    <a href="admin_users_form.php?id=<?= $u['id'] ?>" class="btn btn-sm btn-outline-secondary" title="Ubah"><i class="bi bi-pencil"></i></a>
    <a href="admin_users.php?toggle=<?= $u['id'] ?>" class="btn btn-sm btn-outline-warning" title="Aktifkan/Nonaktifkan"><i class="bi bi-power"></i></a>
    <a href="admin_users.php?delete=<?= $u['id'] ?>" class="btn btn-sm btn-outline-danger" title="Hapus" onclick="return confirm('Hapus pengguna ini?')"><i class="bi bi-trash"></i></a>
  </td>
</tr>
<?php endforeach; ?>
<?php if (empty($users)): ?><tr><td colspan="6" class="text-center text-muted py-4">Belum ada pengguna</td></tr><?php endif; ?>
</tbody>
</table>
</div>
</div>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
