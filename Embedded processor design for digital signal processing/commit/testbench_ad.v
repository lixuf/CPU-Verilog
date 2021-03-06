`timescale 1ns/1ps
module testbench_ad;
reg clk;
reg reset_in;
wire phy_clk;


always #10 clk<=~clk;

wire clk_50_0=clk;








//req通道
reg req_vaild;
wire req_ready;
reg [31:0] r_in;





//rsp通道
wire rsp_vaild;
reg rsp_ready;






//uart
wire tx;
reg botton;//按下后清除中断，继续下一个流水
reg button_start;//按下后才开始输出
////ad

reg [15:0] 		ad_data;            //ad7606 采样数据
reg        		ad_busy;            //ad7606 忙标志位 
reg        		first_data;         //ad7606 第一个数据标志位 	    
wire [2:0] 		ad_os;              //ad7606 过采样倍率选择
wire  		ad_cs;              //ad7606 AD cs
wire    		ad_rd;              //ad7606 AD data read
wire    		ad_reset;           //ad7606 AD reset
wire   		ad_convstab;       //ad7606 AD convert start
////ddr
wire  [ 14: 0] mem_addr;
wire  [  2: 0] mem_ba;
wire           mem_cas_n;
wire  [  0: 0] mem_cke;
wire  [  0: 0] mem_cs_n;
wire  [  1: 0] mem_dm;
wire  [  0: 0] mem_odt;
wire           mem_ras_n;
wire           mem_we_n ;

reg start;

initial begin
ad_busy<=1'b0;
ad_data<=16'hf00f;
clk<=1'b0;
reset_in<=1'b1;
rsp_ready<=1'b0;
req_vaild<=1'b0;
botton<=1'b1;
button_start<=1'b1;
first_data<=1'b0;
start<=1'b0;
end




wire clk_50_90;
wire clk_150_0;
wire clk_150_90;
wire phy_clk_90;

wire reset;
wire done;

clk_manger clk_manger(
.clk_50_0(clk_50_0),
.reset_in(reset_in),
.phy_clk(phy_clk),
.start(start),
.clk_50_90(clk_50_90),
.clk_150_0(clk_150_0),
.clk_150_90(clk_150_90),
.phy_clk_90(phy_clk_90),
.done(done)
);

reg [31:0] cnt;
reg [31:0] cnt_r;
reg [31:0] r[31:0];
initial begin
$stop;
cnt<=32'b0;
cnt_r<=32'b0;
r[0]<=32'b0000000_00_1010100101010010_0001011;
r[1]<=32'b0100000_00_0000000000000101_0001011;
r[2]<=32'b0011100_0000000000_11111111_0001011;
end


always@(posedge clk_150_0)
begin
  if(done)
  begin
  case(cnt)
  32'd0:begin
   req_vaild<=1'b1;
	r_in<=r[cnt_r];
	cnt<=cnt+1;
  end
  
  32'b1:begin
	if(req_ready)
	begin
	 req_vaild<=1'b0;
	 cnt<=cnt+1;
	end
	end
	 
	32'd2:begin
	 if(rsp_vaild)
	 begin
	  rsp_ready<=1'b1;
	  cnt<=cnt+1;
	 end
   end
	
	32'd3:begin
	  rsp_ready<=1'b0;
	  cnt<=cnt+1;
	end
	
	32'd4:begin
	 $stop;
	 cnt<=0;
	 cnt_r<=cnt_r+1;
	end
	
	endcase
	
  end
  
end


reg [31:0] cnt_b;
initial begin
cnt_b<=32'b0;
#5
reset_in<=1'b0;
#25
reset_in<=1'b1;
#25
start<=1'b1;
#87000
botton<=1'b0;
#30
$stop;
end


initial begin
#330
button_start<=1'b0;
#20
button_start<=1'b1;
end

commit commit1(
.req_vaild(req_vaild),
.req_ready(req_ready),
.r_in(r_in),
.rsp_vaild(rsp_vaild),
.rsp_ready(rsp_ready),
.clk(clk_150_0),
.reset(reset_in),
.clk_50_0(clk_50_0),
.clk_50_90(clk_50_90),
.clk_150_0(clk_150_0),
.clk_150_90(clk_150_90),
.tx(tx),
.clk50(clk),
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
.phy_clk_90(phy_clk_90)
);

endmodule
