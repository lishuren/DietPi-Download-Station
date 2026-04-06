<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

// Run vpn-toggle shell script (manages iptables TPROXY + Mihomo mode)
// vpn-toggle is deployed to /usr/local/bin/vpn-toggle with sudo access
function run_vpn_toggle($cmd) {
    $allowed = ['on', 'off', 'status'];
    if (!in_array($cmd, $allowed, true)) {
        return ['success' => false, 'message' => 'Invalid command'];
    }
    $output = [];
    $rc = 0;
    exec('sudo /usr/local/bin/vpn-toggle ' . escapeshellarg($cmd) . ' 2>&1', $output, $rc);
    $msg = implode("\n", $output);
    return ['success' => $rc === 0, 'message' => $msg ?: ($rc === 0 ? 'OK' : 'Failed')];
}

if ($action === 'on') {
    $result = run_vpn_toggle('on');
    echo json_encode($result);
} elseif ($action === 'off') {
    $result = run_vpn_toggle('off');
    echo json_encode($result);
} elseif ($action === 'status') {
    $result = run_vpn_toggle('status');
    echo json_encode($result);
} else {
    echo json_encode(['success' => false, 'error' => 'Invalid action']);
}
?>