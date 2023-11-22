import numpy as np

failed = False

for ctrl in range(256):

    (a, b, c, d, e, f, g, h) = [((ctrl >> i) & 1) ^ 0 for i in range(8)]
    (A, B, C, D, E, F, G, H) = [((ctrl >> i) & 1) ^ 1 for i in range(8)]

    mat = np.array([
        [1, 1, 1, 0, A, a, 0, 0],
        [1, 1, 0, 1, b, B, 0, 0],
        [1, 0, 1, 1, 0, 0, C, c],
        [0, 1, 1, 1, 0, 0, d, D],
        [E, e, 0, 0, 1, 1, 1, 0],
        [f, F, 0, 0, 1, 1, 0, 1],
        [0, 0, G, g, 1, 0, 1, 1],
        [0, 0, h, H, 0, 1, 1, 1],
    ])

    rhs = np.array([0, b, 0, d, 0, f, 1, H])

    x = np.unpackbits(np.arange(256, dtype=np.uint8)).reshape(8, -1, order='F')

    stable = (((mat @ x) & 1) == rhs[:, None]).all(axis=0)
    if stable.any():
        print(f'FAILED for ctrl={ctrl:08b}')
        failed = True
    else:
        print(f'ok for ctrl={ctrl:08b}')

print('Result:', ("PASS", "FAIL")[failed])
