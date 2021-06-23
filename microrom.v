
module microrom(
  input clk,
  input [8:0] addr,
  output reg [26:0] data
);

`include "T11.vh"

// 000 = start vector, fetch IR
// 040 = MOV
// 028 = DEC

// routine locations for addressing modes
// 100 = REG src ok
// 110 = REG dst ok
// 120 = REG DEFERRED src ok
// 130 = REG DEFERRED dst ok
// 140 = AUTO-INC src ok
// 150 = AUTO-INC dst ok
// 160 = AUTO-INC DEFERRED src
// 170 = AUTO-INC DEFERRED dst
// 180 = AUTO-DEC src ok
// 190 = AUTO-DEC dst ok
// 1A0 = AUTO-DEC DEFERRED src wip
// 1B0 = AUTO-DEC DEFERRED dst wip
// 1C0 = INDEX src
// 1D0 = INDEX dst
// 1E0 = INDEX DEFFERED src
// 1F0 = INDEX DEFFERED dst

always @(posedge clk)
  case (addr)

    // FETCH, read PC, load IR, call instruction
    9'h000: data <= { sel_a, sp_pc, sp_ab, wrb, next };
    9'h001: data <= { sel_a, sp_di, sp_ir, wrb, next };
    9'h002: data <= { ainc, sp_pc, sp_pc, wrb, cip, 9'h0 };
    9'h003: data <= { na, na, na, nwr, jmp, 9'h0 };

    // BNE
    9'h008: data <= { na, na, na, nwr, jz, 9'h00e };
    9'h009: data <= { mask, na, sp_w1, wrb, next };
    9'h00a: data <= { aandb, sp_ir, sp_w1, wrb, next };
    9'h00b: data <= { aplsb, sp_w1, sp_w1, wrb, next };
    9'h00c: data <= { coma, sp_w1, sp_w1, wrb, next };
    9'h00d: data <= { aplb1, sp_pc, sp_w1, wra, ret, 9'h0 };
    9'h00e: data <= { na, na, na, nwr, ret, 9'h0 };

    // DEC
    9'h028: data <= { na, na, na, nwr, csd, 9'h0 };
    9'h029: data <= { amns1, sp_w1, na, wra, next };
    9'h02a: data <= { na, na, na, nwr, cdd, 9'h0 };

    // MOV, fetch src, save dst
    9'h040: data <= { na, na, na, nwr, csd, 9'h0 };
    9'h041: data <= { na, na, na, nwr, cdd, 9'h0 };
    9'h042: data <= { na, na, na, nwr, ret, 9'h0 };

    // REG
    9'h100: data <= { sel_a, sp_sc, sp_w1, wrb, ret, 9'h0 };
    9'h110: data <= { sel_a, sp_w1, sp_dt, wrb, ret, 9'h0 };

    // REG DEFERRED
    9'h120: data <= { sel_a, sp_sc, sp_ab, wrb, next };
    9'h121: data <= { sel_a, sp_di, sp_w1, wrb, ret, 9'h0 };
    9'h130: data <= { sel_a, sp_dt, sp_ab, wen, ret, 9'h0 };

    // AUTO-INC
    9'h140: data <= { sel_a, sp_sc, sp_ab, wrb, next };
    9'h141: data <= { sel_a, sp_di, sp_w1, wrb, next };
    9'h142: data <= { ainc, sp_sc, sp_sc, wrb, ret, 9'h0 };
    9'h150: data <= { sel_a, sp_dt, sp_ab, wen, next };
    9'h151: data <= { ainc, sp_dt, sp_dt, wrb, ret, 9'h0 };

    // AUTO-INC DEFERRED
    9'h160: data <= { sel_a, sp_sc, sp_ab, wrb, next };
    9'h161: data <= { sel_a, sp_di, sp_ab, wrb, next };
    9'h162: data <= { sel_a, sp_di, sp_w1, wrb, next };
    9'h163: data <= { ainc, sp_sc, sp_sc, wrb, ret, 9'h0 };
    9'h170: data <= { sel_a, sp_dt, sp_ab, wrb, next };
    9'h171: data <= { sel_a, sp_di, sp_ab, wen, next };
    9'h172: data <= { ainc, sp_dt, sp_dt, wrb, ret, 9'h0 };

    // AUTO-DEC DEFERRED
    9'h1a0: data <= { sel_a, sp_sc, sp_ab, wrb, next };
    9'h1a1: data <= { sel_a, sp_di, sp_ab, wrb, next };
    9'h1a2: data <= { sel_a, sp_di, sp_w1, wrb, next };
    9'h1a3: data <= { adec, sp_sc, sp_sc, wrb, ret, 9'h0 };
    9'h1b0: data <= { sel_a, sp_dt, sp_ab, wrb, next };
    9'h1b1: data <= { sel_a, sp_di, sp_ab, wen, next };
    9'h1b2: data <= { adec, sp_dt, sp_dt, wrb, ret, 9'h0 };

    // AUTO-DEC
    9'h180: data <= { sel_a, sp_sc, sp_ab, wrb, next };
    9'h181: data <= { sel_a, sp_di, sp_w1, wrb, next };
    9'h182: data <= { adec, sp_sc, sp_sc, wra, ret, 9'h0 };
    9'h190: data <= { sel_a, sp_dt, sp_ab, wen, next };
    9'h191: data <= { adec, sp_dt, sp_dt, wra, ret, 9'h0 };

    9'h1ff: data <= { na, na, na, nwr, jmp, 9'h0 };

  endcase

endmodule