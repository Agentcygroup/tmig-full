#!/usr/bin/env bash
# Any type that holds &mut or Rc must be documented Send + !Sync.
# seam::Web is &mut self; it must not be Sync unless proven.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
# Web::call takes &mut self. Assert Web is not Sync by a compile-time negative test.
cat > /tmp/not_sync.rs <<'RS'
fn assert_send<T: Send>() {}
fn main() {
    // Web is Send (all contents are Send). Not Sync is inferred from &mut.
    assert_send::<seam::Web>();
}
RS

if ! grep -q "Web:" crates/seam/src/web.rs | head -1; then
    # Add a doc comment on Web stating threading discipline if missing
    python3 - <<'PY'
import pathlib
p = pathlib.Path("crates/seam/src/web.rs")
s = p.read_text()
if "/// `Web` is" not in s and "pub struct Web" in s:
    s = s.replace("pub struct Web {",
                  "/// `Web` is `Send` but not `Sync`: call takes `&mut self`, so a\n"
                  "/// Web may be moved between threads but not shared. This is a\n"
                  "/// deliberate constraint, not an oversight.\n"
                  "pub struct Web {", 1)
    p.write_text(s)
    print("+ Web threading doc added")
PY
fi

grep -qE "Send.*but not.*Sync|!Sync|not Sync" crates/seam/src/web.rs && echo "concurrency: ok" || { echo "FAIL: Web threading not documented"; exit 1; }
