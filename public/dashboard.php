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
$adaWhere = " AND k.status_keberadaan = 'Ada'" . $rtWhere;

$totalKeluarga = $pdo->query("SELECT COUNT(*) c FROM keluarga k WHERE 1=1 $adaWhere")->fetch()['c'];
$totalAnggota  = $pdo->query("SELECT COALESCE(SUM(jumlah_total),0) c FROM keluarga k WHERE 1=1 $adaWhere")->fetch()['c'];
$totalLk       = $pdo->query("SELECT COALESCE(SUM(jumlah_lk),0) c FROM keluarga k WHERE 1=1 $adaWhere")->fetch()['c'];
$totalPr       = $pdo->query("SELECT COALESCE(SUM(jumlah_pr),0) c FROM keluarga k WHERE 1=1 $adaWhere")->fetch()['c'];
$totalPindah   = $pdo->query("SELECT COUNT(*) c FROM keluarga k WHERE status_keberadaan='Pindah' $rtWhere")->fetch()['c'];
$totalBantuan  = $pdo->query("SELECT COUNT(*) c FROM keluarga k WHERE pernah_bantuan='Ya' $adaWhere")->fetch()['c'];

$bangunanWhere = $rtParam !== null ? " WHERE id = $rtParam" : "";
$bangunan = $pdo->query("SELECT
    COALESCE(SUM(jml_bangunan_tinggal_terisi),0) terisi,
    COALESCE(SUM(jml_bangunan_tinggal_kosong),0) kosong,
    COALESCE(SUM(jml_bangunan_khusus_usaha),0) usaha,
    COALESCE(SUM(jml_bangunan_bukan_tinggal_non_usaha),0) non_usaha
    FROM rt $bangunanWhere")->fetch();
$totalUmkm     = $pdo->query("SELECT COUNT(*) c FROM keluarga k WHERE ada_umkm='Ya' $adaWhere")->fetch()['c'];
$totalAnggotaUmkm = $pdo->query("SELECT COALESCE(SUM(jumlah_anggota_umkm),0) c FROM keluarga k WHERE ada_umkm='Ya' $adaWhere")->fetch()['c'];
$totalDisabilitasKk = $pdo->query("SELECT COUNT(*) c FROM keluarga k WHERE ada_disabilitas='Ya' $adaWhere")->fetch()['c'];
$totalDisabilitasOrang = $pdo->query("SELECT COALESCE(SUM(jumlah_disabilitas),0) c FROM keluarga k WHERE ada_disabilitas='Ya' $adaWhere")->fetch()['c'];

$persenBantuan = $totalKeluarga > 0 ? round($totalBantuan / $totalKeluarga * 100, 1) : 0;
$persenUmkm = $totalKeluarga > 0 ? round($totalUmkm / $totalKeluarga * 100, 1) : 0;

$distPekerjaan = $pdo->query("SELECT status_pekerjaan_kepala_keluarga k2, COUNT(*) jml FROM keluarga k WHERE status_pekerjaan_kepala_keluarga IS NOT NULL $adaWhere GROUP BY status_pekerjaan_kepala_keluarga ORDER BY jml DESC")->fetchAll();

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
      <div class="text-muted small">Total Keluarga (Ada)</div>
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
<div class="alert alert-light border small mb-4">
  <i class="bi bi-info-circle"></i> Statistik di atas hanya menghitung keluarga berstatus keberadaan
  <strong>"Ada"</strong>. Tercatat <strong><?= number_format($totalPindah) ?> keluarga</strong> berstatus
  "Pindah" <a href="keluarga_list.php?keberadaan=Pindah">(lihat daftarnya &raquo;)</a>.
</div>

<div class="d-flex justify-content-between align-items-center mb-2">
  <h6 class="text-muted mb-0 text-uppercase" style="letter-spacing:.03em">Data Bangunan<?= $rtLabelTerpilih ? ' &mdash; RT ' . e($rtLabelTerpilih) : '' ?></h6>
</div>
<div class="row g-3 mb-4">
  <div class="col-6 col-md-3">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Tempat Tinggal Terisi</div>
      <div class="fs-4 fw-bold text-teal"><?= number_format($bangunan['terisi']) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Bangunan Kosong</div>
      <div class="fs-4 fw-bold text-secondary"><?= number_format($bangunan['kosong']) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Khusus Usaha</div>
      <div class="fs-4 fw-bold" style="color:#fd7e14"><?= number_format($bangunan['usaha']) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Bukan Tinggal, Non Usaha</div>
      <div class="fs-4 fw-bold text-muted"><?= number_format($bangunan['non_usaha']) ?></div>
    </div></div>
  </div>
</div>
<?php if (hasRole('admin_kelurahan')): ?>
<div class="text-end mb-4"><a href="admin_rt.php" class="small"><i class="bi bi-pencil"></i> Kelola data bangunan per RT &raquo;</a></div>
<?php endif; ?>

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

<div class="d-flex justify-content-between align-items-center mb-2">
  <h6 class="text-muted mb-0 text-uppercase" style="letter-spacing:.03em">Disabilitas</h6>
</div>
<div class="row g-3 mb-4">
  <div class="col-md-3 col-6">
    <div class="card border-0 shadow-sm h-100" style="border-left:4px solid #6610f2"><div class="card-body">
      <div class="text-muted small">Keluarga dengan Penyandang Disabilitas</div>
      <div class="fs-3 fw-bold" style="color:#6610f2"><?= number_format($totalDisabilitasKk) ?></div>
    </div></div>
  </div>
  <div class="col-md-3 col-6">
    <div class="card border-0 shadow-sm h-100" style="border-left:4px solid #6610f2"><div class="card-body">
      <div class="text-muted small">Total Penyandang Disabilitas</div>
      <div class="fs-3 fw-bold" style="color:#6610f2"><?= number_format($totalDisabilitasOrang) ?> <span class="fs-6 fw-normal text-muted">orang</span></div>
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
