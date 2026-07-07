<?php

function e($str) {
    return htmlspecialchars($str ?? '', ENT_QUOTES, 'UTF-8');
}

function isLoggedIn() {
    return isset($_SESSION['user']);
}

function requireLogin() {
    if (!isLoggedIn()) {
        header('Location: login.php');
        exit;
    }
}

function currentUser() {
    return $_SESSION['user'] ?? null;
}

function hasRole($roles) {
    if (!isLoggedIn()) return false;
    if (is_string($roles)) $roles = [$roles];
    return in_array($_SESSION['user']['role'], $roles, true);
}

function requireRole($roles) {
    requireLogin();
    if (!hasRole($roles)) {
        http_response_code(403);
        require __DIR__ . '/partials_header.php';
        echo '<div class="alert alert-danger">Anda tidak memiliki akses ke halaman ini.</div>';
        require __DIR__ . '/partials_footer.php';
        exit;
    }
}

function formatRupiah($angka) {
    return 'Rp ' . number_format((float)$angka, 0, ',', '.');
}

function formatTanggal($date) {
    if (!$date) return '-';
    $ts = strtotime($date);
    if (!$ts) return '-';
    return date('d-m-Y', $ts);
}

function formatTanggalWaktu($datetime) {
    if (!$datetime) return '-';
    $ts = strtotime($datetime);
    if (!$ts) return '-';
    return date('d-m-Y H:i', $ts);
}

function roleLabel($role) {
    $labels = [
        'admin_kelurahan'    => 'Admin Kelurahan',
        'operator_kelurahan' => 'Operator Kelurahan',
        'ketua_rt'           => 'Ketua RT',
    ];
    return $labels[$role] ?? $role;
}

// Ambil daftar variabel tambahan untuk target tertentu ('keluarga')
function getCustomFields(PDO $pdo, $target) {
    $stmt = $pdo->prepare("SELECT * FROM custom_fields WHERE target_table = ? ORDER BY urutan ASC, id ASC");
    $stmt->execute([$target]);
    return $stmt->fetchAll();
}

// Ambil isi variabel tambahan untuk sebuah record -> [field_key => value]
function getCustomFieldValues(PDO $pdo, $target, $recordId) {
    $sql = "SELECT cf.field_key, cfv.value
            FROM custom_field_values cfv
            JOIN custom_fields cf ON cf.id = cfv.custom_field_id
            WHERE cf.target_table = ? AND cfv.record_id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$target, $recordId]);
    $result = [];
    foreach ($stmt->fetchAll() as $row) {
        $result[$row['field_key']] = $row['value'];
    }
    return $result;
}

// Simpan/perbarui isi variabel tambahan untuk sebuah record
function saveCustomFieldValues(PDO $pdo, $target, $recordId, array $postData) {
    $fields = getCustomFields($pdo, $target);
    foreach ($fields as $field) {
        $key = $field['field_key'];
        $value = $postData[$key] ?? null;

        $check = $pdo->prepare("SELECT id FROM custom_field_values WHERE custom_field_id = ? AND record_id = ?");
        $check->execute([$field['id'], $recordId]);
        $existing = $check->fetch();

        if ($existing) {
            $upd = $pdo->prepare("UPDATE custom_field_values SET value = ? WHERE id = ?");
            $upd->execute([$value, $existing['id']]);
        } else {
            $ins = $pdo->prepare("INSERT INTO custom_field_values (custom_field_id, record_id, value) VALUES (?, ?, ?)");
            $ins->execute([$field['id'], $recordId, $value]);
        }
    }
}

// Tampilkan nilai variabel tambahan beserta satuannya (jika ada)
function formatCustomValue($value, $unit) {
    if ($value === null || $value === '') return '-';
    return e($value) . ($unit ? ' <span class="text-muted small">' . e($unit) . '</span>' : '');
}

// Tambahan filter SQL berdasarkan role (dipakai untuk query dengan alias tabel k)
function rtFilterClause() {
    $user = currentUser();
    if ($user && $user['role'] === 'ketua_rt') {
        return ' AND k.rt_id = ' . (int)$user['rt_id'];
    }
    return '';
}

// Ambil data keluarga berdasarkan ID, sekaligus memastikan user yang sedang
// login berhak mengakses (Ketua RT hanya boleh akses RT-nya sendiri)
function getKeluargaOrFail(PDO $pdo, $id) {
    $stmt = $pdo->prepare("SELECT k.*, r.nomor_rt FROM keluarga k JOIN rt r ON r.id = k.rt_id WHERE k.id = ?");
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if (!$row) {
        $_SESSION['flash_error'] = 'Data keluarga tidak ditemukan.';
        header('Location: keluarga_list.php');
        exit;
    }
    if (hasRole('ketua_rt') && (int)$row['rt_id'] !== (int)currentUser()['rt_id']) {
        $_SESSION['flash_error'] = 'Anda tidak memiliki akses ke data keluarga ini.';
        header('Location: keluarga_list.php');
        exit;
    }
    return $row;
}

// Daftar pilihan tetap yang dipakai di formulir Keluarga / Kepala Keluarga
function pilihanAgama() {
    return ['Islam','Kristen','Katolik','Hindu','Buddha','Khonghucu','Lainnya'];
}
function pilihanStatusKawin() {
    return ['Belum Kawin','Kawin','Cerai Hidup','Cerai Mati'];
}
// Badge Bootstrap untuk status keberadaan keluarga
function keberadaanKeluargaBadge($status) {
    if ($status === 'Pindah') {
        return '<span class="badge bg-warning text-dark">Pindah</span>';
    }
    return '<span class="badge bg-success">Ada</span>';
}

function pilihanPendidikan() {
    return ['Tidak/Belum Sekolah','SD','SMP','SMA/SMK','D1/D2/D3','S1','S2','S3'];
}
function pilihanStatusPekerjaan() {
    return [
        'Buruh harian lepas',
        'PNS/ASN/TNI/Polri',
        'Wirausaha',
        'Karyawan Swasta',
        'Pelajar/Mahasiswa',
        'Tidak Bekerja',
        'Lainnya',
    ];
}

// Status pekerjaan yang TIDAK memerlukan deskripsi pekerjaan tambahan
function statusPekerjaanTanpaDeskripsi() {
    return ['Pelajar/Mahasiswa', 'Tidak Bekerja'];
}

function butuhDeskripsiPekerjaan($statusPekerjaan) {
    return $statusPekerjaan !== '' && !in_array($statusPekerjaan, statusPekerjaanTanpaDeskripsi(), true);
}

// Sembunyikan sebagian digit NIK/Nomor KK untuk tampilan tabel/daftar.
// Hanya menampilkan $visible digit pertama, sisanya diganti bintang.
function maskDigits($value, $visible = 6) {
    $value = (string)($value ?? '');
    if ($value === '') return '-';
    $len = strlen($value);
    if ($len <= $visible) return $value;
    return substr($value, 0, $visible) . str_repeat('*', $len - $visible);
}

// Tanda wajib isi (dipakai di label formulir)
function requiredMark() {
    return ' <span class="text-danger">*</span>';
}

// ===================== Pembaca XLSX ringan (tanpa Composer) =====================
// File .xlsx sebenarnya adalah arsip ZIP berisi XML. Fungsi berikut membaca
// sheet pertama memakai ZipArchive + SimpleXML bawaan PHP, cukup untuk
// kebutuhan impor data sederhana tanpa perlu library tambahan.

function xlsxColLetterToIndex($letters) {
    $letters = strtoupper($letters);
    $index = 0;
    for ($i = 0; $i < strlen($letters); $i++) {
        $index = $index * 26 + (ord($letters[$i]) - ord('A') + 1);
    }
    return $index - 1; // 0-based
}

function readXlsxSimple($filePath, $sheetName = null) {
    if (!class_exists('ZipArchive')) {
        throw new Exception('Ekstensi PHP "zip" tidak aktif di server. Aktifkan extension=zip di php.ini untuk memakai fitur impor Excel.');
    }
    $zip = new ZipArchive();
    if ($zip->open($filePath) !== true) {
        throw new Exception('Gagal membuka file. Pastikan file berformat .xlsx yang valid.');
    }

    // Cari target sheet: jika $sheetName diberikan, cari berdasarkan nama sheet;
    // jika tidak ditemukan atau tidak diberikan, pakai sheet pertama dalam workbook.
    $sheetTarget = 'xl/worksheets/sheet1.xml';
    $workbookXmlContent = $zip->getFromName('xl/workbook.xml');
    $relsContent = $zip->getFromName('xl/_rels/workbook.xml.rels');
    if ($workbookXmlContent !== false && $relsContent !== false) {
        $wbXml = @simplexml_load_string($workbookXmlContent);
        $relsXml = @simplexml_load_string($relsContent);
        if ($wbXml && $relsXml && isset($wbXml->sheets->sheet)) {
            $chosenSheet = null;
            if ($sheetName !== null) {
                foreach ($wbXml->sheets->sheet as $sh) {
                    if ((string)$sh['name'] === $sheetName) { $chosenSheet = $sh; break; }
                }
            }
            if ($chosenSheet === null) $chosenSheet = $wbXml->sheets->sheet[0];

            $rId = (string)$chosenSheet->attributes('r', true)['id'];
            foreach ($relsXml->Relationship as $rel) {
                if ((string)$rel['Id'] === $rId) {
                    $target = ltrim((string)$rel['Target'], '/');
                    if (strpos($target, 'worksheets/') === 0) $target = 'xl/' . $target;
                    $sheetTarget = $target;
                    break;
                }
            }
        }
    }

    $sharedStrings = [];
    $ssContent = $zip->getFromName('xl/sharedStrings.xml');
    if ($ssContent !== false) {
        $ssXml = @simplexml_load_string($ssContent);
        if ($ssXml) {
            foreach ($ssXml->si as $si) {
                if (isset($si->t)) {
                    $sharedStrings[] = (string)$si->t;
                } else {
                    $text = '';
                    foreach ($si->r as $r) { $text .= (string)$r->t; }
                    $sharedStrings[] = $text;
                }
            }
        }
    }

    $sheetContent = $zip->getFromName($sheetTarget);
    $zip->close();
    if ($sheetContent === false) {
        throw new Exception('Data sheet tidak ditemukan dalam file Excel.');
    }

    $sheetXml = @simplexml_load_string($sheetContent);
    if (!$sheetXml) {
        throw new Exception('Gagal membaca struktur file Excel.');
    }

    $rows = [];
    foreach ($sheetXml->sheetData->row as $row) {
        $rowIndex = (int)$row['r'];
        $rowData = [];
        foreach ($row->c as $c) {
            $ref = (string)$c['r'];
            preg_match('/([A-Z]+)(\d+)/', $ref, $m);
            $colIndex = isset($m[1]) ? xlsxColLetterToIndex($m[1]) : count($rowData);

            $type = (string)$c['t'];
            $value = '';
            if (isset($c->v)) {
                $value = (string)$c->v;
                if ($type === 's') {
                    $value = $sharedStrings[(int)$value] ?? '';
                }
            } elseif (isset($c->is->t)) {
                $value = (string)$c->is->t;
            }
            $rowData[$colIndex] = trim($value);
        }
        $rows[$rowIndex] = $rowData;
    }
    return $rows; // [nomor_baris => [index_kolom => nilai]]
}

function xlsxCell($row, $index) {
    return isset($row[$index]) ? trim((string)$row[$index]) : '';
}

// ===================== Paginasi (dipakai bersama beberapa halaman daftar) =====================
function pilihanPerHalaman() {
    return [10, 25, 50, 100, 500];
}

// Hitung parameter paginasi dari query string ($_GET['page'], $_GET['per_page'])
function paginationParams($totalRows, $default = 25) {
    $allowed = pilihanPerHalaman();
    $perPage = (int)($_GET['per_page'] ?? $default);
    if (!in_array($perPage, $allowed, true)) $perPage = $default;

    $totalPages = max(1, (int)ceil($totalRows / $perPage));
    $page = (int)($_GET['page'] ?? 1);
    if ($page < 1) $page = 1;
    if ($page > $totalPages) $page = $totalPages;
    $offset = ($page - 1) * $perPage;

    return ['perPage' => $perPage, 'page' => $page, 'totalPages' => $totalPages, 'offset' => $offset, 'allowed' => $allowed];
}

// Render kontrol paginasi (info jumlah data + pilihan per-halaman + nomor halaman).
// $extraParams: parameter GET lain yang perlu dipertahankan (search, filter RT, dst),
// TANPA 'page'/'per_page' (akan ditambahkan otomatis oleh fungsi ini).
function renderPagination($totalRows, $pg, array $extraParams = []) {
    if ($totalRows === 0) return;
    $page = $pg['page']; $perPage = $pg['perPage']; $totalPages = $pg['totalPages']; $allowed = $pg['allowed'];

    $mkUrl = function ($p) use ($extraParams, $perPage) {
        $params = $extraParams;
        $params['page'] = $p;
        $params['per_page'] = $perPage;
        return '?' . http_build_query($params);
    };
    $shown = min($perPage, $totalRows - ($page - 1) * $perPage);
    $awal = ($page - 1) * $perPage + 1;
    $akhir = $awal + $shown - 1;
    ?>
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mt-3">
      <div class="text-muted small">
        Menampilkan <?= number_format($awal) ?>&ndash;<?= number_format($akhir) ?> dari <?= number_format($totalRows) ?> data
      </div>
      <div class="d-flex align-items-center gap-3 flex-wrap">
        <form method="get" class="d-flex align-items-center gap-2">
          <?php foreach ($extraParams as $k => $v): if ($v === '' || $v === null) continue; ?>
            <input type="hidden" name="<?= e($k) ?>" value="<?= e($v) ?>">
          <?php endforeach; ?>
          <label class="text-muted small mb-0">Tampilkan</label>
          <select name="per_page" class="form-select form-select-sm" style="width:auto" onchange="this.form.submit()">
            <?php foreach ($allowed as $opt): ?>
              <option value="<?= $opt ?>" <?= $perPage == $opt ? 'selected' : '' ?>><?= $opt ?></option>
            <?php endforeach; ?>
          </select>
          <span class="text-muted small">/ halaman</span>
        </form>
        <?php if ($totalPages > 1): ?>
        <nav aria-label="Navigasi halaman">
          <ul class="pagination pagination-sm mb-0 flex-wrap">
            <li class="page-item <?= $page <= 1 ? 'disabled' : '' ?>"><a class="page-link" href="<?= $mkUrl(max(1, $page - 1)) ?>">&laquo;</a></li>
            <?php
            $start = max(1, $page - 2);
            $end = min($totalPages, $page + 2);
            if ($start > 1): ?>
              <li class="page-item"><a class="page-link" href="<?= $mkUrl(1) ?>">1</a></li>
              <?php if ($start > 2): ?><li class="page-item disabled"><span class="page-link">&hellip;</span></li><?php endif; ?>
            <?php endif;
            for ($p = $start; $p <= $end; $p++): ?>
              <li class="page-item <?= $p == $page ? 'active' : '' ?>"><a class="page-link" href="<?= $mkUrl($p) ?>"><?= $p ?></a></li>
            <?php endfor;
            if ($end < $totalPages): ?>
              <?php if ($end < $totalPages - 1): ?><li class="page-item disabled"><span class="page-link">&hellip;</span></li><?php endif; ?>
              <li class="page-item"><a class="page-link" href="<?= $mkUrl($totalPages) ?>"><?= $totalPages ?></a></li>
            <?php endif; ?>
            <li class="page-item <?= $page >= $totalPages ? 'disabled' : '' ?>"><a class="page-link" href="<?= $mkUrl(min($totalPages, $page + 1)) ?>">&raquo;</a></li>
          </ul>
        </nav>
        <?php endif; ?>
      </div>
    </div>
    <?php
}
