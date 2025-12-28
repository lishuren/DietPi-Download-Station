<?php
// system_update.php: Run apt update/upgrade and show version before/after
header('Content-Type: application/json');

function run_cmd($cmd) {
    exec($cmd . ' 2>&1', $out, $code);
    return ["code" => $code, "output" => implode("\n", $out)];
}


$action = $_POST['action'] ?? null;
if ($action === null) {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? '';
}

if ($action === 'version') {
    $ver = run_cmd('lsb_release -a || cat /etc/os-release');
    echo json_encode(["version" => $ver['output']]);
    exit;
}
if ($action === 'update') {
    $before = run_cmd('lsb_release -a || cat /etc/os-release');
    $update = run_cmd('sudo apt update && sudo apt upgrade -y');
    $after = run_cmd('lsb_release -a || cat /etc/os-release');
    echo json_encode([
        "success" => $update['code'] === 0,
        "before" => $before['output'],
        "after" => $after['output'],
        "output" => $update['output']
    ]);
    exit;
}
echo json_encode(["success" => false, "message" => "Invalid action"]);
