const path = require('path');
const koffi = require('koffi');
const here = __dirname;
const lib = koffi.load(path.join(here, 'libffi.dylib'));

// real signature: char* tmig_id_of(const uint8_t* ptr, size_t len)
const id_of = lib.func('tmig_id_of', 'void *', ['const uint8_t *', 'size_t']);
const free  = lib.func('tmig_free',  'void',    ['void *']);

function idOf(buf) {
  const p = id_of(buf, buf.length);
  if (!p) return '';
  const s = koffi.decode(p, 'char', -1);
  free(p);
  return s;
}

module.exports = { idOf };
