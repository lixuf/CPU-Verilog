module commit(
//req通道
input req_vaild,
output reg req_ready,
input [31:0] r_in,





//rsp通道
output reg rsp_vaild,
input rsp_ready,



input clk,
input reset,




//men
input clk_50_0,
input clk_50_90,
input clk_150_0,//主时钟
input clk_150_90,



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
   output           mem_we_n ,
	output phy_clk,
	input phy_clk_90,
	
	
	//jc
	
input botton_jc_reset,
output led1,
output led2,
output led3,
output led4


);



//解码器 纯组合电路 
//输出的控制信号
//修改寄存器
wire [7:0] xbh_en;//在一级流水处锁存
wire [7:0] xbl_en;
wire [7:0] fir_reg_en;
wire [1:0] des_addr_en;
wire [1:0] sor_addr_en;
wire len_en;
wire [3:0] lr_en;
wire [3:0] hr_en;
wire [15:0] operand;
//指令部分
////ad
wire ad_en;
wire des;
wire [7:0] select;
////小波分解;fir滤波器指令;uart输出指令
wire xb_en;
wire fir_en;
wire uarto_en;
wire [7:0] channel;//控制ad通道
wire [1:0] source;//介质选择 10 ad 00 ram 01 ddr
//wire [7:0] select;
////中值滤波指令
wire zlb_en;
//wire [1:0] source;
////存储器搬移指令
wire move_en;
wire dir;
////中断等待指令
wire int_en;
////检测器启用指令
wire jc_en;
//wire [7:0] channel,


decoder dec(
.r_in(r_in),//输入指令


//输出的控制信号
//修改寄存器
.xbh_en(xbh_en),//在一级流水处锁存
.xbl_en(xbl_en),
. fir_reg_en(fir_reg_en),
. des_addr_en(des_addr_en),
. sor_addr_en(sor_addr_en),
. len_en(len_en),
. lr_en(lr_en),
. hr_en(hr_en),
.  operand(operand),
//指令部分
////ad
. ad_en(ad_en),
. des(des),
.  select(select),
////小波分解,fir滤波器指令,uart输出指令
. xb_en(xb_en),
. fir_en(fir_en),
. uarto_en(uarto_en),
. channel(channel),//控制ad通道
. source(source),//介质选择 10 ad 00 ram 01 ddr
//. [7:0] select,
////中值滤波指令
. zlb_en(zlb_en),
//. [1:0] source,
////存储器搬移指令
. move_en(move_en),
//. dir(dir),
////中断等待指令
. int_en( int_en),
////检测( int_en器启用指令
. jc_en(jc_en)
//. [7:0] channel,


);
reg read_quite;//触发后的

wire read_quit;//表明读完了 length为0 !!!!返回ready用

reg [3:0] state;
localparam idle_t = 4'b0;
wire reg_ready_en;

localparam reg_c=4'd1;
wire reg_next=(state==reg_c);
wire reg_req_vaild;
sirv_gnrl_dffr#(1) reg_dffr(reg_next,reg_req_vaild,clk,reset);


localparam xb=4'd2;
localparam fir=4'd4;
localparam zlb=4'd5;
localparam uarto=4'd6;
localparam jc=4'd7;
localparam int=4'd8;
localparam ad=4'd9;

wire int_next=(state==int);
wire int_vaild;
sirv_gnrl_dffr#(1) int_dffr(int_next,int_vaild,clk,reset);

localparam move=4'd9;

localparam wait_ready=4'd10;
wire reg_req_ready;
wire int_ready;

localparam rsp=4'd11;


wire [3:0] next_state={4{reg_ready_en}}&reg_c
                     |{4{xb_en}}&xb
							|{4{fir_en}}&fir
							|{4{zlb_en}}&zlb
							|{4{uarto_en}}&uarto
							|{4{jc_en}}&jc
							|{4{int_en}}&int
							|{4{move_en}}&move
							|{4{ad_en}}&ad
							;

always@(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  state<=4'b0;
  rsp_vaild<=1'b0;
  req_ready<=1'b0;
 end
 else
 begin
 case(state)
 
 idle_t:begin
   rsp_vaild<=1'b0;
	if(req_vaild)
	begin
	   req_ready<=1'b1;
		state<=next_state;
	end
 end
 
 reg_c:begin
  req_ready<=1'b0;
  state<=wait_ready;
 end
 
 
 wait_ready:begin
  if(reg_req_ready)
   state<=rsp;
 end
 
 int:begin
  req_ready<=1'b0;
  if(int_ready)
   state<=rsp;
 end
 
 move_en:begin
  req_ready<=1'b0;
  if(read_quit)
   state<=rsp;
 end
 
 uarto:begin
  req_ready<=1'b0;
  if(read_quit)
   state<=rsp;
 end
 
 jc:begin
  req_ready<=1'b0;
  state<=rsp;
 end
 
 fir:begin
   req_ready<=1'b0;
  if(read_quit)
   state<=rsp;
 end
 
 xb:begin
   req_ready<=1'b0;
  if(read_quit)
   state<=rsp;
 end
 
 ad:begin
    req_ready<=1'b0;
  if(read_quit)
   state<=rsp;
 end
 
 rsp:begin
  if(rsp_ready)
  begin
   rsp_vaild<=1'b0;
   state<=idle_t;
  end
  else if(~rsp_vaild)
   rsp_vaild<=1'b1;
 end
 
 default:begin
  state<=4'b0;
  req_ready<=1'b0;
  rsp_vaild<=1'b0;
 end
 
 endcase
 end
end
 
 




assign reg_ready_en=(//从regfile中挪出来的，表示有写reg发生
xbh_en[0]|
xbh_en[1]|
xbh_en[2]|
xbh_en[3]|
xbh_en[4]|
xbh_en[5]|
xbh_en[6]|
xbh_en[7]|
xbl_en[0]|
xbl_en[1]|
xbl_en[2]|
xbl_en[3]|
xbl_en[4]|
xbl_en[5]|
xbl_en[6]|
xbl_en[7]|
fir_reg_en[0]|
fir_reg_en[1]|
fir_reg_en[2]|
fir_reg_en[3]|
fir_reg_en[4]|
fir_reg_en[5]|
fir_reg_en[6]|
fir_reg_en[7]|
des_addr_en[0]|
des_addr_en[1]|
sor_addr_en[0]|
sor_addr_en[1]|
len_en|
lr_en[0]|
lr_en[1]|
lr_en[2]|
lr_en[3]| 
hr_en[0]|
hr_en[1]|
hr_en[2]|
hr_en[3]
);

wire [15:0] xbh_reg0;
wire [15:0] xbh_reg1;
wire [15:0] xbh_reg2;
wire [15:0] xbh_reg3;
wire [15:0] xbh_reg4;
wire [15:0] xbh_reg5;
wire [15:0] xbh_reg6;
wire [15:0] xbh_reg7;
wire [15:0] xbl_reg0;
wire [15:0] xbl_reg1;
wire [15:0] xbl_reg2;
wire [15:0] xbl_reg3;
wire [15:0] xbl_reg4;
wire [15:0] xbl_reg5;
wire [15:0] xbl_reg6;
wire [15:0] xbl_reg7;
wire [15:0] fir_reg_reg0;
wire [15:0] fir_reg_reg1;
wire [15:0] fir_reg_reg2;
wire [15:0] fir_reg_reg3;
wire [15:0] fir_reg_reg4;
wire [15:0] fir_reg_reg5;
wire [15:0] fir_reg_reg6;
wire [15:0] fir_reg_reg7;
wire [15:0] des_addr_reg0;
wire [15:0] des_addr_reg1; 
wire [15:0] sor_addr_reg0;
wire [15:0] sor_addr_reg1;
wire [15:0] lreg_reg;
wire [15:0] lr_reg0;
wire [15:0] lr_reg1;
wire [15:0] lr_reg2;
wire [15:0] lr_reg3;
wire [15:0] hr_reg0;
wire [15:0] hr_reg1;
wire [15:0] hr_reg2;
wire [15:0] hr_reg3;

//寄存器组
 reg_file rf(

. clk( clk),

. reset( reset),

. ready( reg_req_ready),

. vaild( reg_req_vaild),

//输入
. xbh_en( xbh_en),

.  xbl_en(  xbl_en),

. fir_reg_en( fir_reg_en),

.  des_addr_en(  des_addr_en),

.  sor_addr_en(  sor_addr_en),

. len_en( len_en),

. lr_en( lr_en),

.  hr_en(  hr_en),

. operant( operand),
.ready_en(reg_ready_en),

//输出
.  xbh_reg0(  xbh_reg0),

.  xbh_reg1(  xbh_reg1),

.  xbh_reg2(  xbh_reg2),

.  xbh_reg3(  xbh_reg3),

.  xbh_reg4(  xbh_reg4),

.  xbh_reg5(  xbh_reg5),

.  xbh_reg6(  xbh_reg6),

.  xbh_reg7(  xbh_reg7),

.  xbl_reg0(  xbl_reg0),

.  xbl_reg1(  xbl_reg1),

.  xbl_reg2(  xbl_reg2),

.  xbl_reg3(  xbl_reg3),

.  xbl_reg4(  xbl_reg4),

.  xbl_reg5(  xbl_reg5),

.  xbl_reg6(  xbl_reg6),

.  xbl_reg7(  xbl_reg7),

.  fir_reg_reg0(  fir_reg_reg0),

.  fir_reg_reg1(  fir_reg_reg1),

.  fir_reg_reg2(  fir_reg_reg2),

.  fir_reg_reg3(  fir_reg_reg3),

.  fir_reg_reg4(  fir_reg_reg4),

.  fir_reg_reg5(  fir_reg_reg5),

. fir_reg_reg6( fir_reg_reg6),

.fir_reg_reg7(fir_reg_reg7),

.  des_addr_reg0 (  des_addr_reg0 ),

.  des_addr_reg1 (  des_addr_reg1 ),

. sor_addr_reg0( sor_addr_reg0),

. sor_addr_reg1( sor_addr_reg1),

.  lreg_reg(  lreg_reg),

.  lr_reg0(  lr_reg0),

. lr_reg1( lr_reg1),

.  lr_reg2(  lr_reg2),

. lr_reg3( lr_reg3),

.  hr_reg0(  hr_reg0),

.  hr_reg1(  hr_reg1),

.  hr_reg2(  hr_reg2),

.  hr_reg3( hr_reg3)
);


wire clkout;
wire [7:0] datain_uarto;
wire wrsig_uarto;
wire idle;

int_ins int1(
.int_en(int_en),
.vaild(int_vaild),//一直为高 直到ready回去
.ready(int_ready),

.clk(clk),
.clk50(clk50),
.reset(reset),
.button(botton),
.tx(tx),
.button_start(button_start),
.  xbh_reg0(  xbh_reg0),

.  xbh_reg1(  xbh_reg1),

.  xbh_reg2(  xbh_reg2),

.  xbh_reg3(  xbh_reg3),

.  xbh_reg4(  xbh_reg4),

.  xbh_reg5(  xbh_reg5),

.  xbh_reg6(  xbh_reg6),

.  xbh_reg7(  xbh_reg7),

.  xbl_reg0(  xbl_reg0),

.  xbl_reg1(  xbl_reg1),

.  xbl_reg2(  xbl_reg2),

.  xbl_reg3(  xbl_reg3),

.  xbl_reg4(  xbl_reg4),

.  xbl_reg5(  xbl_reg5),

.  xbl_reg6(  xbl_reg6),

.  xbl_reg7(  xbl_reg7),

.  fir_reg_reg0(  fir_reg_reg0),

.  fir_reg_reg1(  fir_reg_reg1),

.  fir_reg_reg2(  fir_reg_reg2),

.  fir_reg_reg3(  fir_reg_reg3),

.  fir_reg_reg4(  fir_reg_reg4),

.  fir_reg_reg5(  fir_reg_reg5),

. fir_reg_reg6( fir_reg_reg6),

.fir_reg_reg7(fir_reg_reg7),

.  des_addr_reg0 (  des_addr_reg0 ),

.  des_addr_reg1 (  des_addr_reg1 ),

. sor_addr_reg0( sor_addr_reg0),

. sor_addr_reg1( sor_addr_reg1),

.  lreg_reg(  lreg_reg),

.  lr_reg0(  lr_reg0),

. lr_reg1( lr_reg1),

.  lr_reg2(  lr_reg2),

. lr_reg3( lr_reg3),

.  hr_reg0(  hr_reg0),

.  hr_reg1(  hr_reg1),

.  hr_reg2(  hr_reg2),

.  hr_reg3( hr_reg3),
.clkout(clkout),
.datain_uarto(datain_uarto),
.uarto_en(uarto_en),
.wrsig_uarto(wrsig_uarto),
.idle(idle) 

);


//!!!!!由各个数据通路直接给出
reg start;//指明一个需要写或读的指令开始执行了，需要清除fifo并锁存数据，严格保持一个clk
always @(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  start<=1'b0;
 end
 else if(req_vaild&(idle_t==idle_t))
 begin
  start<=1'b1;
 end
 else
  begin
  start<=1'b0;
 end
end

wire read;//读请求--由各个通路给出，先通过选择器选择
wire write;//写请求

wire [15:0] pro_length=lreg_reg;//处理长度，以16bit为单位，每次读满一个fifo减16，控制读介质，写介质由写逻辑控制


wire [15:0] write_data;//写入的数据
wire if_write_ram=zlb_en|fir_en|xb_en|ad_en;//是否用ram做为写介质
wire write_source=(if_write_ram)?1'b1:~source[0];//写介质选择 1 ram 0 ddr
wire write_ddr_en;//表示此时ddr可否被写入
wire [31:0] wr_start_addr={des_addr_reg1,des_addr_reg0};

wire [1:0] read_source=source;//读介质选择 00ddr 01ram 10ad 
wire read_ready;//读请求后等待返回ready，ready置高的同时给出读出的数据

wire [15:0] read_data;//读出的数据;看一看时序 应该能正常存下
wire [31:0] rd_start_addr={sor_addr_reg1,sor_addr_reg0};

men_top men1(
.mem_we_n(mem_we_n),
.req_vaild(req_vaild),
.clk_50_0(clk_50_0),    
.clk_50_90(clk_50_90),
.clk_150_0(clk_150_0),
.clk_150_90(clk_150_90),
.reset(reset),
.start(start),
.read(read),
.write(write),
.pro_length(pro_length),
.write_data(write_data),
.write_source(write_source),
.write_ddr_en(write_ddr_en),
.wr_start_addr(wr_start_addr),
.read_source(read_source),
.read_ready(read_ready),
.read_quit(read_quit),
.read_data(read_data),
.rd_start_addr(rd_start_addr),
.channel(channel),
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
////!!!!!各个模块的读写为归一书写，写完记得需要组合



wire uarto_read_req;
uarto_top uarto_top1(
.clk_150_0(clk_150_0),
.start_req(uarto_en),
.end_req(read_quit),
.read_req(uarto_read_req),
.read_vaild(read_ready),
.read_data(read_data),
.clkout(clkout),
.reset(reset),
.datain_uarto(datain_uarto),
.wrsig_uarto(wrsig_uarto),
.idle(idle)
);


wire move_read_req;
wire move_write_req;
wire [15:0] move_write_data;
move move1(
.clk(clk_150_0),
.reset(reset),
.write_source(write_source),
.move_en(move_en),
.read_quite(read_quit),
.read_req(move_read_req),
.read_ready(read_ready),
.read_data(read_data),
.write_req(move_write_req),
.write_data(move_write_data),
.write_ddr_en(write_ddr_en)
);


wire ad_read_req;
wire ad_write_req;
wire [15:0] ad_write_data;
ad_top ad_top1(
.clk(clk_150_0),
.reset(reset),
.ad_en(ad_en),
.read_quite(read_quit),
.read_req(ad_read_req),
.read_ready(read_ready),
.read_data(read_data),
.write_req(ad_write_req),
.write_data(ad_write_data)
);


wire fir_read_req;
wire fir_write_req;
wire [15:0] fir_write_data;
fir_top fir_top1
(
.clk(clk_150_0),
.reset(reset),
.fir_en(fir_en),
.read_quit(read_quit),
.read_req(fir_read_req),
.read_ready(read_ready),
.read_data(read_data),
.write_req(fir_write_req),
.write_data(fir_write_data),

.fir_reg_reg0(fir_reg_reg0),
.fir_reg_reg1(fir_reg_reg1),
.fir_reg_reg2(fir_reg_reg2),
.fir_reg_reg3(fir_reg_reg3),
.fir_reg_reg4(fir_reg_reg4),
.fir_reg_reg5(fir_reg_reg5),
.fir_reg_reg6(fir_reg_reg6),
.fir_reg_reg7(fir_reg_reg7)
);




wire xb_read_req;
wire xb_write_req;
wire [15:0] xb_write_data;
xb_top xb_top1
(
.clk(clk_150_0),
.reset(reset),
.xb_en(xb_en),
.read_quit(read_quit),
.select(select),
.read_req(xb_read_req),
.read_ready(read_ready),
.read_data(read_data),
.write_req(xb_write_req),
.write_data(xb_write_data),
.xbl_reg0(xbl_reg0),
.xbl_reg1(xbl_reg1),
.xbl_reg2(xbl_reg2),
.xbl_reg3(xbl_reg3),
.xbl_reg4(xbl_reg4),
.xbl_reg5(xbl_reg5),
.xbl_reg6(xbl_reg6),
.xbl_reg7(xbl_reg7),
.xbh_reg0(xbh_reg0),
.xbh_reg1(xbh_reg1),
.xbh_reg2(xbh_reg2),
.xbh_reg3(xbh_reg3),
.xbh_reg4(xbh_reg4),
.xbh_reg5(xbh_reg5),
.xbh_reg6(xbh_reg6),
.xbh_reg7(xbh_reg7)
);


jc jc1(
.jc_en(jc_en),
.clk(clk_150_0),
.reset(reset),
.botton(botton),
.led1(led1),
.led2(led2),
.led3(led3),
.led4(led4),
.xb_write_data(xb_write_data),
.fir_write_data(fir_write_data),
.xb_write_req(xb_write_req),
.fir_write_req(fir_write_req),
.lr_reg0(lr_reg0),
.lr_reg1(lr_reg1),
.lr_reg2(lr_reg2),
.lr_reg3(lr_reg3),
.hr_reg0(hr_reg0),
.hr_reg1(hr_reg1),
.hr_reg2(hr_reg2),
.hr_reg3(hr_reg3)
);

assign read=xb_read_req|fir_read_req|ad_read_req|move_read_req|uarto_read_req;
assign write=xb_write_req|fir_write_req|ad_write_req|move_write_req;
assign write_data=({16{xb_write_req}}&xb_write_data)|({16{fir_write_req}}&fir_write_data)|({16{ad_write_req}}&ad_write_data)|({16{move_write_req}}&move_write_data);


endmodule
