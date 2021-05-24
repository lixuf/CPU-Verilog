`timescale 1ns/1ps
module testbench;
reg clk;
reg reset;
reg start;
initial begin
clk<=1'b0;
reset<=1'b1;
start<=1'b0;
#10
reset<=1'b0;
#10
reset<=1'b1;
#2
start<=1'b1;
end
always #2 clk<=~clk&start;


reg req_vaild;
reg [31:0] r_in;
initial begin
r_in<=32'b0;
req_vaild<=1'b0;
end



initial begin
$stop;
#26
req_vaild<=1'b1;
r_in<=32'b01000100110001111101100100010110;
#29
req_vaild<=1'b1;
r_in<=32'b01000011010000100010100110001010;
#30
req_vaild<=1'b1;
r_in<=32'b00111111011001010011001100100010;
#30
req_vaild<=1'b1;
r_in<=32'b01010110110010000111110100110011;
#30
req_vaild<=1'b1;
r_in<=32'b00111011011111010011011011111101;
#30
req_vaild<=1'b1;
r_in<=32'b00111101010111100100110111110011;
#30
req_vaild<=1'b1;
r_in<=32'b01011000001100000011010110111001;
#30
req_vaild<=1'b1;
r_in<=32'b00111001101111001110111101111111;
#30
req_vaild<=1'b1;
r_in<=32'b00000001101010101010011101011100;
#30
req_vaild<=1'b1;
r_in<=32'b00000011001001010100010101101011;
#30
req_vaild<=1'b1;
r_in<=32'b00000100111010101010110000010101;
#30
req_vaild<=1'b1;
r_in<=32'b00000110111100010101111001110111;
#30
req_vaild<=1'b1;
r_in<=32'b00001000010101001000001000010101;
#30
req_vaild<=1'b1;
r_in<=32'b00001010101111100100000101101111;
#30
req_vaild<=1'b1;
r_in<=32'b00001100101110000000011100100111;
#30
req_vaild<=1'b1;
r_in<=32'b00001110010111001001101001000010;
#30
req_vaild<=1'b1;
r_in<=32'b00010001010000010111010101110010;
#30
req_vaild<=1'b1;
r_in<=32'b00010010000101100100110111110110;
#30
req_vaild<=1'b1;
r_in<=32'b00010100100010110010001000100011;
#30
req_vaild<=1'b1;
r_in<=32'b00010110101111101011011111100100;
#30
req_vaild<=1'b1;
r_in<=32'b00011000100001101100011010000000;
#30
req_vaild<=1'b1;
r_in<=32'b00011010011100100101110101010010;
#30
req_vaild<=1'b1;
r_in<=32'b00011101000000100000010010110100;
#30
req_vaild<=1'b1;
r_in<=32'b00011110010001100001111011100100;
#30
req_vaild<=1'b1;
r_in<=32'b00100001110100011000010100000101;
#30
req_vaild<=1'b1;
r_in<=32'b00100011110001011100011111010001;
#30
req_vaild<=1'b1;
r_in<=32'b00100100101000011101110100111000;
#30
req_vaild<=1'b1;
r_in<=32'b00100111100101001010101101010101;
#30
req_vaild<=1'b1;
r_in<=32'b00101001111010001110011000111011;
#30
req_vaild<=1'b1;
r_in<=32'b00101010011001000010111100001110;
#30
req_vaild<=1'b1;
r_in<=32'b00101100010000000101100000111000;
#30
req_vaild<=1'b1;
r_in<=32'b00101111101110110101100001010000;
#30
req_vaild<=1'b1;
r_in<=32'b00110001100100000101111110011101;
#30
req_vaild<=1'b1;
r_in<=32'b00110010101111010001101110100000;
#30
req_vaild<=1'b1;
r_in<=32'b00110101100001010011010010000100;
#30
req_vaild<=1'b1;
r_in<=32'b00110111110000111001100111001100;
#30
req_vaild<=1'b1;
r_in<=32'b01000001110111010110111111101000;
#30
req_vaild<=1'b1;
r_in<=32'b01000110101011011001111010101001;
#30
req_vaild<=1'b1;
r_in<=32'b01001000101101111000110110000001;
#30
req_vaild<=1'b1;
r_in<=32'b01001010101101100100001100001110;
#30
req_vaild<=1'b1;
r_in<=32'b01001100110011101111110101101001;
#30
req_vaild<=1'b1;
r_in<=32'b01001110010101110101101010000101;
#30
req_vaild<=1'b1;
r_in<=32'b01010001011000001101011110101011;
#30
req_vaild<=1'b1;
r_in<=32'b01010010010110111111001100001110;
#30
req_vaild<=1'b1;
r_in<=32'b01010101111001010111100101101110;
$stop;
end


reg req_vaild_t;
reg [1:0] cnt_t;
initial begin
req_vaild_t<=1'b0;
cnt_t<=2'b0;
end
always@(posedge clk)
begin
 if(req_vaild_t)
  req_vaild_t<=1'b0;
 if(req_vaild)
 begin 
  cnt_t<=cnt_t+2'b1;
  req_vaild<=1'b0;
 end
 else if(cnt_t==2'b1)
 begin
  req_vaild_t<=1'b1;
  cnt_t<=2'b0;
 end
 
end

wire req_ready;
wire rsp_vaild;
commit cmmo(
//req通道
.req_vaild(req_vaild_t),
.req_ready(req_ready),
.r_in(r_in),





//rsp通道
.rsp_vaild(rsp_vaild),
.rsp_ready(1'b1),



.clk(clk),
.reset(reset)
);

endmodule


