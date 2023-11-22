import numpy as np

def exact_entropy(probs):
    probs = probs[probs != 0]
    return -(probs * np.log2(probs)).sum()

def estimated_entropy(counts):
    total = counts.sum()
    assert total >= 10 * counts.size, \
        'The number of observations must be at least 10 times larger than the number of bins'
    entropy = exact_entropy(counts / total)
    # The bias is calculated based on a uniform probability distribution.
    # See "Bias Analysis in Entropy Estimation" by Thomas Schurmann,
    # https://arxiv.org/abs/cond-mat/0403192
    bias = ((counts.size - 1) / (2 * total) + (counts.size**2 - 1) / (12 * total**2)) / np.log(2)
    # The estimation error is chi-squared distributed, so we can derive the
    # standard deviation (sqrt(2*k)) from the mean (k).
    stddev = bias * np.sqrt(2 / (counts.size - 1))
    return dict(entropy=entropy + bias, bias=bias, stddev=stddev)
