<?php
require_once __DIR__ . '/../includes/config.php';
requireRole('admin_kelurahan');
$pageTitle = 'Variabel Tambahan';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $label = trim($_POST['field_label'] ?? '');
    $type = $_POST['field_type'] ?? 'text';
    $options = trim($_POST['field_options'] ?? '');
    $unit = trim($_POST['field_unit'] ?? '');
    $required = isset($_POST['is_required']) ? 1 : 0;

    $key = strtolower(preg_replace('/[^a-zA-Z0-9]+/', '_', $label));
    $key = trim($key, '_');

    if ($label !== '' && $key !== '') {
        $maxUrutan = $pdo->query("SELECT COALESCE(MAX(urutan),0) m FROM custom_fields")->fetch()['m'];
        $stmt = $pdo->prepare("INSERT INTO custom_fields (target_table, field_key, field_label, field_type, field_options, field_unit, is_required, urutan) VALUES ('keluarga',?,?,?,?,?,?,?)");
        $stmt->execute([$key, $label, $type, $options, $unit ?: null, $required, $maxUrutan + 1]);
        $_SESSION['flash_success'] = 'Variabel tambahan berhasil ditambahkan.';
    } else {
        $_SESSION['flash_error'] = 'Nama variabel tidak valid.';
    }
    header('Location: admin_fields.php'); exit;
}

if (isset($_GET['delete'])) {
    $id = (int)$_GET['delete'];
    $pdo->prepare("DELETE FROM custom_fields WHERE id = ?")->execute([$id]); // custom_field_values ikut terhapus (cascade)
    $_SESSION['flash_success'] = 'Variabel tambahan berhasil dihapus.';
    header('Location: admin_fields.php'); exit;
}

$keluargaFields = getCustomFields($pdo, 'keluarga');

require __DIR__ . '/../includes/partials_header.php';
?>
<h4 class="fw-semibold mb-3">Manajemen Variabel Tambahan</h4>
<p class="text-muted">Gunakan halaman ini untuk menambah kolom/variabel baru pada formulir Data Keluarga, tanpa perlu mengubah kode aplikasi.</p>

<div class="card border-0 shadow-sm mb-4">
  <div class="card-header bg-white fw-semibold">Tambah Variabel Baru</div>
  <div class="card-body">
    <form method="post" class="row g-3">
      <div class="col-md-3">
        <label class="form-label">Nama Variabel<?= requiredMark() ?></label>
        <input type="text" name="field_label" class="form-control" placeholder="contoh: Kepemilikan Rumah" required>
      </div>
      <div class="col-md-2">
        <label class="form-label">Tipe</label>
        <select name="field_type" class="form-select">
          <option value="text">Teks</option>
          <option value="number">Angka</option>
          <option value="date">Tanggal</option>
          <option value="select">Pilihan (dropdown)</option>
          <option value="textarea">Teks Panjang</option>
        </select>
      </div>
      <div class="col-md-3">
        <label class="form-label">Opsi (untuk dropdown, pisahkan dengan koma)</label>
        <input type="text" name="field_options" class="form-control" placeholder="Milik Sendiri, Sewa, Menumpang">
      </div>
      <div class="col-md-2">
        <label class="form-label">Satuan (opsional)</label>
        <input type="text" name="field_unit" class="form-control" placeholder="contoh: m2, kg, orang">
      </div>
      <div class="col-md-2 d-flex align-items-end">
        <div class="form-check">
          <input class="form-check-input" type="checkbox" name="is_required" id="req">
          <label class="form-check-label small" for="req">Wajib</label>
        </div>
      </div>
      <div class="col-12"><button class="btn btn-teal"><i class="bi bi-plus-lg"></i> Tambah Variabel</button></div>
    </form>
  </div>
</div>

<div class="card border-0 shadow-sm">
  <div class="card-header bg-white fw-semibold">Variabel Data Keluarga</div>
  <ul class="list-group list-group-flush">
    <?php foreach ($keluargaFields as $f): ?>
    <li class="list-group-item d-flex justify-content-between align-items-center">
      <span><?= e($f['field_label']) ?> <span class="badge bg-light text-dark border"><?= e($f['field_type']) ?></span><?php if ($f['field_unit']): ?> <span class="badge bg-light text-dark border">satuan: <?= e($f['field_unit']) ?></span><?php endif; ?></span>
      <a href="admin_fields.php?delete=<?= $f['id'] ?>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Hapus variabel ini? Semua data pada variabel ini akan ikut terhapus.')"><i class="bi bi-trash"></i></a>
    </li>
    <?php endforeach; ?>
    <?php if (empty($keluargaFields)): ?><li class="list-group-item text-muted">Belum ada variabel tambahan.</li><?php endif; ?>
  </ul>
</div>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
