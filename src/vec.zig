const std = @import("std");
const testing = std.testing;

/// f must be a float type
/// v = (x, y, z, w)
pub fn VecType(comptime f: type) type {
    return struct {
        const Vec = @This();
        const V = @Vector(4, f);
        v: V,

        pub const origin = Vec{ .v = V{ 0, 0, 0, 0 } };
        pub const x_axis = Vec{ .v = V{ 1, 0, 0, 0 } };
        pub const y_axis = Vec{ .v = V{ 0, 1, 0, 0 } };
        pub const z_axis = Vec{ .v = V{ 0, 0, 1, 0 } };
        pub const id = Vec{ .v = V{ 0, 0, 0, 1 } };

        pub fn pos_from(x: f, y: f, z: f) Vec {
            return Vec{ .v = V{ x, y, z, 0 } };
        }

        pub fn quat_from(axis: Vec, angle: f) Vec {
            var ax = axis;
            //w = 0 in case axis is given as quaternion
            ax.v[3] = 0;
            const n = axis.norm();
            const a = angle * 0.5;
            return Vec{ .v = @as(V, @splat(@sin(a) / n)) * ax.v + V{ 0, 0, 0, @cos(a) } };
        }

        pub fn neg(self: Vec) Vec {
            return Vec{ .v = -self.v };
        }

        pub fn inv(self: Vec) Vec {
            return Vec{ .v = self.v * V{ -1, -1, -1, 1 } };
        }

        pub fn norm(self: Vec) f {
            return @sqrt(@reduce(.Add, self.v * self.v));
        }

        pub fn add(self: Vec, other: Vec) Vec {
            return Vec{ .v = self.v + other.v };
        }

        pub fn mul(self: Vec, other: Vec) Vec {
            const w = @as(V, @splat(self.v[3])) * other.v;
            const i = self.v[0];
            const x = @shuffle(f, V{ -i, i, -i, i } * other.v, undefined, @Vector(4, i32){ 3, 2, 1, 0 });
            const j = self.v[1];
            const y = @shuffle(f, V{ -j, -j, j, j } * other.v, undefined, @Vector(4, i32){ 2, 3, 0, 1 });
            const k = self.v[2];
            const z = @shuffle(f, V{ k, -k, -k, k } * other.v, undefined, @Vector(4, i32){ 1, 0, 3, 2 });

            return Vec{ .v = w + x + y + z };
        }
    };
}

test "positions" {
    const Vec = VecType(f32);
    const a = Vec.pos_from(1, 2, 3);
    const b = Vec.pos_from(1, -1, -1);
    const c = a.add(b.neg());
    try std.testing.expectEqual(@as(f32, 5), c.norm());
}

test "quaternions" {
    const Vec = VecType(f64);
    const a = Vec.pos_from(1, 2, 3);
    const qx = try Vec.quat_from(Vec.x_axis, std.math.pi / 2.0);
    const qy = try Vec.quat_from(Vec.y_axis, std.math.pi / 2.0);
    const q = qy.mul(qx);
    const c = q.mul(a).mul(q.inv());
    try vecApproxEqual(Vec.pos_from(2, -3, -1), c);
}

fn vecApproxEqual(expected: anytype, actual: @TypeOf(expected)) !void {
    if (expected.add(actual.neg()).norm() > 1E-8) {
        return error.TestExpectedApproxEq;
    }
}
