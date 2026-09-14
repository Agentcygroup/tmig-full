import ctypes, pathlib
_here = pathlib.Path(__file__).parent
_candidates = [_here / "libffi.dylib", _here / "libffi.so", _here / "ffi.dll"]
_lib = None
for c in _candidates:
    if c.exists():
        _lib = ctypes.CDLL(str(c)); break
if _lib is None:
    raise RuntimeError("libffi not built; run `cargo build --release -p ffi` and copy target/release/libffi.* here")
_lib.tmig_id_of.restype = ctypes.c_void_p
_lib.tmig_id_of.argtypes = [ctypes.c_char_p, ctypes.c_size_t]
_lib.tmig_free.restype = None
_lib.tmig_free.argtypes = [ctypes.c_void_p]

def id_of(b: bytes) -> str:
    p = _lib.tmig_id_of(b, len(b))
    try:
        s = ctypes.cast(p, ctypes.c_char_p).value
        return s.decode() if s else ""
    finally:
        _lib.tmig_free(p)
