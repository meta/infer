// Discriminant reads on instances of generic enums. Each read names the
// enum's declared type, which carries no type arguments.

enum G<T> {
    A(T),
    B,
}

struct Counter {
    n: i32,
}

impl Counter {
    fn next(&mut self) -> Option<i32> {
        if self.n > 0 {
            self.n -= 1;
            Some(self.n)
        } else {
            None
        }
    }
}

fn opt_match(o: Option<i32>) -> i32 {
    match o {
        Some(v) => v,
        None => 0,
    }
}

fn opt_if_let(o: Option<i32>) -> i32 {
    if let Some(v) = o {
        v
    } else {
        0
    }
}

fn res_match(r: Result<i32, i32>) -> i32 {
    match r {
        Ok(v) => v,
        Err(e) => e,
    }
}

fn user_generic(g: G<i32>) -> i32 {
    match g {
        G::A(v) => v,
        G::B => 0,
    }
}

fn opt_ref(o: Option<&i32>) -> i32 {
    match o {
        Some(v) => *v,
        None => 0,
    }
}

fn generic_copy<T: Copy>(o: Option<T>) -> bool {
    match o {
        Some(_) => true,
        None => false,
    }
}

// The same Option read that a `for` loop desugars to, without pulling in
// core::iter (which would make the checked-in .ullbc several times larger).
fn while_let_next(c: &mut Counter) -> i32 {
    let mut s = 0;
    while let Some(v) = c.next() {
        s += v;
    }
    s
}

fn main() {}
