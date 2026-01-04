{ config, pkgs, lib, ... }:

let
  port = 8080;
  hubScript = pkgs.writeScriptBin "update-hub" ''
    #!${pkgs.python3}/bin/python3
    from http.server import BaseHTTPRequestHandler, HTTPServer
    import json
    import os

    DATA_FILE = "/var/lib/update-hub/status.json"

    def load_status():
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, 'r') as f:
                return json.load(f)
        return {"latest_commit": None, "hosts": {}}

    def save_status(status):
        os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
        with open(DATA_FILE, 'w') as f:
            json.dump(status, f, indent=2)

    def notify_hosts(status):
        import urllib.request
        # wg1 ネットワーク内の固定マッピング（DNS解決が困難な場合のため）
        IP_MAP = {
            "torii-chan": "10.0.1.1",
            "kagutsuchi-sama": "10.0.1.3",
            "shosoin-tan": "10.0.1.4",
            "sando-kun": "10.0.1.2",
        }
        
        # ステータスに登録されている全ホストをループ
        for hostname in status.get("hosts", {}).keys():
            ip = IP_MAP.get(hostname)
            if not ip:
                continue
                
            try:
                url = f"http://{ip}:8081/trigger-update"
                print(f"Notifying {hostname} at {url}...")
                req = urllib.request.Request(url, method='POST')
                # タイムアウトを短くし、各通知を独立させる
                with urllib.request.urlopen(req, timeout=1) as f:
                    pass
            except Exception as e:
                print(f"Failed to notify {hostname}: {e}")

    class HubHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            status = load_status()
            if self.path == "/status":
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(status).encode())
            elif self.path == "/latest-commit":
                self.send_response(200)
                self.end_headers()
                self.wfile.write(str(status.get("latest_commit", "")).encode())
            else:
                self.send_response(404)
                self.end_headers()

        def do_POST(self):
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode())
            status = load_status()

            if self.path == "/producer/done":
                status["latest_commit"] = data.get("commit")
                save_status(status)
                self.send_response(200)
                self.end_headers()
                # 別スレッドで通知を実行（レスポンスを速く返すため）
                import threading
                threading.Thread(target=notify_hosts, args=(status,)).start()
            elif self.path == "/consumer/reported":
                hostname = data.get("host")
                if hostname:
                    status["hosts"][hostname] = {
                        "commit": data.get("commit"),
                        "last_update": data.get("timestamp")
                    }
                    save_status(status)
                self.send_response(200)
                self.end_headers()
            else:
                self.send_response(404)
                self.end_headers()

    server = HTTPServer(('0.0.0.0', ${toString port}), HubHandler)
    print(f"Starting update-hub on port ${toString port}...")
    server.serve_forever()
  '';
in
{
  networking.firewall.allowedTCPPorts = [ port ];

  systemd.services.update-hub = {
    description = "NixOS Update Status Hub";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${hubScript}/bin/update-hub";
      Restart = "always";
      StateDirectory = "update-hub";
      User = "root";
    };
  };
}
