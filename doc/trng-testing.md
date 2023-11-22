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

- Use a very simple post-processing algorithm which on its own can't act as a good pseudorandom number generator, and then run a powerful randomness tests (e.g PractRand, not AIS31) on large amounts of post-processed data (e.g. 1GB). For example, a 16-bit pseudorandom number generator would immediately fail PractRand's tests since the number of possible states is just too small, so if a postprocessing algorithm with a 16-bit state is able to pass PractRand's tests, this at least proves that it isn't *just* producing pseudorandom data.







TODO: how to test (resetting, practrand, ...)

TODO: how the self-test works, what it means, total failure test vs chi-squared test, ...

The issue with excessively high clock frequencies is that the entropy source may not be able to accumulate sufficient thermal noise within one clock cycle in order to produce high-entropy 'raw' bits.
