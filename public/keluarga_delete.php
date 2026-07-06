<?php
require_once __DIR__ . '/../includes/config.php';
requireRole(['ketua_rt','operator_kelurahan','admin_kelurahan']);
$id = $_GET['id'] ?? 0;
$keluarga = getKeluargaOrFail($pdo, $id);

$pdo->prepare("DELETE cfv FROM custom_field_values cfv JOIN custom_fields cf ON cf.id=cfv.custom_field_id WHERE cf.target_table='keluarga' AND cfv.record_id = ?")->execute([$id]);
$pdo->prepare("DELETE FROM keluarga WHERE id = ?")->execute([$id]);

$_SESSION['flash_success'] = 'Data keluarga berhasil dihapus.';
header('Location: keluarga_list.php');
exit;
