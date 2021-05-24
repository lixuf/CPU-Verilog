module e203_test_top
(
input start_whole,

input clk,
input reset_in,

//uart
output tx,

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
   output           mem_we_n ,

	
	//jc
	
input botton_jc_reset,
output led1,
output led2,
output led3,
output led4,

input rx,

//sim 记得最后去掉
output clk_150_0_s,
output [2:0] state_top_s,
output done_s,
output [31:0] r_in_s
);

wire phy_clk;
reg start_r;
always @(posedge clk or negedge reset_in)
begin
 if(~reset_in)
  start_r<=1'b0;
 else if(~start_whole)
  start_r<=1'b1;
end


//req通道
reg req_vaild;
wire req_ready;






//rsp通道
wire rsp_vaild;
reg rsp_ready;

wire reset_150_90;
wire done;
wire phy_clk_90;
wire clk_50_0=clk;
wire clk_50_90;
wire clk_150_0;//主时钟
assign clk_150_0_s=clk_150_0;//sim
wire clk_150_90;
wire clk50=clk;
wire reset;

reg[3:0] rdaddress;
wire tx_r;
wire tx_c;
wire [31:0] r_in;
assign r_in_s=r_in;
//总控
reg [2:0] state_top;
assign state_top_s=state_top;//sim
localparam recv_r=3'b0;
localparam send_evaild=3'b1;
localparam wait_eready=3'd2;
localparam wait_read=3'd3;
localparam wait_svaild=3'd4;
always@(posedge clk_150_0 or negedge  reset)
begin
 if(~reset)
 begin 
  rsp_ready<=1'b0;
  req_vaild<=1'b0;
  state_top<=3'b0;
  rdaddress<=4'b0;
 end
 else begin
 case(state_top)
 
 recv_r:begin
 rdaddress<=4'b0;
 rsp_ready<=1'b0;
 req_vaild<=1'b0;
 if(start_r)
 begin
  state_top<=wait_read;
 end
 end
 
 wait_read:begin
  state_top<=send_evaild;
 end
 
 send_evaild:begin
  rsp_ready<=1'b0;
  req_vaild<=1'b1;
  state_top<=wait_eready;
 end
 
 wait_eready:begin
  if(req_ready)
  begin
   req_vaild<=1'b0;
	state_top<=wait_svaild;
  end
end

 wait_svaild:begin
  if(rsp_vaild)
  begin
   rsp_ready<=1'b1;
	state_top<=wait_read;
	rdaddress<=rdaddress+4'b1;
  end
 end

 endcase
 end
 
 end

uart_r_ram uart_r_ram1(
.clk_50_0(clk),
.reset(reset),
.rx(rx),
.r_in(r_in),
.rdaddress(rdaddress),
.rdclock(clk_150_0),
.tx(tx_r)
);




wire start=botton_jc_reset;
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
assign done_s=done;//sim
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
.tx(tx_c),
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
.phy_clk(phy_clk),
.phy_clk_90(phy_clk_90),
.botton_jc_reset(botton_jc_reset),
.led1(led1),
.led2(led2),
.led3(led3),
.led4(led4)
);

wire state_top_is_recv=(state_top==recv_r);
assign tx=(state_top_is_recv&tx_r)
|((~state_top_is_recv)&tx_c);
endmodule
