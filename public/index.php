<?php
require_once __DIR__ . '/../includes/config.php';
header('Location: ' . (isLoggedIn() ? landingPageFor(currentUser()['role']) : 'login.php'));
exit;
