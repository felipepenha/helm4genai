"""Simple copy of MCP Server.

This module provides a basic HTTP server that acts as a mock Model Context Protocol (MCP) server.
It handles GET requests to fetch content from a given URL or confirm the server status.
"""

import http.server
import socketserver
import urllib.parse
import urllib.request

PORT = 8080


class MCPHandler(http.server.SimpleHTTPRequestHandler):
    """Handler for MCP server requests.

    This handler extends SimpleHTTPRequestHandler to process specific GET requests
    mimicking an MCP server behavior.
    """

    def do_GET(self) -> None:
        """Handle GET requests.

        Routes requests based on the path:
        - '/fetch': Retrieves content from a specified URL in the query parameter.
        - Other paths: Returns a default status message.
        """
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/fetch":
            query = urllib.parse.parse_qs(parsed.query)
            url = query.get("url", [None])[0]

            if not url:
                self.send_error(400, "Missing 'url' parameter")
                return

            try:
                print(f"Fetching: {url}")
                # Security warning: Simple proxy, careful in prod
                with urllib.request.urlopen(url) as response:
                    content = response.read()
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(content)
            except Exception as e:
                self.send_error(500, f"Error fetching URL: {str(e)}")
        else:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"MCP Server Mock Running")


if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), MCPHandler) as httpd:
        print(f"Serving MCP Mock on port {PORT}")
        httpd.serve_forever()
