True Random Number Generator Testing
====================================

True random number generators (TRNGs) are tricky to test for several reasons. Since TRNGs depend on physical properties of the device, such as thermal noise, it is not possible to rely on simulations to verify the functionality - testing must happen on real hardware. Test results may depend on the specific FPGA family being used, and may even vary somewhat between different FPGAs of the same type, so testing should be done on more than just one FPGA. 

Randomness test suites
----------------------

For pseudorandom number generators, testing is typically done with state-of-the-art randomness test suites such as [PractRand](http://pracrand.sourceforge.net/) or [TestU01](http://simul.iro.umontreal.ca/testu01/tu01.html). I personally prefer PractRand because it is more flexible and has a much lower false positive rate.

Unfortunately these tools are not quite what we need to test a true random number generator, for two reasons:

- If we run these tools on the raw (unprocessed) random bits produced by the entropy source, it will immediately fail the randomness tests because the raw bits have significant bias, which is expected for a true random number generator and not really a problem.
- If we run these tools on the post-processed bits, and the data fails the randomness tests, we will know for sure that the data wasn't truly random. However if the data passes the randomness tests, we won't know whether this is because the data is truly random, or because the post-processing acted as a sufficiently good pseudorandom number generator to hide the patterns in the data from the randomness tests.

There exist some test suites made specifically for true random number generators, the most well-known one being the AIS31 standard, which describes a number of randomness tests. The reference implementation can be downloaded [here](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Zertifizierung/Interpretationen/AIS_31_testsuit_zip.zip). To be honest I don't find these particularly useful. These tests are much weaker than those used in PractRand and TestU01, the main 'benefit' seems to be that the tests are so weak that even somewhat biased data (such as raw random bits, or very lightly post-processed random bits) can pass these tests (at least if you are lucky, since the probability of failure increases with the amount of bias). Perhaps this is the reason why this test suite is so popular in academic publications.

While the procedures described in AIS31 may be useful as built-in self-tests to detect whether a true random number generator is completely broken (since they are very simple to implement), passing these tests proves very little and certainly shouldn't be your main criterion for evaluating a true random number generator! If the complexity of the tests is of no concern, I would recommend using PractRand instead.

Given that these tools can't distinguish between pseudorandom data and true random data, how can we actually test our true random number generator? There are a few possible strategies we can use:

- Use a very simple post-processing algorithm which on its own can't act as a good pseudorandom number generator, and then run a powerful randomness test suite (e.g PractRand, not AIS31) on large amounts of post-processed data (e.g. 1GB). For example, a 16-bit pseudorandom number generator would immediately fail PractRand's tests since the number of possible states is just too small, so if a postprocessing algorithm with a 16-bit state is able to pass PractRand's tests, this at least proves that it isn't *just* producing pseudorandom data.

- Repeatedly reset the state of the true random number generator (including the complete analog state of the entropy source), and capture the first N clock cycles of output over and over again. Then compare the data captured over successive reset cycles and look for any correlations. If the random data is mostly being produced by a pseudorandom process, then its output will be highly correlated over successive reset cycles - for a purely pseudorandom number generator, it will be completely identical. However for a good true random number generator, the output should only be correlated immediately after coming out of reset, and after that should quickly diverge between reset cycles. By repeatedly collecting small amounts of data immediately after reset, you can build histograms and calculate exactly how much entropy is being generated in those cycles. This is only really feasible for very small amounts of data since the histograms become too large otherwise, but it allows you to calculate exactly how much entropy is being generated in those first few cycles, which is a good indication of the overall entropy geneneration rate.

- Another simple way to distinguish pseudorandom data from true random data is to capture a small amount of post-processed data after each reset cycle (e.g. a 32-bit CRC of the first 10 cycles of output), repeat this a few billion times, concatenate all the data, and send it through a strong randomness test suite such as PractRand. The test will almost certainly fail if you capture the data directly after each reset, since the entropy source and post-processing algorithm need some time to get started - this is normal. However if you wait a bit longer before capturing, the quality of the collected data should be better. The number of cycles you need to wait in order to make the randomness tests pass gives a good indication of how much entropy is actually generated.

Hardware self-test
------------------

Since true random number generators depend on physical device characteristics, its behavior may change depending on e.g. temperature or supply voltage. As a result, a random number generator which was working fine during testing might randomly fail at some later time. For this reason it is desirable to have a self-test built directly into the hardware, which monitors the output of the true random number generator and alerts you when it is not working properly.

For practical reasons, these self-tests are usually much more simplistic than actual high-quality software randomness test suites like PractRand or TestU01. Often they are as simple as counting the number of zeros and ones to make sure they are roughly similar. These tests generally won't be able to detect subtle degradation of the entropy source, but they can detect total failures, and do so rather quickly. Since these tests are very weak, they need to be applied to the raw data, before postprocessing - otherwise the postprocessing will hide the flaws of the entropy source.

It is also possible to implement more advanced random tests such as basic chi-squared tests, which can detect more subtle degradation given enough time. If this is combined with a post-processing algorithm with significant redundancy (i.e. the amount of output data is much smaller than the raw input data, and it is designed in such a way that the output quality remains high even when the entropy of the input data is low), then the self-test may be sufficient to detect degradation of the entropy source before it affects the quality of the output. However such tests are more expensive in terms of hardware resources and take a long time 

Xorminator implements two self-tests: a fast, low-cost 'lite' test, and a slower, more complicated 'full' test.

### 'Lite' self-test

This self-tests works by selecting one of the 8 raw data bits, collecting 1023 consecutive values, and counting how many times this bit is equal to 1. Ideally this number should be 511.5 on average, though in practice there is likely some bias. If the number is less than 256 or greater than 767, the test fails. Otherwise, the test is repeated for the next bit. If the values for all 8 raw bits are within the correct range, the self-test passes.

### 'Full' self-test

This self-test works by first doing some simple preprocessing on the raw 8-bit data, collecting 65536 consecutive 8-bit values, and generating a histogram which counts how many times each possible 8-bit value occurred. Ideally this should be 256 on average. If any histogram value is less than 96 or greater than 479, the test fails. The test then calculates an approximate chi-squared statistic of the histogram, which for ideal random data should produce an average value of 1024, however due to bias in the actual data it tends to be higher in practice. If this value is less than 128 or greater than 4351, the test fails. Otherwise, the test is repeated with a different preprocessing algorithm (out of 4 possibilities). Since the 'full' xorminator contains three entropy sources, this procedure is applied to all three sources. If the values are within the correct ranges for all 4 preprocessing algorithms for all 3 entropy sources, the self-test passes.

The four preprocessing algorithms are (A = the current data, B = the data from the previous cycle):

- (A0^B0, A1^B1, A2^B2, A3^B3, A4^B4, A5^B5, A6^B6, A7^B7)
- (A0^A1, A2^A3, A4^A5, A6^A7, B0^B1, B2^B3, B4^B5, B6^B7)
- (A0^A2, A1^A3, A4^A6, A5^A7, B0^B2, B1^B3, B4^B6, B5^B7)
- (A0^A4, A1^A5, A2^A6, A3^A7, B0^B4, B1^B5, B2^B6, B3^B7)

These preprocessing algorithms are indended to detect correlations between bits.

Influence of clock frequencies on randomness quality
----------------------------------------------------

The xorminator entropy source is based on a chaotic oscillator, the entropy of which is somewhat dependent on the clock frequency which is used to sample the output. Experiments have shown that the circuit works well for a wide range of clock frequencies, but it may produce lower quality results for either very low or very high frequencies.

The issue with excessively low clock frequencies is that the control inputs switch at the clock frequency, and at low frequencies they may no longer switch sufficiently fast to effectively break [limit cycles](limit-cycles.md). This increases the likelyhood that the chaotic oscillator will enter a limit cycle within one cycle of the clock, which in turn significantly distorts the probability distribution of the raw data, because values that appear in the limit cycle become significantly more likely than other values.

The issue with excessively high clock frequencies is that the entropy source may not be able to accumulate sufficient thermal noise within one clock cycle in order to produce high-entropy 'raw' bits. While the individual values remain quite random, they become correlated across clock cycles, which reduces the actual entropy.

It is a good idea to test the entropy source over a range of clock frequencies to see how this affects the randomness quality. Refer to [characterization on a Xilinx Artix 7 XC7A100T FPGA](characterization-xilinx-artix7-xc7a100t.md) to see this effect in practice.
