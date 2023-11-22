Xorminator True Random Number Generator
=======================================

Xorminator is a true random number generator designed for FPGAs, specifically Xilinx 7 Series FPGAs. It produces high-quality true random data at high speed with minimal hardware resources. Xorminator can run at clock speeds ranging from 10 MHz to 200 MHz and produces fresh true random output bits each clock cycle.

Operating principle
-------------------

Xorminator derives true randomness from thermal noise inside the FPGA, which manifests itself as jitter - tiny variations in the propagation delays of logic gates. Xorminator contains a chaotic oscillator which is designed to be especially sensitive to this jitter, such that even tiny amounts of jitter cause rapid divergence of the generated waveforms. The chaotic oscillator is similar to a ring oscilator, but contains multiple combinatorial loops that interact with each other. The oscillator produces 8 output waveforms, which are periodically sampled by flip-flops. This produces 8 low-quality random bits per clock cycle. These bits are further post-processed and compressed to a smaller number of high-quality true random bits.

Xorminator variants
-------------------

Two variants are available:
- `xorminator_lite` is a lightweight variant for non-cryptographic applications where low resource usage is the main requirement. It produces 4 true random bits per cycle and contains a simple built-in self-test.
- `xorminator_full` is a more robust variant for cryptographic applications and other applications where randomness quality is more important than resource usage. It contains three independent entropy sources for redundancy, and uses a cryptographically secure postprocessing algorithm to add an extra layer of security. It produces 8 true random bits per cycle and contains a more extensive built-in self-test.

Both variants pass all randomness tests and are resilient to modeling attacks, so in theory there is no difference in randomness quality between them as long as they are both operating correctly. The difference lies in the level of redundancy: `xorminator_lite` has essentially no redundancy, so if something fails, the quality of the output may be compromised. The built-in self-test is sufficiently powerful to detect total failure of the entropy source, but won't necessarily detect partial degradation that might affect output quality. In contrast, `xorminator_full` is designed with redundancy in mind: it contains three independent entropy sources and will still produce true random output even if for example one of the three sources fails completely, or all three sources are severely degraded such that their effective entropy is halved. Additionally, `xorminator_full` uses the cryptographically secure [Trivium stream cipher](https://en.wikipedia.org/wiki/Trivium_(cipher)) as its post-processing algorithm, which ensures that even if all three entropy sources somehow fail simultaneously, the Trivium stream cipher will continue to produce output that is cryptographically secure (though not truly random). Finally, `xorminator_full` contains a more extensive built-in self-test that can detect not just total failure but also more subtle partial degradation of its entropy sources.

|                          | xorminator_lite  | xorminator_full |
| ------------------------ | ---------------- | ----------------- |
| Entropy sources          | 1                | 3                 |
| Compression ratio        | 2:1              | 3:1               |
| Compression algorithm    | Xormix-based     | Trivium-based     |
| Entropy pool size        | 16 bits          | 288 bits          |
| Startup time             | 8 cycles         | 184 cycles        |
| Raw entropy              | ~7.92 bits/cycle | ~23.76 bits/cycle |
| Output entropy           | 4 bits/cycle     | 8 bits/cycle      |
| # LUTs without self-test | 67               | 382               |
| # FFs without self-test  | 65               | 340               |
| # LUTs with self-test    | 35               | 108               |
| # FFs with self-test     | 44               | 207               |

Documentation
-------------

- [Xorminator Architecture](doc/architecture.md)
- [Xorminator Hardware Module (VHDL) Interface](doc/hardware-interface.md)
