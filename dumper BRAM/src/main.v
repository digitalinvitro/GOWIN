/*
  Test - ZERO
 do:   RAM region -> UART

   UART 115200/8/1
*/
module main(
    input   B_button,        // B_button - active LOW (общий при замыкании), подятнута к VCC
    input   clk,             // clk - 24MHz тактовый сигнал генератора
    output  ledG,
    output  ledR,
    output  ledB,
    output  TXpin
);


wire RESET = !B_button;  

reg [28:0]cnt = 29'd0;
always@(posedge clk or posedge RESET) begin
  if(RESET) begin
     cnt <= 0;
  end else begin
     cnt[28:0]   <=  cnt[28:0] +   1'b1;
  end
end

// cnt[25] - делитель clk/16777215, т.е. каждые 1,43Hz или 0,69 раз в секунду 
wire clk_1_43Hz = cnt[12];
reg [31:0]R[7:0];

assign  ledG = clk_1_43Hz;
assign  ledR = (clk_1_43Hz)? !DATA[12] : 1'b1;
assign  ledB = (clk_1_43Hz)? !DATA[13] : 1'b1;

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
wire Start = !Tpulse & clk_1_43Hz;

always@(posedge clk or posedge RESET) begin
  if(RESET) begin
     sendbyte <= 1'b0;
     Tpulse <= 1'b0;
  end else begin
     Tpulse <= clk_1_43Hz;
     sendbyte <= (sendbyte)? !txbusy : Start;  
  end
end

`define     STAGE_HEADER        3'b000
`define     STAGE_ADDRESS_HI    3'b001
`define     STAGE_ADDRESS_LO    3'b010
`define     STAGE_SPACE         3'b011
`define     STAGE_DATA_HI       3'b100
`define     STAGE_DATA_LO       3'b101
`define     STAGE_NOP           3'b110
`define     STAGE_TRAIL         3'b111

//reg [3:0]uart_counter;
reg [2:0]uart_stage; 
reg [9:0]uart_address_from;

always@(posedge sendbyte or posedge RESET) begin 
  if(RESET) begin
//    uart_counter <= 4'd0;
    uart_stage <= 3'b110;
    uart_address_from <= 10'd0;
  end else begin
    if(uart_stage == `STAGE_DATA_LO) begin
//        uart_counter <=  uart_counter + 1'b1;
        uart_address_from <= uart_address_from + 1'b1;
    end;
    uart_stage <= ((uart_stage == `STAGE_NOP) & (uart_address_from[3:0] != 4'd0))? `STAGE_DATA_HI : uart_stage + 1'b1;
  end 
end

wire [7:0]HEX_TABLE[15:0] = {"F", "E", "D", "C", "B", "A", "9", "8", "7", "6", "5", "4", "3", "2", "1", "0"};
wire [7:0]uart_out = 
 (uart_stage == `STAGE_HEADER)?      "$" : 
 (uart_stage == `STAGE_ADDRESS_HI)?  HEX_TABLE[uart_address_from[7:4]] : 
 (uart_stage == `STAGE_ADDRESS_LO)?  HEX_TABLE[uart_address_from[3:0]] :
 (uart_stage == `STAGE_SPACE)?       "#" : 
 (uart_stage == `STAGE_DATA_HI)?     HEX_TABLE[DATA[7:4]] :
 (uart_stage == `STAGE_DATA_LO)?     HEX_TABLE[DATA[3:0]] :
 (uart_stage == `STAGE_NOP)?         " " : 
 8'd13;

serial_tx   UART_TX(.reset(RESET), .clk(clk), .sbyte(uart_out), .send(sendbyte), .tx(TXpin), .busy(txbusy));


wire [31:0]DATA;

SP bram_sp_0 (
.CLK(clk),
.OCE(1'b1),
.CE(1'b1),
.WRE(1'b0),
.RESET(1'b0),
.AD({ uart_address_from, 4'b0000 }),
.DI(32'hFFFFFFFF),
.DO({DATA[31:8],DATA[7:0]}),
.BLKSEL(3'b000) 
);

defparam bram_sp_0.READ_MODE = 1'b0;
defparam bram_sp_0.WRITE_MODE = 2'b00;
defparam bram_sp_0.BIT_WIDTH = 16;
defparam bram_sp_0.BLK_SEL = 3'b000;
defparam bram_sp_0.RESET_MODE = "SYNC";
//                                                                                    
defparam bram_sp_0.INIT_RAM_00 = 256'h00A000000000000B00A000000000000B00A000000000000B_FC7F_404D_FC7F_C845;
defparam bram_sp_0.INIT_RAM_01 = 256'h00A000000000000B00A000000000000B00A000000000000B00A000000000000B;
defparam bram_sp_0.INIT_RAM_3F = 256'h00A000000000000B00A000000000000B00A000000000000B00A000000000000B;

/* CPU */
wire [1:0]mode;
wire [4:0]operate;
wire [2:0]rA,rB,rC;

assign {mode,operate,rA,rB,rC} = DATA[15:0];

endmodule

