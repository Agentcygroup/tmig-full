use std::ffi::CString;
use std::os::raw::c_char;
#[no_mangle]
pub extern "C" fn tmig_id_of(ptr: *const u8, len: usize) -> *mut c_char {
    if ptr.is_null() {
        return std::ptr::null_mut();
    }
    let bytes = unsafe { std::slice::from_raw_parts(ptr, len) };
    CString::new(addr::Id::of(bytes).hex())
        .map(|c| c.into_raw())
        .unwrap_or(std::ptr::null_mut())
}
#[no_mangle]
pub extern "C" fn tmig_free(p: *mut c_char) {
    if p.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(p);
    }
}
