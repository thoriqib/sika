<?php
require_once __DIR__ . '/../includes/config.php';
requireRole(['ketua_rt','operator_kelurahan','admin_kelurahan']);
$pageTitle = 'Ubah Keluarga';

$id = $_GET['id'] ?? $_POST['id'] ?? 0;
$keluarga = getKeluargaOrFail($pdo, $id);
$rtList = $pdo->query("SELECT * FROM rt ORDER BY nomor_rt")->fetchAll();
$customFields = getCustomFields($pdo, 'keluarga');
$customValues = getCustomFieldValues($pdo, 'keluarga', $id);
$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nama = trim($_POST['nama_kepala_keluarga'] ?? '');
    $alamat = trim($_POST['alamat'] ?? '');
    $rt_id = hasRole('ketua_rt') ? currentUser()['rt_id'] : ($_POST['rt_id'] ?? '');
    $nomor_kk = trim($_POST['nomor_kk'] ?? '');
    $jumlah_lk = (int)($_POST['jumlah_lk'] ?? 0);
    $jumlah_pr = (int)($_POST['jumlah_pr'] ?? 0);
    $jumlah_total = $jumlah_lk + $jumlah_pr;
    $status_keberadaan = ($_POST['status_keberadaan'] ?? 'Ada') === 'Pindah' ? 'Pindah' : 'Ada';

    $nik = trim($_POST['nik_kepala_keluarga'] ?? '');
    $jk = $_POST['jenis_kelamin_kepala_keluarga'] ?? '';
    $tgl = $_POST['tanggal_lahir_kepala_keluarga'] ?? '';
    $agama = trim($_POST['agama_kepala_keluarga'] ?? '');
    $status_kawin = trim($_POST['status_perkawinan_kepala_keluarga'] ?? '');
    $pendidikan = trim($_POST['pendidikan_kepala_keluarga'] ?? '');
    $status_pekerjaan = trim($_POST['status_pekerjaan_kepala_keluarga'] ?? '');
    $pekerjaan = trim($_POST['pekerjaan_kepala_keluarga'] ?? '');

    $pernah_bantuan = ($_POST['pernah_bantuan'] ?? 'Tidak') === 'Ya' ? 'Ya' : 'Tidak';
    $jenis_bantuan_arr = array_intersect($_POST['jenis_bantuan'] ?? [], pilihanJenisBantuan());
    $bulan_terakhir_bantuan = trim($_POST['bulan_terakhir_bantuan'] ?? '');
    $tahun_terakhir_bantuan = trim($_POST['tahun_terakhir_bantuan'] ?? '');
    $deskripsi_bantuan = trim($_POST['deskripsi_bantuan'] ?? '');
    $ada_umkm = ($_POST['ada_umkm'] ?? 'Tidak') === 'Ya' ? 'Ya' : 'Tidak';
    $jumlah_umkm_lk = $ada_umkm === 'Ya' ? (int)($_POST['jumlah_anggota_umkm_lk'] ?? 0) : null;
    $jumlah_umkm_pr = $ada_umkm === 'Ya' ? (int)($_POST['jumlah_anggota_umkm_pr'] ?? 0) : null;
    $ada_disabilitas = ($_POST['ada_disabilitas'] ?? 'Tidak') === 'Ya' ? 'Ya' : 'Tidak';
    $jumlah_disabilitas = $ada_disabilitas === 'Ya' ? (int)($_POST['jumlah_disabilitas'] ?? 0) : null;
    $jenis_disabilitas = $ada_disabilitas === 'Ya' ? trim($_POST['jenis_disabilitas'] ?? '') : null;

    if ($nama === '') $errors[] = 'Nama kepala keluarga wajib diisi.';
    if ($alamat === '') $errors[] = 'Alamat wajib diisi.';
    if (!$rt_id) $errors[] = 'RT wajib dipilih.';
    if ($nomor_kk === '' || !preg_match('/^\d{16}$/', $nomor_kk)) $errors[] = 'Nomor KK harus berupa 16 digit angka.';
    if ($jumlah_lk < 0 || $jumlah_pr < 0) $errors[] = 'Jumlah anggota tidak boleh negatif.';
    if ($jumlah_total < 1) $errors[] = 'Jumlah anggota keluarga (laki-laki + perempuan) minimal 1 (Kepala Keluarga).';

    if (!preg_match('/^\d{16}$/', $nik)) $errors[] = 'NIK Kepala Keluarga harus berupa 16 digit angka.';
    if (!in_array($jk, ['Laki-laki','Perempuan'])) $errors[] = 'Jenis kelamin Kepala Keluarga wajib dipilih.';
    if ($tgl === '') $errors[] = 'Tanggal lahir Kepala Keluarga wajib diisi.';
    elseif (parseTanggalForm($tgl) === null) $errors[] = 'Tanggal lahir Kepala Keluarga tidak valid (format dd/mm/yyyy).';
    if (!in_array($status_pekerjaan, pilihanStatusPekerjaan())) {
        $errors[] = 'Status pekerjaan Kepala Keluarga wajib dipilih.';
    } elseif (butuhDeskripsiPekerjaan($status_pekerjaan) && $pekerjaan === '') {
        $errors[] = 'Deskripsi pekerjaan Kepala Keluarga wajib diisi untuk status pekerjaan yang dipilih.';
    }
    if (!butuhDeskripsiPekerjaan($status_pekerjaan)) $pekerjaan = null;
    if ($ada_umkm === 'Ya' && ($jumlah_umkm_lk + $jumlah_umkm_pr) < 1) $errors[] = 'Jumlah anggota keluarga pemilik UMKM (laki-laki/perempuan) wajib diisi, minimal 1 orang.';
    if ($ada_umkm === 'Ya' && $jumlah_umkm_lk > $jumlah_lk) $errors[] = 'Jumlah anggota UMKM laki-laki tidak boleh melebihi jumlah anggota keluarga laki-laki.';
    if ($ada_umkm === 'Ya' && $jumlah_umkm_pr > $jumlah_pr) $errors[] = 'Jumlah anggota UMKM perempuan tidak boleh melebihi jumlah anggota keluarga perempuan.';
    if ($pernah_bantuan === 'Ya' && empty($jenis_bantuan_arr)) $errors[] = 'Pilih minimal satu jenis bantuan yang pernah diterima.';
    if ($pernah_bantuan === 'Ya' && in_array('Lainnya', $jenis_bantuan_arr) && $deskripsi_bantuan === '') $errors[] = 'Deskripsi bantuan wajib diisi jika memilih jenis bantuan "Lainnya".';
    $jenis_bantuan_csv = ($pernah_bantuan === 'Ya' && $jenis_bantuan_arr) ? implode(',', $jenis_bantuan_arr) : null;
    if ($pernah_bantuan !== 'Ya' || !in_array('Lainnya', $jenis_bantuan_arr)) $deskripsi_bantuan = null; else $deskripsi_bantuan = $deskripsi_bantuan ?: null;
    $tgl_terakhir_bantuan_sql = null;
    if ($pernah_bantuan === 'Ya') {
        if ($bulan_terakhir_bantuan === '' || $tahun_terakhir_bantuan === '') {
            $errors[] = 'Kapan Terakhir Menerima Bantuan (bulan & tahun) wajib diisi.';
        } elseif (bulanTahunKeSql($bulan_terakhir_bantuan, $tahun_terakhir_bantuan) === null) {
            $errors[] = 'Kapan Terakhir Menerima Bantuan tidak valid.';
        } else {
            $tgl_terakhir_bantuan_sql = bulanTahunKeSql($bulan_terakhir_bantuan, $tahun_terakhir_bantuan);
        }
    }
    if ($ada_disabilitas === 'Ya') {
        if ($jumlah_disabilitas < 1) $errors[] = 'Jumlah anggota keluarga penyandang disabilitas wajib diisi (minimal 1).';
        if ($jenis_disabilitas === '') $errors[] = 'Jenis disabilitas wajib diisi.';
    }

    if (empty($errors)) {
        $check = $pdo->prepare("SELECT id FROM keluarga WHERE nomor_kk = ? AND id != ?");
        $check->execute([$nomor_kk, $id]);
        if ($check->fetch()) $errors[] = 'Nomor KK sudah digunakan keluarga lain.';

        $checkNik = $pdo->prepare("SELECT id FROM keluarga WHERE nik_kepala_keluarga = ? AND id != ?");
        $checkNik->execute([$nik, $id]);
        if ($checkNik->fetch()) $errors[] = 'NIK Kepala Keluarga sudah digunakan keluarga lain.';
    }

    if (empty($errors)) {
        $stmt = $pdo->prepare("UPDATE keluarga SET
            nama_kepala_keluarga=?, alamat=?, rt_id=?, nomor_kk=?, jumlah_lk=?, jumlah_pr=?, jumlah_total=?,
            nik_kepala_keluarga=?, jenis_kelamin_kepala_keluarga=?, tanggal_lahir_kepala_keluarga=?,
            agama_kepala_keluarga=?, status_perkawinan_kepala_keluarga=?, pendidikan_kepala_keluarga=?,
            status_pekerjaan_kepala_keluarga=?, pekerjaan_kepala_keluarga=?,
            pernah_bantuan=?, jenis_bantuan=?, tanggal_terakhir_bantuan=?, deskripsi_bantuan=?, ada_umkm=?, jumlah_anggota_umkm_lk=?, jumlah_anggota_umkm_pr=?,
            ada_disabilitas=?, jumlah_disabilitas=?, jenis_disabilitas=?,
            status_keberadaan=?, updated_by=?
            WHERE id=?");
        $stmt->execute([
            $nama, $alamat, $rt_id, $nomor_kk, $jumlah_lk, $jumlah_pr, $jumlah_total,
            $nik, $jk, parseTanggalForm($tgl), $agama, $status_kawin, $pendidikan,
            $status_pekerjaan, $pekerjaan,
            $pernah_bantuan, $jenis_bantuan_csv, $tgl_terakhir_bantuan_sql, $deskripsi_bantuan, $ada_umkm, $jumlah_umkm_lk, $jumlah_umkm_pr,
            $ada_disabilitas, $jumlah_disabilitas, $jenis_disabilitas,
            $status_keberadaan, currentUser()['id'], $id,
        ]);
        saveCustomFieldValues($pdo, 'keluarga', $id, $_POST);

        $_SESSION['flash_success'] = 'Data keluarga berhasil diperbarui.';
        header('Location: keluarga_view.php?id=' . $id . '&clear_draft=draft_keluarga_edit_' . $id);
        exit;
    }
    $keluarga = array_merge($keluarga, $_POST);
}

$tglLahirKkDisplay = ($_SERVER['REQUEST_METHOD'] === 'POST')
    ? ($_POST['tanggal_lahir_kepala_keluarga'] ?? '')
    : tanggalUntukForm($keluarga['tanggal_lahir_kepala_keluarga']);
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $bulanTerakhirBantuanDisplay = $_POST['bulan_terakhir_bantuan'] ?? '';
    $tahunTerakhirBantuanDisplay = $_POST['tahun_terakhir_bantuan'] ?? '';
} else {
    $tsBantuan = !empty($keluarga['tanggal_terakhir_bantuan']) ? strtotime($keluarga['tanggal_terakhir_bantuan']) : false;
    $bulanTerakhirBantuanDisplay = $tsBantuan ? (int)date('n', $tsBantuan) : '';
    $tahunTerakhirBantuanDisplay = $tsBantuan ? (int)date('Y', $tsBantuan) : '';
}

require __DIR__ . '/../includes/partials_header.php';
?>
<h4 class="fw-semibold mb-3">Ubah Data Keluarga</h4>
<?php if ($errors): ?><div class="alert alert-danger"><ul class="mb-0"><?php foreach($errors as $er) echo '<li>'.e($er).'</li>'; ?></ul></div><?php endif; ?>

<div id="draftBanner" class="draft-banner"></div>

<form method="post" id="formKeluargaEdit">
  <input type="hidden" name="id" value="<?= (int)$id ?>">

  <div class="card border-0 shadow-sm mb-3">
    <div class="card-header bg-white fw-semibold">Data Keluarga</div>
    <div class="card-body">
      <div class="row g-3">
        <div class="col-md-6">
          <label class="form-label">Nama Kepala Keluarga<?= requiredMark() ?></label>
          <input type="text" name="nama_kepala_keluarga" class="form-control" value="<?= e($keluarga['nama_kepala_keluarga']) ?>" required>
        </div>
        <div class="col-md-3">
          <label class="form-label">Nomor KK<?= requiredMark() ?></label>
          <input type="text" name="nomor_kk" maxlength="16" class="form-control" value="<?= e($keluarga['nomor_kk']) ?>" required>
        </div>
        <div class="col-md-3">
          <label class="form-label">RT<?= requiredMark() ?></label>
          <?php if (hasRole('ketua_rt')): ?>
            <input type="text" class="form-control" value="RT <?= e(currentUser()['nomor_rt']) ?>" disabled>
          <?php else: ?>
            <select name="rt_id" class="form-select" required>
              <?php foreach ($rtList as $rt): ?>
                <option value="<?= $rt['id'] ?>" <?= $rt['id']==$keluarga['rt_id']?'selected':'' ?>><?= e($rt['nomor_rt']) ?></option>
              <?php endforeach; ?>
            </select>
          <?php endif; ?>
        </div>
        <div class="col-md-8">
          <label class="form-label">Alamat<?= requiredMark() ?></label>
          <textarea name="alamat" class="form-control" rows="2" required><?= e($keluarga['alamat']) ?></textarea>
        </div>
        <div class="col-md-2">
          <label class="form-label">Jumlah Laki-laki<?= requiredMark() ?></label>
          <input type="number" min="0" name="jumlah_lk" id="jumlahLk" class="form-control" value="<?= e($keluarga['jumlah_lk']) ?>" required>
        </div>
        <div class="col-md-2">
          <label class="form-label">Jumlah Perempuan<?= requiredMark() ?></label>
          <input type="number" min="0" name="jumlah_pr" id="jumlahPr" class="form-control" value="<?= e($keluarga['jumlah_pr']) ?>" required>
        </div>
        <div class="col-md-2">
          <label class="form-label">Total Anggota</label>
          <input type="text" id="jumlahTotal" class="form-control" value="0" disabled>
          <div class="form-text">Dihitung otomatis</div>
        </div>
        <div class="col-md-6">
          <label class="form-label d-block">Status Keberadaan Keluarga<?= requiredMark() ?></label>
          <div class="btn-group" role="group">
            <input type="radio" class="btn-check" name="status_keberadaan" id="keberadaanAda" value="Ada" <?= $keluarga['status_keberadaan']=='Ada'?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="keberadaanAda">Ada</label>
            <input type="radio" class="btn-check" name="status_keberadaan" id="keberadaanPindah" value="Pindah" <?= $keluarga['status_keberadaan']=='Pindah'?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="keberadaanPindah">Pindah</label>
          </div>
          <div class="form-text">"Pindah" berarti keluarga ini sudah tidak berdomisili di alamat tersebut.</div>
        </div>

        <?php if ($customFields): ?>
          <div class="col-12"><hr><h6 class="text-muted">Variabel Tambahan</h6></div>
          <?php foreach ($customFields as $cf): $val = $customValues[$cf['field_key']] ?? ''; ?>
            <div class="col-md-4">
              <label class="form-label"><?= e($cf['field_label']) ?><?= $cf['is_required'] ? requiredMark() : '' ?></label>
              <?php if ($cf['field_type'] === 'select'): ?>
                <select name="<?= e($cf['field_key']) ?>" class="form-select" <?= $cf['is_required'] ? 'required' : '' ?>>
                  <option value="">Pilih</option>
                  <?php foreach (explode(',', $cf['field_options']) as $opt): $opt = trim($opt); if ($opt === '') continue; ?>
                    <option value="<?= e($opt) ?>" <?= $val===$opt?'selected':'' ?>><?= e($opt) ?></option>
                  <?php endforeach; ?>
                </select>
              <?php elseif ($cf['field_type'] === 'textarea'): ?>
                <textarea name="<?= e($cf['field_key']) ?>" class="form-control" <?= $cf['is_required'] ? 'required' : '' ?>><?= e($val) ?></textarea>
              <?php else: ?>
                <div class="input-group">
                  <input type="<?= e($cf['field_type']) ?>" name="<?= e($cf['field_key']) ?>" class="form-control" value="<?= e($val) ?>" <?= $cf['is_required'] ? 'required' : '' ?>>
                  <?php if ($cf['field_unit']): ?><span class="input-group-text input-group-unit"><?= e($cf['field_unit']) ?></span><?php endif; ?>
                </div>
              <?php endif; ?>
            </div>
          <?php endforeach; ?>
        <?php endif; ?>
      </div>
    </div>
  </div>

  <div class="card border-0 shadow-sm mb-3">
    <div class="card-header bg-white fw-semibold"><i class="bi bi-person-badge"></i> Data Pribadi Kepala Keluarga</div>
    <div class="card-body">
      <div class="row g-3">
        <div class="col-md-6">
          <label class="form-label">NIK<?= requiredMark() ?></label>
          <input type="text" name="nik_kepala_keluarga" maxlength="16" class="form-control" value="<?= e($keluarga['nik_kepala_keluarga']) ?>" required>
        </div>
        <div class="col-md-3">
          <label class="form-label">Jenis Kelamin<?= requiredMark() ?></label>
          <select name="jenis_kelamin_kepala_keluarga" class="form-select" required>
            <option value="Laki-laki" <?= $keluarga['jenis_kelamin_kepala_keluarga']=='Laki-laki'?'selected':'' ?>>Laki-laki</option>
            <option value="Perempuan" <?= $keluarga['jenis_kelamin_kepala_keluarga']=='Perempuan'?'selected':'' ?>>Perempuan</option>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">Tanggal Lahir<?= requiredMark() ?></label>
          <input type="text" name="tanggal_lahir_kepala_keluarga" id="tglLahirKK" class="form-control" placeholder="dd/mm/yyyy" maxlength="10" inputmode="numeric" value="<?= e($tglLahirKkDisplay) ?>" required>
        </div>
        <div class="col-md-3">
          <label class="form-label">Agama</label>
          <select name="agama_kepala_keluarga" class="form-select">
            <option value="">Pilih</option>
            <?php foreach (pilihanAgama() as $ag): ?>
              <option value="<?= $ag ?>" <?= $keluarga['agama_kepala_keluarga']==$ag?'selected':'' ?>><?= $ag ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">Status Perkawinan</label>
          <select name="status_perkawinan_kepala_keluarga" class="form-select">
            <option value="">Pilih</option>
            <?php foreach (pilihanStatusKawin() as $sp): ?>
              <option value="<?= $sp ?>" <?= $keluarga['status_perkawinan_kepala_keluarga']==$sp?'selected':'' ?>><?= $sp ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">Pendidikan Terakhir</label>
          <select name="pendidikan_kepala_keluarga" class="form-select">
            <option value="">Pilih</option>
            <?php foreach (pilihanPendidikan() as $pd): ?>
              <option value="<?= $pd ?>" <?= $keluarga['pendidikan_kepala_keluarga']==$pd?'selected':'' ?>><?= $pd ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="col-md-4">
          <label class="form-label">Status Pekerjaan<?= requiredMark() ?></label>
          <select name="status_pekerjaan_kepala_keluarga" class="form-select" id="selStatusPekerjaan" required>
            <option value="">Pilih</option>
            <?php foreach (pilihanStatusPekerjaan() as $i => $sp): ?>
              <option value="<?= e($sp) ?>" <?= $keluarga['status_pekerjaan_kepala_keluarga']==$sp?'selected':'' ?>><?= ($i+1) ?>. <?= e($sp) ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="col-md-4" id="wrapDeskripsiPekerjaan">
          <label class="form-label">Deskripsi Pekerjaan<span id="markDeskripsiPekerjaan"></span></label>
          <input type="text" name="pekerjaan_kepala_keluarga" id="inputDeskripsiPekerjaan" class="form-control" value="<?= e($keluarga['pekerjaan_kepala_keluarga']) ?>">
        </div>
      </div>
    </div>
  </div>

  <div class="card border-0 shadow-sm mb-3">
    <div class="card-header bg-white fw-semibold"><i class="bi bi-hand-holding-heart"></i> Bantuan, UMKM &amp; Disabilitas</div>
    <div class="card-body">
      <div class="row g-3">
        <div class="col-md-4">
          <label class="form-label d-block">Pernah menerima bantuan dari pemerintah?<?= requiredMark() ?></label>
          <div class="btn-group" role="group">
            <input type="radio" class="btn-check" name="pernah_bantuan" id="bantuanYa" value="Ya" <?= $keluarga['pernah_bantuan']=='Ya'?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="bantuanYa">Ya</label>
            <input type="radio" class="btn-check" name="pernah_bantuan" id="bantuanTidak" value="Tidak" <?= $keluarga['pernah_bantuan']=='Tidak'?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="bantuanTidak">Tidak</label>
          </div>
        </div>
        <div class="col-md-8" id="wrapJenisBantuan">
          <label class="form-label d-block">Jenis Bantuan yang Diterima<span id="markJenisBantuan"></span></label>
          <div class="d-flex flex-wrap gap-3">
            <?php $selectedBantuan = array_map('trim', explode(',', $keluarga['jenis_bantuan'] ?? '')); foreach (pilihanJenisBantuan() as $jb): $cbId = 'jb_' . preg_replace('/[^a-zA-Z0-9]/', '', $jb); ?>
              <div class="form-check">
                <input class="form-check-input" type="checkbox" name="jenis_bantuan[]" value="<?= e($jb) ?>" id="<?= $cbId ?>" <?= in_array($jb, $selectedBantuan) ? 'checked' : '' ?> <?= $jb === 'Lainnya' ? 'onchange="toggleDeskripsiBantuan()"' : '' ?>>
                <label class="form-check-label" for="<?= $cbId ?>"><?= e($jb) ?></label>
              </div>
            <?php endforeach; ?>
          </div>
          <div class="mt-2" id="wrapTglTerakhirBantuan">
            <label class="form-label d-block">Kapan Terakhir Menerima Bantuan?<span id="markTglTerakhirBantuan"></span></label>
            <div class="d-flex gap-2">
              <select name="bulan_terakhir_bantuan" id="bulanTerakhirBantuan" class="form-select" style="max-width:160px">
                <option value="">Bulan</option>
                <?php foreach (range(1,12) as $bl): ?>
                  <option value="<?= $bl ?>" <?= ($bulanTerakhirBantuanDisplay == $bl) ? 'selected' : '' ?>><?= namaBulanIndonesia($bl) ?></option>
                <?php endforeach; ?>
              </select>
              <select name="tahun_terakhir_bantuan" id="tahunTerakhirBantuan" class="form-select" style="max-width:130px">
                <option value="">Tahun</option>
                <?php $tahunSekarang = (int)date('Y'); foreach (range($tahunSekarang, $tahunSekarang - 9) as $th): ?>
                  <option value="<?= $th ?>" <?= ($tahunTerakhirBantuanDisplay == $th) ? 'selected' : '' ?>><?= $th ?></option>
                <?php endforeach; ?>
              </select>
            </div>
          </div>
          <div class="mt-2" id="wrapDeskripsiBantuan">
            <label class="form-label">Deskripsi Bantuan "Lainnya"<span id="markDeskripsiBantuan"></span></label>
            <input type="text" name="deskripsi_bantuan" id="inputDeskripsiBantuan" class="form-control" value="<?= e($keluarga['deskripsi_bantuan']) ?>">
          </div>
        </div>

        <div class="col-md-4">
          <label class="form-label d-block">Ada anggota keluarga yang memiliki UMKM?<?= requiredMark() ?></label>
          <div class="btn-group" role="group">
            <input type="radio" class="btn-check" name="ada_umkm" id="umkmYa" value="Ya" <?= $keluarga['ada_umkm']=='Ya'?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="umkmYa">Ya</label>
            <input type="radio" class="btn-check" name="ada_umkm" id="umkmTidak" value="Tidak" <?= $keluarga['ada_umkm']=='Tidak'?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="umkmTidak">Tidak</label>
          </div>
        </div>
        <div class="col-md-4" id="wrapJumlahUmkm">
          <label class="form-label d-block">Berapa Anggota Keluarga yang Memiliki UMKM?<span id="markJumlahUmkm"></span></label>
          <div class="row g-2">
            <div class="col-6">
              <label class="form-label small text-muted mb-1">Laki-laki</label>
              <input type="number" min="0" name="jumlah_anggota_umkm_lk" id="inputJumlahUmkmLk" class="form-control" value="<?= e($keluarga['jumlah_anggota_umkm_lk'] ?? '0') ?>">
            </div>
            <div class="col-6">
              <label class="form-label small text-muted mb-1">Perempuan</label>
              <input type="number" min="0" name="jumlah_anggota_umkm_pr" id="inputJumlahUmkmPr" class="form-control" value="<?= e($keluarga['jumlah_anggota_umkm_pr'] ?? '0') ?>">
            </div>
          </div>
          <div class="form-text">Tidak boleh melebihi jumlah anggota keluarga laki-laki/perempuan pada Data Keluarga.</div>
        </div>

        <div class="col-md-4">
          <label class="form-label d-block">Ada anggota keluarga penyandang disabilitas?<?= requiredMark() ?></label>
          <div class="btn-group" role="group">
            <input type="radio" class="btn-check" name="ada_disabilitas" id="disabilitasYa" value="Ya" <?= $keluarga['ada_disabilitas']=='Ya'?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="disabilitasYa">Ya</label>
            <input type="radio" class="btn-check" name="ada_disabilitas" id="disabilitasTidak" value="Tidak" <?= $keluarga['ada_disabilitas']=='Tidak'?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="disabilitasTidak">Tidak</label>
          </div>
          <div class="form-text">Individu dengan keterbatasan fisik, mental, intelektual, atau sensorik jangka panjang.</div>
        </div>
        <div class="col-md-4" id="wrapJumlahDisabilitas">
          <label class="form-label">Berapa Orang?<span id="markJumlahDisabilitas"></span></label>
          <input type="number" min="1" name="jumlah_disabilitas" id="inputJumlahDisabilitas" class="form-control" value="<?= e($keluarga['jumlah_disabilitas']) ?>">
        </div>
        <div class="col-md-4" id="wrapJenisDisabilitas">
          <label class="form-label">Jenis Disabilitas<span id="markJenisDisabilitas"></span></label>
          <input type="text" name="jenis_disabilitas" id="inputJenisDisabilitas" class="form-control" value="<?= e($keluarga['jenis_disabilitas']) ?>">
        </div>
      </div>
    </div>
  </div>

  <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4">
    <div>
      <button class="btn btn-teal"><i class="bi bi-save"></i> Simpan Perubahan</button>
      <a href="keluarga_view.php?id=<?= (int)$id ?>" class="btn btn-outline-secondary">Batal</a>
    </div>
    <div id="draftStatus" class="draft-status"></div>
  </div>
</form>

<script>
function pasangMaskTanggal(id) {
  const el = document.getElementById(id);
  if (!el) return;
  el.addEventListener('input', function () {
    let v = el.value.replace(/\D/g, '').slice(0, 8);
    let out = v.slice(0, 2);
    if (v.length > 2) out += '/' + v.slice(2, 4);
    if (v.length > 4) out += '/' + v.slice(4, 8);
    el.value = out;
  });
}
pasangMaskTanggal('tglLahirKK');

function hitungTotalAnggota() {
  const lk = parseInt(document.getElementById('jumlahLk').value) || 0;
  const pr = parseInt(document.getElementById('jumlahPr').value) || 0;
  document.getElementById('jumlahTotal').value = lk + pr;
}
document.getElementById('jumlahLk').addEventListener('input', hitungTotalAnggota);
document.getElementById('jumlahPr').addEventListener('input', hitungTotalAnggota);
hitungTotalAnggota();

const TANPA_DESKRIPSI = ['Pelajar/Mahasiswa', 'Tidak Bekerja'];
function toggleDeskripsiPekerjaan() {
  const val = document.getElementById('selStatusPekerjaan').value;
  const input = document.getElementById('inputDeskripsiPekerjaan');
  const butuh = val !== '' && !TANPA_DESKRIPSI.includes(val);
  document.getElementById('wrapDeskripsiPekerjaan').style.display = (val === '') ? 'none' : 'block';
  input.required = butuh;
  input.disabled = !butuh;
  document.getElementById('markDeskripsiPekerjaan').innerHTML = butuh ? ' <span class="text-danger">*</span>' : '';
}
document.getElementById('selStatusPekerjaan').addEventListener('change', toggleDeskripsiPekerjaan);
toggleDeskripsiPekerjaan();

function toggleWrapJenisBantuan() {
  const ya = document.getElementById('bantuanYa').checked;
  document.getElementById('wrapJenisBantuan').style.display = ya ? 'block' : 'none';
  document.getElementById('markJenisBantuan').innerHTML = ya ? ' <span class="text-danger">*</span>' : '';
  document.getElementById('markTglTerakhirBantuan').innerHTML = ya ? ' <span class="text-danger">*</span>' : '';
  document.getElementById('bulanTerakhirBantuan').required = ya;
  document.getElementById('tahunTerakhirBantuan').required = ya;
  if (!ya) {
    document.querySelectorAll('#wrapJenisBantuan input[type=checkbox]').forEach(cb => cb.checked = false);
    document.getElementById('inputDeskripsiBantuan').value = '';
    document.getElementById('bulanTerakhirBantuan').value = '';
    document.getElementById('tahunTerakhirBantuan').value = '';
  }
  toggleDeskripsiBantuan();
}
document.getElementById('bantuanYa').addEventListener('change', toggleWrapJenisBantuan);
document.getElementById('bantuanTidak').addEventListener('change', toggleWrapJenisBantuan);
toggleWrapJenisBantuan();

function toggleDeskripsiBantuan() {
  const lainnyaChecked = document.getElementById('jb_Lainnya') && document.getElementById('jb_Lainnya').checked;
  const tampil = document.getElementById('bantuanYa').checked && lainnyaChecked;
  document.getElementById('wrapDeskripsiBantuan').style.display = tampil ? 'block' : 'none';
  document.getElementById('inputDeskripsiBantuan').required = tampil;
  document.getElementById('markDeskripsiBantuan').innerHTML = tampil ? ' <span class="text-danger">*</span>' : '';
  if (!tampil) document.getElementById('inputDeskripsiBantuan').value = '';
}
toggleDeskripsiBantuan();

function toggleJumlahUmkm() {
  const ya = document.getElementById('umkmYa').checked;
  document.getElementById('wrapJumlahUmkm').style.display = ya ? 'block' : 'none';
  document.getElementById('inputJumlahUmkmLk').required = ya;
  document.getElementById('inputJumlahUmkmPr').required = ya;
  document.getElementById('markJumlahUmkm').innerHTML = ya ? ' <span class="text-danger">*</span>' : '';
  if (!ya) { document.getElementById('inputJumlahUmkmLk').value = '0'; document.getElementById('inputJumlahUmkmPr').value = '0'; }
}
document.getElementById('umkmYa').addEventListener('change', toggleJumlahUmkm);
document.getElementById('umkmTidak').addEventListener('change', toggleJumlahUmkm);
toggleJumlahUmkm();

function batasiJumlahUmkm() {
  const lk = parseInt(document.getElementById('jumlahLk').value) || 0;
  const pr = parseInt(document.getElementById('jumlahPr').value) || 0;
  document.getElementById('inputJumlahUmkmLk').max = lk;
  document.getElementById('inputJumlahUmkmPr').max = pr;
}
document.getElementById('jumlahLk').addEventListener('input', batasiJumlahUmkm);
document.getElementById('jumlahPr').addEventListener('input', batasiJumlahUmkm);
batasiJumlahUmkm();

function toggleDisabilitas() {
  const ya = document.getElementById('disabilitasYa').checked;
  document.getElementById('wrapJumlahDisabilitas').style.display = ya ? 'block' : 'none';
  document.getElementById('wrapJenisDisabilitas').style.display = ya ? 'block' : 'none';
  document.getElementById('inputJumlahDisabilitas').required = ya;
  document.getElementById('inputJenisDisabilitas').required = ya;
  document.getElementById('markJumlahDisabilitas').innerHTML = ya ? ' <span class="text-danger">*</span>' : '';
  document.getElementById('markJenisDisabilitas').innerHTML = ya ? ' <span class="text-danger">*</span>' : '';
}
document.getElementById('disabilitasYa').addEventListener('change', toggleDisabilitas);
document.getElementById('disabilitasTidak').addEventListener('change', toggleDisabilitas);
toggleDisabilitas();

Draft.init('formKeluargaEdit', 'draft_keluarga_edit_<?= (int)$id ?>', { bannerElId: 'draftBanner', statusElId: 'draftStatus' });
</script>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
