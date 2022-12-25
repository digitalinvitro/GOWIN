/*
  Test - ZERO
 do:   RAM region -> UART

   UART 115200/8/1
*/
module main(
    input   B_button,        // B_button - active LOW (общий при замыкании), подятнута к VCC
    input   clk_24MHz,       // clk - 24MHz тактовый сигнал генератора
    output  ledG,
    output  ledR,
    output  ledB,
    output  TXpin 
);


wire RESET = !B_button;  

wire clk_1_43Hz;
wire clk_min;

clkdivider clkdiv(.RESET(RESET), .clk(clk_24MHz), .clk_div(clk_1_43Hz), .clk_min(clk_min));

reg [31:0]R[7:0];
reg [15:0]RgTMP;
reg [7:0]OP_CODE;

wire [15:0]DATA;
wire [10:0]ADDR;

wire [7:0]RFsrc;
wire toRAM;

wire [15:0]DATAB;
reg [10:0]IP;

wire [10:0]ADDRB = (toRAM)? RgTMP[10:0] : IP;

DPB dpb_inst_0 ( 
.RESETA(RESET),
.CLKA(clk_1_43Hz),
.OCEA(1'b1),
.CEA(1'b1),
.WREA(1'b0),
.ADA({ ADDR, 3'b000 }),
.DOA({ DATA[15:8], DATA[7:0] }), 
.DIA(16'd0),
.BLKSELA(3'b000),

.RESETB(RESET),
.CLKB(clk_1_43Hz),
.OCEB(1'b1),
.CEB(1'b1),
.WREB(toRAM),
.ADB({ADDRB, 3'b000 }),
.DOB(DATAB),
.DIB({8'd0, RFsrc}),
.BLKSELB(3'b000)
);

defparam dpb_inst_0.READ_MODE0 = 1'b0;
defparam dpb_inst_0.READ_MODE1 = 1'b0;
defparam dpb_inst_0.WRITE_MODE0 = 2'b00;
defparam dpb_inst_0.WRITE_MODE1 = 2'b00;
defparam dpb_inst_0.BIT_WIDTH_0 = 8;
defparam dpb_inst_0.BIT_WIDTH_1 = 8;
defparam dpb_inst_0.BLK_SEL_0 = 3'b000;
defparam dpb_inst_0.BLK_SEL_1 = 3'b000;
defparam dpb_inst_0.RESET_MODE = "SYNC";

//                                                                                    
defparam dpb_inst_0.INIT_RAM_00 = 256'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_30_A0_AA_B0;
//defparam dpb_inst_0.INIT_RAM_3F = 256'hFF_0F_0E_0D_0C_0B_0A_09_08_07_06_05_04_03_02_01_00_A0_00_00_C3_CD_A0_0B_FC_7F_40_4D_FC_7F_C8_45;

reg [7:0]RF[7:0];

wire fetch, REG_WR, INC_IP;
wire [1:0]target;

wire [3:0]OP;
wire [2:0]rg;
wire d;
assign {OP,d,rg} = OP_CODE;

assign {ledR,ledB} = 2'b11;

sequenser microcode(.RESET(RESET),.clk(clk_min),.aseq(OP),.iseq({target, REG_WR, INC_IP}), .fetch(fetch)/*, .count({ledR, ledB})*/);

wire toRF = (target == 2'b00);
wire toTMP = (target == 2'b01);
assign toRAM = (target == 2'b10);

always@(posedge clk_min or posedge RESET) begin
  if(RESET) begin
     IP <= 10'd0;
     OP_CODE <= 8'h00;
  end else begin
     if(fetch) OP_CODE <= DATAB[7:0];
     IP <= IP + INC_IP;
     if(toRF & REG_WR) RF[rg] <= DATAB[7:0];
     if(toTMP) RgTMP[15:0] <= {DATAB[7:0], RgTMP[15:8]};
  end
end
assign RFsrc = RF[rg];
assign  ledG = INC_IP;

/* Serial debug interface */
serialdebug debug(
  .RESET(RESET),
  .clk(clk_24MHz),
  .clk_div(clk_1_43Hz),
  .TxPin(TXpin),
  .RequestAddress(ADDR),
  .RequestDATA(DATA[7:0])
);

/* CPU */
wire [1:0]mode;
wire [4:0]operate;
wire [2:0]rA,rB,rC;

assign {mode,operate,rA,rB,rC} = DATA[15:0];

endmodule

`define FETCH_BIT 4

module sequenser(
  input  RESET,
  input  clk,
  input  [3:0]aseq, 
  output [`FETCH_BIT-1:0]iseq,
  output reg fetch,
  output count
);

reg [4:0]sequence[63:0];
reg [1:0]count;

always@(posedge clk or posedge RESET) begin
//  reg: 000 - AL, 001 - CL, 010 - DL, 011 - BL, 100 - AH, 101 - CH, 110 - DH, 111 - BH
  if(RESET) begin
     fetch <= 1'b1;
     count <= 2'd0;
/* start                             F TO W IP    */
     sequence[{2'b00, 4'b0000}] = 5'b0_00_0_0;
// 1011.0.reg  op=1011 d=0 --> op.d.reg #const8 (B0 AA)  MOV AL, 0xAA
     sequence[{2'b00, 4'b1011}] = 5'b0_00_0_1;
     sequence[{2'b01, 4'b1011}] = 5'b1_00_1_1;
     sequence[{2'b10, 4'b1011}] = 5'b0_00_0_0;
     sequence[{2'b11, 4'b1011}] = 5'b0_00_0_0;
// 1010.000.w addr_l addr_h w=0 -> A0 00 30  MOV AL, byte ptr [0x3000]
     sequence[{2'b00, 4'b1010}] = 5'b0_00_0_1;
     sequence[{2'b01, 4'b1010}] = 5'b0_01_1_1;
     sequence[{2'b10, 4'b1010}] = 5'b0_01_1_1;
     sequence[{2'b11, 4'b1010}] = 5'b1_10_1_1;
  end else begin
     fetch <= sequence[{count, aseq}][`FETCH_BIT];
     count <= (fetch)? 2'd0 : (count + 1'b1);
  end
end

assign iseq[`FETCH_BIT-1:0] = sequence[{count, aseq}][`FETCH_BIT-1:0];

endmodule

module clkdivider(
  input   RESET,
  input   clk,
  output  clk_div,
  output  clk_min
);
reg [28:0]cnt = 29'd0;
always@(posedge clk or posedge RESET) begin
  if(RESET) begin
     cnt <= 0;
  end else begin
     cnt[28:0]   <=  cnt[28:0] +   1'b1;
  end
end

// cnt[25] - делитель clk/16777215, т.е. каждые 1,43Hz или 0,69 раз в секунду 
assign clk_div = cnt[12];
assign clk_min = cnt[25];
endmodule

module serialdebug(
  input   RESET,
  input   clk,
  input   clk_div,
  output  TxPin,
  output  reg [10:0]RequestAddress,
  input   [7:0]RequestDATA
);

wire txbusy;
reg  sendbyte = 1'b0;
reg  Tpulse = 1'b0;
reg  [7:0]UART_DATA;
/*
 Lookup table for Start
 Tpulse = 0 1, clk_1_43Hz = 0   => Start = 0
 Tpulse = 0 1, clk_1_43Hz = 1   => Start = 1
 Tpulse = 1 0, clk_1_43Hz = 1   => Start = 0
 Tpulse = 1 0, clk_1_43Hz = 0   => Start = 0
*/
wire Start = !Tpulse & clk_div;

always@(posedge clk or posedge RESET) begin
  if(RESET) begin
     sendbyte <= 1'b0;
     Tpulse <= 1'b0;
  end else begin
     Tpulse <= clk_div;
     sendbyte <= (sendbyte)? !txbusy : Start;  
  end
end

`define     STAGE_HEADER        3'b000
`define     STAGE_ADDRESS       3'b001
`define     STAGE_SPACE         3'b010
`define     STAGE_DATA_HI       3'b011
`define     STAGE_DATA_LO       3'b100
`define     STAGE_NOP           3'b101
`define     STAGE_TRAIL         3'b110

reg [2:0]uart_stage; 
//reg [9:0]uart_address_from;
reg [3:0]ADDR_STOP;
reg [15:0]ADDR_SHIFT;

always@(posedge sendbyte or posedge RESET) begin 
  if(RESET) begin
    uart_stage <= 3'b110;
    RequestAddress <= 10'd0;
    ADDR_STOP <= 4'd0;
  end else begin
    if(uart_stage == `STAGE_DATA_LO) RequestAddress <= RequestAddress + 1'b1;
    ADDR_STOP <= (uart_stage == `STAGE_HEADER)?   4'b0001 : {ADDR_STOP[2:0], 1'b0};
    ADDR_SHIFT <= (uart_stage == `STAGE_HEADER)?  RequestAddress : {ADDR_SHIFT[11:8], ADDR_SHIFT[7:4], ADDR_SHIFT[3:0], 4'd0};
    uart_stage <= 
      ((uart_stage == `STAGE_NOP) & (RequestAddress[3:0] != 4'd0))? `STAGE_DATA_HI : 
      ((uart_stage == `STAGE_ADDRESS) & (ADDR_STOP[3] == 0))? `STAGE_ADDRESS :
      uart_stage + 1'b1;
  end 
end

wire [7:0]HEX_TABLE[15:0] = {"F", "E", "D", "C", "B", "A", "9", "8", "7", "6", "5", "4", "3", "2", "1", "0"};
wire [7:0]uart_out = 
 (uart_stage == `STAGE_HEADER)?      "$" : 
 (uart_stage == `STAGE_ADDRESS)?     HEX_TABLE[ADDR_SHIFT[15:12]] : 
 (uart_stage == `STAGE_SPACE)?       "#" : 
 (uart_stage == `STAGE_DATA_HI)?     HEX_TABLE[RequestDATA[7:4]] :
 (uart_stage == `STAGE_DATA_LO)?     HEX_TABLE[RequestDATA[3:0]] :
 (uart_stage == `STAGE_TRAIL)?       8'd13 : 
 " ";

serial_tx   UART_TX(.reset(RESET), .clk(clk), .sbyte(uart_out), .send(sendbyte), .tx(TxPin), .busy(txbusy));

endmodule 