const std = @import("std");
const testing = std.testing;
const VecType = @import("vec.zig").VecType;

/// 'F' must be a float type
pub fn PlacementType(comptime F: type) type {
    return struct {
        const Placement = @This();
        const Vec = VecType(F);
        pos: Vec,
        rot: Vec,

        const origin = Placement{
            .pos = Vec.origin,
            .rot = Vec.id,
        };

        pub fn from(coord: @Vector(3, F), axis: @Vector(3, F), angle: F) Placement {
            return Placement{
                .pos = Vec.pos_from(coord),
                .rot = Vec.quat_from(axis, angle),
            };
        }

        /// euler angles: x-y-z
        pub fn from_euler(coord: @Vector(3, F), angles: @Vector(3, F)) Placement {
            return Placement{
                .pos = Vec.pos_from(coord),
                .rot = Vec.quat_from(.{ 0, 0, 1 }, angles[2]).mul(Vec.quat_from(.{ 0, 1, 0 }, angles[1])).mul(Vec.quat_from(.{ 1, 0, 0 }, angles[0])),
            };
        }

        pub fn inv(self: Placement) Placement {
            const rot_inv = self.rot.inv();
            return Placement{
                .pos = rot_inv.mul(self.pos.neg()).mul(self.rot),
                .rot = rot_inv,
            };
        }

        pub fn fix(self: Placement) Placement {
            return Placement{
                .pos = self.pos.fix_pos(),
                .rot = self.rot.fix_quat(),
            };
        }

        /// 0 -> self -> other
        /// 0 -> result
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
    const a = Placement.from_euler(
        .{ 1, 2, 3 },
        .{ std.math.pi / 2.0, std.math.pi / 2.0, std.math.pi / 2.0 },
    );
    const b = a.apply(a.inv());
    for (0..4) |i| {
        try testing.expectApproxEqAbs(Placement.origin.pos.v[i], b.pos.v[i], 1E-8);
        try testing.expectApproxEqAbs(Placement.origin.rot.v[i], b.rot.v[i], 1E-8);
    }
}
