<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

// Try both common paths for systemctl
$cmd = "sudo /usr/bin/systemctl";
if (!file_exists('/usr/bin/systemctl') && file_exists('/bin/systemctl')) {
    $cmd = "sudo /bin/systemctl";
}

if ($action === 'on') {
    exec("$cmd start mihomo 2>&1", $output, $return_var);
    echo json_encode([
        'success' => $return_var === 0,
        'message' => $return_var === 0 ? 'VPN Started' : implode(" ", $output)
    ]);
} elseif ($action === 'off') {
    exec("$cmd stop mihomo 2>&1", $output, $return_var);
    echo json_encode([
        'success' => $return_var === 0,
        'message' => $return_var === 0 ? 'VPN Stopped' : implode(" ", $output)
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Invalid action']);
}
?>
