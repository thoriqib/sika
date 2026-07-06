<?php
require_once __DIR__ . '/../includes/config.php';
requireRole(['ketua_rt','operator_kelurahan','admin_kelurahan']);
$pageTitle = 'Tambah Keluarga';

$rtList = $pdo->query("SELECT * FROM rt ORDER BY nomor_rt")->fetchAll();
$customFields = getCustomFields($pdo, 'keluarga');
$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nama = trim($_POST['nama_kepala_keluarga'] ?? '');
    $alamat = trim($_POST['alamat'] ?? '');
    $rt_id = hasRole('ketua_rt') ? currentUser()['rt_id'] : ($_POST['rt_id'] ?? '');
    $nomor_kk = trim($_POST['nomor_kk'] ?? '');
    $jumlah_lk = (int)($_POST['jumlah_lk'] ?? 0);
    $jumlah_pr = (int)($_POST['jumlah_pr'] ?? 0);
    $jumlah_total = $jumlah_lk + $jumlah_pr;

    $nik = trim($_POST['nik_kepala_keluarga'] ?? '');
    $jk = $_POST['jenis_kelamin_kepala_keluarga'] ?? '';
    $tgl = $_POST['tanggal_lahir_kepala_keluarga'] ?? '';
    $agama = trim($_POST['agama_kepala_keluarga'] ?? '');
    $status_kawin = trim($_POST['status_perkawinan_kepala_keluarga'] ?? '');
    $pendidikan = trim($_POST['pendidikan_kepala_keluarga'] ?? '');
    $status_pekerjaan = trim($_POST['status_pekerjaan_kepala_keluarga'] ?? '');
    $pekerjaan = trim($_POST['pekerjaan_kepala_keluarga'] ?? '');

    $pernah_bantuan = ($_POST['pernah_bantuan'] ?? 'Tidak') === 'Ya' ? 'Ya' : 'Tidak';
    $ada_umkm = ($_POST['ada_umkm'] ?? 'Tidak') === 'Ya' ? 'Ya' : 'Tidak';
    $jumlah_anggota_umkm = $ada_umkm === 'Ya' ? (int)($_POST['jumlah_anggota_umkm'] ?? 0) : null;

    if ($nama === '') $errors[] = 'Nama kepala keluarga wajib diisi.';
    if ($alamat === '') $errors[] = 'Alamat wajib diisi.';
    if (!$rt_id) $errors[] = 'RT wajib dipilih.';
    if ($nomor_kk === '' || !preg_match('/^\d{16}$/', $nomor_kk)) $errors[] = 'Nomor KK harus berupa 16 digit angka.';
    if ($jumlah_lk < 0 || $jumlah_pr < 0) $errors[] = 'Jumlah anggota tidak boleh negatif.';
    if ($jumlah_total < 1) $errors[] = 'Jumlah anggota keluarga (laki-laki + perempuan) minimal 1 (Kepala Keluarga).';

    if (!preg_match('/^\d{16}$/', $nik)) $errors[] = 'NIK Kepala Keluarga harus berupa 16 digit angka.';
    if (!in_array($jk, ['Laki-laki','Perempuan'])) $errors[] = 'Jenis kelamin Kepala Keluarga wajib dipilih.';
    if ($tgl === '') $errors[] = 'Tanggal lahir Kepala Keluarga wajib diisi.';
    if (!in_array($status_pekerjaan, pilihanStatusPekerjaan())) {
        $errors[] = 'Status pekerjaan Kepala Keluarga wajib dipilih.';
    } elseif (butuhDeskripsiPekerjaan($status_pekerjaan) && $pekerjaan === '') {
        $errors[] = 'Deskripsi pekerjaan Kepala Keluarga wajib diisi untuk status pekerjaan yang dipilih.';
    }
    if (!butuhDeskripsiPekerjaan($status_pekerjaan)) $pekerjaan = null;
    if ($ada_umkm === 'Ya' && $jumlah_anggota_umkm < 1) $errors[] = 'Jumlah anggota keluarga pemilik UMKM wajib diisi (minimal 1) jika ada UMKM.';

    if (empty($errors)) {
        $check = $pdo->prepare("SELECT id FROM keluarga WHERE nomor_kk = ?");
        $check->execute([$nomor_kk]);
        if ($check->fetch()) $errors[] = 'Nomor KK sudah terdaftar.';

        $checkNik = $pdo->prepare("SELECT id FROM keluarga WHERE nik_kepala_keluarga = ?");
        $checkNik->execute([$nik]);
        if ($checkNik->fetch()) $errors[] = 'NIK Kepala Keluarga sudah terdaftar pada keluarga lain.';
    }

    if (empty($errors)) {
        $stmt = $pdo->prepare("INSERT INTO keluarga
            (nama_kepala_keluarga, alamat, rt_id, nomor_kk, jumlah_lk, jumlah_pr, jumlah_total,
             nik_kepala_keluarga, jenis_kelamin_kepala_keluarga, tanggal_lahir_kepala_keluarga,
             agama_kepala_keluarga, status_perkawinan_kepala_keluarga, pendidikan_kepala_keluarga,
             status_pekerjaan_kepala_keluarga, pekerjaan_kepala_keluarga,
             pernah_bantuan, ada_umkm, jumlah_anggota_umkm, created_by, updated_by)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
        $stmt->execute([
            $nama, $alamat, $rt_id, $nomor_kk, $jumlah_lk, $jumlah_pr, $jumlah_total,
            $nik, $jk, $tgl, $agama, $status_kawin, $pendidikan,
            $status_pekerjaan, $pekerjaan,
            $pernah_bantuan, $ada_umkm, $jumlah_anggota_umkm, currentUser()['id'], currentUser()['id'],
        ]);
        $keluargaId = $pdo->lastInsertId();
        saveCustomFieldValues($pdo, 'keluarga', $keluargaId, $_POST);

        $_SESSION['flash_success'] = 'Data keluarga berhasil ditambahkan.';
        header('Location: keluarga_view.php?id=' . $keluargaId . '&clear_draft=draft_keluarga_create');
        exit;
    }
}

require __DIR__ . '/../includes/partials_header.php';
?>
<h4 class="fw-semibold mb-3">Tambah Data Keluarga</h4>
<?php if ($errors): ?><div class="alert alert-danger"><ul class="mb-0"><?php foreach($errors as $er) echo '<li>'.e($er).'</li>'; ?></ul></div><?php endif; ?>

<div id="draftBanner" class="draft-banner"></div>

<form method="post" id="formKeluargaCreate">
  <div class="card border-0 shadow-sm mb-3">
    <div class="card-header bg-white fw-semibold">Data Keluarga</div>
    <div class="card-body">
      <div class="row g-3">
        <div class="col-md-6">
          <label class="form-label">Nama Kepala Keluarga<?= requiredMark() ?></label>
          <input type="text" name="nama_kepala_keluarga" class="form-control" value="<?= e($_POST['nama_kepala_keluarga'] ?? '') ?>" required>
        </div>
        <div class="col-md-3">
          <label class="form-label">Nomor KK<?= requiredMark() ?></label>
          <input type="text" name="nomor_kk" maxlength="16" class="form-control" value="<?= e($_POST['nomor_kk'] ?? '') ?>" required>
        </div>
        <div class="col-md-3">
          <label class="form-label">RT<?= requiredMark() ?></label>
          <?php if (hasRole('ketua_rt')): ?>
            <input type="text" class="form-control" value="RT <?= e(currentUser()['nomor_rt']) ?>" disabled>
          <?php else: ?>
            <select name="rt_id" class="form-select" required>
              <option value="">Pilih RT</option>
              <?php foreach ($rtList as $rt): ?>
                <option value="<?= $rt['id'] ?>"><?= e($rt['nomor_rt']) ?></option>
              <?php endforeach; ?>
            </select>
          <?php endif; ?>
        </div>
        <div class="col-md-8">
          <label class="form-label">Alamat<?= requiredMark() ?></label>
          <textarea name="alamat" class="form-control" rows="2" required><?= e($_POST['alamat'] ?? '') ?></textarea>
        </div>
        <div class="col-md-2">
          <label class="form-label">Jumlah Laki-laki<?= requiredMark() ?></label>
          <input type="number" min="0" name="jumlah_lk" id="jumlahLk" class="form-control" value="<?= e($_POST['jumlah_lk'] ?? '0') ?>" required>
        </div>
        <div class="col-md-2">
          <label class="form-label">Jumlah Perempuan<?= requiredMark() ?></label>
          <input type="number" min="0" name="jumlah_pr" id="jumlahPr" class="form-control" value="<?= e($_POST['jumlah_pr'] ?? '0') ?>" required>
        </div>
        <div class="col-md-2">
          <label class="form-label">Total Anggota</label>
          <input type="text" id="jumlahTotal" class="form-control" value="0" disabled>
          <div class="form-text">Dihitung otomatis</div>
        </div>

        <?php if ($customFields): ?>
          <div class="col-12"><hr><h6 class="text-muted">Variabel Tambahan</h6></div>
          <?php foreach ($customFields as $cf): ?>
            <div class="col-md-4">
              <label class="form-label"><?= e($cf['field_label']) ?><?= $cf['is_required'] ? requiredMark() : '' ?></label>
              <?php if ($cf['field_type'] === 'select'): ?>
                <select name="<?= e($cf['field_key']) ?>" class="form-select" <?= $cf['is_required'] ? 'required' : '' ?>>
                  <option value="">Pilih</option>
                  <?php foreach (explode(',', $cf['field_options']) as $opt): $opt = trim($opt); if ($opt === '') continue; ?>
                    <option value="<?= e($opt) ?>"><?= e($opt) ?></option>
                  <?php endforeach; ?>
                </select>
              <?php elseif ($cf['field_type'] === 'textarea'): ?>
                <textarea name="<?= e($cf['field_key']) ?>" class="form-control" <?= $cf['is_required'] ? 'required' : '' ?>></textarea>
              <?php else: ?>
                <div class="input-group">
                  <input type="<?= e($cf['field_type']) ?>" name="<?= e($cf['field_key']) ?>" class="form-control" <?= $cf['is_required'] ? 'required' : '' ?>>
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
          <input type="text" name="nik_kepala_keluarga" maxlength="16" class="form-control" value="<?= e($_POST['nik_kepala_keluarga'] ?? '') ?>" required>
        </div>
        <div class="col-md-3">
          <label class="form-label">Jenis Kelamin<?= requiredMark() ?></label>
          <select name="jenis_kelamin_kepala_keluarga" class="form-select" required>
            <option value="">Pilih</option>
            <option value="Laki-laki" <?= (($_POST['jenis_kelamin_kepala_keluarga'] ?? '')=='Laki-laki')?'selected':'' ?>>Laki-laki</option>
            <option value="Perempuan" <?= (($_POST['jenis_kelamin_kepala_keluarga'] ?? '')=='Perempuan')?'selected':'' ?>>Perempuan</option>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">Tanggal Lahir<?= requiredMark() ?></label>
          <input type="date" name="tanggal_lahir_kepala_keluarga" class="form-control" value="<?= e($_POST['tanggal_lahir_kepala_keluarga'] ?? '') ?>" required>
        </div>
        <div class="col-md-3">
          <label class="form-label">Agama</label>
          <select name="agama_kepala_keluarga" class="form-select">
            <option value="">Pilih</option>
            <?php foreach (pilihanAgama() as $ag): ?>
              <option value="<?= $ag ?>" <?= (($_POST['agama_kepala_keluarga'] ?? '')==$ag)?'selected':'' ?>><?= $ag ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">Status Perkawinan</label>
          <select name="status_perkawinan_kepala_keluarga" class="form-select">
            <option value="">Pilih</option>
            <?php foreach (pilihanStatusKawin() as $sp): ?>
              <option value="<?= $sp ?>" <?= (($_POST['status_perkawinan_kepala_keluarga'] ?? '')==$sp)?'selected':'' ?>><?= $sp ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">Pendidikan Terakhir</label>
          <select name="pendidikan_kepala_keluarga" class="form-select">
            <option value="">Pilih</option>
            <?php foreach (pilihanPendidikan() as $pd): ?>
              <option value="<?= $pd ?>" <?= (($_POST['pendidikan_kepala_keluarga'] ?? '')==$pd)?'selected':'' ?>><?= $pd ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="col-md-4">
          <label class="form-label">Status Pekerjaan<?= requiredMark() ?></label>
          <select name="status_pekerjaan_kepala_keluarga" class="form-select" id="selStatusPekerjaan" required>
            <option value="">Pilih</option>
            <?php foreach (pilihanStatusPekerjaan() as $i => $sp): ?>
              <option value="<?= e($sp) ?>" <?= (($_POST['status_pekerjaan_kepala_keluarga'] ?? '')==$sp)?'selected':'' ?>><?= ($i+1) ?>. <?= e($sp) ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="col-md-4" id="wrapDeskripsiPekerjaan">
          <label class="form-label">Deskripsi Pekerjaan<span id="markDeskripsiPekerjaan"></span></label>
          <input type="text" name="pekerjaan_kepala_keluarga" id="inputDeskripsiPekerjaan" class="form-control" placeholder="contoh: Petani sawit, Guru SD, Pedagang sayur" value="<?= e($_POST['pekerjaan_kepala_keluarga'] ?? '') ?>">
        </div>
      </div>
    </div>
  </div>

  <div class="card border-0 shadow-sm mb-3">
    <div class="card-header bg-white fw-semibold"><i class="bi bi-hand-holding-heart"></i> Bantuan &amp; UMKM</div>
    <div class="card-body">
      <div class="row g-3">
        <div class="col-md-6">
          <label class="form-label d-block">Apakah keluarga ini pernah menerima bantuan dari pemerintah?<?= requiredMark() ?></label>
          <div class="btn-group" role="group">
            <input type="radio" class="btn-check" name="pernah_bantuan" id="bantuanYa" value="Ya" <?= (($_POST['pernah_bantuan'] ?? 'Tidak')=='Ya')?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="bantuanYa">Ya</label>
            <input type="radio" class="btn-check" name="pernah_bantuan" id="bantuanTidak" value="Tidak" <?= (($_POST['pernah_bantuan'] ?? 'Tidak')=='Tidak')?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="bantuanTidak">Tidak</label>
          </div>
        </div>
        <div class="col-md-6">
          <label class="form-label d-block">Apakah ada anggota keluarga yang memiliki UMKM?<?= requiredMark() ?></label>
          <div class="btn-group" role="group">
            <input type="radio" class="btn-check" name="ada_umkm" id="umkmYa" value="Ya" <?= (($_POST['ada_umkm'] ?? 'Tidak')=='Ya')?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="umkmYa">Ya</label>
            <input type="radio" class="btn-check" name="ada_umkm" id="umkmTidak" value="Tidak" <?= (($_POST['ada_umkm'] ?? 'Tidak')=='Tidak')?'checked':'' ?>>
            <label class="btn btn-outline-teal" for="umkmTidak">Tidak</label>
          </div>
        </div>
        <div class="col-md-4" id="wrapJumlahUmkm">
          <label class="form-label">Berapa Anggota Keluarga yang Memiliki UMKM?<span id="markJumlahUmkm"></span></label>
          <input type="number" min="1" name="jumlah_anggota_umkm" id="inputJumlahUmkm" class="form-control" value="<?= e($_POST['jumlah_anggota_umkm'] ?? '') ?>">
        </div>
      </div>
    </div>
  </div>

  <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4">
    <div>
      <button class="btn btn-teal"><i class="bi bi-save"></i> Simpan</button>
      <a href="keluarga_list.php" class="btn btn-outline-secondary">Batal</a>
    </div>
    <div id="draftStatus" class="draft-status"></div>
  </div>
</form>

<script>
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
  if (!butuh) input.value = '';
}
document.getElementById('selStatusPekerjaan').addEventListener('change', toggleDeskripsiPekerjaan);
toggleDeskripsiPekerjaan();

function toggleJumlahUmkm() {
  const ya = document.getElementById('umkmYa').checked;
  document.getElementById('wrapJumlahUmkm').style.display = ya ? 'block' : 'none';
  document.getElementById('inputJumlahUmkm').required = ya;
  document.getElementById('markJumlahUmkm').innerHTML = ya ? ' <span class="text-danger">*</span>' : '';
  if (!ya) document.getElementById('inputJumlahUmkm').value = '';
}
document.getElementById('umkmYa').addEventListener('change', toggleJumlahUmkm);
document.getElementById('umkmTidak').addEventListener('change', toggleJumlahUmkm);
toggleJumlahUmkm();

Draft.init('formKeluargaCreate', 'draft_keluarga_create', { bannerElId: 'draftBanner', statusElId: 'draftStatus' });
</script>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
