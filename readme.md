# placement

This zig library helps simplify working with 3D positions and orientations/rotations.

Features:

    [x] quaternions for orientation
    [x] float type can be easily swapped

Design Choices:

    * for simplicity: positions use the same 'Vec' struct as the orientations and thus have 1 coordinate that is always 0

