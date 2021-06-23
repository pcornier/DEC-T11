// alu operations

localparam na    = 4'h0;
localparam sel_a = 4'h0; // a
localparam sel_b = 4'h1; // b
localparam coma  = 4'h2; // ~a
localparam adc_d = 4'h3; // a+b+d(c)
localparam adec  = 4'h4; // a-1 or a-2 based on i6 & mode
localparam ainc  = 4'h5; // a+1 or a+2 based on i6 & mode
localparam axorb = 4'h6; // a^b
localparam aandb = 4'h7; // a and b
localparam asifd = 4'h8; // a-b if c=1 else a+b
localparam alsfb = 4'h9; // a << b
localparam aplsb = 4'ha; // a+b
localparam aplb1 = 4'hb; // a+b+1
localparam amnsb = 4'hc; // a-b
// localparam aplnb = 4'hd; // a+(~b)
localparam amns1 = 4'he; // a-1
localparam mask  = 4'hf; // a[7:0]

// scratchpad write back

localparam nwr = 2'b00; // no scratchpad write
localparam wra = 2'b01; // write a
localparam wrb = 2'b10; // write b
localparam wen = 2'b11; // write enable

// microcode sequence modifiers

localparam inc = 4'h0; // inc seq
localparam jmp = 4'h1; // force jump
localparam jz  = 4'h2; // jump if z
localparam jnz = 4'h3; // jump if ~z
localparam jc  = 4'h4; // jump if c
localparam jnc = 4'h5; // jump if ~c
localparam js  = 4'h6; // jump if n (bit 15 == 1)
localparam jns = 4'h7; // jump if ~n
localparam cal = 4'h8; // call
localparam ret = 4'h9; // return
localparam cip = 4'ha; // call instruction
localparam csd = 4'hb; // call src decode
localparam cdd = 4'hc; // call dst decode
localparam next = 13'h0; // next

// scratchpad layout

localparam sp_r0 = 4'h0; // /\
localparam sp_r1 = 4'h1; // ||
localparam sp_r2 = 4'h2; // ||
localparam sp_r3 = 4'h3; // || public register file
localparam sp_r4 = 4'h4; // || exposed to macro code
localparam sp_r5 = 4'h5; // ||
localparam sp_sp = 4'h6; // ||
localparam sp_pc = 4'h7; // \/
                         // below are internal registers for micro code only
localparam sp_w1 = 4'h8; // /\ -> work register 1 / data out
localparam sp_sc = 4'h9; // || -> src addressing mode
localparam sp_di = 4'ha; // || -> din (copy of cpu data in)
localparam sp_dt = 4'hb; // || -> dst addressing mode
localparam sp_ir = 4'hc; // || -> instr register IR
localparam sp_ab = 4'hd; // || -> address bus
localparam sp_s1 = 4'he; // || -> stack level 1
localparam sp_s2 = 4'hf; // \/ -> stack level 2

// processor status flags

localparam ps_carry    = 2'd0;
localparam ps_overflow = 2'd1;
localparam ps_zero     = 2'd2;
localparam ps_neg      = 2'd3;
