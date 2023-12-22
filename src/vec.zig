const std = @import("std");
const testing = std.testing;

/// f must be a float type
pub fn VecType(comptime F: type) type {
    return struct {
        const Vec = @This();
        const V = @Vector(4, F);
        v: V,

        pub const origin = Vec{ .v = V{ 0, 0, 0, 0 } };
        pub const id = Vec{ .v = V{ 1, 0, 0, 0 } };

        pub fn pos_from(coord: @Vector(3, F)) Vec {
            return Vec{ .v = V{ 0, coord[0], coord[1], coord[2] } };
        }

        pub fn quat_from(axis: @Vector(3, F), angle: F) Vec {
            var ax = pos_from(axis);
            const a = angle * 0.5;
            return Vec{ .v = V{ @cos(a), 0, 0, 0 } + @as(V, @splat(@sin(a) / ax.norm())) * ax.v };
        }

        pub fn pos(self: Vec) @Vector(3, F) {
            return @as([4]F, self.v)[1..4].*;
        }

        pub fn rot(self: Vec) struct { axis: @Vector(3, F) = .{ 0, 0, 0 }, angle: F = 0 } {
            if (@abs(self.v[0]) >= 1) return .{};
            const a = 2 * std.math.acos(self.v[0]);
            const n = @sqrt(1 - self.v[0] * self.v[0]);
            var ax = self.div(n) catch return .{};
            return .{ .axis = ax.pos(), .angle = a };
        }

        pub fn neg(self: Vec) Vec {
            return Vec{ .v = -self.v };
        }

        pub fn inv(self: Vec) Vec {
            return Vec{ .v = self.v * V{ 1, -1, -1, -1 } };
        }

        pub fn norm(self: Vec) F {
            return @sqrt(@reduce(.Add, self.v * self.v));
        }

        pub fn div(self: Vec, d: F) !Vec {
            if (d == 0) return error.DivByZero;
            return Vec{ .v = self.v / @as(V, @splat(d)) };
        }

        pub fn fix_pos(self: Vec) !Vec {
            if (self.v[0] == 0) return self;
            var h = self;
            h.v[0] = 0;
            return Vec{ .v = try h.div(h.norm() / self.norm()) };
        }

        pub fn fix_quat(self: Vec) !Vec {
            return Vec{ .v = try self.div(self.norm()) };
        }

        pub fn add(self: Vec, other: Vec) Vec {
            return Vec{ .v = self.v + other.v };
        }

        pub fn mul(self: Vec, other: Vec) Vec {
            const w = @as(V, @splat(self.v[0])) * other.v;
            const i = self.v[1];
            const x = @shuffle(F, V{ i, -i, i, -i } * other.v, undefined, @Vector(4, i32){ 1, 0, 3, 2 });
            const j = self.v[2];
            const y = @shuffle(F, V{ j, -j, -j, j } * other.v, undefined, @Vector(4, i32){ 2, 3, 0, 1 });
            const k = self.v[3];
            const z = @shuffle(F, V{ k, k, -k, -k } * other.v, undefined, @Vector(4, i32){ 3, 2, 1, 0 });
            return Vec{ .v = w + x + y + z };
        }
    };
}

test "positions" {
    const Vec = VecType(f32);
    const a = Vec.pos_from(.{ 1, 2, 3 });
    const b = Vec.pos_from(.{ 1, -1, -1 });
    const c = a.add(b.neg());
    try std.testing.expectEqual(@as(f32, 5), c.norm());
}

test "quaternions" {
    const Vec = VecType(f64);
    const a = Vec.pos_from(.{ 1, 2, 3 });
    const qx = Vec.quat_from(.{ 1, 0, 0 }, std.math.pi / 2.0);
    const qy = Vec.quat_from(.{ 0, 1, 0 }, std.math.pi / 2.0);
    const qz = Vec.quat_from(.{ 0, 0, 1 }, std.math.pi / 2.0);
    const q = qz.mul(qy.mul(qx));
    try testing.expect(@reduce(.Max, @abs(q.rot().axis - @Vector(3, f64){ 0, 1, 0 })) < 1E-8);
    try testing.expectApproxEqAbs(@as(f64, std.math.pi / 2.0), q.rot().angle, 1E-8);
    const c = q.mul(a).mul(q.inv());
    try testing.expect(@reduce(.Max, @abs(c.pos() - @Vector(3, f64){ 3, 2, -1 })) < 1E-8);
}
