<?php
require_once __DIR__ . '/../includes/config.php';
requireRole('admin_kelurahan');
$id = $_GET['id'] ?? $_POST['id'] ?? null;
$user = ['nama'=>'','username'=>'','role'=>'ketua_rt','rt_id'=>'','status'=>'aktif'];
if ($id) {
    $stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
    $stmt->execute([$id]);
    $user = $stmt->fetch() ?: $user;
}
$pageTitle = $id ? 'Ubah Pengguna' : 'Tambah Pengguna';
$rtList = $pdo->query("SELECT * FROM rt ORDER BY nomor_rt")->fetchAll();
$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nama = trim($_POST['nama'] ?? '');
    $username = trim($_POST['username'] ?? '');
    $role = $_POST['role'] ?? '';
    $rt_id = $role === 'ketua_rt' ? ($_POST['rt_id'] ?? '') : null;
    $password = $_POST['password'] ?? '';

    if ($nama === '') $errors[] = 'Nama wajib diisi.';
    if ($username === '') $errors[] = 'Username wajib diisi.';
    if (!in_array($role, ['admin_kelurahan','operator_kelurahan','ketua_rt'])) $errors[] = 'Role tidak valid.';
    if ($role === 'ketua_rt' && !$rt_id) $errors[] = 'RT wajib dipilih untuk role Ketua RT.';
    if (!$id && $password === '') $errors[] = 'Password wajib diisi untuk pengguna baru.';

    if (empty($errors)) {
        $check = $pdo->prepare("SELECT id FROM users WHERE username = ? AND id != ?");
        $check->execute([$username, $id ?: 0]);
        if ($check->fetch()) $errors[] = 'Username sudah digunakan.';
    }

    if (empty($errors)) {
        if ($id) {
            if ($password !== '') {
                $stmt = $pdo->prepare("UPDATE users SET nama=?, username=?, role=?, rt_id=?, password=? WHERE id=?");
                $stmt->execute([$nama, $username, $role, $rt_id, password_hash($password, PASSWORD_DEFAULT), $id]);
            } else {
                $stmt = $pdo->prepare("UPDATE users SET nama=?, username=?, role=?, rt_id=? WHERE id=?");
                $stmt->execute([$nama, $username, $role, $rt_id, $id]);
            }
            $_SESSION['flash_success'] = 'Pengguna berhasil diperbarui.';
        } else {
            $stmt = $pdo->prepare("INSERT INTO users (nama, username, password, role, rt_id) VALUES (?,?,?,?,?)");
            $stmt->execute([$nama, $username, password_hash($password, PASSWORD_DEFAULT), $role, $rt_id]);
            $_SESSION['flash_success'] = 'Pengguna berhasil ditambahkan.';
        }
        header('Location: admin_users.php');
        exit;
    }
    $user = array_merge($user, $_POST);
}

require __DIR__ . '/../includes/partials_header.php';
?>
<h4 class="fw-semibold mb-3"><?= $id ? 'Ubah' : 'Tambah' ?> Pengguna</h4>
<?php if ($errors): ?><div class="alert alert-danger"><ul class="mb-0"><?php foreach($errors as $er) echo '<li>'.e($er).'</li>'; ?></ul></div><?php endif; ?>
<div class="card border-0 shadow-sm">
<div class="card-body">
<form method="post">
<?php if ($id): ?><input type="hidden" name="id" value="<?= (int)$id ?>"><?php endif; ?>
<div class="row g-3">
  <div class="col-md-6"><label class="form-label">Nama Lengkap<?= requiredMark() ?></label><input type="text" name="nama" class="form-control" value="<?= e($user['nama']) ?>" required></div>
  <div class="col-md-6"><label class="form-label">Username<?= requiredMark() ?></label><input type="text" name="username" class="form-control" value="<?= e($user['username']) ?>" required></div>
  <div class="col-md-6">
    <label class="form-label">Password <?= $id ? '(kosongkan jika tidak ingin diubah)' : requiredMark() ?></label>
    <input type="password" name="password" class="form-control" <?= $id ? '' : 'required' ?>>
  </div>
  <div class="col-md-3">
    <label class="form-label">Role<?= requiredMark() ?></label>
    <select name="role" id="roleSelect" class="form-select" required onchange="document.getElementById('rtWrap').style.display = this.value==='ketua_rt' ? 'block' : 'none'">
      <option value="ketua_rt" <?= $user['role']=='ketua_rt'?'selected':'' ?>>Ketua RT</option>
      <option value="operator_kelurahan" <?= $user['role']=='operator_kelurahan'?'selected':'' ?>>Operator Kelurahan</option>
      <option value="admin_kelurahan" <?= $user['role']=='admin_kelurahan'?'selected':'' ?>>Admin Kelurahan</option>
    </select>
  </div>
  <div class="col-md-3" id="rtWrap" style="display: <?= $user['role']=='ketua_rt' ? 'block':'none' ?>">
    <label class="form-label">RT<?= requiredMark() ?></label>
    <select name="rt_id" class="form-select">
      <option value="">Pilih RT</option>
      <?php foreach ($rtList as $rt): ?>
        <option value="<?= $rt['id'] ?>" <?= ($user['rt_id'] ?? '')==$rt['id']?'selected':'' ?>>RT <?= e($rt['nomor_rt']) ?></option>
      <?php endforeach; ?>
    </select>
  </div>
</div>
<div class="mt-4">
  <button class="btn btn-teal"><i class="bi bi-save"></i> Simpan</button>
  <a href="admin_users.php" class="btn btn-outline-secondary">Batal</a>
</div>
</form>
</div>
</div>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
