struct Point { x: i32, y: i32 }

fn get(v: &[i32], i: usize) -> i32 { v[3] + v[i] }
fn set(v: &mut [i32], i: usize, x: i32) { v[i] = x; }
fn len(v: &[i32]) -> usize { v.len() }
fn first_elem<T: Copy>(v: &[T]) -> T { v[0] }
fn sum_x(pts: &[Point], i: usize) -> i32 { pts[i].x + pts[0].y }
fn nested(m: &[&[i32]], i: usize, j: usize) -> i32 { m[i][j] }
// Slice patterns read the slice length (a PtrMetadata place), which the frontend
// does not support yet, so this function falls back to a declaration.
fn first_or_zero(v: &[i32]) -> i32 { if let [first, ..] = v { *first } else { 0 } }

fn main() {
    let mut a = [1, 2, 3, 4];
    set(&mut a, 0, 5);
    let _ = get(&a, 1);
    let _ = len(&a);
    let _ = first_elem(&a);
    let pts = [Point { x: 1, y: 2 }];
    let _ = sum_x(&pts, 0);
    let row: &[i32] = &a;
    let m = [row];
    let _ = nested(&m, 0, 1);
    let _ = first_or_zero(&a);
}
