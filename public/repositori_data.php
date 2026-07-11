<?php
require_once __DIR__ . '/../includes/config.php';
requireRole(['admin_kelurahan', 'operator_kelurahan']);
$pageTitle = 'Repositori Data';

$tahun = date('Y');

// ===================== Tabel 3.1: Penduduk per RT & Jenis Kelamin =====================
$t31 = $pdo->query("
    SELECT r.nomor_rt,
           COALESCE(SUM(k.jumlah_lk),0) lk,
           COALESCE(SUM(k.jumlah_pr),0) pr,
           COALESCE(SUM(k.jumlah_total),0) total
    FROM rt r LEFT JOIN keluarga k ON k.rt_id = r.id AND k.status_keberadaan = 'Ada'
    GROUP BY r.id ORDER BY r.nomor_rt
")->fetchAll();
$t31total = ['lk' => array_sum(array_column($t31, 'lk')), 'pr' => array_sum(array_column($t31, 'pr')), 'total' => array_sum(array_column($t31, 'total'))];

// ===================== Tabel 3.2: KK & Bangunan per RT =====================
$t32 = $pdo->query("
    SELECT r.nomor_rt,
           (SELECT COUNT(*) FROM keluarga k2 WHERE k2.rt_id = r.id AND k2.status_keberadaan = 'Ada') jml_kk,
           r.jml_bangunan_tinggal, r.jml_bangunan_rumah_ibadah,
           r.jml_bangunan_fasilitas_pendidikan, r.jml_bangunan_fasilitas_kesehatan, r.jml_bangunan_kosong
    FROM rt r ORDER BY r.nomor_rt
")->fetchAll();
$t32total = [
    'jml_kk' => array_sum(array_column($t32, 'jml_kk')),
    'jml_bangunan_tinggal' => array_sum(array_column($t32, 'jml_bangunan_tinggal')),
    'jml_bangunan_rumah_ibadah' => array_sum(array_column($t32, 'jml_bangunan_rumah_ibadah')),
    'jml_bangunan_fasilitas_pendidikan' => array_sum(array_column($t32, 'jml_bangunan_fasilitas_pendidikan')),
    'jml_bangunan_fasilitas_kesehatan' => array_sum(array_column($t32, 'jml_bangunan_fasilitas_kesehatan')),
    'jml_bangunan_kosong' => array_sum(array_column($t32, 'jml_bangunan_kosong')),
];

// ===================== Tabel 3.3: Sex Ratio per RT =====================
$t33 = [];
foreach ($t31 as $row) {
    $t33[] = ['nomor_rt' => $row['nomor_rt'], 'sex_ratio' => $row['pr'] > 0 ? round($row['lk'] / $row['pr'] * 100, 2) : ($row['lk'] > 0 ? null : 0)];
}
$t33total = $t31total['pr'] > 0 ? round($t31total['lk'] / $t31total['pr'] * 100, 2) : 0;

// ===================== Tabel 3.4: Bantuan, UMKM & Disabilitas per RT =====================
$t34 = $pdo->query("
    SELECT r.nomor_rt,
           COALESCE(SUM(CASE WHEN k.pernah_bantuan='Ya' THEN 1 ELSE 0 END),0) jml_bantuan,
           COALESCE(SUM(CASE WHEN k.ada_umkm='Ya' THEN 1 ELSE 0 END),0) jml_umkm,
           COALESCE(SUM(CASE WHEN k.ada_disabilitas='Ya' THEN 1 ELSE 0 END),0) jml_kk_disabilitas,
           COALESCE(SUM(k.jumlah_disabilitas),0) jml_orang_disabilitas
    FROM rt r LEFT JOIN keluarga k ON k.rt_id = r.id AND k.status_keberadaan = 'Ada'
    GROUP BY r.id ORDER BY r.nomor_rt
")->fetchAll();
$t34total = [
    'jml_bantuan' => array_sum(array_column($t34, 'jml_bantuan')),
    'jml_umkm' => array_sum(array_column($t34, 'jml_umkm')),
    'jml_kk_disabilitas' => array_sum(array_column($t34, 'jml_kk_disabilitas')),
    'jml_orang_disabilitas' => array_sum(array_column($t34, 'jml_orang_disabilitas')),
];

require __DIR__ . '/../includes/partials_header.php';
?>
<style>
  .rd-table-wrap { overflow-x: auto; margin-bottom: 2.5rem; }
  .rd-caption { margin-bottom: .5rem; }
  .rd-caption .rd-nomor { font-weight: 700; }
  .rd-caption .rd-judul { font-weight: 700; }
  .rd-caption .rd-judul-en { font-style: italic; color: #555; }
  table.rd-table { border-collapse: collapse; width: 100%; min-width: 600px; background: #fff; }
  table.rd-table th, table.rd-table td { border: none; padding: 10px 14px; text-align: center; }
  table.rd-table thead tr.rd-head-main th { background: #F6B94D; font-weight: 700; color: #4a3300; }
  table.rd-table thead tr.rd-head-sub th { background: #FBD98E; font-weight: 700; color: #4a3300; font-size: .92rem; }
  table.rd-table thead tr.rd-head-num th { background: #FCE7BC; color: #7a5a1e; font-size: .82rem; font-weight: 400; }
  table.rd-table tbody td:first-child, table.rd-table thead th:first-child { text-align: left; font-weight: 600; color: #4a3300; }
  table.rd-table tbody tr:nth-child(odd) { background: #FFF6E6; }
  table.rd-table tbody tr:nth-child(even) { background: #FFFBF2; }
  table.rd-table tfoot td { background: #F6B94D; font-weight: 700; color: #4a3300; text-align: left; }
  table.rd-table tfoot td:not(:first-child) { text-align: center; }
  .rd-source { font-size: .82rem; color: #666; margin-top: -1.5rem; margin-bottom: 2.5rem; }
  .rd-toolbar { display: flex; gap: .5rem; }
  .rd-source b { font-weight: 600; }
  @media print {
    .no-print { display: none !important; }
  }
</style>

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2 no-print">
  <h4 class="fw-semibold mb-0">Repositori Data</h4>
  <button onclick="window.print()" class="btn btn-outline-secondary"><i class="bi bi-printer"></i> Cetak / Simpan PDF</button>
</div>
<p class="text-muted no-print">Rekap data agregat per RT, format tabel resmi untuk keperluan laporan/publikasi kelurahan.</p>

<!-- ===================== Tabel 3.1 ===================== -->
<div class="rd-caption">
  <span class="rd-nomor">Tabel&nbsp;3.1</span>
  <span class="rd-judul">Jumlah Penduduk Kelurahan Mudung Laut menurut Rukun Tetangga dan Jenis Kelamin Tahun <?= $tahun ?></span><br>
  <span class="rd-judul-en">Population of Mudung Laut Subdistrict by Neighborhood Association and Gender, <?= $tahun ?></span>
</div>
<div class="rd-toolbar no-print mb-2">
  <button type="button" class="btn btn-sm btn-outline-secondary" onclick="unduhTabelExcel('tabel31','Tabel_3.1_Penduduk_per_RT')"><i class="bi bi-file-earmark-excel"></i> Unduh Excel</button>
</div>
<div class="rd-table-wrap">
  <table class="rd-table" id="tabel31">
    <thead>
      <tr class="rd-head-main">
        <th rowspan="2">Rukun Tetangga<br><span class="rd-judul-en" style="font-size:.85rem">Neighborhood</span></th>
        <th colspan="3">Penduduk/<span class="rd-judul-en">Population</span></th>
      </tr>
      <tr class="rd-head-sub">
        <th>Laki-laki/<span class="rd-judul-en">Male</span></th>
        <th>Perempuan/<span class="rd-judul-en">Female</span></th>
        <th>Jumlah/<span class="rd-judul-en">Total</span></th>
      </tr>
      <tr class="rd-head-num"><th>(1)</th><th>(2)</th><th>(3)</th><th>(4)</th></tr>
    </thead>
    <tbody>
      <?php foreach ($t31 as $row): ?>
      <tr>
        <td>RT <?= e($row['nomor_rt']) ?></td>
        <td><?= number_format($row['lk']) ?></td>
        <td><?= number_format($row['pr']) ?></td>
        <td><?= number_format($row['total']) ?></td>
      </tr>
      <?php endforeach; ?>
    </tbody>
    <tfoot>
      <tr><td>Mudung Laut</td><td><?= number_format($t31total['lk']) ?></td><td><?= number_format($t31total['pr']) ?></td><td><?= number_format($t31total['total']) ?></td></tr>
    </tfoot>
  </table>
</div>
<div class="rd-source">Sumber/<i>Source</i>: <b>Sistem SIKA Kelurahan Mudung Laut</b> (data diperbarui otomatis, per <?= date('d-m-Y H:i') ?> WIB)</div>

<!-- ===================== Tabel 3.2 ===================== -->
<div class="rd-caption">
  <span class="rd-nomor">Tabel&nbsp;3.2</span>
  <span class="rd-judul">Jumlah Kepala Keluarga (KK) dan Bangunan menurut Rukun Tetangga di Kelurahan Mudung Laut, <?= $tahun ?></span><br>
  <span class="rd-judul-en">Number of Heads of Families and Buildings according to Neighborhood Association in Mudung Laut Subdistrict, <?= $tahun ?></span>
</div>
<div class="rd-toolbar no-print mb-2">
  <button type="button" class="btn btn-sm btn-outline-secondary" onclick="unduhTabelExcel('tabel32','Tabel_3.2_KK_dan_Bangunan_per_RT')"><i class="bi bi-file-earmark-excel"></i> Unduh Excel</button>
</div>
<div class="rd-table-wrap">
  <table class="rd-table" id="tabel32">
    <thead>
      <tr class="rd-head-main">
        <th rowspan="2">Rukun Tetangga<br><span class="rd-judul-en" style="font-size:.85rem">Neighborhood</span></th>
        <th rowspan="2">Kepala<br>Keluarga/<span class="rd-judul-en">Families</span></th>
        <th colspan="5">Bangunan/<span class="rd-judul-en">Buildings</span></th>
      </tr>
      <tr class="rd-head-sub">
        <th>Tempat<br>Tinggal</th>
        <th>Rumah<br>Ibadah</th>
        <th>Fas.<br>Pendidikan</th>
        <th>Fas.<br>Kesehatan</th>
        <th>Kosong</th>
      </tr>
      <tr class="rd-head-num"><th>(1)</th><th>(2)</th><th>(3)</th><th>(4)</th><th>(5)</th><th>(6)</th><th>(7)</th></tr>
    </thead>
    <tbody>
      <?php foreach ($t32 as $row): ?>
      <tr>
        <td>RT <?= e($row['nomor_rt']) ?></td>
        <td><?= number_format($row['jml_kk']) ?></td>
        <td><?= number_format($row['jml_bangunan_tinggal']) ?></td>
        <td><?= number_format($row['jml_bangunan_rumah_ibadah']) ?></td>
        <td><?= number_format($row['jml_bangunan_fasilitas_pendidikan']) ?></td>
        <td><?= number_format($row['jml_bangunan_fasilitas_kesehatan']) ?></td>
        <td><?= number_format($row['jml_bangunan_kosong']) ?></td>
      </tr>
      <?php endforeach; ?>
    </tbody>
    <tfoot>
      <tr>
        <td>Mudung Laut</td>
        <td><?= number_format($t32total['jml_kk']) ?></td>
        <td><?= number_format($t32total['jml_bangunan_tinggal']) ?></td>
        <td><?= number_format($t32total['jml_bangunan_rumah_ibadah']) ?></td>
        <td><?= number_format($t32total['jml_bangunan_fasilitas_pendidikan']) ?></td>
        <td><?= number_format($t32total['jml_bangunan_fasilitas_kesehatan']) ?></td>
        <td><?= number_format($t32total['jml_bangunan_kosong']) ?></td>
      </tr>
    </tfoot>
  </table>
</div>
<div class="rd-source">Sumber/<i>Source</i>: <b>Sistem SIKA Kelurahan Mudung Laut</b> (data diperbarui otomatis, per <?= date('d-m-Y H:i') ?> WIB)</div>

<!-- ===================== Tabel 3.3 ===================== -->
<div class="rd-caption">
  <span class="rd-nomor">Tabel&nbsp;3.3</span>
  <span class="rd-judul">Sex Ratio Penduduk menurut Rukun Tetangga di Kelurahan Mudung Laut, <?= $tahun ?></span><br>
  <span class="rd-judul-en">Sex Ratio of Population according to Neighborhood Association in Mudung Laut Subdistrict, <?= $tahun ?></span>
</div>
<div class="rd-toolbar no-print mb-2">
  <button type="button" class="btn btn-sm btn-outline-secondary" onclick="unduhTabelExcel('tabel33','Tabel_3.3_Sex_Ratio_per_RT')"><i class="bi bi-file-earmark-excel"></i> Unduh Excel</button>
</div>
<div class="rd-table-wrap">
  <table class="rd-table" id="tabel33">
    <thead>
      <tr class="rd-head-main">
        <th>Rukun Tetangga<br><span class="rd-judul-en" style="font-size:.85rem">Neighborhood</span></th>
        <th>Sex Ratio</th>
      </tr>
      <tr class="rd-head-num"><th>(1)</th><th>(2)</th></tr>
    </thead>
    <tbody>
      <?php foreach ($t33 as $row): ?>
      <tr>
        <td>RT <?= e($row['nomor_rt']) ?></td>
        <td><?= $row['sex_ratio'] === null ? '-' : number_format($row['sex_ratio'], 2) ?></td>
      </tr>
      <?php endforeach; ?>
    </tbody>
    <tfoot>
      <tr><td>Mudung Laut</td><td><?= number_format($t33total, 2) ?></td></tr>
    </tfoot>
  </table>
</div>
<div class="rd-source">Sumber/<i>Source</i>: <b>Sistem SIKA Kelurahan Mudung Laut</b> (data diperbarui otomatis, per <?= date('d-m-Y H:i') ?> WIB). Sex Ratio = (Jumlah Laki-laki &divide; Jumlah Perempuan) &times; 100.</div>

<!-- ===================== Tabel 3.4 ===================== -->
<div class="rd-caption">
  <span class="rd-nomor">Tabel&nbsp;3.4</span>
  <span class="rd-judul">Jumlah Keluarga Penerima Bantuan, Pemilik UMKM, dan Penyandang Disabilitas menurut Rukun Tetangga di Kelurahan Mudung Laut, <?= $tahun ?></span><br>
  <span class="rd-judul-en">Number of Families Receiving Government Aid, Owning MSMEs, and with Persons with Disabilities according to Neighborhood Association, <?= $tahun ?></span>
</div>
<div class="rd-toolbar no-print mb-2">
  <button type="button" class="btn btn-sm btn-outline-secondary" onclick="unduhTabelExcel('tabel34','Tabel_3.4_Bantuan_UMKM_Disabilitas_per_RT')"><i class="bi bi-file-earmark-excel"></i> Unduh Excel</button>
</div>
<div class="rd-table-wrap">
  <table class="rd-table" id="tabel34">
    <thead>
      <tr class="rd-head-main">
        <th rowspan="2">Rukun Tetangga<br><span class="rd-judul-en" style="font-size:.85rem">Neighborhood</span></th>
        <th rowspan="2">Keluarga<br>Penerima<br>Bantuan</th>
        <th rowspan="2">Keluarga<br>dengan<br>UMKM</th>
        <th colspan="2">Disabilitas</th>
      </tr>
      <tr class="rd-head-sub">
        <th>Jml. Keluarga</th>
        <th>Jml. Orang</th>
      </tr>
      <tr class="rd-head-num"><th>(1)</th><th>(2)</th><th>(3)</th><th>(4)</th><th>(5)</th></tr>
    </thead>
    <tbody>
      <?php foreach ($t34 as $row): ?>
      <tr>
        <td>RT <?= e($row['nomor_rt']) ?></td>
        <td><?= number_format($row['jml_bantuan']) ?></td>
        <td><?= number_format($row['jml_umkm']) ?></td>
        <td><?= number_format($row['jml_kk_disabilitas']) ?></td>
        <td><?= number_format($row['jml_orang_disabilitas']) ?></td>
      </tr>
      <?php endforeach; ?>
    </tbody>
    <tfoot>
      <tr>
        <td>Mudung Laut</td>
        <td><?= number_format($t34total['jml_bantuan']) ?></td>
        <td><?= number_format($t34total['jml_umkm']) ?></td>
        <td><?= number_format($t34total['jml_kk_disabilitas']) ?></td>
        <td><?= number_format($t34total['jml_orang_disabilitas']) ?></td>
      </tr>
    </tfoot>
  </table>
</div>
<div class="rd-source">Sumber/<i>Source</i>: <b>Sistem SIKA Kelurahan Mudung Laut</b> (data diperbarui otomatis, per <?= date('d-m-Y H:i') ?> WIB)</div>

<script src="assets/vendor/xlsx/xlsx.full.min.js"></script>
<script>
// Ubah tabel HTML jadi array-of-arrays (baris x kolom), gabungkan rowspan/colspan
// sederhana dengan mengulang nilai sel induk pada sel yang tergabung.
function tabelKeArray(tableId) {
  const table = document.getElementById(tableId);
  const rows = Array.from(table.querySelectorAll('thead tr, tbody tr, tfoot tr'));
  const grid = [];
  rows.forEach((tr, r) => { grid[r] = []; });

  rows.forEach((tr, r) => {
    let c = 0;
    Array.from(tr.children).forEach(cell => {
      while (grid[r][c] !== undefined) c++;
      const text = cell.innerText.trim().replace(/\s+/g, ' ');
      const rowspan = parseInt(cell.getAttribute('rowspan') || '1');
      const colspan = parseInt(cell.getAttribute('colspan') || '1');
      for (let i = 0; i < rowspan; i++) {
        for (let j = 0; j < colspan; j++) {
          if (!grid[r + i]) grid[r + i] = [];
          grid[r + i][c + j] = i === 0 && j === 0 ? text : (i === 0 ? '' : text);
        }
      }
      c += colspan;
    });
  });
  return grid.map(row => row.map(cell => cell === undefined ? '' : cell));
}

function unduhTabelExcel(tableId, namaFile) {
  const data = tabelKeArray(tableId);
  const ws = XLSX.utils.aoa_to_sheet(data);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Data');
  XLSX.writeFile(wb, namaFile + '.xlsx');
}
</script>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
