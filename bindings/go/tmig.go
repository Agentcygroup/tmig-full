package tmig

/*
#cgo LDFLAGS: -L${SRCDIR} -lffi
#include <stdlib.h>
extern char* tmig_id_of(const unsigned char*, size_t);
extern void tmig_free(char*);
*/
import "C"
import "unsafe"

func IdOf(b []byte) string {
    var p *C.uchar
    if len(b) > 0 { p = (*C.uchar)(unsafe.Pointer(&b[0])) }
    c := C.tmig_id_of(p, C.size_t(len(b)))
    if c == nil { return "" }
    defer C.tmig_free(c)
    return C.GoString(c)
}
