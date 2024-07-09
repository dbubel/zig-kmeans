const std = @import("std");

extern fn add(a: i32, b: i32) i32;

pub fn run() i32 {
    const a: i32 = add(1, 2);
    return a;
}
