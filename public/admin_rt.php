<?php
require_once __DIR__ . '/../includes/config.php';
requireRole(['admin_kelurahan', 'operator_kelurahan']);
$pageTitle = 'Manajemen RT';
$isAdmin = hasRole('admin_kelurahan');

function bangunanFields() {
    return [
        'jml_bangunan_tinggal_terisi' => 'Jumlah Bangunan Tempat Tinggal Terisi',
        'jml_bangunan_tinggal_kosong' => 'Jumlah Bangunan Kosong',
        'jml_bangunan_khusus_usaha' => 'Jumlah Bangunan Khusus Usaha',
        'jml_bangunan_bukan_tinggal_non_usaha' => 'Jumlah Bangunan Bukan Tempat Tinggal Non Usaha',
    ];
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = (int)($_POST['id'] ?? 0);

    $bangunan = [];
    foreach (array_keys(bangunanFields()) as $key) {
        $bangunan[$key] = max(0, (int)($_POST[$key] ?? 0));
    }

    if ($id > 0) {
        // ===== Mode Ubah =====
        // Operator Kelurahan hanya boleh memperbarui data bangunan, tidak boleh
        // mengubah Nomor RT / Keterangan (itu tetap wewenang Admin Kelurahan).
        if ($isAdmin) {
            $nomor = trim($_POST['nomor_rt'] ?? '');
            if ($nomor !== '' && ctype_digit($nomor)) $nomor = str_pad($nomor, 3, '0', STR_PAD_LEFT);
            $ket = trim($_POST['keterangan'] ?? '');
            if ($nomor === '') {
                $_SESSION['flash_error'] = 'Nomor RT wajib diisi.';
                header('Location: admin_rt.php'); exit;
            }
            $check = $pdo->prepare("SELECT id FROM rt WHERE nomor_rt = ? AND id != ?");
            $check->execute([$nomor, $id]);
            if ($check->fetch()) {
                $_SESSION['flash_error'] = "RT $nomor sudah dipakai RT lain.";
                header('Location: admin_rt.php'); exit;
            }
            $stmt = $pdo->prepare("UPDATE rt SET nomor_rt=?, keterangan=?,
                jml_bangunan_tinggal_terisi=?, jml_bangunan_tinggal_kosong=?,
                jml_bangunan_khusus_usaha=?, jml_bangunan_bukan_tinggal_non_usaha=?
                WHERE id=?");
            $stmt->execute([
                $nomor, $ket ?: null,
                $bangunan['jml_bangunan_tinggal_terisi'], $bangunan['jml_bangunan_tinggal_kosong'],
                $bangunan['jml_bangunan_khusus_usaha'], $bangunan['jml_bangunan_bukan_tinggal_non_usaha'],
                $id,
            ]);
        } else {
            // Operator: hanya kolom data bangunan yang diperbarui
            $stmt = $pdo->prepare("UPDATE rt SET
                jml_bangunan_tinggal_terisi=?, jml_bangunan_tinggal_kosong=?,
                jml_bangunan_khusus_usaha=?, jml_bangunan_bukan_tinggal_non_usaha=?
                WHERE id=?");
            $stmt->execute([
                $bangunan['jml_bangunan_tinggal_terisi'], $bangunan['jml_bangunan_tinggal_kosong'],
                $bangunan['jml_bangunan_khusus_usaha'], $bangunan['jml_bangunan_bukan_tinggal_non_usaha'],
                $id,
            ]);
        }
        $_SESSION['flash_success'] = 'Data RT berhasil diperbarui.';
    } elseif ($isAdmin) {
        // ===== Mode Tambah (khusus Admin Kelurahan) =====
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
                $stmt = $pdo->prepare("INSERT INTO rt (nomor_rt, keterangan,
                    jml_bangunan_tinggal_terisi, jml_bangunan_tinggal_kosong,
                    jml_bangunan_khusus_usaha, jml_bangunan_bukan_tinggal_non_usaha)
                    VALUES (?,?,?,?,?,?)");
                $stmt->execute([
                    $nomor, $ket ?: null,
                    $bangunan['jml_bangunan_tinggal_terisi'], $bangunan['jml_bangunan_tinggal_kosong'],
                    $bangunan['jml_bangunan_khusus_usaha'], $bangunan['jml_bangunan_bukan_tinggal_non_usaha'],
                ]);
                $_SESSION['flash_success'] = 'RT berhasil ditambahkan.';
            }
        }
    } else {
        $_SESSION['flash_error'] = 'Anda tidak memiliki akses untuk menambah RT baru.';
    }
    header('Location: admin_rt.php'); exit;
}

if (isset($_GET['delete'])) {
    if (!$isAdmin) {
        $_SESSION['flash_error'] = 'Anda tidak memiliki akses untuk menghapus RT.';
        header('Location: admin_rt.php'); exit;
    }
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
$totalBangunan = $pdo->query("SELECT
    COALESCE(SUM(jml_bangunan_tinggal_terisi),0) terisi,
    COALESCE(SUM(jml_bangunan_tinggal_kosong),0) kosong,
    COALESCE(SUM(jml_bangunan_khusus_usaha),0) usaha,
    COALESCE(SUM(jml_bangunan_bukan_tinggal_non_usaha),0) non_usaha
    FROM rt")->fetch();

require __DIR__ . '/../includes/partials_header.php';
?>
<h4 class="fw-semibold mb-3">Manajemen RT<?= $isAdmin ? '' : ' &amp; Data Bangunan' ?></h4>
<?php if (!$isAdmin): ?>
<div class="alert alert-light border small">
  <i class="bi bi-info-circle text-teal"></i>
  Sebagai Operator Kelurahan, Anda dapat memperbarui <strong>data bangunan</strong> tiap RT.
  Menambah/menghapus RT dan mengubah Nomor RT hanya dapat dilakukan oleh Admin Kelurahan.
</div>
<?php endif; ?>

<div class="row g-3 mb-3">
  <div class="col-6 col-md-3">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Bangunan Tempat Tinggal Terisi</div>
      <div class="fs-4 fw-bold text-teal"><?= number_format($totalBangunan['terisi']) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Bangunan Kosong</div>
      <div class="fs-4 fw-bold text-secondary"><?= number_format($totalBangunan['kosong']) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Bangunan Khusus Usaha</div>
      <div class="fs-4 fw-bold" style="color:#fd7e14"><?= number_format($totalBangunan['usaha']) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Bangunan Bukan Tinggal, Non Usaha</div>
      <div class="fs-4 fw-bold text-muted"><?= number_format($totalBangunan['non_usaha']) ?></div>
    </div></div>
  </div>
</div>

<div class="row g-3">
  <?php if ($isAdmin): ?>
  <div class="col-md-4">
    <div class="card border-0 shadow-sm">
      <div class="card-header bg-white fw-semibold">Tambah RT</div>
      <div class="card-body">
        <form method="post">
          <div class="mb-2"><label class="form-label">Nomor RT<?= requiredMark() ?></label><input type="text" name="nomor_rt" class="form-control" placeholder="contoh: 009" maxlength="3" required>
          <div class="form-text">Cukup ketik angkanya (mis. 9), sistem otomatis menyimpan sebagai 3 digit (009).</div></div>
          <div class="mb-3"><label class="form-label">Keterangan (opsional)</label><input type="text" name="keterangan" class="form-control"></div>
          <hr>
          <h6 class="text-muted small text-uppercase">Data Bangunan (opsional, bisa diisi belakangan)</h6>
          <?php foreach (bangunanFields() as $key => $label): ?>
            <div class="mb-2">
              <label class="form-label small"><?= e($label) ?></label>
              <input type="number" min="0" name="<?= $key ?>" class="form-control form-control-sm" value="0">
            </div>
          <?php endforeach; ?>
          <button class="btn btn-teal w-100 mt-2"><i class="bi bi-plus-lg"></i> Tambah</button>
        </form>
      </div>
    </div>
  </div>
  <?php endif; ?>
  <div class="<?= $isAdmin ? 'col-md-8' : 'col-md-12' ?>">
    <div class="card border-0 shadow-sm">
      <div class="table-responsive">
        <table class="table table-hover mb-0 table-mobile-cards">
          <thead class="table-light">
            <tr>
              <th>RT</th><th>Keterangan</th><th class="text-center">Jml Keluarga</th>
              <th class="text-center">Tinggal Terisi</th><th class="text-center">Kosong</th>
              <th class="text-center">Khusus Usaha</th><th class="text-center">Non Usaha</th>
              <th class="text-end">Aksi</th>
            </tr>
          </thead>
          <tbody>
          <?php foreach ($rtList as $rt): ?>
          <tr>
            <td data-label="RT">RT <?= e($rt['nomor_rt']) ?></td>
            <td data-label="Keterangan"><?= e($rt['keterangan']) ?></td>
            <td data-label="Jml Keluarga" class="text-center"><?= (int)$rt['jml_keluarga'] ?></td>
            <td data-label="Tinggal Terisi" class="text-center"><?= (int)$rt['jml_bangunan_tinggal_terisi'] ?></td>
            <td data-label="Kosong" class="text-center"><?= (int)$rt['jml_bangunan_tinggal_kosong'] ?></td>
            <td data-label="Khusus Usaha" class="text-center"><?= (int)$rt['jml_bangunan_khusus_usaha'] ?></td>
            <td data-label="Non Usaha" class="text-center"><?= (int)$rt['jml_bangunan_bukan_tinggal_non_usaha'] ?></td>
            <td data-label="Aksi" class="text-end td-action">
              <button type="button" class="btn btn-sm btn-outline-secondary" title="Ubah"
                onclick='bukaModalEdit(<?= json_encode($rt) ?>)'><i class="bi bi-pencil"></i></button>
              <?php if ($isAdmin): ?>
              <a href="admin_rt.php?delete=<?= $rt['id'] ?>" class="btn btn-sm btn-outline-danger" title="Hapus" onclick="return confirm('Hapus RT ini?')"><i class="bi bi-trash"></i></a>
              <?php endif; ?>
            </td>
          </tr>
          <?php endforeach; ?>
          <?php if (empty($rtList)): ?><tr><td colspan="8" class="text-center text-muted py-3">Belum ada data RT</td></tr><?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<!-- Modal Ubah RT -->
<div class="modal fade" id="modalEditRt" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <form method="post">
        <input type="hidden" name="id" id="editId">
        <div class="modal-header">
          <h5 class="modal-title">Ubah Data RT</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div class="mb-2">
            <label class="form-label">Nomor RT<?= $isAdmin ? requiredMark() : '' ?></label>
            <input type="text" name="nomor_rt" id="editNomorRt" class="form-control" maxlength="3" <?= $isAdmin ? 'required' : 'disabled' ?>>
          </div>
          <div class="mb-3">
            <label class="form-label">Keterangan</label>
            <input type="text" name="keterangan" id="editKeterangan" class="form-control" <?= $isAdmin ? '' : 'disabled' ?>>
          </div>
          <?php if (!$isAdmin): ?>
            <div class="form-text mb-2">Nomor RT &amp; Keterangan hanya dapat diubah oleh Admin Kelurahan.</div>
          <?php endif; ?>
          <hr>
          <h6 class="text-muted small text-uppercase">Data Bangunan</h6>
          <?php foreach (bangunanFields() as $key => $label): ?>
            <div class="mb-2">
              <label class="form-label small"><?= e($label) ?></label>
              <input type="number" min="0" name="<?= $key ?>" id="edit_<?= $key ?>" class="form-control form-control-sm">
            </div>
          <?php endforeach; ?>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Batal</button>
          <button type="submit" class="btn btn-teal">Simpan Perubahan</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
function bukaModalEdit(rt) {
  document.getElementById('editId').value = rt.id;
  document.getElementById('editNomorRt').value = rt.nomor_rt;
  document.getElementById('editKeterangan').value = rt.keterangan || '';
  document.getElementById('edit_jml_bangunan_tinggal_terisi').value = rt.jml_bangunan_tinggal_terisi;
  document.getElementById('edit_jml_bangunan_tinggal_kosong').value = rt.jml_bangunan_tinggal_kosong;
  document.getElementById('edit_jml_bangunan_khusus_usaha').value = rt.jml_bangunan_khusus_usaha;
  document.getElementById('edit_jml_bangunan_bukan_tinggal_non_usaha').value = rt.jml_bangunan_bukan_tinggal_non_usaha;
  new bootstrap.Modal(document.getElementById('modalEditRt')).show();
}
</script>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
