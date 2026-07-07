<?php
require_once __DIR__ . '/../includes/config.php';
// Halaman ini SENGAJA tidak memanggil requireLogin() — dapat diakses publik.
// SEMUA query di halaman ini HANYA boleh berupa agregat (COUNT/SUM/GROUP BY).
// DILARANG menampilkan nama, NIK, nomor KK, atau alamat individu di halaman ini.
$pageTitle = 'Dashboard Publik';

$rtList = $pdo->query("SELECT * FROM rt ORDER BY nomor_rt")->fetchAll();

$bangunanTotal = $pdo->query("SELECT
    COALESCE(SUM(jml_bangunan_tinggal_terisi),0) terisi,
    COALESCE(SUM(jml_bangunan_tinggal_kosong),0) kosong,
    COALESCE(SUM(jml_bangunan_khusus_usaha),0) usaha,
    COALESCE(SUM(jml_bangunan_bukan_tinggal_non_usaha),0) non_usaha
    FROM rt")->fetch();

// ===================== Ringkasan Umum =====================
$totalKeluarga = (int)$pdo->query("SELECT COUNT(*) c FROM keluarga WHERE status_keberadaan='Ada'")->fetch()['c'];
$totalLk = (int)$pdo->query("SELECT COALESCE(SUM(jumlah_lk),0) c FROM keluarga WHERE status_keberadaan='Ada'")->fetch()['c'];
$totalPr = (int)$pdo->query("SELECT COALESCE(SUM(jumlah_pr),0) c FROM keluarga WHERE status_keberadaan='Ada'")->fetch()['c'];
$totalPenduduk = $totalLk + $totalPr;
$rataAnggota = $totalKeluarga > 0 ? round($totalPenduduk / $totalKeluarga, 1) : 0;
$rasioJk = $totalPr > 0 ? round($totalLk / $totalPr * 100, 1) : 0;

$totalBantuan = (int)$pdo->query("SELECT COUNT(*) c FROM keluarga WHERE pernah_bantuan='Ya' AND status_keberadaan='Ada'")->fetch()['c'];
$totalUmkm = (int)$pdo->query("SELECT COUNT(*) c FROM keluarga WHERE ada_umkm='Ya' AND status_keberadaan='Ada'")->fetch()['c'];
$totalDisabilitasKk = (int)$pdo->query("SELECT COUNT(*) c FROM keluarga WHERE ada_disabilitas='Ya' AND status_keberadaan='Ada'")->fetch()['c'];
$totalDisabilitasOrang = (int)$pdo->query("SELECT COALESCE(SUM(jumlah_disabilitas),0) c FROM keluarga WHERE ada_disabilitas='Ya' AND status_keberadaan='Ada'")->fetch()['c'];
$persenBantuan = $totalKeluarga > 0 ? round($totalBantuan / $totalKeluarga * 100, 1) : 0;
$persenUmkm = $totalKeluarga > 0 ? round($totalUmkm / $totalKeluarga * 100, 1) : 0;

// ===================== Data per RT (agregat) =====================
$perRt = $pdo->query("
    SELECT r.id, r.nomor_rt, COUNT(k.id) jml_keluarga,
           COALESCE(SUM(k.jumlah_total),0) jml_penduduk,
           COALESCE(SUM(CASE WHEN k.pernah_bantuan='Ya' THEN 1 ELSE 0 END),0) jml_bantuan,
           COALESCE(SUM(CASE WHEN k.ada_umkm='Ya' THEN 1 ELSE 0 END),0) jml_umkm,
           r.jml_bangunan_tinggal_terisi, r.jml_bangunan_tinggal_kosong,
           r.jml_bangunan_khusus_usaha, r.jml_bangunan_bukan_tinggal_non_usaha
    FROM rt r LEFT JOIN keluarga k ON k.rt_id = r.id AND k.status_keberadaan = 'Ada'
    GROUP BY r.id ORDER BY r.nomor_rt
")->fetchAll();

$mapPoints = [];
foreach ($perRt as $r) {
    $persenBantuanRt = $r['jml_keluarga'] > 0 ? round($r['jml_bantuan'] / $r['jml_keluarga'] * 100, 1) : 0;
    $persenUmkmRt = $r['jml_keluarga'] > 0 ? round($r['jml_umkm'] / $r['jml_keluarga'] * 100, 1) : 0;
    $mapPoints[] = [
        'rt' => $r['nomor_rt'], 'keluarga' => (int)$r['jml_keluarga'], 'penduduk' => (int)$r['jml_penduduk'],
        'persen_bantuan' => $persenBantuanRt, 'persen_umkm' => $persenUmkmRt,
        'bangunan_terisi' => (int)$r['jml_bangunan_tinggal_terisi'], 'bangunan_kosong' => (int)$r['jml_bangunan_tinggal_kosong'],
        'bangunan_usaha' => (int)$r['jml_bangunan_khusus_usaha'], 'bangunan_non_usaha' => (int)$r['jml_bangunan_bukan_tinggal_non_usaha'],
        'ada_data' => (int)$r['jml_keluarga'] > 0,
    ];
}

// ===================== Kelompok Usia Kepala Keluarga (agregat) =====================
$ageRows = $pdo->query("
    SELECT
      CASE
        WHEN TIMESTAMPDIFF(YEAR, tanggal_lahir_kepala_keluarga, CURDATE()) < 30 THEN '0'
        WHEN TIMESTAMPDIFF(YEAR, tanggal_lahir_kepala_keluarga, CURDATE()) < 40 THEN '1'
        WHEN TIMESTAMPDIFF(YEAR, tanggal_lahir_kepala_keluarga, CURDATE()) < 50 THEN '2'
        WHEN TIMESTAMPDIFF(YEAR, tanggal_lahir_kepala_keluarga, CURDATE()) < 60 THEN '3'
        ELSE '4'
      END AS grp,
      jenis_kelamin_kepala_keluarga AS jk, COUNT(*) jml
    FROM keluarga WHERE status_keberadaan = 'Ada'
    GROUP BY grp, jk
")->fetchAll();
$ageLabels = ['< 30 Tahun','30-39 Tahun','40-49 Tahun','50-59 Tahun','60+ Tahun'];
$ageLk = array_fill(0, 5, 0); $agePr = array_fill(0, 5, 0);
foreach ($ageRows as $ar) {
    $idx = (int)$ar['grp'];
    if ($ar['jk'] === 'Laki-laki') $ageLk[$idx] = (int)$ar['jml']; else $agePr[$idx] = (int)$ar['jml'];
}

function distribusiKk(PDO $pdo, $kolom) {
    $stmt = $pdo->query("SELECT $kolom AS k, COUNT(*) jml FROM keluarga WHERE $kolom IS NOT NULL AND $kolom <> '' AND status_keberadaan = 'Ada' GROUP BY $kolom ORDER BY jml DESC");
    $out = [];
    foreach ($stmt->fetchAll() as $row) { $out[$row['k']] = (int)$row['jml']; }
    return $out;
}
$distPendidikan = distribusiKk($pdo, 'pendidikan_kepala_keluarga');
$distPekerjaan = distribusiKk($pdo, 'status_pekerjaan_kepala_keluarga');
$distAgama = distribusiKk($pdo, 'agama_kepala_keluarga');
$distKawin = distribusiKk($pdo, 'status_perkawinan_kepala_keluarga');

require __DIR__ . '/../includes/partials_header.php';
?>
<link rel="stylesheet" href="assets/leaflet/leaflet.css"/>
<style>
  .pub-hero { background: linear-gradient(120deg, var(--teal-dark), var(--teal)); color: #fff; border-radius: 16px; padding: 2rem; margin-bottom: 1.5rem; }
  .pub-kpi { border-radius: 14px; }
  .pub-section-title { font-weight: 700; color: var(--teal-dark); border-left: 4px solid var(--teal); padding-left: .6rem; margin: 2rem 0 1rem; }
  #petaRt { height: 420px; border-radius: 12px; }
  .legend-box { background: #fff; padding: 8px 12px; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,.2); font-size: .8rem; }
  .rt-tooltip-label { background: transparent; border: none; box-shadow: none; font-weight: 700; color: #0f5e56; text-shadow: -1px 0 #fff, 0 1px #fff, 1px 0 #fff, 0 -1px #fff; }
</style>

<div class="pub-hero">
  <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
    <div>
      <h2 class="fw-bold mb-1"><i class="bi bi-bar-chart-line-fill"></i> Dashboard Data Terbuka</h2>
      <div class="fs-5">Kelurahan Mudung Laut, Kecamatan Pelayangan, Kota Jambi</div>
      <div class="small opacity-75 mt-1">Data agregat kependudukan &amp; kesejahteraan warga — diperbarui otomatis setiap kali halaman dibuka (<?= date('d-m-Y H:i') ?> WIB)</div>
    </div>
    <a href="login.php" class="btn btn-light btn-sm"><i class="bi bi-box-arrow-in-right"></i> Masuk sebagai Petugas</a>
  </div>
</div>

<div class="alert alert-light border small">
  <i class="bi bi-shield-check text-teal"></i>
  Seluruh data pada halaman ini disajikan dalam bentuk <strong>rekap/agregat</strong> (jumlah &amp; persentase).
  Sesuai prinsip perlindungan data pribadi, halaman publik ini <strong>tidak menampilkan nama, NIK, nomor KK,
  maupun alamat perorangan</strong>.
</div>

<!-- ===================== KPI Utama ===================== -->
<div class="row g-3 mb-2">
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Jumlah Keluarga</div>
      <div class="fs-3 fw-bold text-teal"><?= number_format($totalKeluarga) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Jumlah Penduduk</div>
      <div class="fs-3 fw-bold text-teal"><?= number_format($totalPenduduk) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Rata-rata Jiwa / Keluarga</div>
      <div class="fs-3 fw-bold text-teal"><?= $rataAnggota ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Rasio Jenis Kelamin</div>
      <div class="fs-3 fw-bold text-teal"><?= $rasioJk ?></div>
      <div class="text-muted small">L per 100 P</div>
    </div></div>
  </div>
</div>

<div class="row g-3 mb-2">
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100" style="border-left:4px solid #14867a"><div class="card-body">
      <div class="text-muted small">Keluarga Pernah Terima Bantuan</div>
      <div class="fs-4 fw-bold text-teal"><?= number_format($totalBantuan) ?> <span class="fs-6 fw-normal text-muted">(<?= $persenBantuan ?>%)</span></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100" style="border-left:4px solid #fd7e14"><div class="card-body">
      <div class="text-muted small">Keluarga dengan UMKM</div>
      <div class="fs-4 fw-bold" style="color:#fd7e14"><?= number_format($totalUmkm) ?> <span class="fs-6 fw-normal text-muted">(<?= $persenUmkm ?>%)</span></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100" style="border-left:4px solid #6610f2"><div class="card-body">
      <div class="text-muted small">Penyandang Disabilitas</div>
      <div class="fs-4 fw-bold" style="color:#6610f2"><?= number_format($totalDisabilitasOrang) ?> <span class="fs-6 fw-normal text-muted">orang</span></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100" style="border-left:4px solid #6c757d"><div class="card-body">
      <div class="text-muted small">Jumlah RT</div>
      <div class="fs-4 fw-bold"><?= count($rtList) ?></div>
    </div></div>
  </div>
</div>

<div class="pub-section-title"><i class="bi bi-building"></i> Data Bangunan</div>
<div class="row g-3 mb-2">
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Tempat Tinggal Terisi</div>
      <div class="fs-4 fw-bold text-teal"><?= number_format($bangunanTotal['terisi']) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Bangunan Kosong</div>
      <div class="fs-4 fw-bold text-secondary"><?= number_format($bangunanTotal['kosong']) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Khusus Usaha</div>
      <div class="fs-4 fw-bold" style="color:#fd7e14"><?= number_format($bangunanTotal['usaha']) ?></div>
    </div></div>
  </div>
  <div class="col-6 col-md-3">
    <div class="card pub-kpi border-0 shadow-sm h-100"><div class="card-body">
      <div class="text-muted small">Bukan Tinggal, Non Usaha</div>
      <div class="fs-4 fw-bold text-muted"><?= number_format($bangunanTotal['non_usaha']) ?></div>
    </div></div>
  </div>
</div>

<!-- ===================== Peta Tematik ===================== -->
<div class="pub-section-title"><i class="bi bi-geo-alt-fill"></i> Peta Sebaran per RT</div>
<div class="card border-0 shadow-sm mb-2">
  <div class="card-body p-2">
    <div id="petaRt"></div>
  </div>
</div>
<div class="alert alert-light border small">
  <i class="bi bi-info-circle text-teal"></i>
  Batas wilayah RT pada peta bersumber dari data Satuan Lingkungan Setempat (SLS) resmi.
  Warna menunjukkan persentase keluarga yang pernah menerima bantuan pemerintah; wilayah
  non-permukiman (hutan/semak belukar) ditampilkan netral tanpa data statistik.
</div>

<!-- ===================== Grafik per RT ===================== -->
<div class="pub-section-title"><i class="bi bi-houses-fill"></i> Data per RT</div>
<div class="row g-3 mb-2">
  <div class="col-md-4">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <h6 class="text-muted">Jumlah Keluarga per RT</h6>
      <canvas id="chartKeluargaRt" height="220"></canvas>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <h6 class="text-muted">% Keluarga Pernah Terima Bantuan per RT</h6>
      <canvas id="chartBantuanRt" height="220"></canvas>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <h6 class="text-muted">% Keluarga dengan UMKM per RT</h6>
      <canvas id="chartUmkmRt" height="220"></canvas>
    </div></div>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-12">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <h6 class="text-muted">Data Bangunan per RT</h6>
      <canvas id="chartBangunanRt" height="200"></canvas>
    </div></div>
  </div>
</div>

<!-- ===================== Profil Kepala Keluarga ===================== -->
<div class="pub-section-title"><i class="bi bi-person-badge"></i> Profil Kepala Keluarga</div>
<div class="row g-3 mb-2">
  <div class="col-md-7">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <h6 class="text-muted">Kelompok Usia Kepala Keluarga menurut Jenis Kelamin</h6>
      <canvas id="chartUsiaKk" height="260"></canvas>
    </div></div>
  </div>
  <div class="col-md-5">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <h6 class="text-muted">Status Perkawinan</h6>
      <canvas id="chartKawin" height="260"></canvas>
    </div></div>
  </div>
</div>

<div class="row g-3 mb-2">
  <div class="col-md-6">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <h6 class="text-muted">Tingkat Pendidikan Terakhir</h6>
      <canvas id="chartPendidikan" height="240"></canvas>
    </div></div>
  </div>
  <div class="col-md-6">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <h6 class="text-muted">Status Pekerjaan</h6>
      <canvas id="chartPekerjaan" height="240"></canvas>
    </div></div>
  </div>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card border-0 shadow-sm h-100"><div class="card-body">
      <h6 class="text-muted">Komposisi Agama</h6>
      <canvas id="chartAgama" height="220"></canvas>
    </div></div>
  </div>
</div>

<footer class="text-center text-muted small py-4 border-top">
  Data bersumber dari Sistem SIKA (Sistem Informasi Keluarga) Kelurahan Mudung Laut &bull;
  Ditampilkan dalam bentuk agregat untuk menjaga privasi data warga &bull;
  <a href="login.php">Masuk sebagai petugas &raquo;</a>
</footer>

<script src="assets/leaflet/leaflet.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
<script>
const TEAL = '#14867a';
const TEAL_DARK = '#0f5e56';
const ORANGE = '#fd7e14';
const PALETTE = ['#14867a','#0f5e56','#5aa89c','#fd7e14','#dc3545','#6c757d','#ffc107','#20c997','#6610f2','#e83e8c'];

// ---------- Peta Tematik (choropleth berbasis batas wilayah RT resmi) ----------
const rtStats = {};
<?php foreach ($mapPoints as $p): ?>
rtStats[<?= json_encode($p['rt']) ?>] = <?= json_encode($p) ?>;
<?php endforeach; ?>

const map = L.map('petaRt').setView([-1.567, 103.613], 14);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; OpenStreetMap contributors',
  maxZoom: 19,
}).addTo(map);

const maxPersen = Math.max(1, ...Object.values(rtStats).map(s => s.persen_bantuan));

function colorForPersen(p) {
  const t = maxPersen > 0 ? p / maxPersen : 0;
  const r = Math.round(255 * Math.min(1, 0.3 + t * 0.4));
  const g = Math.round(100 + 100 * (1 - t));
  const b = Math.round(120 * (1 - t)) + 40;
  return `rgb(${r},${g},${b})`;
}

function extractRtNumber(nmsls) {
  const m = /RT\s*0*(\d+)/i.exec(nmsls || '');
  if (!m) return null;
  return m[1].padStart(3, '0');
}

fetch('assets/mudunglaut_rt.geojson')
  .then(res => res.json())
  .then(geo => {
    const layer = L.geoJSON(geo, {
      style: feature => {
        const rtNum = extractRtNumber(feature.properties.nmsls);
        if (!rtNum) {
          return { color: '#8a9a8a', weight: 1, fillColor: '#d9e4d9', fillOpacity: 0.5 };
        }
        const stat = rtStats[rtNum];
        if (!stat || !stat.ada_data) {
          return { color: '#ffffff', weight: 2, fillColor: '#cfd4d6', fillOpacity: 0.7 };
        }
        return { color: '#ffffff', weight: 2, fillColor: colorForPersen(stat.persen_bantuan), fillOpacity: 0.82 };
      },
      onEachFeature: (feature, lyr) => {
        const rtNum = extractRtNumber(feature.properties.nmsls);
        if (!rtNum) {
          lyr.bindPopup(`<strong>${feature.properties.nmsls || 'Wilayah non-permukiman'}</strong><br>Bukan wilayah RT (tidak termasuk statistik).`);
          return;
        }
        const stat = rtStats[rtNum];
        if (!stat || !stat.ada_data) {
          lyr.bindPopup(`<strong>RT ${rtNum}</strong><br>Belum ada data keluarga tercatat di sistem.`);
        } else {
          lyr.bindPopup(
            `<strong>RT ${rtNum}</strong><br>` +
            `Jumlah Keluarga: ${stat.keluarga.toLocaleString('id-ID')}<br>` +
            `Jumlah Penduduk: ${stat.penduduk.toLocaleString('id-ID')}<br>` +
            `Pernah Terima Bantuan: ${stat.persen_bantuan}%<br>` +
            `Ada UMKM: ${stat.persen_umkm}%`
          );
          lyr.bindTooltip(`RT ${rtNum}`, { permanent: true, direction: 'center', className: 'rt-tooltip-label' });
        }
      },
    }).addTo(map);
    map.fitBounds(layer.getBounds());
  })
  .catch(() => {
    document.getElementById('petaRt').innerHTML = '<div class="p-4 text-center text-muted">Gagal memuat data batas wilayah RT.</div>';
  });

const legend = L.control({ position: 'bottomright' });
legend.onAdd = function () {
  const div = L.DomUtil.create('div', 'legend-box');
  div.innerHTML = 'Warna = % keluarga pernah terima bantuan pemerintah<br>' +
    '<span style="display:inline-block;width:10px;height:10px;background:rgb(107,220,160);"></span> Rendah &nbsp;' +
    '<span style="display:inline-block;width:10px;height:10px;background:rgb(178,140,40);"></span> Tinggi &nbsp;' +
    '<span style="display:inline-block;width:10px;height:10px;background:#cfd4d6;"></span> Belum ada data';
  return div;
};
legend.addTo(map);

// ---------- Chart per RT ----------
const chartRtData = <?= json_encode($mapPoints) ?>;
new Chart(document.getElementById('chartKeluargaRt'), {
  type: 'bar',
  data: { labels: chartRtData.map(p => 'RT ' + p.rt), datasets: [{ label: 'Jumlah Keluarga', data: chartRtData.map(p => p.keluarga), backgroundColor: TEAL }] },
  options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } },
});
new Chart(document.getElementById('chartBantuanRt'), {
  type: 'bar',
  data: { labels: chartRtData.map(p => 'RT ' + p.rt), datasets: [{ label: '% Bantuan', data: chartRtData.map(p => p.persen_bantuan), backgroundColor: TEAL_DARK }] },
  options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { callback: v => v + '%' } } } },
});
new Chart(document.getElementById('chartUmkmRt'), {
  type: 'bar',
  data: { labels: chartRtData.map(p => 'RT ' + p.rt), datasets: [{ label: '% UMKM', data: chartRtData.map(p => p.persen_umkm), backgroundColor: ORANGE }] },
  options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { callback: v => v + '%' } } } },
});

new Chart(document.getElementById('chartBangunanRt'), {
  type: 'bar',
  data: {
    labels: chartRtData.map(p => 'RT ' + p.rt),
    datasets: [
      { label: 'Tinggal Terisi', data: chartRtData.map(p => p.bangunan_terisi), backgroundColor: TEAL },
      { label: 'Bangunan Kosong', data: chartRtData.map(p => p.bangunan_kosong), backgroundColor: '#adb5bd' },
      { label: 'Khusus Usaha', data: chartRtData.map(p => p.bangunan_usaha), backgroundColor: ORANGE },
      { label: 'Bukan Tinggal, Non Usaha', data: chartRtData.map(p => p.bangunan_non_usaha), backgroundColor: '#6610f2' },
    ],
  },
  options: { scales: { x: { stacked: true }, y: { stacked: true, beginAtZero: true } } },
});

// ---------- Chart: Kelompok Usia Kepala Keluarga ----------
new Chart(document.getElementById('chartUsiaKk'), {
  type: 'bar',
  data: {
    labels: <?= json_encode($ageLabels) ?>,
    datasets: [
      { label: 'Laki-laki', data: <?= json_encode($ageLk) ?>, backgroundColor: TEAL },
      { label: 'Perempuan', data: <?= json_encode($agePr) ?>, backgroundColor: '#e8879b' },
    ],
  },
  options: { scales: { x: { stacked: false }, y: { beginAtZero: true } } },
});

// ---------- Chart generik donut/bar ----------
function buatDonut(id, labelData) {
  new Chart(document.getElementById(id), {
    type: 'doughnut',
    data: { labels: Object.keys(labelData), datasets: [{ data: Object.values(labelData), backgroundColor: PALETTE }] },
    options: { plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 10 } } } } },
  });
}
function buatBarH(id, labelData, color) {
  new Chart(document.getElementById(id), {
    type: 'bar',
    data: { labels: Object.keys(labelData), datasets: [{ data: Object.values(labelData), backgroundColor: color || TEAL }] },
    options: { indexAxis: 'y', plugins: { legend: { display: false } }, scales: { x: { beginAtZero: true } } },
  });
}

buatDonut('chartKawin', <?= json_encode($distKawin) ?>);
buatBarH('chartPendidikan', <?= json_encode($distPendidikan) ?>);
buatBarH('chartPekerjaan', <?= json_encode($distPekerjaan) ?>, '#0f5e56');
buatDonut('chartAgama', <?= json_encode($distAgama) ?>);
</script>
<?php require __DIR__ . '/../includes/partials_footer.php'; ?>
