<?php
// Handle subscription update - full overwrite with redirect support
$subMsg = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($_POST['update_url'])) {
    $url = trim($_POST['update_url']);
    if (filter_var($url, FILTER_VALIDATE_URL)) {
        $configPath = '/etc/mihomo/config.yaml';
        $cmd = "curl -L -s --fail-with-body " . escapeshellarg($url) . " -o " . escapeshellarg($configPath);
        exec($cmd, $output, $code);
        
        if ($code === 0 && filesize($configPath) > 500) {
            $content = file_get_contents($configPath);
            if (strpos($content, 'proxies:') !== false) {
                exec('sudo systemctl restart mihomo');
                $subMsg = '<div class="message success">Subscription updated & mihomo reloaded!</div>';
            } else {
                $subMsg = '<div class="message error">Downloaded file is not valid YAML.</div>';
            }
        } else {
            $subMsg = '<div class="message error">Failed to download subscription.</div>';
        }
    } else {
        $subMsg = '<div class="message error">Invalid URL.</div>';
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VPN Control</title>
    <style>
        :root {
            --bg: #0f172a;
            --card: #1e293b;
            --text: #e2e8f0;
            --muted: #94a3b8;
            --accent: #38bdf8;
            --on: #22c55e;
            --off: #f44336;
            --success: #166534;
            --error: #7f1d1d;
        }
        body { margin: 0; font-family: system-ui, sans-serif; background: var(--bg); color: var(--text); padding: 20px; }
        .container { max-width: 1000px; margin: 0 auto; }
        header { text-align: center; margin-bottom: 30px; position: relative; }
        h1 { font-size: 2.4rem; background: linear-gradient(90deg, #38bdf8, #818cf8); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        .back { position: absolute; left: 0; top: 50%; transform: translateY(-50%); padding: 10px 20px; background: var(--card); border-radius: 12px; color: var(--text); text-decoration: none; font-weight: 600; }
        .status { background: var(--card); padding: 24px; border-radius: 16px; margin-bottom: 30px; display: flex; justify-content: space-between; align-items: center; }
        .info { font-size: 1.2rem; line-height: 1.8; }
        .vpn-on { color: var(--on); font-weight: bold; }
        .vpn-off { color: var(--off); font-weight: bold; }
        .toggle { position: relative; width: 90px; height: 46px; }
        .toggle input { opacity: 0; width: 0; height: 0; }
        .slider { position: absolute; cursor: pointer; inset: 0; background: var(--off); border-radius: 46px; transition: 0.4s; }
        .slider:before { content: ""; position: absolute; width: 38px; height: 38px; left: 4px; bottom: 4px; background: white; border-radius: 50%; transition: 0.4s; }
        input:checked + .slider { background: var(--on); }
        input:checked + .slider:before { transform: translateX(44px); }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 30px; }
        @media (max-width: 900px) { .grid { grid-template-columns: 1fr; } }
        .card { background: var(--card); padding: 30px; border-radius: 16px; }
        .card h2 { margin: 0 0 20px; color: var(--accent); font-size: 1.6rem; }
        input[type="text"] { width: 100%; padding: 14px; border-radius: 12px; border: 1px solid #475569; background: #0f172a; color: var(--text); margin-bottom: 20px; }
        .btn { padding: 14px 28px; border: none; border-radius: 12px; cursor: pointer; font-weight: 600; margin-right: 12px; margin-bottom: 12px; }
        .btn-primary { background: var(--accent); color: #000; }
        .btn-secondary { background: #f59e0b; color: #000; }
        .message { padding: 16px; border-radius: 12px; margin: 20px 0; text-align: center; font-weight: 500; }
        .success { background: var(--success); color: #86efac; }
        .error { background: var(--error); color: #fca5a5; }
        .proxy-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(170px, 1fr)); gap: 16px; margin-top: 20px; }
        .proxy-card { background: #2d3748; padding: 20px; border-radius: 16px; text-align: center; cursor: pointer; transition: 0.3s; }
        .proxy-card:hover { transform: translateY(-8px); box-shadow: 0 16px 32px rgba(0,0,0,0.5); }
        .proxy-card.active { background: #134e1c; border: 2px solid var(--on); }
        .proxy-name { font-weight: bold; margin-bottom: 12px; font-size: 1.1rem; }
        .latency { margin-top: 12px; font-weight: bold; }
        .good { color: var(--on); }
        .fair { color: #f59e0b; }
        .poor { color: var(--off); }
        .traffic { margin-top: 30px; font-size: 1.4rem; text-align: center; color: var(--accent); font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="back">← Back to Portal</a>
        <header>
            <h1>VPN Control</h1>
        </header>

        <div class="status">
            <div class="info" id="statusInfo">Loading...</div>
            <label class="toggle">
                <input type="checkbox" id="vpnToggle" onchange="toggleVPN(this.checked)">
                <span class="slider"></span>
            </label>
        </div>

        <div class="grid">
            <div class="card">
                <h2>Subscription</h2>
                <form method="POST">
                    <input type="text" name="update_url" placeholder="Paste subscription URL" required>
                    <button type="submit" class="btn btn-primary">Update & Reload</button>
                </form>
                <?php echo $subMsg; ?>
                <div id="subInfo" style="margin-top:20px; line-height:1.8;"></div>
            </div>

            <div class="card">
                <h2>Proxy Manager</h2>
                <button onclick="testAllLatency()" class="btn btn-secondary">Test All Latency</button>
                <div id="nodeList" class="proxy-grid"></div>
                <div id="trafficInfo" class="traffic">↑ 0 B/s | ↓ 0 B/s</div>
            </div>
        </div>
    </div>

    <script>
        let proxyData = {};

        async function loadAll() {
            await fetchStatus();
            await fetchProxies();
        }

        async function fetchStatus() {
            try {
                const res = await fetch('api/clash.php?action=status');
                const data = await res.json();

                const isOn = data.vpn_on === true;
                document.getElementById('vpnToggle').checked = isOn;

                document.getElementById('statusInfo').innerHTML = `
                    <div><strong>VPN: ${isOn ? '<span class="vpn-on">ON</span>' : '<span class="vpn-off">OFF</span>'}</strong></div>
                    <div>Current: ${data.current_proxy || 'DIRECT'}</div>
                    <div>IP: ${data.proxy_ip || 'N/A'} (Proxy) | ${data.direct_ip || 'N/A'} (Direct)</div>
                `;

                let subHtml = '<em>No subscription data</em>';
                if (data.provider) {
                    const i = data.provider.info || {};
                    const used = (i.Upload || 0) + (i.Download || 0);
                    subHtml = `
                        Usage: ${formatBytes(used)} / ${formatBytes(i.Total || 0)}<br>
                        Expires: ${i.Expire ? new Date(i.Expire * 1000).toLocaleDateString() : 'N/A'}
                    `;
                }
                document.getElementById('subInfo').innerHTML = subHtml;
            } catch (e) {
                document.getElementById('statusInfo').innerHTML = '<span style="color:#fca5a5">Error loading status</span>';
            }
        }

        async function toggleVPN(checked) {
            const input = document.getElementById('vpnToggle');
            input.disabled = true;
            try {
                const res = await fetch('api/vpn_control.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action: checked ? 'on' : 'off' })
                });
                const data = await res.json();
                if (!data.success) {
                    alert(data.message || 'Failed');
                    input.checked = !checked;
                }
            } catch (e) {
                alert('Network error');
                input.checked = !checked;
            }
            input.disabled = false;
            fetchStatus();
        }

        async function fetchProxies() {
            try {
                const res = await fetch('api/clash.php?action=proxies');
                const data = await res.json();
                proxyData = data.proxies || {};

                renderNodes();
                startTrafficPoll();
            } catch (e) {
                document.getElementById('nodeList').innerHTML = '<div style="color:#fca5a5">Failed to load proxies</div>';
            }
        }

        function renderNodes() {
            const container = document.getElementById('nodeList');
            container.innerHTML = '';

            const globalGroup = proxyData['GLOBAL'];
            if (!globalGroup || !globalGroup.all || globalGroup.all.length === 0) {
                container.innerHTML = '<div style="color:#94a3b8">No proxies available</div>';
                return;
            }

            globalGroup.all.forEach(name => {
                const node = proxyData[name] || { type: 'Unknown' };
                const card = document.createElement('div');
                card.className = `proxy-card ${name === globalGroup.now ? 'active' : ''}`;
                card.onclick = () => selectProxy('GLOBAL', name);

                card.innerHTML = `
                    <div class="proxy-name">${name}</div>
                    <div style="color:#94a3b8">${node.type}</div>
                    <div class="latency" id="lat-${name.replace(/\s+/g, '_')}">— ms</div>
                `;
                container.appendChild(card);
            });
        }

        async function selectProxy(group, name) {
            try {
                await fetch(`api/clash.php?action=select&group=${encodeURIComponent(group)}&name=${encodeURIComponent(name)}`);
                fetchProxies();
                fetchStatus();
            } catch (e) {
                alert('Failed to switch proxy');
            }
        }

        async function testAllLatency() {
            const globalGroup = proxyData['GLOBAL'];
            if (!globalGroup) return;
            for (const name of globalGroup.all) {
                await testLatency(name);
                await new Promise(r => setTimeout(r, 100));
            }
        }

        async function testLatency(name) {
            const el = document.getElementById(`lat-${name.replace(/\s+/g, '_')}`);
            if (!el) return;
            el.textContent = '...';
            try {
                const res = await fetch(`api/clash.php?action=latency&name=${encodeURIComponent(name)}`);
                const data = await res.json();
                const delay = data.delay ?? 'Timeout';
                el.textContent = typeof delay === 'number' ? delay + ' ms' : delay;
                el.className = 'latency ' + (delay < 200 ? 'good' : delay < 500 ? 'fair' : 'poor');
            } catch (e) {
                el.textContent = 'Error';
            }
        }

        function startTrafficPoll() {
            setInterval(async () => {
                try {
                    const res = await fetch('api/clash.php?action=traffic');
                    const d = await res.json();
                    document.getElementById('trafficInfo').textContent = 
                        `↑ ${formatBytes(d.up || 0)}/s | ↓ ${formatBytes(d.down || 0)}/s`;
                } catch (e) {}
            }, 3000);
        }

        function formatBytes(b) {
            if (b === 0) return '0';
            const u = ['B', 'KB', 'MB', 'GB'];
            let i = 0;
            while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
            return b.toFixed(1) + ' ' + u[i];
        }

        loadAll();
        setInterval(fetchStatus, 15000);
    </script>
</body>
</html>