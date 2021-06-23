
module T11(
  input reset,
  input clk,
  output [15:0] addr,
  input [15:0] din,
  output [15:0] dout,
  output wr_n,
  output reg [8:0] microrom_addr,
  input [26:0] microrom_data
);

`include "T11.vh"

reg [15:0] MR;  // CPU mode register
reg [15:0] SP[15:0]; // scratchpad (register file)

// instruction register decoding
// i1/i3 4bit for compatibility

wire [15:0] IR = SP[sp_ir];

wire       i6 = IR[15];
wire [2:0] i5 = IR[14:12];
wire [2:0] i4 = IR[11:9];
wire [3:0] i3 = IR[8:6];
wire [2:0] i2 = IR[5:3];
wire [3:0] i1 = IR[2:0];

// microcode instruction decoding

wire [3:0] ALU_OPE   = microrom_data[26:23]; // ALU operation
wire [3:0] ALU_ASL   = microrom_data[22:19]; // A SEL
wire [3:0] ALU_BSL   = microrom_data[18:15]; // B SEL
wire [1:0] ALU_WB    = microrom_data[14:13]; // WB SEL (A|B)
wire [3:0] MW_P1     = microrom_data[12:9];  // dout bus sel or jmp condition
wire [8:0] MW_SEQ    = microrom_data[8:0];   // sequence

// jump vector address for microcode instruction routine
wire [8:0] ivect = i5 != 0 ? { i5, 6'd0 } : { 3'b0, i4, 3'd0 };

// microsequencer next address calculation
// MW_SEQ = addr fixed in ROM, cip/csd/cdd = dynamic addr resolution
// cip = call micro instruction, csd/cdd = call src/dst micro routine for
// addressing mode resolution

wire [8:0] next_seq =
  MW_P1 == cip ? ivect :
  MW_P1 == csd ? { 1'b1, i5 ? i4 : i2, 5'h0 } : // single op if i5==0 (src=dst)
  MW_P1 == cdd ? { 1'b1, i2, 5'h10 } :
  MW_P1 == ret ? SP[sp_s1] :
  MW_P1 == jmp || MW_P1 == cal  ? MW_SEQ :
  MW_P1 == jz  &  PSW[ps_zero]  ? MW_SEQ :
  MW_P1 == jnz & ~PSW[ps_zero]  ? MW_SEQ :
  MW_P1 == jc  &  PSW[ps_carry] ? MW_SEQ :
  MW_P1 == jnc & ~PSW[ps_carry] ? MW_SEQ :
  MW_P1 == js  &  PSW[ps_neg]   ? MW_SEQ :
  MW_P1 == jns & ~PSW[ps_neg]   ? MW_SEQ : microrom_addr + 9'd1;

// call flag
wire call = MW_P1 == cip || MW_P1 == csd || MW_P1 == cdd || MW_P1 == cal;

// address bus & data bus
// emit write if sp_ab & wen

assign addr = ALU_BSL == sp_ab ? AOUT : 16'd0;
assign dout = ALU_BSL == sp_ab ? SP[sp_w1] : 16'd0;
assign wr_n = ALU_WB == wen ? 1'b0 : 1'b1;

// ALU

wire [15:0] AIN =
  ALU_ASL == sp_sc ? SP[i5 ? i3 : i1] : // single op if i5==0 (src=dst)
  ALU_ASL == sp_dt ? SP[i1] : SP[ALU_ASL];

wire [15:0] BIN =
  ALU_BSL == sp_sc ? SP[i5 ? i3 : i1] : // single op if i5==0 (src=dst)
  ALU_BSL == sp_dt ? SP[i1] : SP[ALU_BSL];

// status register

wire updateflags =
  ALU_OPE == aplsb |
  ALU_OPE == amnsb |
  ALU_OPE == amns1;

reg [15:0] PSW;
always @(posedge clk)
  if (updateflags)
    PSW <= {
      12'd0,
      AOUT[15],      // neg
      AOUT == 15'd0, // zero
      1'b0,          // overflow
      AC             // carry
    };

// ALU OUT & carry

wire [15:0] winc = i6 && i1 != sp_pc && i1 != sp_sp ? 16'd1 : 16'd2;

wire AC;
wire [15:0] AOUT;
assign { AC, AOUT } =
  ALU_OPE == sel_a ? AIN :
  ALU_OPE == sel_b ? BIN :
  ALU_OPE == aplsb ? AIN + BIN :
  ALU_OPE == amnsb ? AIN - BIN :
  ALU_OPE == ainc ? AIN + winc :
  ALU_OPE == adec ? AIN - winc :
  ALU_OPE == amns1 ? AIN - 16'd1 :
  ALU_OPE == mask ? 16'hf :
  ALU_OPE == aandb ? AIN & BIN :
  ALU_OPE == coma ? ~AIN :
  ALU_OPE == aplb1 ? AIN + BIN + 16'd1 : 17'd0;

// FSM

// decide where to write, explicit register or src/dst resolution
wire [3:0] AWB = ALU_ASL == sp_sc ? i3 : ALU_ASL == sp_dt ? i1 : ALU_ASL;
wire [3:0] BWB = ALU_BSL == sp_sc ? i3 : ALU_BSL == sp_dt ? i1 : ALU_BSL;

reg started, powered;

always @(posedge clk) begin

  if (reset) begin

    powered <= 1'b1;
    microrom_addr <= 9'h1ff;
    SP[sp_ir] <= 16'd0;

    MR <= din;
    SP[sp_pc] <=
      (MR[15:13] == 3'd0 ? 16'hc000 : 16'd0) |
      (MR[15:13] == 3'd1 ? 16'h8000 : 16'd0) |
      (MR[15:13] == 3'd3 ? 16'h2000 : 16'd0) |
      (MR[15:13] == 3'd2 ? 16'h4000 : 16'd0) |
      (MR[15:13] == 3'd4 ? 16'h1000 : 16'd0) |
      (MR[15:13] == 3'd5 ? 16'h0000 : 16'd0) |
      (MR[15:13] == 3'd6 ? 16'hf600 : 16'd0) |
      (MR[15:13] == 3'd7 ? 16'hf400 : 16'd0);

    if (started) SP[sp_pc][2] <= 1'b1;

  end
  else begin

    started <= powered;
    microrom_addr <= next_seq;

    // scratchpad write

    SP[sp_di] <= din;
    if (ALU_WB[0]) SP[AWB] <= { i6 ? SP[AWB][15:8] : AOUT[15:8], AOUT[7:0] };
    if (ALU_WB[1]) SP[BWB] <= { i6 ? SP[BWB][15:8] : AOUT[15:8], AOUT[7:0] };

    // update the microcode two level stack

    if (call) { SP[sp_s2], SP[sp_s1] } <= { SP[sp_s1], {7'd0, microrom_addr+9'd1}};
    if (MW_P1 == ret) { SP[sp_s2], SP[sp_s1] } <= { 16'd0, SP[sp_s2] };

  end
end

//**************************
// DEBUG
//**************************

wire [15:0] debug_sp0 = SP[4'h0];
wire [15:0] debug_sp1 = SP[4'h1];
wire [15:0] debug_sp2 = SP[4'h2];
wire [15:0] debug_sp3 = SP[4'h3];
wire [15:0] debug_sp4 = SP[4'h4];
wire [15:0] debug_sp5 = SP[4'h5];
wire [15:0] debug_sp6 = SP[4'h6];
wire [15:0] debug_sp7 = SP[4'h7];
wire [15:0] debug_sp8 = SP[4'h8];
wire [15:0] debug_sp9 = SP[4'h9];
wire [15:0] debug_spa = SP[4'ha];
wire [15:0] debug_spb = SP[4'hb];
wire [15:0] debug_spc = SP[4'hc];
wire [15:0] debug_spd = SP[4'hd];
wire [15:0] debug_spe = SP[4'he];
wire [15:0] debug_spf = SP[4'hf];

endmodule