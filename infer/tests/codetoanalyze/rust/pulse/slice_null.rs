fn first(v: &[*const i32]) -> i32 {
    unsafe { *v[0] }
}

fn null_through_slice_bad() {
    let a = [0 as *const i32];
    let _ = first(&a);
}

fn valid_pointer_through_slice_ok() {
    let x = 7;
    let a = [&x as *const i32];
    let _ = first(&a);
}

fn main() {
    null_through_slice_bad();
    valid_pointer_through_slice_ok();
}
