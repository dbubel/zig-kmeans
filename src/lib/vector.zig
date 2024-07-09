const std = @import("std");
pub fn VectorOps(comptime N: comptime_int, comptime T: type) type {
    return struct {
        pub fn dot(v1: @Vector(N, T), v2: @Vector(N, T)) T {
            return @as(T, @floatCast(@reduce(.Add, v1 * v2)));
        }

        pub fn dist(v1: @Vector(N, T), v2: @Vector(N, T)) T {
            return mag(v2 - v1);
        }

        pub fn mag(v1: @Vector(N, T)) T {
            return std.math.sqrt(@as(T, @floatCast(@reduce(.Add, v1 * v1))));
        }

        pub fn cos_sim(v1: @Vector(N, T), v2: @Vector(N, T)) T {
            return dot(v1, v2) / (mag(v1) * mag(v2));
        }
    };
}

test "test basic ops 3 dim" {
    const a = @Vector(3, f32){ 1, 1, 1 };
    const vOps3Dimf32 = VectorOps(3, f32);

    const mag = vOps3Dimf32.mag(a);
    try std.testing.expectEqual(1.7320508e0, mag);

    const dist = vOps3Dimf32.dist(a, a);
    try std.testing.expectEqual(0e0, dist);

    const dot = vOps3Dimf32.dot(a, a);
    try std.testing.expectEqual(3, dot);

    const cos = vOps3Dimf32.cos_sim(a, a);
    try std.testing.expectEqual(1, cos);
}
