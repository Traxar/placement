const std = @import("std");
const testing = std.testing;
const VecType = @import("vec.zig").VecType;

/// f must be a float type
pub fn PlacementType(comptime f: type) type {
    return struct {
        const Placement = @This();
        const Vec = VecType(f);
        pos: Vec,
        rot: Vec,

        const origin = Placement{
            .pos = Vec.origin,
            .rot = Vec.id,
        };

        pub fn from(x: f, y: f, z: f, a: f, b: f, c: f) Placement {
            return Placement{
                .pos = Vec.pos_from(x, y, z),
                .rot = Vec.quat_from(Vec.z_axis, c).mul(Vec.quat_from(Vec.y_axis, b)).mul(Vec.quat_from(Vec.x_axis, a)),
            };
        }

        pub fn xyz(self: Placement) [3]f {
            return @as([4]f, self.pos.v)[0..3].*;
        }

        pub fn abc(self: Placement) [3]f {
            const x = self.rot.mul(Vec.x_axis).mul(self.rot.inv());
            const b = std.math.asin(std.math.clamp(x.v[2], -1.0, 1.0));
            const c = if (b == 1 or b == -1 or (x.v[1] == 0 and x.v[0] == 0)) 0.0 else std.math.atan2(f, x.v[1], x.v[0]);
            const q = Vec.quat_from(Vec.z_axis, c).mul(Vec.quat_from(Vec.y_axis, b)).inv().mul(self.rot);
            std.debug.print("\nq: {}", .{q});
            const a = 2 * std.math.asin(std.math.clamp(q.v[0], -1.0, 1.0));
            return [_]f{ a, b, c };
        }

        pub fn inv(self: Placement) Placement {
            return Placement{
                .pos = self.rot.inv().mul(self.pos.neg()).mul(self.rot),
                .rot = self.rot.inv(),
            };
        }

        ///0 -> self -> other
        ///0 -> result
        pub fn apply(self: Placement, other: Placement) Placement {
            return Placement{
                .pos = self.pos.add(self.rot.mul(other.pos).mul(self.rot.inv())),
                .rot = other.rot.mul(self.rot),
            };
        }
    };
}

test "placements" {
    const Placement = PlacementType(f64);
    const a = Placement.from(1, 2, 3, std.math.pi / 2.0, 0, 0);
    const b = a.apply(a.inv());
    for (0..4) |i| {
        try testing.expectApproxEqAbs(Placement.origin.pos.v[i], b.pos.v[i], 1E-8);
        try testing.expectApproxEqAbs(Placement.origin.rot.v[i], b.rot.v[i], 1E-8);
    }
    std.debug.print("\nposition: {any}", .{a.xyz()});
    std.debug.print("\nxyz rotation: {any}", .{a.abc()});
}
