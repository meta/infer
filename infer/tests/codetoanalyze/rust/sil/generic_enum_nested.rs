// Patterns that reach a field or a discriminant through a field whose
// declared type is a generic parameter. Such fields are translated with type
// void, so these projections have a *void base.

use std::cmp::Ordering;

enum MyErr {
    X,
    Y,
}

struct S {
    x: i32,
}

struct W<T> {
    inner: T,
}

struct P<T>(T);

fn some_ordering(o: Option<Ordering>) -> i32 {
    match o {
        Some(Ordering::Less) => 1,
        _ => 0,
    }
}

fn err_variant(r: Result<i32, MyErr>) -> i32 {
    match r {
        Err(MyErr::X) => 1,
        Err(MyErr::Y) => 2,
        Ok(_) => 0,
    }
}

fn ok_some(r: Result<Option<i32>, i32>) -> i32 {
    match r {
        Ok(Some(v)) => v,
        _ => 0,
    }
}

fn some_some(o: Option<Option<i32>>) -> i32 {
    match o {
        Some(Some(v)) => v,
        _ => 0,
    }
}

fn some_struct(o: &Option<S>) -> i32 {
    match o {
        Some(S { x }) => *x,
        None => 0,
    }
}

fn generic_field(w: &W<Option<i32>>) -> i32 {
    match w.inner {
        Some(v) => v,
        None => 0,
    }
}

fn generic_tuple_field(p: &P<Option<i32>>) -> i32 {
    match p.0 {
        Some(v) => v,
        None => 0,
    }
}

fn write_generic_field(w: &mut W<S>) {
    w.inner.x = 1;
}

fn main() {}
