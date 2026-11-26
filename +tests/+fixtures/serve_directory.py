"""Serve a directory over HTTP on localhost, with support for Range requests.

Used by tests.fixtures.HttpServerFixture to read Zarr stores over HTTP. Python's
built-in server ignores the Range header, so partial reads would silently fetch
whole chunks; this server answers single-range requests with 206 Partial Content.

Usage: python serve_directory.py DIRECTORY PORT_FILE [REQUEST_LOG]

The server binds to a free port on 127.0.0.1 and writes the port number to
PORT_FILE once it is listening. If REQUEST_LOG is given, each request is appended
to it as "<status> <path>".
"""

from __future__ import annotations

from functools import partial
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import os
from pathlib import Path
import re
import sys

RANGE_PATTERN = re.compile(r"^bytes=(\d*)-(\d*)$")


class RangeRequestHandler(SimpleHTTPRequestHandler):
    request_log: Path | None = None

    def send_head(self):
        range_header = self.headers.get("Range")
        path = self.translate_path(self.path)
        if range_header is None or not os.path.isfile(path):
            return super().send_head()

        match = RANGE_PATTERN.match(range_header.strip())
        size = os.path.getsize(path)
        if match is None or match.groups() == ("", ""):
            self.send_error(HTTPStatus.REQUESTED_RANGE_NOT_SATISFIABLE)
            return None
        first, last = match.groups()
        if first == "":
            start, end = max(0, size - int(last)), size - 1
        else:
            start, end = int(first), min(int(last) if last else size - 1, size - 1)
        if start > end or start >= size:
            self.send_error(HTTPStatus.REQUESTED_RANGE_NOT_SATISFIABLE)
            return None

        file = open(path, "rb")
        file.seek(start)
        self.range_length = end - start + 1
        self.send_response(HTTPStatus.PARTIAL_CONTENT)
        self.send_header("Content-Type", self.guess_type(path))
        self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.send_header("Content-Length", str(self.range_length))
        self.end_headers()
        return file

    def copyfile(self, source, outputfile):
        length = getattr(self, "range_length", None)
        if length is None:
            return super().copyfile(source, outputfile)
        outputfile.write(source.read(length))
        self.range_length = None

    def log_request(self, code="-", size="-"):
        if self.request_log is not None:
            with self.request_log.open("a", encoding="utf-8") as log:
                log.write(f"{int(code) if str(code).isdigit() else code} {self.path}\n")

    def log_message(self, format, *args):
        # Requests are logged by log_request; nothing goes to stderr.
        pass


def main() -> int:
    directory, port_file = sys.argv[1], Path(sys.argv[2])
    RangeRequestHandler.request_log = Path(sys.argv[3]) if len(sys.argv) > 3 else None
    handler = partial(RangeRequestHandler, directory=directory)
    with ThreadingHTTPServer(("127.0.0.1", 0), handler) as server:
        port_file.write_text(str(server.server_address[1]), encoding="utf-8")
        server.serve_forever()
    return 0


if __name__ == "__main__":
    sys.exit(main())
