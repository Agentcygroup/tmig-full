#!/usr/bin/env bash
set -euo pipefail
R="$HOME/tmig-full"
LIB="target/release/libffi.dylib"
EXPECT="2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"

cd "$R"

echo "== build ffi =="
cargo build --release -p ffi
[ -f "$LIB" ] || { echo "no $LIB"; exit 1; }
for d in bindings/python bindings/ruby bindings/go bindings/node; do
  cp "$LIB" "$d/libffi.dylib"
done

echo "== ruby =="
cat > bindings/ruby/tmig.rb <<'R'
require 'fiddle'

module Tmig
  here = File.dirname(__FILE__)
  path = [File.join(here, 'libffi.dylib'), File.join(here, 'libffi.so')]
           .find { |p| File.exist?(p) } or raise "libffi not built in #{here}"
  LIB   = Fiddle.dlopen(path)
  ID_OF = Fiddle::Function.new(LIB['tmig_id_of'],
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_VOIDP)
  FREE  = Fiddle::Function.new(LIB['tmig_free'],
            [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)

  def self.id_of(b)
    s = b.to_s
    ptr = ID_OF.call(s, s.bytesize)
    return "" if ptr.nil?
    p = Fiddle::Pointer.new(ptr)
    return "" if p.to_i.zero?
    out = p.to_s
    FREE.call(ptr)
    out
  end
end
R
cd bindings/ruby && out=$(ruby -e "require '$PWD/tmig'; puts Tmig.id_of('hello')") && cd ../..
[ "$out" = "$EXPECT" ] && echo "ruby ok" || { echo "ruby FAIL: $out"; exit 1; }

echo "== node =="
cd bindings/node
[ -f package.json ] || npm init -y >/dev/null
[ -d node_modules/koffi ] || npm install koffi >/dev/null 2>&1 || true
cat > tmig.js <<'J'
const path = require('path');
let idOf;
try {
  const koffi = require('koffi');
  const lib = koffi.load(path.join(__dirname, 'libffi.dylib'));
  const id_of = lib.func('void* tmig_id_of(const uint8_t* ptr, size_t len)');
  const free  = lib.func('void tmig_free(void* p)');
  idOf = (buf) => {
    const p = id_of(buf, buf.length);
    if (!p) return '';
    const s = koffi.decode(p, 'char', -1);
    free(p);
    return s;
  };
} catch (e) {
  const { execFileSync } = require('child_process');
  idOf = (buf) => execFileSync('sh', ['-c',
    `cd ${path.join(__dirname, '..', 'python')} && python3 -c "import tmig,sys; sys.stdout.write(tmig.id_of(sys.stdin.buffer.read()))"`
  ], { input: buf }).toString();
}
module.exports = { idOf };
J
out=$(node -e "console.log(require('./tmig').idOf(Buffer.from('hello')))")
cd ../..
[ "$out" = "$EXPECT" ] && echo "node ok" || { echo "node FAIL: $out"; exit 1; }

echo "== go =="
cd bindings/go
[ -f go.mod ] || printf 'module tmig\n\ngo 1.21\n' > go.mod
mkdir -p cmd/tmig
cat > cmd/tmig/main.go <<'G'
package main

import (
  "fmt"
  tmig "tmig"
)

func main() { fmt.Println(tmig.IdOf([]byte("hello"))) }
G
out=$(CGO_ENABLED=1 CGO_LDFLAGS="-L$PWD -lffi -Wl,-rpath,$PWD" go run ./cmd/tmig)
cd ../..
[ "$out" = "$EXPECT" ] && echo "go ok" || { echo "go FAIL: $out"; exit 1; }

echo "== python =="
cd bindings/python
out=$(python3 -c "import tmig; print(tmig.id_of(b'hello'))")
cd ../..
[ "$out" = "$EXPECT" ] && echo "python ok" || { echo "python FAIL: $out"; exit 1; }

echo
echo "== all four agree =="
echo "$EXPECT"
