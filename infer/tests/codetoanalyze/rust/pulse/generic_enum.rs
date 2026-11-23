// Null dereferences in crates that match on generic enums, loop with `for`,
// or use `?`. Capturing such a crate used to abort before analysis.

fn deref_payload(o: &Option<*const i32>) -> i32 {
    match o {
        Some(p) => unsafe { **p },
        None => 0,
    }
}

fn some_null_by_ref_bad() -> i32 {
    let o = Some(0 as *const i32);
    deref_payload(&o)
}

fn some_nonnull_by_ref_ok() -> i32 {
    let a = 3;
    let o = Some(&a as *const i32);
    deref_payload(&o)
}

fn none_arm_bad() -> i32 {
    let o: Option<i32> = None;
    let p = 0 as *const i32;
    match o {
        None => unsafe { *p },
        Some(v) => v,
    }
}

fn ok_arm_bad() -> i32 {
    let r: Result<i32, i32> = Ok(1);
    let p = 0 as *const i32;
    match r {
        Ok(_) => unsafe { *p },
        Err(e) => e,
    }
}

fn for_loop_bad(n: i32) -> i32 {
    let mut s = 0;
    for i in 0..n {
        s += i;
    }
    let p = 0 as *const i32;
    unsafe { *p + s }
}

fn question_bad(r: Result<i32, i32>) -> Result<i32, i32> {
    let v = r?;
    let p = 0 as *const i32;
    Ok(unsafe { *p } + v)
}

// FP: the discriminant read yields the address of the discriminant field, not
// its value, so Pulse explores every arm of the match, including this one,
// which cannot run.
fn FP_dead_none_arm_ok() -> i32 {
    let o = Some(1);
    let p = 0 as *const i32;
    match o {
        None => unsafe { *p },
        Some(v) => v,
    }
}

// FN: Pulse does not copy the fields of a struct or enum value on a
// whole-value copy, so the payload of `o2` is not known to be null.
fn FN_copied_option_bad() -> i32 {
    let o = Some(0 as *const i32);
    let o2 = o;
    match o2 {
        Some(p) => unsafe { *p },
        None => 0,
    }
}

fn main() {}
