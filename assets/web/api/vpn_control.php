<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'error' => 'POST required']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';



$group = 'VPN-Switch';
$api_url = "http://127.0.0.1:9090/proxies/" . rawurlencode($group);
$target = $action === 'on' ? 'GLOBAL' : 'DIRECT';

$ch = curl_init($api_url);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['name' => $target]));
curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo json_encode([
    'success' => $code === 204,
    'message' => $code === 204 ? 'VPN turned ' . ($action === 'on' ? 'ON' : 'OFF') : 'Failed'
]);
?>