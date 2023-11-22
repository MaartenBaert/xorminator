import decimal
import matplotlib.pyplot as plt
import numpy as np

num_state_bits = 16
num_input_bits = 8
num_output_bits = 4

output_skip = 4

xormix_matrix = [
    [ 5, 11,  6,  8, 10],
    [ 3, 13,  8,  5, 14],
    [11, 13,  4,  7,  3],
    [ 7,  6, 15,  1, 13],
    [10, 13,  2,  6,  9],
    [ 2, 10, 15,  4,  7],
    [ 4,  1,  2,  9, 14],
    [ 6, 12, 13,  7,  8],
    [ 1,  4, 14, 12,  3, 15],
    [10, 14, 11,  1,  9,  7],
    [15,  2,  0, 11,  5,  3],
    [ 3, 12, 11,  4, 10,  8],
    [ 0, 10, 14,  5,  6,  2],
    [ 9,  5,  0, 12,  1,  4],
    [ 9,  8,  0, 15,  2, 12],
    [ 0,  5, 15,  3,  9,  1],
]

def postproc_sim(cycles=100, input_probs=0.15, seed=12345, fixed_output=None, show_plot=False):

    # prepare input probabilities
    if not isinstance(input_probs, np.ndarray):
        input_probs = np.full(num_input_bits, input_probs)

    # precalculate xormix transitions and outputs
    xormix_values = np.arange(2**num_state_bits, dtype=np.int32)
    xormix_prev = np.zeros(2**num_state_bits, dtype=np.int32)
    xormix_next = np.zeros(2**num_state_bits, dtype=np.int32)
    for i in range(num_state_bits):
        for j in xormix_matrix[i]:
            xormix_next ^= ((xormix_values >> j) & 1) << i
    xormix_prev[xormix_next] = xormix_values
    xormix_output = xormix_values & ((1 << num_output_bits) - 1)

    # prepare state probabilities
    state_probs = np.zeros(2**num_state_bits)
    state_probs[0] = 1

    # create RNG instance
    rng = np.random.default_rng(seed)

    # create output arrays
    output_probabilities = np.zeros((cycles, 2**num_output_bits))
    output_entropies = np.zeros(cycles)
    state_entropies = np.zeros(cycles)
    bayer_factors_log2 = np.zeros(cycles)

    for i in range(-output_skip, cycles):

        # apply state transition
        state_probs = state_probs[xormix_prev]

        # apply input bit flips
        for bit in range(num_input_bits):
            flipped = xormix_values ^ (1 << bit)
            state_probs = state_probs * (1 - input_probs[bit]) + state_probs[flipped] * input_probs[bit]

        # calculate output probabilities
        output_probs = np.array([
            state_probs[xormix_output == value].sum()
            for value in range(2**num_output_bits)
        ])

        if i >= 0:

            # choose a random output (Monte Carlo)
            if fixed_output is None:
                output_value = rng.choice(2**num_output_bits, p=output_probs)
            else:
                output_value = fixed_output[i]

            # collapse probabilities (Bayes)
            state_probs[xormix_output != output_value] = 0
            state_probs /= state_probs.sum()

            # save output
            output_probabilities[i] = output_probs
            output_entropies[i] = -(output_probs[output_probs != 0] * np.log2(output_probs[output_probs != 0])).sum()
            state_entropies[i] = -(state_probs[state_probs != 0] * np.log2(state_probs[state_probs != 0])).sum()
            bayer_factors_log2[i] = np.log2(output_probs[output_value] * 2**num_output_bits)

    # calculate RMS relative probability error
    rms_prob_errors = np.sqrt(np.mean(np.square(output_probabilities * 2**num_output_bits - 1), axis=1))
    avg_rms_prob_error = np.sqrt(np.mean(np.square(output_probabilities * 2**num_output_bits - 1)))

    # calculate average output entropy the obvious way
    avg_output_entropy = output_entropies.mean()
    
    # calculate average output entropy with higher accuracy
    avg_entropy_loss = num_output_bits - avg_output_entropy
    if avg_entropy_loss < 1e-8:
        avg_entropy_loss = np.square(avg_rms_prob_error) / np.log(4)
    avg_output_entropy_dec = decimal.Decimal(num_output_bits) - decimal.Decimal(avg_entropy_loss)

    # calculate cumulative bayes factors
    bayer_factors_log2 = np.cumsum(bayer_factors_log2)
    total_bayes_factor_log2 = bayer_factors_log2[-1]

    if show_plot:
        print(f'RMS relative probability error: {avg_rms_prob_error}')
        print(f'Output entropy (low precision): {avg_output_entropy}')
        print(f'Output entropy (high precision): {avg_output_entropy_dec}',)
        print(f'Bayes factor: {total_bayes_factor_log2} (after {cycles} cycles)')

        plt.close('all')

        plt.figure('Entropy', figsize=(12, 10))
        ax = plt.subplot(3, 1, 1)
        plt.plot(output_entropies, '-', label='Output entropy')
        plt.plot(state_entropies, '-', label='State entropy')
        plt.grid()
        plt.legend(loc='upper left')
        plt.subplot(3, 1, 2, sharex=ax)
        plt.plot(rms_prob_errors, '-', label='RMS probability error')
        plt.grid()
        plt.legend(loc='upper left')
        plt.subplot(3, 1, 3, sharex=ax)
        plt.plot(bayer_factors_log2, '-', label='Bayes factor')
        plt.grid()
        plt.legend(loc='upper left')
        plt.tight_layout()
        plt.show()

    return (avg_rms_prob_error, avg_output_entropy, avg_entropy_loss, total_bayes_factor_log2)

# Simple test with plotting
if False:
    postproc_sim(cycles=10000, show_plot=True)

# Input probability sweep (fixed bias)
if True:
    input_probs1 = np.tile(np.linspace(0.1, 0.5, 41)[:, None], (1, num_input_bits))
    rn = np.random.default_rng(999).normal(size=(200, num_input_bits)) * np.linspace(0, 2, 201)[1 :, None]
    input_probs2 = np.clip(1 / (1 + np.exp(rn)), 0, 1)
    input_entropy1 = -(input_probs1 * np.log2(input_probs1) + (1 - input_probs1) * np.log2(1 - input_probs1)).sum(axis=1)
    input_entropy2 = -(input_probs2 * np.log2(input_probs2) + (1 - input_probs2) * np.log2(1 - input_probs2)).sum(axis=1)

    entropy_loss1 = np.zeros(len(input_probs1))
    entropy_loss2 = np.zeros(len(input_probs2))
    for i in range(len(input_probs1)):
        (_, _, entropy_loss1[i], _) = postproc_sim(cycles=100, input_probs=input_probs1[i], seed=i)
    for i in range(len(input_probs2)):
        (_, _, entropy_loss2[i], _) = postproc_sim(cycles=100, input_probs=input_probs2[i], seed=i)

    plt.close('all')

    plt.figure('Input Probability Sweep', figsize=(8, 6))
    plt.semilogy(input_entropy1 / num_input_bits, entropy_loss1.T / num_output_bits, '.-')
    plt.semilogy(input_entropy2 / num_input_bits, entropy_loss2.T / num_output_bits, '.')
    plt.grid()
    plt.xlabel('Input entropy (per bit)')
    plt.ylabel('Output entropy loss (per bit)')
    plt.tight_layout()
    plt.show()

if False:
    input_entropy = np.linspace(0.9, 1, 50, endpoint=False)
    input_probs = np.array([scipy.optimize.brentq(lambda x: -(x * np.log2(x) + (1 - x) * np.log2(1 - x)) - ent, 1e-15, 0.5) for ent in input_entropy])
    rms_prob_errors = []
    output_entropies = []
    entropy_losses = []
    for input_prob in input_probs:
        (rms_prob_error, output_entropy, entropy_loss) = postproc_sim(cycles=100, input_prob=input_prob)
        rms_prob_errors.append(rms_prob_error)
        output_entropies.append(output_entropy)
        entropy_losses.append(entropy_loss)
    rms_prob_errors = np.array(rms_prob_errors)
    output_entropies = np.array(output_entropies)
    entropy_losses = np.array(entropy_losses)

    plt.close('all')

    plt.figure('Input Probability Sweep', figsize=(8, 6))
    plt.semilogy(input_entropy, entropy_losses / num_output_bits, '.-')
    plt.grid()
    plt.xlabel('Input bit probability')
    plt.ylabel('Output entropy loss (per bit)')
    plt.tight_layout()
    plt.show()

if False:
    input_prob = 0.15
    cycles = 10000

    state = 0
    rng = np.random.default_rng(987456321)
    fixed_output = np.zeros(cycles, dtype=np.int32)
    for cy in range(-4, cycles):
        nextstate = 0
        for i in range(num_state_bits):
            for j in xormix_matrix[i]:
                nextstate ^= ((state >> j) & 1) << i
        state = nextstate
        for i in range(8):
            state ^= rng.choice(2, p=[1 - input_prob, input_prob]) << i
        if cy >= 0:
            fixed_output[cy] = state & 15

    # fixed_output = rng.integers(0, 16, cycles)
    postproc_sim(xormix_matrix=xormix_matrix, cycles=cycles, input_prob=input_prob, fixed_output=fixed_output, show_plot=True)
