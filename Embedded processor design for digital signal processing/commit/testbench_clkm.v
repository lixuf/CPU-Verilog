`timescale 1ns/1ps
module testbench_clkm;

reg clk_50_0;
reg reset_in;
reg phy_clk;
reg start;


initial begin
$stop;
clk_50_0<=1'b0;
reset_in<=1'b1;
phy_clk<=1'b0;
start<=1'b1;
end

always #10 clk_50_0<=~clk_50_0;
always #2.99 phy_clk<=~phy_clk;

initial begin
#10
reset_in<=1'b0;
#30
reset_in<=1'b1;
#10000
start<=1'b0;
#30
start<=1'b1;
#40
reset_in<=1'b0;
#40
reset_in<=1'b1;
#10
$stop;
end

wire clk_50_90;
wire clk_150_0;
wire clk_150_90;
wire phy_clk_90;

wire reset;
wire done;
wire reset_150_90;



clk_manger clk_manger1(
.clk_50_0(clk_50_0),
.reset_in(reset_in),
.phy_clk(phy_clk),
.start(start),
.clk_50_90(clk_50_90),
.clk_150_0(clk_150_0),
.clk_150_90(clk_150_90),
.phy_clk_90(phy_clk_90),
.reset(reset),
.done(done),
.reset_150_90(reset_150_90)
);
endmodule
