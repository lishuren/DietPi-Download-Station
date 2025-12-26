<?php
header('Content-Type: application/json');

function getDiskStats($path) {
    $total = @disk_total_space($path);
    $free = @disk_free_space($path);
    $used = ($total !== false && $free !== false) ? max($total - $free, 0) : null;
    return [
        'totalBytes' => $total !== false ? $total : 0,
        'freeBytes' => $free !== false ? $free : 0,
        'usedBytes' => $used !== null ? $used : 0
    ];
}

// Root Filesystem (TF Card)
$root = getDiskStats('/');

// USB Disk
$usbPath = '/mnt/usb_data';
$usb = getDiskStats($usbPath);

// Check if USB is actually mounted
$usb['mounted'] = false;
$proc = @file('/proc/mounts');
if ($proc) {
    foreach ($proc as $line) {
        $parts = preg_split('/\s+/', trim($line));
        if (isset($parts[1]) && $parts[1] === $usbPath) {
            $usb['mounted'] = true;
            $usb['fstype'] = $parts[2] ?? 'unknown';
            break;
        }
    }
}

echo json_encode([
    'root' => $root,
    'usb' => $usb
]);
?>
