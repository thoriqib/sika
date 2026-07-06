<?php
require_once __DIR__ . '/../includes/config.php';
requireLogin();
$pageTitle = 'Dashboard';

$rtList = $pdo->query("SELECT * FROM rt ORDER BY nomor_rt")->fetchAll();
$selectedRt = $_GET['rt'] ?? '';

// Klausa filter RT: Ketua RT selalu terkunci ke RT-nya sendiri,
// Admin/Operator bisa pilih RT tertentu atau "Semua RT"
$rtParam = null;
if (hasRole('ketua_rt')) {
    $rtParam = (int)currentUser()['rt_id'];
} elseif ($selectedRt !== '') {
    $rtParam = (int)$selectedRt;
}
$rtWhere = $rtParam !== null ? " AND k.rt_id = $rtParam" : "";

$totalKeluarga = $pdo->query("SELECT COUNT(*) c FROM keluarga k WHERE 1=1 $rtWhere")->fetch()['c'];
$totalAnggota  = $pdo->query("SELECT COALESCE(SUM(jumlah_total),0) c FROM keluarga k WHERE 1=1 $rtWhere")->fetch()['c'];
$totalLk       = $pdo->query("SELECT COALESCE(SUM(jumlah_lk),0) c FROM keluarga k WHERE 1=1 $rtWhere")->fetch()['c'];
$totalPr       = $pdo->query("SELECT COALESCE(SUM(jumlah_pr),0) c FROM keluarga k WHERE 1=1 $rtWhere")->fetch()['c'];
$totalBantuan  = $pdo->query("SELECT COUNT(*) c FROM keluarga k WHERE pernah_bantuan='Ya' $rtWhere")->fetch()['c'];
$totalUmkm     = $pdo->query("SELECT COUNT(*) c FROM keluarga k WHERE ada_umkm='Ya' $rtWhere")->fetch()['c'];
$totalAnggotaUmkm = $pdo->query("SELECT COALESCE(SUM(jumlah_anggota_umkm),0) c FROM keluarga k WHERE ada_umkm='Ya' $rtWhere")->fetch()['c'];

$persenBantuan = $totalKeluarga > 0 ? round($totalBantuan / $totalKeluarga * 100, 1) : 0;
$persenUmkm = $totalKeluarga > 0 ? round($totalUmkm / $totalKeluarga * 100, 1) : 0;

$distPekerjaan = $pdo->query("SELECT status_pekerjaan_kepala_keluarga k2, COUNT(*) jml FROM keluarga k WHERE status_pekerjaan_kepala_keluarga IS NOT NULL $rtWhere GROUP BY status_pekerjaan_kepala_keluarga ORDER BY jml DESC")->fetchAll();

$recent = $pdo->query("SELECT k.*, r.nomor_rt FROM keluarga k JOIN rt r ON r.id=k.rt_id WHERE 1=1 $rtWhere ORDER BY k.created_at DESC LIMIT 5")->fetchAll();

$rtLabelTerpilih = '';
if ($rtParam) {
    foreach ($rtList as $rt) { if ((int)$rt['id'] === $rtParam) { $rtLabelTerpilih = $rt['nomor_rt']; break; } }
}

require __DIR__ . '/../includes/partials_header.php';
?>
<div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4">
  <h4 class="fw-semibold mb-0">Dashboard</h4>
  <?php if (!hasRole('ketua_rt')): ?>
  <form method="get" class="d-flex align-items-center gap-2">
    <label class="text-muted small mb-0">Filter RT:</label>
    <select name="rt" class="form-select form-select-sm" style="width:auto" onchange="this.form.submit()">
      <option value="">Semua RT</option>
      <?php foreach ($rtList as $rt): ?>
        <option value="<?= $rt['id'] ?>" <?= (string)$selectedRt === (string)$rt['id'] ? 'selected' : '' ?>>RT <?= e($rt['nomor_rt']) ?></option>
      <?php endforeach; ?>
    </select>
  </form>
  <?php endif; ?>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-3 col-6">
    <div class="card stat-card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Total Keluarga</div>
      <div class="fs-3 fw-bold"><?= number_format($totalKeluarga) ?></div>
    </div></div>
  </div>
  <div class="col-md-3 col-6">
    <div class="card stat-card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Total Anggota</div>
      <div class="fs-3 fw-bold"><?= number_format($totalAnggota) ?></div>
    </div></div>
  </div>
  <div class="col-md-3 col-6">
    <div class="card stat-card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Laki-laki</div>
      <div class="fs-3 fw-bold"><?= number_format($totalLk) ?></div>
    </div></div>
  </div>
  <div class="col-md-3 col-6">
    <div class="card stat-card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Perempuan</div>
      <div class="fs-3 fw-bold"><?= number_format($totalPr) ?></div>
    </div></div>
  </div>
</div>

<div class="d-flex justify-content-between align-items-center mb-2">
  <h6 class="text-muted mb-0 text-uppercase" style="letter-spacing:.03em">Bantuan &amp; UMKM<?= $rtLabelTerpilih ? ' &mdash; RT ' . e($rtLabelTerpilih) : '' ?></h6>
</div>
<div class="row g-3 mb-4">
  <div class="col-md-3 col-6">
    <div class="card border-0 shadow-sm h-100" style="border-left:4px solid #14867a"><div class="card-body">
      <div class="text-muted small">Keluarga Pernah Terima Bantuan</div>
      <div class="fs-3 fw-bold text-teal"><?= number_format($totalBantuan) ?> <span class="fs-6 fw-normal text-muted">(<?= $persenBantuan ?>%)</span></div>
    </div></div>
  </div>
  <div class="col-md-3 col-6">
    <div class="card border-0 shadow-sm h-100" style="border-left:4px solid #fd7e14"><div class="card-body">
      <div class="text-muted small">Keluarga dengan UMKM</div>
      <div class="fs-3 fw-bold" style="color:#fd7e14"><?= number_format($totalUmkm) ?> <span class="fs-6 fw-normal text-muted">(<?= $persenUmkm ?>%)</span></div>
    </div></div>
  </div>
  <div class="col-md-6 col-12">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Total Anggota Pemilik UMKM</div>
      <div class="fs-3 fw-bold"><?= number_format($totalAnggotaUmkm) ?> <span class="fs-6 fw-normal text-muted">orang</span></div>
    </div></div>
  </div>
</div>

<div class="row g-3">
  <?php if (!hasRole('ketua_rt') && !$rtParam): ?>
  <div class="col-md-5">
    <div class="card border-0 shadow-sm mb-3">
      <div class="card-header bg-white fw-semibold">Jumlah Keluarga per RT</div>
      <div class="card-body">
        <?php
        $perRt = $pdo->query("SELECT r.nomor_rt, COUNT(k.id) jml FROM rt r LEFT JOIN keluarga k ON k.rt_id = r.id GROUP BY r.id ORDER BY r.nomor_rt")->fetchAll();
        foreach ($perRt as $r): ?>
        <div class="d-flex justify-content-between border-bottom py-1">
          <span>RT <?= e($r['nomor_rt']) ?></span>
          <strong><?= (int)$r['jml'] ?></strong>
        </div>
        <?php endforeach; ?>
      </div>
    </div>
  <?php endif; ?>
    <div class="card border-0 shadow-sm">
      <div class="card-header bg-white fw-semibold">Status Pekerjaan Kepala Keluarga</div>
      <div class="card-body">
        <?php foreach ($distPekerjaan as $dp): ?>
        <div class="d-flex justify-content-between border-bottom py-1">
          <span><?= e($dp['k2']) ?></span>
          <strong><?= (int)$dp['jml'] ?></strong>
        </div>
        <?php endforeach; ?>
        <?php if (empty($distPekerjaan)): ?><div class="text-muted small py-2">Belum ada data</div><?php endif; ?>
      </div>
    </div>
  <?php if (!hasRole('ketua_rt') && !$rtParam): ?>
  </div>
  <?php endif; ?>
  <div class="<?= (hasRole('ketua_rt') || $rtParam) ? 'col-md-12' : 'col-md-7' ?>">
    <div class="card border-0 shadow-sm">
      <div class="card-header bg-white fw-semibold d-flex justify-content-between align-items-center">
        Data Terbaru
        <a href="keluarga_list.php" class="small">Lihat semua &raquo;</a>
      </div>
      <div class="card-body p-0">
        <table class="table mb-0">
          <thead><tr><th>Nama Kepala Keluarga</th><th>RT</th><th>No. KK</th></tr></thead>
          <tbody>
          <?php foreach ($recent as $r): ?>
            <tr>
              <td><a href="keluarga_view.php?id=<?= $r['id'] ?>"><?= e($r['nama_kepala_keluarga']) ?></a></td>
              <td>RT <?= e($r['nomor_rt']) ?></td>
              <td><?= e(maskDigits($r['nomor_kk'])) ?></td>
            </tr>
          <?php endforeach; ?>
          <?php if (empty($recent)): ?><tr><td colspan="3" class="text-center text-muted py-3">Belum ada data</td></tr><?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
