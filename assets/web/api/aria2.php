<?php
header('Content-Type: application/json');

/**
 * Aria2 RPC Status API
 * Fetches download statistics from Aria2 RPC interface
 */

$rpc_host = '127.0.0.1';
$rpc_port = 6800;

$result = [
    'global' => [
        'downloadSpeed' => 0,
        'uploadSpeed' => 0,
        'numActive' => 0,
        'numWaiting' => 0
    ]
];

try {
    $url = "http://{$rpc_host}:{$rpc_port}/jsonrpc";
    $payload = json_encode([
        'jsonrpc' => '2.0',
        'method' => 'aria2.getGlobalStat',
        'id' => 1
    ]);

    // Use stream context for HTTP request
    $opts = [
        'http' => [
            'method'  => 'POST',
            'header'  => 'Content-type: application/json',
            'content' => $payload,
            'timeout' => 2
        ]
    ];
    $context = stream_context_create($opts);
    $response = @file_get_contents($url, false, $context);

    if ($response) {
        $data = json_decode($response, true);
        if (isset($data['result'])) {
            $result['global'] = [
                'downloadSpeed' => intval($data['result']['downloadSpeed'] ?? 0),
                'uploadSpeed' => intval($data['result']['uploadSpeed'] ?? 0),
                'numActive' => intval($data['result']['numActive'] ?? 0),
                'numWaiting' => intval($data['result']['numWaiting'] ?? 0),
                'numStopped' => intval($data['result']['numStopped'] ?? 0)
            ];
        }
    }
} catch (Exception $e) {
    // Return default empty stats on error
}

echo json_encode($result);
?>
