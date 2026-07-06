<?php
require_once __DIR__ . '/../includes/config.php';
requireRole(['ketua_rt','operator_kelurahan','admin_kelurahan']);
$pageTitle = 'Impor Data Keluarga dari Excel';

$COL = [
    'nomor_kk' => 0, 'nama_kk' => 1, 'rt' => 2, 'alamat' => 3,
    'jumlah_lk' => 4, 'jumlah_pr' => 5,
    'nik' => 6, 'jenis_kelamin' => 7, 'tanggal_lahir' => 8, 'agama' => 9,
    'status_perkawinan' => 10, 'pendidikan' => 11, 'status_pekerjaan' => 12, 'pekerjaan' => 13,
    'pernah_bantuan' => 14, 'ada_umkm' => 15, 'jumlah_anggota_umkm' => 16,
];

$rtList = $pdo->query("SELECT * FROM rt ORDER BY nomor_rt")->fetchAll();
$rtByNomor = [];
foreach ($rtList as $rt) { $rtByNomor[$rt['nomor_rt']] = $rt['id']; }

$laporan = [];
$jmlBerhasil = 0;
$jmlGagal = 0;
$sudahUpload = false;

function validTanggal($str) {
    if (!preg_match('/^\d{2}-\d{2}-\d{4}$/', $str)) return false;
    [$d, $m, $y] = explode('-', $str);
    return checkdate((int)$m, (int)$d, (int)$y);
}

function tanggalKeSql($str) {
    if (!validTanggal($str)) return null;
    [$d, $m, $y] = explode('-', $str);
    return sprintf('%04d-%02d-%02d', $y, $m, $d);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file_excel'])) {
    $sudahUpload = true;
    $file = $_FILES['file_excel'];

    if ($file['error'] !== UPLOAD_ERR_OK) {
        $_SESSION['flash_error'] = 'Gagal mengunggah file. Silakan coba lagi.';
        header('Location: keluarga_import.php');
        exit;
    }
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if ($ext !== 'xlsx') {
        $_SESSION['flash_error'] = 'File harus berformat .xlsx (Excel).';
        header('Location: keluarga_import.php');
        exit;
    }

    try {
        $rows = readXlsxSimple($file['tmp_name'], 'Import Keluarga');
    } catch (Exception $ex) {
        $_SESSION['flash_error'] = 'Gagal membaca file: ' . $ex->getMessage();
        header('Location: keluarga_import.php');
        exit;
    }

    $rowNums = array_keys($rows);
    sort($rowNums);
    $existingNikInFile = [];
    $existingKkInFile = [];

    foreach ($rowNums as $rn) {
        if ($rn <= 1) continue; // lewati baris header
        $r = $rows[$rn];
        $nomorKk = xlsxCell($r, $COL['nomor_kk']);
        if ($nomorKk === '') continue; // baris kosong dilewati

        $namaKk = xlsxCell($r, $COL['nama_kk']);
        if (stripos($namaKk, 'Contoh ') === 0) continue; // lewati baris contoh bawaan template

        $errorsRow = [];
        $rtNomor = str_pad(xlsxCell($r, $COL['rt']), 3, '0', STR_PAD_LEFT);
        $alamat = xlsxCell($r, $COL['alamat']);
        $jumlahLk = xlsxCell($r, $COL['jumlah_lk']);
        $jumlahPr = xlsxCell($r, $COL['jumlah_pr']);
        $nik = xlsxCell($r, $COL['nik']);
        $jk = xlsxCell($r, $COL['jenis_kelamin']);
        $tglLahir = xlsxCell($r, $COL['tanggal_lahir']);
        $agama = xlsxCell($r, $COL['agama']);
        $statusKawin = xlsxCell($r, $COL['status_perkawinan']);
        $pendidikan = xlsxCell($r, $COL['pendidikan']);
        $statusPekerjaan = xlsxCell($r, $COL['status_pekerjaan']);
        $pekerjaan = xlsxCell($r, $COL['pekerjaan']);
        $pernahBantuan = xlsxCell($r, $COL['pernah_bantuan']) ?: 'Tidak';
        $adaUmkm = xlsxCell($r, $COL['ada_umkm']) ?: 'Tidak';
        $jumlahUmkm = xlsxCell($r, $COL['jumlah_anggota_umkm']);

        $prefix = "Baris $rn: ";
        if (!preg_match('/^\d{16}$/', $nomorKk)) $errorsRow[] = $prefix . 'Nomor KK harus 16 digit angka.';
        if ($namaKk === '') $errorsRow[] = $prefix . 'Nama Kepala Keluarga kosong.';
        if (!isset($rtByNomor[$rtNomor])) $errorsRow[] = $prefix . "RT '$rtNomor' tidak ditemukan di sistem.";
        if ($alamat === '') $errorsRow[] = $prefix . 'Alamat kosong.';
        if (!is_numeric($jumlahLk) || (int)$jumlahLk < 0) $errorsRow[] = $prefix . 'Jumlah Laki-laki tidak valid.';
        if (!is_numeric($jumlahPr) || (int)$jumlahPr < 0) $errorsRow[] = $prefix . 'Jumlah Perempuan tidak valid.';
        if (((int)$jumlahLk + (int)$jumlahPr) < 1) $errorsRow[] = $prefix . 'Total anggota (laki-laki + perempuan) minimal 1.';
        if (!preg_match('/^\d{16}$/', $nik)) $errorsRow[] = $prefix . 'NIK Kepala Keluarga harus 16 digit angka.';
        if (!in_array($jk, ['Laki-laki','Perempuan'])) $errorsRow[] = $prefix . 'Jenis Kelamin tidak valid.';
        if (!validTanggal($tglLahir)) $errorsRow[] = $prefix . 'Tanggal Lahir tidak valid (format DD-MM-YYYY).';
        if (!in_array($statusPekerjaan, pilihanStatusPekerjaan())) {
            $errorsRow[] = $prefix . 'Status Pekerjaan tidak valid.';
        } elseif (butuhDeskripsiPekerjaan($statusPekerjaan) && $pekerjaan === '') {
            $errorsRow[] = $prefix . 'Deskripsi Pekerjaan wajib diisi untuk status pekerjaan ini.';
        }
        if (!butuhDeskripsiPekerjaan($statusPekerjaan)) $pekerjaan = '';
        if (!in_array($pernahBantuan, ['Ya','Tidak'])) $errorsRow[] = $prefix . 'Pernah Terima Bantuan harus "Ya" atau "Tidak".';
        if (!in_array($adaUmkm, ['Ya','Tidak'])) $errorsRow[] = $prefix . 'Ada UMKM harus "Ya" atau "Tidak".';
        if ($adaUmkm === 'Ya' && (!is_numeric($jumlahUmkm) || (int)$jumlahUmkm < 1)) $errorsRow[] = $prefix . 'Jumlah Anggota UMKM wajib diisi (minimal 1) jika Ada UMKM = Ya.';

        // Ketua RT hanya boleh impor untuk RT-nya sendiri
        if (hasRole('ketua_rt') && isset($rtByNomor[$rtNomor]) && (int)$rtByNomor[$rtNomor] !== (int)currentUser()['rt_id']) {
            $errorsRow[] = $prefix . 'RT pada file (' . $rtNomor . ') berbeda dengan RT Anda.';
        }

        if (isset($existingKkInFile[$nomorKk])) $errorsRow[] = $prefix . 'Nomor KK duplikat dengan baris lain dalam file.';
        if (isset($existingNikInFile[$nik])) $errorsRow[] = $prefix . 'NIK duplikat dengan baris lain dalam file.';

        if (empty($errorsRow)) {
            $check = $pdo->prepare("SELECT id FROM keluarga WHERE nomor_kk = ?");
            $check->execute([$nomorKk]);
            if ($check->fetch()) $errorsRow[] = $prefix . 'Nomor KK sudah terdaftar di sistem.';

            $checkNik = $pdo->prepare("SELECT id FROM keluarga WHERE nik_kepala_keluarga = ?");
            $checkNik->execute([$nik]);
            if ($checkNik->fetch()) $errorsRow[] = $prefix . 'NIK Kepala Keluarga sudah terdaftar di sistem.';
        }

        if (!empty($errorsRow)) {
            $jmlGagal++;
            $laporan[] = ['kk' => $nomorKk, 'nama' => $namaKk, 'status' => 'gagal', 'pesan' => $errorsRow];
            continue;
        }

        $existingKkInFile[$nomorKk] = true;
        $existingNikInFile[$nik] = true;

        try {
            $stmt = $pdo->prepare("INSERT INTO keluarga
                (nama_kepala_keluarga, alamat, rt_id, nomor_kk, jumlah_lk, jumlah_pr, jumlah_total,
                 nik_kepala_keluarga, jenis_kelamin_kepala_keluarga, tanggal_lahir_kepala_keluarga,
                 agama_kepala_keluarga, status_perkawinan_kepala_keluarga, pendidikan_kepala_keluarga,
                 status_pekerjaan_kepala_keluarga, pekerjaan_kepala_keluarga,
                 pernah_bantuan, ada_umkm, jumlah_anggota_umkm, created_by, updated_by)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
            $stmt->execute([
                $namaKk, $alamat, $rtByNomor[$rtNomor], $nomorKk, (int)$jumlahLk, (int)$jumlahPr, (int)$jumlahLk + (int)$jumlahPr,
                $nik, $jk, tanggalKeSql($tglLahir), $agama ?: null, $statusKawin ?: null, $pendidikan ?: null,
                $statusPekerjaan, $pekerjaan ?: null,
                $pernahBantuan, $adaUmkm, $adaUmkm === 'Ya' ? (int)$jumlahUmkm : null,
                currentUser()['id'], currentUser()['id'],
            ]);
            $jmlBerhasil++;
            $laporan[] = ['kk' => $nomorKk, 'nama' => $namaKk, 'status' => 'berhasil', 'pesan' => ['Berhasil diimpor.']];
        } catch (Exception $ex) {
            $jmlGagal++;
            $laporan[] = ['kk' => $nomorKk, 'nama' => $namaKk, 'status' => 'gagal', 'pesan' => ['Terjadi kesalahan sistem: ' . $ex->getMessage()]];
        }
    }

    if (empty($laporan)) {
        $_SESSION['flash_error'] = 'Tidak ada data yang dapat dibaca dari file. Pastikan Anda mengisi mulai baris ke-2 dan tidak mengubah struktur kolom template.';
    }
}

require __DIR__ . '/../includes/partials_header.php';
?>
<h4 class="fw-semibold mb-3">Impor Data Keluarga dari Excel</h4>

<div class="row g-3 mb-3">
  <div class="col-md-6">
    <div class="card border-0 shadow-sm h-100">
      <div class="card-header bg-white fw-semibold">Langkah 1: Unduh Template</div>
      <div class="card-body">
        <p class="text-muted small">Gunakan template ini agar format kolom sesuai dan bisa langsung dibaca sistem. Template sudah dilengkapi dropdown untuk kolom berkode dan contoh pengisian.</p>
        <a href="template_import_keluarga.xlsx" class="btn btn-outline-secondary" download><i class="bi bi-download"></i> Unduh Template Excel</a>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card border-0 shadow-sm h-100">
      <div class="card-header bg-white fw-semibold">Langkah 2: Unggah File Terisi</div>
      <div class="card-body">
        <form method="post" enctype="multipart/form-data">
          <div class="mb-3">
            <label class="form-label">Pilih file Excel (.xlsx)<?= requiredMark() ?></label>
            <input type="file" name="file_excel" accept=".xlsx" class="form-control" required>
          </div>
          <button class="btn btn-teal"><i class="bi bi-upload"></i> Impor Data</button>
        </form>
      </div>
    </div>
  </div>
</div>

<div class="alert alert-light border small">
  <i class="bi bi-info-circle"></i>
  Satu baris = satu keluarga (data Kepala Keluarga langsung digabung pada baris yang sama).
  Nomor KK dan NIK yang sudah terdaftar di sistem akan ditolak (gunakan menu Ubah Data Keluarga
  untuk memperbarui data yang sudah ada).
  <?php if (hasRole('ketua_rt')): ?>Sebagai Ketua RT, Anda hanya dapat mengimpor data untuk RT <?= e(currentUser()['nomor_rt']) ?>.<?php endif; ?>
</div>

<?php if ($sudahUpload): ?>
<div class="card border-0 shadow-sm">
  <div class="card-header bg-white fw-semibold d-flex justify-content-between align-items-center flex-wrap gap-2">
    <span>Hasil Impor</span>
    <span>
      <span class="badge bg-success">Berhasil: <?= $jmlBerhasil ?> keluarga</span>
      <span class="badge bg-danger">Gagal: <?= $jmlGagal ?> keluarga</span>
    </span>
  </div>
  <div class="table-responsive">
    <table class="table table-hover mb-0 align-middle table-mobile-cards">
      <thead class="table-light"><tr><th>Nomor KK</th><th>Nama Kepala Keluarga</th><th>Status</th><th>Keterangan</th></tr></thead>
      <tbody>
      <?php foreach ($laporan as $l): ?>
        <tr>
          <td data-label="Nomor KK"><?= e($l['kk']) ?></td>
          <td data-label="Nama Kepala Keluarga"><?= e($l['nama']) ?></td>
          <td data-label="Status">
            <?php if ($l['status'] === 'berhasil'): ?>
              <span class="badge bg-success">Berhasil</span>
            <?php else: ?>
              <span class="badge bg-danger">Gagal</span>
            <?php endif; ?>
          </td>
          <td data-label="Keterangan">
            <ul class="mb-0 ps-3 small">
              <?php foreach ($l['pesan'] as $p): ?><li><?= e($p) ?></li><?php endforeach; ?>
            </ul>
          </td>
        </tr>
      <?php endforeach; ?>
      <?php if (empty($laporan)): ?>
        <tr><td colspan="4" class="text-center text-muted py-4">Tidak ada baris data yang diproses</td></tr>
      <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>
<?php if ($jmlBerhasil > 0): ?>
  <div class="mt-3"><a href="keluarga_list.php" class="btn btn-teal"><i class="bi bi-list-check"></i> Lihat Data Keluarga</a></div>
<?php endif; ?>
<?php endif; ?>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
