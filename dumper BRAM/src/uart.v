// последовательный приемник
// 38400бит/сек
// 8бит, без четности
//скорость приема и передачи определяется этой константой
// 10'000'000/115200 = 86,80555555555556 ~ 87 (7bit)
// 3'000'000/115200 = 26,04166666666667 ~ 26 (5bit)
// 3'125'000/115200 = 27,12673611111111 ~ 27 (5bit)     
//  2'500'000/115200 = 21,70138888888889 ~ 22 (5bit)  DIV[3]
//  1'250'000/115200 = 10,85
//  1'250'000/57600 = 21,70138888888889 ~ 27
//  1'024'000/115200 = 8.8(8)
module serial_rx(
    input reset,
    input clk,
    input rx,
    output [7:0]rxbyte,
    output ready
);
parameter RCONST =  208; //10; //21; //86; //109; //325; 

reg [8:0]shift_reg = 0;     //сдвиговый регистр приемника
reg [7:0]cnt = 0;           //счетчик предделитель битрейта
reg recv_edge = 1'b0;
reg RDY = 1'b1;

wire RXMx = (RDY)? rx : shift_reg[0];
wire RSTT = ({RDY, RXMx} == 2'b11)? 1'b1 : 1'b0;
wire recv_edge_t = (cnt == ((RCONST/2) - 1));
wire recv_time = (cnt == RCONST);

assign rxbyte = shift_reg[7:0];
assign ready = RSTT & recv_edge;

/*always@(posedge recv_edge or posedge reset) begin
    if(reset) 
        RDY <= 1'b1;
    else
        RDY <= RXMx;
end*/
always@(posedge clk or posedge reset) begin
    if(reset)
       recv_edge <= 1'b0;
    else
       recv_edge <= recv_edge_t;
end

always@(posedge recv_edge or posedge reset) begin
    if(reset) begin
        shift_reg <= 0;
        RDY <= 1'b1;
    end else begin
      RDY <= RXMx;
      if(RDY) 
          shift_reg <= 9'b1_0000_0000;
      else
          shift_reg[8:0] <= {rx|RDY, shift_reg[8:1]};
    end
end

always@(posedge clk or posedge reset) begin
    if(reset)
        cnt <= 0;
    else
        cnt <= (recv_time | RSTT)? 0 : (cnt + 1'b1);   //счетчик длительности принимаемого бита
end
endmodule

// последовательный передатчик UART
// 115200 бод - 3125000/115200 = 27,12673611111111 ~ 27 (5bit)      DIV[3]
// 8бит, без четности
// 24'000'000/115200 = 208,3333333333333 ~ 209 (8bit)
// 12'500'000/115200 = 108,5069444444444 ~ 109 (7bit)
// 20'000'000/115200 = 173,6111111111111 ~ 174 (8bit)
// 10'000'000/115200 = 86,80555555555556 ~ 87 (7bit)
//  5'000'000/115200 = 43,40277777777778 ~ 43 (6bit)
// 3'000'000/115200 = 26,04166666666667 ~ 26 (5bit)
//  2'500'000/115200 = 21,70138888888889 ~ 22 (5bit)
//  1'250'000/115200 = 10,85
//  1'024'000/115200 = 8,8(8)
//  1'024'000/57600 = 17,7(7)
module serial_tx(
    input reset, 
    input clk,
    input [7:0]sbyte,
    input send,
    output tx,
    output busy
    );

parameter RCONST = 208; //8; //10; //21; //27; 

//передатчик
reg [9:0]send_reg = 10'b1_11111111_1;
reg [7:0]send_cnt = 0;

wire send_time = (send_cnt == RCONST);

assign tx = send_reg[0];
wire   [7:0]equ  = {8{send_reg[9]}} ^ send_reg[8:1];
wire   bsy = !(|equ);
assign busy = |equ;

reg carry;

always@(posedge clk or posedge reset) begin
     if(reset)
       send_cnt <= 0;
     else
       {carry, send_cnt} <= (send_time | send)? 0 : (send_cnt + 1'b1); 
end

always@(posedge clk or posedge reset)
begin
  if(reset)
    send_reg[9:0] <= 10'b1_11111111_1; 
  else begin
  //передача начинается по сигналу send
      if(send | send_time) begin 
            send_reg[8:1] <= (send)? sbyte : send_reg[9:2];
            send_reg[0] <= (send)? 1'b0 : send_reg[1]|bsy;
      end
      if(send) begin
            send_reg[9] <= !sbyte[7];
      end
  end
end
endmodule 