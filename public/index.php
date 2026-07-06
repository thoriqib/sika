<?php
require_once __DIR__ . '/../includes/config.php';
header('Location: ' . (isLoggedIn() ? 'dashboard.php' : 'login.php'));
exit;
