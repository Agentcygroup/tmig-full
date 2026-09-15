import hashlib, pathlib

def write_if_changed(path, content):
    p = pathlib.Path(path)
    if isinstance(content, str):
        content = content.encode()
    if p.exists() and p.read_bytes() == content:
        return False
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(content)
    return True

def sha256(b):
    if isinstance(b, str):
        b = b.encode()
    return hashlib.sha256(b).hexdigest()
