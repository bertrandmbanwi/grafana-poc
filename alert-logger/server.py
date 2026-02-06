from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from datetime import datetime


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        try:
            data = json.loads(body)
            alerts = data.get("alerts", [])
            for alert in alerts:
                status = alert.get("status", "unknown").upper()
                name = alert.get("labels", {}).get("alertname", "unknown")
                severity = alert.get("labels", {}).get("severity", "unknown")
                summary = alert.get("annotations", {}).get("summary", "")
                ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                print(f"[{ts}] [{status}] [{severity}] {name}: {summary}", flush=True)
        except Exception as e:
            print(f"Error parsing alert: {e}", flush=True)
        self.send_response(200)
        self.end_headers()

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    print("Alert Logger listening on :5001 - alerts will appear here", flush=True)
    HTTPServer(("0.0.0.0", 5001), Handler).serve_forever()
