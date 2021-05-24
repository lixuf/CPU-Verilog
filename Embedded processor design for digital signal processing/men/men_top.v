module men_top(//对于存储器来说只要按照起始地址一直读即可，然后用处理长度控制读fifo读出的数据即可，每次fifo空了就取存储器取数据
input clk_50_0,
input clk_50_90,
input clk_150_0,//主时钟
input clk_150_90,
input reset,

input start,//指明一个需要写或读的指令开始执行了，需要清除fifo并锁存数据，严格保持一个clk
input read,//读请求--由各个通路给出，先通过选择器选择
input write,//写请求,要严格保持一个clk

//下面三个数据都需要锁存住，动态更改
input [15:0] pro_length,//处理长度，以16bit为单位，每次读满一个fifo减16，控制读介质，写介质由写逻辑控制


input [15:0] write_data,//写入的数据
input write_source,//写介质选择 1 ram 0 ddr
output write_ddr_en,//表示此时ddr可否被写入
input [31:0] wr_start_addr,

input [1:0] read_source,//读介质选择 00ddr 01ram 10ad 
output read_ready,//读请求后等待返回ready，ready置高的同时给出读出的数据
output reg read_quit,//表明读完了 length为0
output reg [15:0] read_data,//读出的数据,看一看时序 应该能正常存下
input [31:0] rd_start_addr,


//ad
input [7:0] channel,//控制ad读通道'
input [15:0] 		ad_data,            //ad7606 采样数据
input        		ad_busy,            //ad7606 忙标志位 
input        		first_data,         //ad7606 第一个数据标志位 	    
output [2:0] 		ad_os,              //ad7606 过采样倍率选择
output  		ad_cs,              //ad7606 AD cs
output    		ad_rd,              //ad7606 AD data read
output    		ad_reset,           //ad7606 AD reset
output   		ad_convstab,       //ad7606 AD convert start


//ddr
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
	input req_vaild
	
);


wire is_ram_write=write&write_source;
wire is_ddr_write=write&(~write_source);

wire rd_addr_en;
wire [31:0] rd_addr;
wire [31:0] rd_addr_next=rd_addr+32'd1;
sirv_gnrl_dfflre #(32) rd_addr_dfflre(rd_addr_en,rd_addr_next,rd_addr,clk_150_0,reset&(~start),rd_start_addr);

wire wr_addr_en=is_ram_write;
wire [31:0] wr_addr;
wire [31:0] wr_addr_next=wr_addr+32'd1;
sirv_gnrl_dfflre #(32) wr_addr_dfflre(wr_addr_en,wr_addr_next,wr_addr,clk_150_0,reset&(~start),wr_start_addr);

wire length_en;
wire [15:0] length_r;
wire [15:0] length_next=length_r-16'd1;
sirv_gnrl_dfflre #(16) length_dfflre(length_en,length_next,length_r,clk_150_0,reset&(~start),pro_length);


reg [2:0] read_state;
localparam read_idle=3'b0;
reg length_en_t;
assign length_en=length_en_t;

localparam r_ad=3'd1;
wire data_flag;
reg ad_read;


localparam r_ddr=3'd2;
localparam r_ddr2=3'd4;
reg ddr_read;
wire read_en;
wire ddr_r_empty;//读端的fifo的空，不空就可以读

localparam r_ram=3'd3;
reg ram_cnt;
reg ram_read;
assign rd_addr_en=ram_read;

wire [2:0] next_state=({3{(read_source==2'b00)}}&r_ddr)
							|({3{(read_source==2'b01)}}&r_ram)
							|({3{(read_source==2'b10)}}&r_ad);

//输出到前一个模块							
assign read_ready=ddr_read|ram_read|ad_read;
wire [15:0] ad_read_data;
wire [15:0] ddr_read_data;
wire [15:0] ram_read_data;

always@(posedge clk_150_0 or negedge reset)
begin
 if(~reset)
 begin
  read_quit<=1'b0;
  read_state<=3'b0;
  length_en_t<=1'b0;
  ddr_read<=1'b0;
  ram_read<=1'b0;
  ad_read<=1'b0;
  read_data<=16'b0;
  ram_cnt<=1'b0;
 end
 else
 begin
 case(read_state)
 
 read_idle:begin
  ram_cnt<=1'b0;
  ram_read<=1'b0;
  ddr_read<=1'b0;
  ad_read<=1'b0;
  if(req_vaild)
  begin
   read_quit<=1'b0;
  end
  else if(read&(~read_quit))
  begin
   read_state<=next_state;
	length_en_t<=1'b1;
  end
  else
  begin
   length_en_t<=1'b0;
  end

 

 
 end
 
 r_ddr:begin
  if(length_r==16'b0)
 begin
  read_quit<=1'b1;
  read_state<=read_idle;
 end
 else
 begin
  read_quit<=1'b0;
 end
 length_en_t<=1'b0;
 if((read_en)&(read&(~read_quit)))
 begin
  ddr_read<=1'b1;
  read_state<=r_ddr2;
 end
 else
 begin
  ddr_read<=1'b0;
 end
 end
 
 r_ddr2:begin
  if(length_r==16'b0)
 begin
  read_quit<=1'b1;
  read_state<=read_idle;
 end
 else
 begin
  read_quit<=1'b0;
 end
 
  read_data<=ddr_read_data;
  ddr_read<=1'b0;
  read_state<=read_idle;
 end
 
 r_ram:begin
 if(length_r==16'b0)
 begin
  read_quit<=1'b1;
  read_state<=read_idle;
 end
 else
 begin
  read_quit<=1'b0;
 end
 if(ram_cnt) begin
  length_en_t<=1'b0;
  ram_read<=1'b1;
  read_data<=ram_read_data;
  read_state<=read_idle;
 end
 else
  ram_cnt<=1'b1;
 end
 
 r_ad:begin
  if(length_r==16'b0)
 begin
  read_quit<=1'b1;
  read_state<=read_idle;
 end
 else
 begin
  read_quit<=1'b0;
 end
  length_en_t<=1'b0;
  if(data_flag)
  begin
   ad_read<=1'b1;
	read_state<=read_idle;
	read_data<=ad_read_data;
  end
  else
  begin
   ad_read<=1'b0;
  end
 end
 
 default:begin
 read_state<=read_idle;
 end
 
 endcase
 end
end





//ad
ad7606 ad1(
   . clk_150_0(clk_150_0),
   .        		clk(clk_50_0),                  //50mhz
	.        		rst_n(reset),	
	. 		ad_data(ad_data),            //ad7606 采样数据
	.        		ad_busy(ad_busy),            //ad7606 忙标志位 
   .        		first_data(first_data),         //ad7606 第一个数据标志位 	    
	.  		ad_os(ad_os),              //ad7606 过采样倍率选择
	.    		ad_cs(ad_cs),              //ad7606 AD cs
	.    		ad_rd(ad_rd),              //ad7606 AD data read
	.    		ad_reset(ad_reset),           //ad7606 AD reset
	.    		ad_convstab(ad_convstab),        //ad7606 AD convert start
	. 				channel(channel),
	.   ad_ch_syn(ad_read_data),
	.  data_flag_syn(data_flag)
	);
	
	
ramip ram1(//一次读写16bit，读需要等待俩clk
	.clock(clk_150_90),
	.data(write_data),
	.rdaddress(rd_addr[11:0]),
	.wraddress(wr_addr[11:0]),
	.wren(is_ram_write),
	.q(ram_read_data)
	);

wire write_en;
ddr_addr_top ddr1(//记得改回来
//gen
.reset(reset),
. clk_50_0( clk_50_0),
. clk_150_90(clk_150_90),
. ddr_vaild(start),
. phy_clk(phy_clk),//送到clk manage
. phy_clk_90(phy_clk_90),

//pin
   . mem_addr( mem_addr),
   .  mem_ba( mem_ba),
   .           mem_cas_n( mem_cas_n),
   .   mem_cke( mem_cke),
   . mem_clk( mem_clk),
   .mem_clk_n(mem_clk_n),
   .   mem_cs_n(mem_cs_n),
   .   mem_dm(mem_dm),
   . mem_dq( mem_dq),
   . mem_dqs(mem_dqs),
   .  mem_odt( mem_odt),
   .    mem_ras_n( mem_ras_n),
   . mem_we_n (mem_we_n),
	
	




//读写起始地址以及长度
. rd_start_addr(rd_start_addr[23:0]),
. wr_start_addr(wr_start_addr[23:0]),

//与存储器top
. read_en(read_en),
. read_req(ddr_read),
.  read_data(ddr_read_data),

. write_data(write_data),
. write_req(is_ddr_write),
. write_en(write_en)
);	

assign write_ddr_en=write_en;
	
endmodule
