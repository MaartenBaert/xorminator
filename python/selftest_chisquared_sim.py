import numpy as np

rng = np.random.default_rng()

raw_prob = 0.4
num_trials = 256
num_samples = 2**16

chisq_exact = np.zeros((num_trials, 4))
chisq_approx = np.zeros((num_trials, 4))

approx_table = ((np.arange(512) - 256)**2 / 64).reshape(-1, 2).mean(axis=1).round().astype(np.int32)

for trial in range(num_trials):

    for subtest in range(4):

        # generate raw data
        raw = ((rng.random((num_samples + 1, 8)) < raw_prob).astype(np.int32) << np.arange(8)).sum(axis=1)
        raw1 = raw[: -1]
        raw2 = raw[1 :]

        # generate processed data
        if subtest == 0:
            processed = raw1 ^ raw2
        elif subtest == 1:
            part1 = (raw1 ^ (raw1 >> 1)) & 0b01010101
            part2 = (raw2 ^ (raw2 << 1)) & 0b10101010
            processed = part1 | part2
        elif subtest == 2:
            part1 = (raw1 ^ (raw1 >> 2)) & 0b00110011
            part2 = (raw2 ^ (raw2 << 2)) & 0b11001100
            processed = part1 | part2
        elif subtest == 3:
            part1 = (raw1 ^ (raw1 >> 4)) & 0b00001111
            part2 = (raw2 ^ (raw2 << 4)) & 0b11110000
            processed = part1 | part2
        else:
            assert False, 'Invalid subtest'

        # generate histogram
        hist = np.zeros(2**8, dtype=np.int32)
        np.add.at(hist, processed, 1)

        # calculate chi-squared value
        chisq_exact[trial, subtest] = np.square(hist - num_samples / 2**8).sum() / 2**8
        chisq_approx[trial, subtest] = approx_table[hist >> 1].sum() / 4

print('Exact mean:', np.mean(chisq_exact, axis=0))
print('Exact std:', np.std(chisq_exact, ddof=1, axis=0))

print('Approx mean:', np.mean(chisq_approx, axis=0))
print('Approx std:', np.std(chisq_approx, ddof=1, axis=0))

print('RMS approx error:', np.sqrt(np.mean(np.square(chisq_exact - chisq_approx))))

