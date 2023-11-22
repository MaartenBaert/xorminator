* Xorminator core transistor-level model

.include '45nm_LP.pm'
.tran 10p 20n 0 10p
.option method=gear

.subckt MB_gate_inv VDD VSS IN_P OUT_N
M0 OUT_N IN_P VDD VDD pmos w=240n l=45n
M1 OUT_N IN_P VSS VSS nmos w=120n l=45n
I0 OUT_N VSS TRNOISE(200n 10p 0 0)
.ends

.subckt MB_gate_nand2 VDD VSS IN1_P IN2_P OUT_N
M0 OUT_N IN2_P VDD VDD pmos w=240n l=45n
M1 OUT_N IN1_P VDD VDD pmos w=240n l=45n
M2 OUT_N IN1_P n_0 VSS nmos w=120n l=45n
M3 n_0 IN2_P VSS VSS nmos w=120n l=45n
I0 OUT_N VSS TRNOISE(200n 10p 0 0)
.ends

.subckt MB_gate_and2 VDD VSS IN1_P IN2_P OUT_P
X0 VDD VSS IN1_P IN2_P n_0 MB_gate_nand2
X1 VDD VSS n_0 OUT_P MB_gate_inv
.ends

.subckt MB_gate_xor2_diff VDD VSS IN1_P IN1_N IN2_P IN2_N OUT_P
M0 n_0 IN1_P VDD VDD pmos w=240n l=45n
M1 n_0 IN2_P VDD VDD pmos w=240n l=45n
M2 OUT_P IN1_N n_0 VDD pmos w=240n l=45n
M3 OUT_P IN2_N n_0 VDD pmos w=240n l=45n
M4 OUT_P IN2_P n_1 VSS nmos w=120n l=45n
M5 OUT_P IN2_N n_2 VSS nmos w=120n l=45n
M6 n_1 IN1_P VSS VSS nmos w=120n l=45n
M7 n_2 IN1_N VSS VSS nmos w=120n l=45n
I0 OUT_P VSS TRNOISE(200n 10p 0 0)
.ends

.subckt MB_gate_xor2 VDD VSS IN1_P IN2_P OUT_P
X0 VDD VSS IN1_P n_0 MB_gate_inv
X1 VDD VSS IN2_P n_1 MB_gate_inv
X2 VDD VSS IN1_P n_0 IN2_P n_1 OUT_P MB_gate_xor2_diff
.ends

.subckt MB_gate_xor4 VDD VSS IN1_P IN2_P IN3_P IN4_P OUT_P
X0 VDD VSS IN1_P IN2_P n_0 MB_gate_xor2
X1 VDD VSS IN3_P IN4_P n_1 MB_gate_xor2
X2 VDD VSS n_0 n_1 OUT_P MB_gate_xor2
.ends

.subckt MB_gate_nmux2_diff VDD VSS IN1_P IN2_P SEL_P SEL_N OUT_N
M0 n_0 IN2_P VDD VDD pmos w=240n l=45n
M1 n_0 SEL_P VDD VDD pmos w=240n l=45n
M2 OUT_N IN1_P n_0 VDD pmos w=240n l=45n
M3 OUT_N SEL_N n_0 VDD pmos w=240n l=45n
M4 OUT_N SEL_P n_1 VSS nmos w=120n l=45n
M5 OUT_N SEL_N n_2 VSS nmos w=120n l=45n
M6 n_1 IN2_P VSS VSS nmos w=120n l=45n
M7 n_2 IN1_P VSS VSS nmos w=120n l=45n
I0 OUT_N VSS TRNOISE(200n 10p 0 0)
.ends

.subckt MB_gate_nmux2 VDD VSS IN1_P IN2_P SEL_P OUT_N
X0 VDD VSS SEL_P n_0 MB_gate_inv
X1 VDD VSS IN1_P IN2_P SEL_P n_0 OUT_N MB_gate_nmux2_diff
.ends

.subckt MB_gate_mux2 VDD VSS IN1_P IN2_P SEL_P OUT_P
X0 VDD VSS IN1_P IN2_P SEL_P n_0 MB_gate_nmux2
X1 VDD VSS n_0 OUT_P MB_gate_inv
.ends

.subckt MB_delayline VDD VSS IN_P OUT1_P OUT2_P OUT3_P OUT4_P
.param load1=1f
.param load2=1f
.param load3=1f
.param load4=1f
X0 VDD VSS IN_P n_0 MB_gate_inv
X1 VDD VSS n_0 n_1 MB_gate_inv
X2 VDD VSS n_1 n_2 MB_gate_inv
X3 VDD VSS n_2 OUT1_P MB_gate_inv
X4 VDD VSS OUT1_P n_3 MB_gate_inv
X5 VDD VSS n_3 n_4 MB_gate_inv
X6 VDD VSS n_4 n_5 MB_gate_inv
X7 VDD VSS n_5 OUT2_P MB_gate_inv
X8 VDD VSS OUT2_P n_6 MB_gate_inv
X9 VDD VSS n_6 n_7 MB_gate_inv
X10 VDD VSS n_7 n_8 MB_gate_inv
X11 VDD VSS n_8 OUT3_P MB_gate_inv
X12 VDD VSS OUT3_P n_9 MB_gate_inv
X13 VDD VSS n_9 n_10 MB_gate_inv
X14 VDD VSS n_10 n_11 MB_gate_inv
X15 VDD VSS n_11 OUT4_P MB_gate_inv
Cload0 n_0 VSS 'load1'
Cload1 n_1 VSS 'load1'
Cload2 n_2 VSS 'load1'
Cload3 n_3 VSS 'load2'
Cload4 n_4 VSS 'load2'
Cload5 n_5 VSS 'load2'
Cload6 n_6 VSS 'load3'
Cload7 n_7 VSS 'load3'
Cload8 n_8 VSS 'load3'
Cload9 n_9 VSS 'load4'
Cload10 n_10 VSS 'load4'
Cload11 n_11 VSS 'load4'
Cload0b OUT1_P VSS 'load1'
Cload1b OUT2_P VSS 'load2'
Cload2b OUT3_P VSS 'load3'
Cload3b OUT4_P VSS 'load4'
.ends

.subckt MB_xorminator_source VDD VSS RST C0 C1 C2 C3 C4 C5 C6 C7 osc0 osc1 osc2 osc3 osc4 osc5 osc6 osc7

Xinvr VDD VSS RST rstn MB_gate_inv
Xinvc VDD VSS C7 c7n MB_gate_inv

Xmux0 VDD VSS OSC4_d1 OSC5_d2 C0 mux0 MB_gate_mux2
Xmux1 VDD VSS OSC5_d1 OSC4_d2 C1 mux1 MB_gate_mux2
Xmux2 VDD VSS OSC6_d1 OSC7_d2 C2 mux2 MB_gate_mux2
Xmux3 VDD VSS OSC7_d1 OSC6_d2 C3 mux3 MB_gate_mux2
Xmux4 VDD VSS OSC0_d1 OSC1_d2 C4 mux4 MB_gate_mux2
Xmux5 VDD VSS OSC1_d1 OSC0_d2 C5 mux5 MB_gate_mux2
Xmux6 VDD VSS OSC2_d1 OSC3_d2 C6 mux6 MB_gate_mux2
Xmux7 VDD VSS OSC3_d1 OSC2_d2 C7 mux7 MB_gate_mux2

Xxor0 VDD VSS OSC1_d3 mux0 OSC2_d4 VSS xor0 MB_gate_xor4
Xxor1 VDD VSS OSC0_d3 mux1 OSC3_d4 C1  xor1 MB_gate_xor4
Xxor2 VDD VSS OSC3_d3 mux2 OSC0_d4 VSS xor2 MB_gate_xor4
Xxor3 VDD VSS OSC2_d3 mux3 OSC1_d4 C3  xor3 MB_gate_xor4
Xxor4 VDD VSS OSC5_d3 mux4 OSC6_d4 VSS xor4 MB_gate_xor4
Xxor5 VDD VSS OSC4_d3 mux5 OSC7_d4 C5  xor5 MB_gate_xor4
Xxor6 VDD VSS OSC7_d3 mux6 OSC4_d4 VDD xor6 MB_gate_xor4
Xxor7 VDD VSS OSC6_d3 mux7 OSC5_d4 c7n xor7 MB_gate_xor4

Xand0 VDD VSS xor0 rstn OSC0 MB_gate_and2
Xand1 VDD VSS xor1 rstn OSC1 MB_gate_and2
Xand2 VDD VSS xor2 rstn OSC2 MB_gate_and2
Xand3 VDD VSS xor3 rstn OSC3 MB_gate_and2
Xand4 VDD VSS xor4 rstn OSC4 MB_gate_and2
Xand5 VDD VSS xor5 rstn OSC5 MB_gate_and2
Xand6 VDD VSS xor6 rstn OSC6 MB_gate_and2
Xand7 VDD VSS xor7 rstn OSC7 MB_gate_and2

Xdelay0 VDD VSS OSC0 OSC0_d4 OSC0_d2 OSC0_d1 OSC0_d3 MB_delayline load1=1.941f load2=1.938f load3=1.865f load4=1.226f
Xdelay1 VDD VSS OSC1 OSC1_d2 OSC1_d1 OSC1_d3 OSC1_d4 MB_delayline load1=1.258f load2=1.428f load3=1.904f load4=1.203f
Xdelay2 VDD VSS OSC2 OSC2_d4 OSC2_d2 OSC2_d3 OSC2_d1 MB_delayline load1=1.462f load2=1.876f load3=1.913f load4=1.937f
Xdelay3 VDD VSS OSC3 OSC3_d4 OSC3_d3 OSC3_d2 OSC3_d1 MB_delayline load1=1.876f load2=1.736f load3=1.652f load4=1.357f
Xdelay4 VDD VSS OSC4 OSC4_d3 OSC4_d4 OSC4_d1 OSC4_d2 MB_delayline load1=1.549f load2=1.645f load3=1.602f load4=1.864f
Xdelay5 VDD VSS OSC5 OSC5_d4 OSC5_d3 OSC5_d2 OSC5_d1 MB_delayline load1=1.423f load2=1.021f load3=1.858f load4=1.132f
Xdelay6 VDD VSS OSC6 OSC6_d2 OSC6_d1 OSC6_d4 OSC6_d3 MB_delayline load1=1.697f load2=1.854f load3=1.742f load4=1.789f
Xdelay7 VDD VSS OSC7 OSC7_d2 OSC7_d3 OSC7_d4 OSC7_d1 MB_delayline load1=1.749f load2=1.512f load3=1.327f load4=1.878f

.ends

Vvdd vdd 0 1.1
Vrst rst 0 1.1 PWL(1.00n 1.1 1.01n 0.0)

Vc0 c0 0 1.1
Vc1 c1 0 1.1
Vc2 c2 0 1.1
Vc3 c3 0 1.1
Vc4 c4 0 1.1
Vc5 c5 0 1.1
Vc6 c6 0 1.1
Vc7 c7 0 1.1

Xcore vdd 0 rst c0 c1 c2 c3 c4 c5 c6 c7 osc0 osc1 osc2 osc3 osc4 osc5 osc6 osc7 MB_xorminator_source

.save v(rst) v(Xcore.rstn)
.save v(Xcore.xor0) v(Xcore.xor1) v(Xcore.xor2) v(Xcore.xor3) v(Xcore.xor4) v(Xcore.xor5) v(Xcore.xor6) v(Xcore.xor7)
.save v(Xcore.mux0) v(Xcore.mux1) v(Xcore.mux2) v(Xcore.mux3) v(Xcore.mux4) v(Xcore.mux5) v(Xcore.mux6) v(Xcore.mux7)
.save v(osc0) v(osc1) v(osc2) v(osc3) v(osc4) v(osc5) v(osc6) v(osc7)

.end
