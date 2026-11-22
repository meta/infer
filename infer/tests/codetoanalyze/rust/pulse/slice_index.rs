fn get(v: &[i32]) -> i32 {
    v[3]
}

fn null_deref_after_slice_index_bad() {
    let a = [1, 2, 3, 4];
    let _x = get(&a);
    let ptr = 0 as *const i32;
    let _y = unsafe { *ptr };
}

fn main() {
    null_deref_after_slice_index_bad();
}
