#!/usr/bin/env python3
"""
Legal Metrology Enforcement Bridge Server
Listens for HTTP POST payloads from the LMO Flutter app and appends them to inspections.json.
Also provides a live API and serves the Ministry Web Dashboard.
"""

import os
import json
from http.server import HTTPServer, SimpleHTTPRequestHandler
import socket

PORT = 8080
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INSPECTIONS_FILE = os.path.join(BASE_DIR, "inspections.json")
DASHBOARD_DIR = os.path.join(os.path.dirname(BASE_DIR), "dashboard")

def get_local_ip():
    """Attempts to find the laptop's LAN IP address for the user."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

class LegalMetrologyBridgeHandler(SimpleHTTPRequestHandler):
    def send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Accept, Authorization")

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()

    def do_GET(self):
        # 1. API: Get all inspections
        if self.path == "/api/inspections" or self.path.startswith("/api/inspections?"):
            self.send_response(200)
            self.send_cors_headers()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            try:
                if os.path.exists(INSPECTIONS_FILE):
                    with open(INSPECTIONS_FILE, "r", encoding="utf-8") as f:
                        data = f.read()
                else:
                    data = "[]"
                self.wfile.write(data.encode("utf-8"))
            except Exception as e:
                self.wfile.write(json.dumps({"error": str(e)}).encode("utf-8"))
            return

        # 2. Serve Ministry Dashboard
        if self.path == "/" or self.path == "/dashboard" or self.path == "/dashboard/":
            index_path = os.path.join(DASHBOARD_DIR, "index.html")
            if os.path.exists(index_path):
                self.send_response(200)
                self.send_cors_headers()
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                with open(index_path, "rb") as f:
                    self.wfile.write(f.read())
                return

        # Fallback to standard file serving
        super().do_GET()

    def do_POST(self):
        if self.path == "/api/inspection" or self.path.startswith("/api/inspection"):
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)

            try:
                record = json.loads(body.decode("utf-8"))
                
                # Read existing records
                inspections = []
                if os.path.exists(INSPECTIONS_FILE):
                    try:
                        with open(INSPECTIONS_FILE, "r", encoding="utf-8") as f:
                            inspections = json.load(f)
                    except Exception:
                        inspections = []

                # Append new inspection record
                inspections.insert(0, record) # Newest first

                # Write back atomically to inspections.json
                with open(INSPECTIONS_FILE, "w", encoding="utf-8") as f:
                    json.dump(inspections, f, indent=2, ensure_ascii=False)

                status_symbol = "🟢 PASS" if record.get("status") == "PASS" else "🔴 FAIL (VIOLATION)"
                print(f"\n[BRIDGE LOG] New Inspection Received!")
                print(f"  ID: {record.get('id')} | Status: {status_symbol}")
                print(f"  Officer: {record.get('officer_name')} ({record.get('officer_id')})")
                print(f"  GPS: ({record.get('latitude')}, {record.get('longitude')})")
                print(f"  Appended to: {INSPECTIONS_FILE}\n")

                self.send_response(200)
                self.send_cors_headers()
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                response = {
                    "status": "success",
                    "message": "Inspection recorded and stored to inspections.json",
                    "inspection_id": record.get("id")
                }
                self.wfile.write(json.dumps(response).encode("utf-8"))

            except Exception as e:
                print(f"[BRIDGE ERROR] Failed to process payload: {e}")
                self.send_response(400)
                self.send_cors_headers()
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "message": str(e)}).encode("utf-8"))
            return

        self.send_response(404)
        self.end_headers()

def run():
    lan_ip = get_local_ip()
    print("=" * 65)
    print("  MINISTRY OF CONSUMER AFFAIRS - LEGAL METROLOGY LOCAL BRIDGE  ")
    print("=" * 65)
    print(f"  Server listening on: http://0.0.0.0:{PORT}")
    print(f"  Laptop LAN IP (for phone): http://{lan_ip}:{PORT}")
    print(f"  Ministry Dashboard:        http://localhost:{PORT}/dashboard")
    print(f"  Data Storage:              {INSPECTIONS_FILE}")
    print("=" * 65)
    print("Waiting for LMO phone inspections...\n")

    server_address = ("0.0.0.0", PORT)
    httpd = HTTPServer(server_address, LegalMetrologyBridgeHandler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server.")
        httpd.server_close()

if __name__ == "__main__":
    run()
