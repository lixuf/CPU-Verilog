module clk_manger(
input clk_50_0,
input reset_in,
input phy_clk,
input start,

output clk_50_90,
output clk_150_0,
output clk_150_90,
output phy_clk_90,

output reset,
output done,
output reset_150_90
);
wire pll1_lock;
pllip pll1(
	.areset(),
	.inclk0(clk_50_0),
	.c0(clk_150_0),
.	c1(clk_150_90),
	.c2(clk_50_90),
	.locked(pll1_lock)
	);

wire pll2_lock;
pllip2 pll2
(
	.areset(),
	.inclk0(phy_clk),
	.c0(phy_clk_90),
	.locked(pll2_lock)
	);


reg flag;
always@(posedge clk_50_0)
begin
 if(~reset)
 begin
  flag<=1'b0;
 end
 else if(~start)
 begin
  flag<=1'b1;
 end
end

wire reset_150_90_t;
sirv_gnrl_dffr#(1) reset_150_90_dffr (1'b1,reset_150_90_t,clk_150_90,reset_in);
sirv_gnrl_dffrs#(1) reset_150_90_dffrs (reset_150_90_t,reset_150_90,clk_150_90,reset_in);
assign reset=reset_in;
assign done=pll2_lock&pll1_lock&flag;//仿真无phy clk因此要去掉
//assign done=pll1_lock&flag;
endmodule
