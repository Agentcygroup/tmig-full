#!/usr/bin/env python3
import http.server, socketserver, pathlib
PORT = 8765
root = pathlib.Path(__file__).parent / "static"
class H(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=str(root), **kw)
    def log_message(self, *a): pass
with socketserver.TCPServer(("127.0.0.1", PORT), H) as httpd:
    print(f"ui/web on http://127.0.0.1:{PORT}")
    httpd.serve_forever()
