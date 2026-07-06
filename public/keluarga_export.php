<?php
require_once __DIR__ . '/../includes/config.php';
requireLogin();

$search = trim($_GET['q'] ?? '');
$rtFilter = $_GET['rt'] ?? '';
$bantuanFilter = $_GET['bantuan'] ?? '';
$umkmFilter = $_GET['umkm'] ?? '';

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

$sql = "SELECT k.*, r.nomor_rt FROM keluarga k JOIN rt r ON r.id=k.rt_id $where ORDER BY r.nomor_rt, k.nama_kepala_keluarga";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$data = $stmt->fetchAll();

$customFields = getCustomFields($pdo, 'keluarga');

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="data_keluarga_mudunglaut_' . date('Ymd_His') . '.csv"');

$out = fopen('php://output', 'w');
fwrite($out, chr(0xEF) . chr(0xBB) . chr(0xBF)); // BOM agar Excel membaca UTF-8 dengan benar

$headers = [
    'Nama Kepala Keluarga', 'Nomor KK', 'RT', 'Alamat',
    'Jumlah Laki-laki', 'Jumlah Perempuan', 'Jumlah Total Anggota',
    'NIK Kepala Keluarga', 'Jenis Kelamin KK', 'Tanggal Lahir KK', 'Agama KK',
    'Status Perkawinan KK', 'Pendidikan KK', 'Status Pekerjaan KK', 'Deskripsi Pekerjaan KK',
    'Pernah Terima Bantuan Pemerintah', 'Ada UMKM', 'Jumlah Anggota Pemilik UMKM',
    'Terakhir Diupdate',
];
foreach ($customFields as $cf) {
    $headers[] = $cf['field_label'] . ($cf['field_unit'] ? ' (' . $cf['field_unit'] . ')' : '');
}
fputcsv($out, $headers);

foreach ($data as $row) {
    $customValues = getCustomFieldValues($pdo, 'keluarga', $row['id']);
    $line = [
        $row['nama_kepala_keluarga'],
        $row['nomor_kk'],
        'RT ' . $row['nomor_rt'],
        $row['alamat'],
        $row['jumlah_lk'],
        $row['jumlah_pr'],
        $row['jumlah_total'],
        $row['nik_kepala_keluarga'],
        $row['jenis_kelamin_kepala_keluarga'],
        formatTanggal($row['tanggal_lahir_kepala_keluarga']),
        $row['agama_kepala_keluarga'],
        $row['status_perkawinan_kepala_keluarga'],
        $row['pendidikan_kepala_keluarga'],
        $row['status_pekerjaan_kepala_keluarga'],
        $row['pekerjaan_kepala_keluarga'],
        $row['pernah_bantuan'],
        $row['ada_umkm'],
        $row['jumlah_anggota_umkm'],
        formatTanggalWaktu($row['updated_at']),
    ];
    foreach ($customFields as $cf) $line[] = $customValues[$cf['field_key']] ?? '';
    fputcsv($out, $line);
}
fclose($out);
exit;
