`timescale 1ns/1ps
module testbench_ram;
reg clk;
initial begin
clk<=1'b0;
end
always #3 clk<=~clk;

reg [15:0] data;
wire [15:0] q;
reg wren;
reg [11:0] raddr;
reg [11:0] waddr;
initial begin
data<=16'b0;
wren<=1'b0;
raddr<=12'b0;
waddr<=12'b0;
#2
wren<=1'b1;
waddr<=11'd10;
data<=16'hffff;
#2
wren<=1'b0;
raddr<=11'd10;
#4
raddr<=11'd11;
#4
$stop;
end

ramip ram1(
	.clock(clk),
	.data(data),
	.rdaddress(raddr),
	.wraddress(waddr),
	.wren(wren),
	.q(q)
	);
	
endmodule
