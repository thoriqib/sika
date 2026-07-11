<?php
require_once __DIR__ . '/../includes/config.php';
requireLogin();
$pageTitle = 'Data Keluarga';

$search = trim($_GET['q'] ?? '');
$rtFilter = $_GET['rt'] ?? '';
$bantuanFilter = $_GET['bantuan'] ?? '';
$umkmFilter = $_GET['umkm'] ?? '';
$keberadaanFilter = $_GET['keberadaan'] ?? '';

$rtList = $pdo->query("SELECT * FROM rt ORDER BY nomor_rt")->fetchAll();

$myRt = null;
if (hasRole('ketua_rt')) {
    $stmtMyRt = $pdo->prepare("SELECT * FROM rt WHERE id = ?");
    $stmtMyRt->execute([currentUser()['rt_id']]);
    $myRt = $stmtMyRt->fetch();
}
$bangunanFieldsList = [
    'jml_bangunan_tinggal' => 'Jumlah Bangunan Tempat Tinggal',
    'jml_bangunan_rumah_ibadah' => 'Jumlah Bangunan Rumah Ibadah',
    'jml_bangunan_fasilitas_pendidikan' => 'Jumlah Bangunan Fasilitas Pendidikan',
    'jml_bangunan_fasilitas_kesehatan' => 'Jumlah Bangunan Fasilitas Kesehatan',
    'jml_bangunan_kosong' => 'Jumlah Bangunan Kosong',
];

$where = "WHERE 1=1";
$params = [];

if (hasRole('ketua_rt')) {
    $where .= " AND k.rt_id = ?";
    $params[] = currentUser()['rt_id'];
} elseif ($rtFilter !== '') {
    $where .= " AND k.rt_id = ?";
    $params[] = $rtFilter;
}

if ($search !== '') {
    $where .= " AND (k.nama_kepala_keluarga LIKE ? OR k.nomor_kk LIKE ? OR k.alamat LIKE ?)";
    $like = "%$search%";
    $params[] = $like; $params[] = $like; $params[] = $like;
}

if (in_array($bantuanFilter, ['Ya','Tidak'], true)) {
    $where .= " AND k.pernah_bantuan = ?";
    $params[] = $bantuanFilter;
}
if (in_array($umkmFilter, ['Ya','Tidak'], true)) {
    $where .= " AND k.ada_umkm = ?";
    $params[] = $umkmFilter;
}
if (in_array($keberadaanFilter, ['Ada','Pindah'], true)) {
    $where .= " AND k.status_keberadaan = ?";
    $params[] = $keberadaanFilter;
}

$countStmt = $pdo->prepare("SELECT COUNT(*) c FROM keluarga k JOIN rt r ON r.id = k.rt_id $where");
$countStmt->execute($params);
$totalRows = (int)$countStmt->fetch()['c'];

$pg = paginationParams($totalRows, 25);

// Deteksi apakah ada filter yang sedang aktif dipilih pengguna (RT tetap milik
// Ketua RT tidak dihitung sebagai "filter" karena itu bukan pilihan, tapi
// batasan akses bawaan perannya).
$adaFilterAktif = $search !== ''
    || ($rtFilter !== '' && !hasRole('ketua_rt'))
    || in_array($bantuanFilter, ['Ya','Tidak'], true)
    || in_array($umkmFilter, ['Ya','Tidak'], true)
    || in_array($keberadaanFilter, ['Ada','Pindah'], true);

$sql = "SELECT k.*, r.nomor_rt FROM keluarga k JOIN rt r ON r.id = k.rt_id $where ORDER BY k.nama_kepala_keluarga ASC LIMIT {$pg['perPage']} OFFSET {$pg['offset']}";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$data = $stmt->fetchAll();

require __DIR__ . '/../includes/partials_header.php';
?>
<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
  <h4 class="fw-semibold mb-0">Data Keluarga</h4>
  <div class="d-flex gap-2 flex-wrap">
    <?php if (hasRole(['operator_kelurahan','admin_kelurahan'])): ?>
    <a href="keluarga_export.php?<?= http_build_query($_GET) ?>" class="btn btn-outline-secondary" title="<?= $adaFilterAktif ? 'Mengunduh data sesuai filter yang aktif saat ini' : 'Mengunduh seluruh data (tidak ada filter aktif)' ?>">
      <i class="bi bi-download"></i> Unduh Data
      <?php if ($adaFilterAktif): ?>
        <span class="badge bg-teal ms-1">Terfilter &bull; <?= number_format($totalRows) ?></span>
      <?php else: ?>
        <span class="badge bg-secondary ms-1">Semua &bull; <?= number_format($totalRows) ?></span>
      <?php endif; ?>
    </a>
    <a href="keluarga_import.php" class="btn btn-outline-secondary"><i class="bi bi-upload"></i> Impor dari Excel</a>
    <?php endif; ?>
    <a href="keluarga_create.php" class="btn btn-teal"><i class="bi bi-plus-lg"></i> Tambah Keluarga</a>
    <?php if (hasRole('ketua_rt') && $myRt): ?>
    <button type="button" class="btn btn-outline-secondary" onclick="bukaModalBangunan()"><i class="bi bi-building"></i> Update Jumlah Bangunan</button>
    <?php endif; ?>
  </div>
</div>

<div class="card border-0 shadow-sm mb-3">
  <div class="card-body">
    <form class="row g-2" method="get">
      <div class="col-md-3">
        <input type="text" name="q" value="<?= e($search) ?>" class="form-control" placeholder="Cari nama, no. KK, atau alamat...">
      </div>
      <?php if (!hasRole('ketua_rt')): ?>
      <div class="col-md-2">
        <select name="rt" class="form-select">
          <option value="">Semua RT</option>
          <?php foreach ($rtList as $rt): ?>
            <option value="<?= $rt['id'] ?>" <?= (string)$rtFilter === (string)$rt['id'] ? 'selected' : '' ?>>RT <?= e($rt['nomor_rt']) ?></option>
          <?php endforeach; ?>
        </select>
      </div>
      <?php endif; ?>
      <div class="col-md-2">
        <select name="keberadaan" class="form-select">
          <option value="">Semua (Keberadaan)</option>
          <option value="Ada" <?= $keberadaanFilter==='Ada'?'selected':'' ?>>Ada</option>
          <option value="Pindah" <?= $keberadaanFilter==='Pindah'?'selected':'' ?>>Pindah</option>
        </select>
      </div>
      <div class="col-md-2">
        <select name="bantuan" class="form-select">
          <option value="">Semua (Bantuan)</option>
          <option value="Ya" <?= $bantuanFilter==='Ya'?'selected':'' ?>>Pernah Terima Bantuan</option>
          <option value="Tidak" <?= $bantuanFilter==='Tidak'?'selected':'' ?>>Belum Pernah</option>
        </select>
      </div>
      <div class="col-md-2">
        <select name="umkm" class="form-select">
          <option value="">Semua (UMKM)</option>
          <option value="Ya" <?= $umkmFilter==='Ya'?'selected':'' ?>>Ada UMKM</option>
          <option value="Tidak" <?= $umkmFilter==='Tidak'?'selected':'' ?>>Tidak Ada UMKM</option>
        </select>
      </div>
      <div class="col-md-1">
        <button class="btn btn-teal w-100"><i class="bi bi-search"></i></button>
      </div>
    </form>
  </div>
</div>

<div class="card border-0 shadow-sm">
  <div class="table-responsive">
    <table class="table table-hover mb-0 align-middle table-mobile-cards">
      <thead class="table-light">
        <tr>
          <th>Nama Kepala Keluarga</th>
          <th>No. KK</th>
          <th>RT</th>
          <th>Alamat</th>
          <th class="text-center">Jml Anggota</th>
          <th class="text-center">Keberadaan</th>
          <th class="text-center">Bantuan</th>
          <th class="text-center">UMKM</th>
          <th>Terakhir Diupdate</th>
          <th class="text-end">Aksi</th>
        </tr>
      </thead>
      <tbody>
      <?php foreach ($data as $row): ?>
        <tr>
          <td data-label="Nama Kepala Keluarga"><?= e($row['nama_kepala_keluarga']) ?></td>
          <td data-label="No. KK"><?= e(maskDigits($row['nomor_kk'])) ?></td>
          <td data-label="RT"><span class="badge bg-secondary">RT <?= e($row['nomor_rt']) ?></span></td>
          <td data-label="Alamat"><?= e($row['alamat']) ?></td>
          <td data-label="Jml Anggota" class="text-center"><?= (int)$row['jumlah_total'] ?> <span class="text-muted small">(L:<?= (int)$row['jumlah_lk'] ?>/P:<?= (int)$row['jumlah_pr'] ?>)</span></td>
          <td data-label="Keberadaan" class="text-center"><?= keberadaanKeluargaBadge($row['status_keberadaan']) ?></td>
          <td data-label="Bantuan" class="text-center"><?= $row['pernah_bantuan']==='Ya' ? '<span class="badge bg-success">Ya</span>' : '<span class="badge bg-secondary">Tidak</span>' ?></td>
          <td data-label="UMKM" class="text-center"><?= $row['ada_umkm']==='Ya' ? '<span class="badge bg-success">Ya (L:'.(int)$row['jumlah_anggota_umkm_lk'].'/P:'.(int)$row['jumlah_anggota_umkm_pr'].')</span>' : '<span class="badge bg-secondary">Tidak</span>' ?></td>
          <td data-label="Terakhir Diupdate"><span class="text-muted small"><?= e(formatTanggalWaktu($row['updated_at'])) ?></span></td>
          <td data-label="Aksi" class="text-end td-action">
            <a href="keluarga_view.php?id=<?= $row['id'] ?>" class="btn btn-sm btn-outline-primary" title="Lihat"><i class="bi bi-eye"></i></a>
            <a href="keluarga_edit.php?id=<?= $row['id'] ?>" class="btn btn-sm btn-outline-secondary" title="Ubah"><i class="bi bi-pencil"></i></a>
            <a href="keluarga_delete.php?id=<?= $row['id'] ?>" class="btn btn-sm btn-outline-danger" title="Hapus" onclick="return confirm('Hapus data keluarga ini?')"><i class="bi bi-trash"></i></a>
          </td>
        </tr>
      <?php endforeach; ?>
      <?php if (empty($data)): ?>
        <tr><td colspan="10" class="text-center text-muted py-4">Tidak ada data ditemukan</td></tr>
      <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>
<?php renderPagination($totalRows, $pg, ['q' => $search, 'rt' => $rtFilter, 'bantuan' => $bantuanFilter, 'umkm' => $umkmFilter, 'keberadaan' => $keberadaanFilter]); ?>

<?php if (hasRole('ketua_rt') && $myRt): ?>
<!-- Modal Update Jumlah Bangunan (Ketua RT) -->
<div class="modal fade" id="modalBangunan" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <form method="post" action="admin_rt.php">
        <input type="hidden" name="id" value="<?= (int)$myRt['id'] ?>">
        <div class="modal-header">
          <h5 class="modal-title">Update Jumlah Bangunan — RT <?= e($myRt['nomor_rt']) ?></h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <?php foreach ($bangunanFieldsList as $key => $label): ?>
            <div class="mb-2">
              <label class="form-label small"><?= e($label) ?></label>
              <input type="number" min="0" name="<?= $key ?>" class="form-control" value="<?= (int)$myRt[$key] ?>">
            </div>
          <?php endforeach; ?>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Batal</button>
          <button type="submit" class="btn btn-teal">Simpan</button>
        </div>
      </form>
    </div>
  </div>
</div>
<script>
function bukaModalBangunan() {
  new bootstrap.Modal(document.getElementById('modalBangunan')).show();
}
</script>
<?php endif; ?>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
