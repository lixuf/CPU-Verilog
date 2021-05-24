module commit_test_top(
input reset,
//uart
output tx,
input clk50,
input botton,//按下后清除中断，继续下一个流水
input button_start,//按下后才开始输出
////ad

input [15:0] 		ad_data,            //ad7606 采样数据
input        		ad_busy,            //ad7606 忙标志位 
input        		first_data,         //ad7606 第一个数据标志位 	    
output [2:0] 		ad_os,              //ad7606 过采样倍率选择
output  		ad_cs,              //ad7606 AD cs
output    		ad_rd,              //ad7606 AD data read
output    		ad_reset,           //ad7606 AD reset
output   		ad_convstab,       //ad7606 AD convert start
////ddr
output  [ 14: 0] mem_addr,
output  [  2: 0] mem_ba,
   output           mem_cas_n,
   output  [  0: 0] mem_cke,
   inout   [  0: 0] mem_clk,
   inout   [  0: 0] mem_clk_n,
   output  [  0: 0] mem_cs_n,
   output  [  1: 0] mem_dm,
   inout   [ 15: 0] mem_dq,
   inout   [  1: 0] mem_dqs,
   output  [  0: 0] mem_odt,
   output           mem_ras_n,
   output           mem_we_n 


);

//pllip 150 150_90 50_90
//pllip2 in:phy  out:phy_90
wire clk_50_0;
wire clk_50_90;
wire clk_150_0;//主时钟
wire clk_150_90;
wire clk;
wire req_vaild;
wire req_ready;
wire [31:0] r_in;





//rsp通道
reg rsp_vaild;
wire rsp_ready;
wire phy_clk;
wire phy_clk_90;



commit commit1(
.req_vaild(req_vaild),
.req_ready(req_ready),
.r_in(r_in),
.rsp_vaild(rsp_vaild),
.rsp_ready(rsp_ready),
.clk(clk),
.reset(reset),
.clk_50_0(clk_50_0),
.clk_50_90(clk_50_90),
.clk_150_0(clk_150_0),
.clk_150_90(clk_150_90),
.tx(tx),
.clk50(clk50),
.botton(botton),
.button_start(button_start),
.ad_data(ad_data),
.ad_busy(ad_busy),
.first_data(first_data),
.ad_os(ad_os),
.ad_cs(ad_cs),
.ad_rd(ad_rd),
.ad_reset(ad_reset),
.ad_convstab(ad_convstab),
.mem_addr(mem_addr),
.mem_ba(mem_ba),
.mem_cas_n(mem_cas_n),
.mem_cke(mem_cke),
.mem_clk(mem_clk),
.mem_clk_n(mem_clk_n),
.mem_cs_n(mem_cs_n),
.mem_dm(mem_dm),
.mem_dq(mem_dq),
.mem_dqs(mem_dqs),
.mem_odt(mem_odt),
.mem_ras_n(mem_ras_n),
.phy_clk_90(phy_clk_90),
.phy_clk(phy_clk)
);




endmodule
