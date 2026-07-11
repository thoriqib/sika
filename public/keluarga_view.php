<?php
require_once __DIR__ . '/../includes/config.php';
requireLogin();
$id = $_GET['id'] ?? 0;
$keluarga = getKeluargaOrFail($pdo, $id);
$pageTitle = 'Detail Keluarga';
$customFields = getCustomFields($pdo, 'keluarga');
$customValues = getCustomFieldValues($pdo, 'keluarga', $id);

require __DIR__ . '/../includes/partials_header.php';
?>
<div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-3">
  <div>
    <h4 class="fw-semibold mb-0"><?= e($keluarga['nama_kepala_keluarga']) ?></h4>
    <div class="text-muted">RT <?= e($keluarga['nomor_rt']) ?> &bull; No. KK <?= e(maskDigits($keluarga['nomor_kk'])) ?> &bull; <?= keberadaanKeluargaBadge($keluarga['status_keberadaan']) ?></div>
  </div>
  <div>
    <a href="keluarga_edit.php?id=<?= $id ?>" class="btn btn-outline-secondary"><i class="bi bi-pencil"></i> Ubah</a>
    <a href="keluarga_list.php" class="btn btn-outline-secondary"><i class="bi bi-arrow-left"></i> Kembali</a>
  </div>
</div>

<div class="row g-3 mb-3">
  <div class="col-md-8">
    <div class="card border-0 shadow-sm h-100">
      <div class="card-header bg-white fw-semibold">Informasi Keluarga</div>
      <div class="card-body">
        <div class="row">
          <div class="col-sm-6 mb-2"><span class="text-muted small">Alamat</span><div><?= nl2br(e($keluarga['alamat'])) ?></div></div>
          <div class="col-sm-6 mb-2"><span class="text-muted small">Terakhir Diupdate</span><div><?= e(formatTanggalWaktu($keluarga['updated_at'])) ?></div></div>
          <div class="col-sm-4 mb-2"><span class="text-muted small">Jumlah Laki-laki</span><div><?= (int)$keluarga['jumlah_lk'] ?></div></div>
          <div class="col-sm-4 mb-2"><span class="text-muted small">Jumlah Perempuan</span><div><?= (int)$keluarga['jumlah_pr'] ?></div></div>
          <div class="col-sm-4 mb-2"><span class="text-muted small">Total Anggota</span><div class="fw-semibold"><?= (int)$keluarga['jumlah_total'] ?></div></div>
          <div class="col-sm-6 mb-2"><span class="text-muted small">Pernah Menerima Bantuan Pemerintah</span><div>
            <?php if ($keluarga['pernah_bantuan']==='Ya'): ?>
              <span class="badge bg-success">Ya</span> <span class="text-muted small"><?= e(formatJenisBantuan($keluarga['jenis_bantuan'], $keluarga['deskripsi_bantuan'])) ?></span>
              <?php if (!empty($keluarga['tanggal_terakhir_bantuan'])): ?>
                <div class="text-muted small">Terakhir diterima: <?= e(formatBulanTahun($keluarga['tanggal_terakhir_bantuan'])) ?></div>
              <?php endif; ?>
            <?php else: ?>
              <span class="badge bg-secondary">Tidak</span>
            <?php endif; ?>
          </div></div>
          <div class="col-sm-6 mb-2"><span class="text-muted small">Ada Anggota Keluarga dengan UMKM</span><div>
            <?php if ($keluarga['ada_umkm']==='Ya'): ?>
              <span class="badge bg-success">Ya</span> <span class="text-muted small">(L: <?= (int)$keluarga['jumlah_anggota_umkm_lk'] ?>, P: <?= (int)$keluarga['jumlah_anggota_umkm_pr'] ?>)</span>
            <?php else: ?>
              <span class="badge bg-secondary">Tidak</span>
            <?php endif; ?>
          </div></div>
          <div class="col-sm-6 mb-2"><span class="text-muted small">Ada Anggota Keluarga Penyandang Disabilitas</span><div>
            <?php if ($keluarga['ada_disabilitas']==='Ya'): ?>
              <span class="badge bg-success">Ya</span> <span class="text-muted small">(<?= (int)$keluarga['jumlah_disabilitas'] ?> orang &mdash; <?= e($keluarga['jenis_disabilitas']) ?>)</span>
            <?php else: ?>
              <span class="badge bg-secondary">Tidak</span>
            <?php endif; ?>
          </div></div>
          <?php foreach ($customFields as $cf): ?>
            <div class="col-sm-6 mb-2"><span class="text-muted small"><?= e($cf['field_label']) ?></span><div><?= formatCustomValue($customValues[$cf['field_key']] ?? '', $cf['field_unit']) ?></div></div>
          <?php endforeach; ?>
        </div>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card border-0 shadow-sm h-100">
      <div class="card-header bg-white fw-semibold"><i class="bi bi-person-badge"></i> Data Pribadi Kepala Keluarga</div>
      <div class="card-body">
        <div class="d-flex justify-content-between py-1 border-bottom"><span class="text-muted small">NIK</span><span><?= e(maskDigits($keluarga['nik_kepala_keluarga'])) ?></span></div>
        <div class="d-flex justify-content-between py-1 border-bottom"><span class="text-muted small">Jenis Kelamin</span><span><?= e($keluarga['jenis_kelamin_kepala_keluarga']) ?></span></div>
        <div class="d-flex justify-content-between py-1 border-bottom"><span class="text-muted small">Tanggal Lahir</span><span><?= e(formatTanggal($keluarga['tanggal_lahir_kepala_keluarga'])) ?></span></div>
        <div class="d-flex justify-content-between py-1 border-bottom"><span class="text-muted small">Agama</span><span><?= e($keluarga['agama_kepala_keluarga'] ?: '-') ?></span></div>
        <div class="d-flex justify-content-between py-1 border-bottom"><span class="text-muted small">Status Perkawinan</span><span><?= e($keluarga['status_perkawinan_kepala_keluarga'] ?: '-') ?></span></div>
        <div class="d-flex justify-content-between py-1 border-bottom"><span class="text-muted small">Pendidikan</span><span><?= e($keluarga['pendidikan_kepala_keluarga'] ?: '-') ?></span></div>
        <div class="d-flex justify-content-between py-1"><span class="text-muted small">Status Pekerjaan</span><span class="text-end"><?= e($keluarga['status_pekerjaan_kepala_keluarga'] ?: '-') ?><?= $keluarga['pekerjaan_kepala_keluarga'] ? '<div class="text-muted small">'.e($keluarga['pekerjaan_kepala_keluarga']).'</div>' : '' ?></span></div>
      </div>
    </div>
  </div>
</div>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
