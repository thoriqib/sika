<?php
require_once __DIR__ . '/../includes/config.php';
if (isLoggedIn()) {
    clearRememberCookie($pdo, currentUser()['id']);
}
$_SESSION = [];
session_destroy();
header('Location: login.php');
exit;
