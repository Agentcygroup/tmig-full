const path = require('path');
const ffi = require('ffi-napi');
const here = __dirname;
const lib = ffi.Library(path.join(here, 'libffi.dylib'), {
  tmig_id_of: ['pointer', ['pointer', 'size_t']],
  tmig_free:  ['void',    ['pointer']],
});
function idOf(buf) {
  const p = lib.tmig_id_of(buf, buf.length);
  if (p.isNull()) return '';
  const s = p.readCString();
  lib.tmig_free(p);
  return s;
}
module.exports = { idOf };
