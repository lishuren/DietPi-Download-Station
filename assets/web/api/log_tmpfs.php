<?php
// log_tmpfs.php: Toggle /var/log to tmpfs (RAM) or restore to disk
header('Content-Type: application/json');

$action = $_POST['action'] ?? null;
if ($action === null) {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? '';
}

function run_cmd($cmd) {
    exec($cmd . ' 2>&1', $out, $code);
    return ["code" => $code, "output" => implode("\n", $out)];
}

if ($action === 'enable') {
    // Mount tmpfs to /var/log
    $out1 = run_cmd('sudo systemctl stop rsyslog');
    $out2 = run_cmd('sudo mount -t tmpfs -o size=50M tmpfs /var/log');
    $out3 = run_cmd('sudo systemctl start rsyslog');
    $success = ($out2['code'] === 0);
    echo json_encode([
        "success" => $success,
        "message" => $success ? "Logs moved to RAM (tmpfs)" : "Failed to mount tmpfs: " . $out2['output'],
        "details" => [$out1, $out2, $out3]
    ]);
    exit;
} elseif ($action === 'disable') {
    // Unmount tmpfs and restore /var/log to disk
    $out1 = run_cmd('sudo systemctl stop rsyslog');
    $out2 = run_cmd('sudo umount /var/log');
    $out3 = run_cmd('sudo systemctl start rsyslog');
    $success = ($out2['code'] === 0);
    echo json_encode([
        "success" => $success,
        "message" => $success ? "Logs restored to disk" : "Failed to unmount tmpfs: " . $out2['output'],
        "details" => [$out1, $out2, $out3]
    ]);
    exit;
} elseif ($action === 'status') {
    $mounts = file_get_contents('/proc/mounts');
    $is_tmpfs = strpos($mounts, '/var/log tmpfs') !== false;
    echo json_encode(["tmpfs" => $is_tmpfs]);
    exit;
}

echo json_encode(["success" => false, "message" => "Invalid action"]);
