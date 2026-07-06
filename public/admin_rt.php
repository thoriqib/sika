<?php
require_once __DIR__ . '/../includes/config.php';
requireRole('admin_kelurahan');
$pageTitle = 'Manajemen RT';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nomor = trim($_POST['nomor_rt'] ?? '');
    if ($nomor !== '' && ctype_digit($nomor)) $nomor = str_pad($nomor, 3, '0', STR_PAD_LEFT);
    $ket = trim($_POST['keterangan'] ?? '');
    if ($nomor === '') {
        $_SESSION['flash_error'] = 'Nomor RT wajib diisi.';
    } else {
        $check = $pdo->prepare("SELECT id FROM rt WHERE nomor_rt = ?");
        $check->execute([$nomor]);
        if ($check->fetch()) {
            $_SESSION['flash_error'] = "RT $nomor sudah terdaftar sebelumnya. Tidak bisa menambahkan RT dengan nomor yang sama.";
        } else {
            $pdo->prepare("INSERT INTO rt (nomor_rt, keterangan) VALUES (?,?)")->execute([$nomor, $ket ?: null]);
            $_SESSION['flash_success'] = 'RT berhasil ditambahkan.';
        }
    }
    header('Location: admin_rt.php'); exit;
}

if (isset($_GET['delete'])) {
    $id = (int)$_GET['delete'];
    $check = $pdo->prepare("SELECT COUNT(*) c FROM keluarga WHERE rt_id = ?");
    $check->execute([$id]);
    if ($check->fetch()['c'] > 0) {
        $_SESSION['flash_error'] = 'RT tidak dapat dihapus karena masih memiliki data keluarga.';
    } else {
        $pdo->prepare("DELETE FROM rt WHERE id = ?")->execute([$id]);
        $_SESSION['flash_success'] = 'RT berhasil dihapus.';
    }
    header('Location: admin_rt.php'); exit;
}

$rtList = $pdo->query("SELECT r.*, (SELECT COUNT(*) FROM keluarga k WHERE k.rt_id=r.id) jml_keluarga FROM rt r ORDER BY r.nomor_rt")->fetchAll();
require __DIR__ . '/../includes/partials_header.php';
?>
<h4 class="fw-semibold mb-3">Manajemen RT</h4>
<div class="row g-3">
  <div class="col-md-4">
    <div class="card border-0 shadow-sm">
      <div class="card-header bg-white fw-semibold">Tambah RT</div>
      <div class="card-body">
        <form method="post">
          <div class="mb-2"><label class="form-label">Nomor RT<?= requiredMark() ?></label><input type="text" name="nomor_rt" class="form-control" placeholder="contoh: 009" maxlength="3" required>
          <div class="form-text">Cukup ketik angkanya (mis. 9), sistem otomatis menyimpan sebagai 3 digit (009).</div></div>
          <div class="mb-3"><label class="form-label">Keterangan (opsional)</label><input type="text" name="keterangan" class="form-control"></div>
          <button class="btn btn-teal w-100"><i class="bi bi-plus-lg"></i> Tambah</button>
        </form>
      </div>
    </div>
  </div>
  <div class="col-md-8">
    <div class="card border-0 shadow-sm">
      <div class="table-responsive">
        <table class="table table-hover mb-0 table-mobile-cards">
          <thead class="table-light"><tr><th>RT</th><th>Keterangan</th><th>Jml Keluarga</th><th class="text-end">Aksi</th></tr></thead>
          <tbody>
          <?php foreach ($rtList as $rt): ?>
          <tr>
            <td data-label="RT">RT <?= e($rt['nomor_rt']) ?></td>
            <td data-label="Keterangan"><?= e($rt['keterangan']) ?></td>
            <td data-label="Jml Keluarga"><?= (int)$rt['jml_keluarga'] ?></td>
            <td data-label="Aksi" class="text-end td-action"><a href="admin_rt.php?delete=<?= $rt['id'] ?>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Hapus RT ini?')"><i class="bi bi-trash"></i></a></td>
          </tr>
          <?php endforeach; ?>
          <?php if (empty($rtList)): ?><tr><td colspan="4" class="text-center text-muted py-3">Belum ada data RT</td></tr><?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
