module ddr_addr_top_t(
//gen
input reset,
input clk_50_0,
input clk_150_90,
input ddr_vaild,
output phy_clk,//送到clk manage
input phy_clk_90,

//pin
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
	
	


//读写起始地址以及长度
input [23:0] rd_start_addr,
input [23:0] wr_start_addr,

//与存储器top
output read_en,
input read_req,
output [15:0] read_data,

input [15:0] write_data,
input write_req,
output write_en
);

wire locked;
wire phy_clk_t;
assign phy_clk=phy_clk_t&locked;
wire phy_clk_90_t;
wire phy_clk_90_tt=phy_clk_90_t&locked;
pllt pll1667(
	.areset(),
	.inclk0(clk_50_0),
	.c0(phy_clk_t),
	.c1(phy_clk_90_t),
	.locked(locked)
);

reg [31:0] local_rdata;
reg write_fifo;
reg startw;
reg [3:0] cntw;

wire [31:0] data_out;
reg read_fifo_req;
reg startr;
reg [3:0] cntr;

parameter DATA_WIDTH = 32;           //总线数据宽度
parameter ADDR_WIDTH = 25;           //总线地址宽度

parameter IDLE = 3'd0;
parameter MEM_READ = 3'd1;
parameter MEM_WRITE  = 3'd2; 



wire[ADDR_WIDTH - 1:0] local_address;
wire local_burstbegin;
wire local_init_done;
//wire[DATA_WIDTH - 1:0] local_rdata;
wire local_rdata_valid;
wire local_read_req;
wire[DATA_WIDTH - 1:0] local_wdata;
wire local_wdata_req;
wire local_write_req;
wire[2:0] local_size;
wire[3:0] local_be;

wire rd_addr_up;
wire wr_addr_up;
wire[24:0] rd_addr;
wire[24:0] wr_addr;





//wire write_fifo;
wire read_en_t;
assign read_en=~read_en_t;
wire empty;
read_fifo rfifo1(
	.aclr(ddr_vaild),
	.data(local_rdata),
	.rdclk(clk_150_90),
	.rdreq(read_req),
	.wrclk(phy_clk_90_tt),
	.wrreq(write_fifo),
	.q(read_data),
	.rdempty(read_en_t),
	.wrempty(empty)
	);

wire write_en_t;
assign write_en=~write_en_t;
//wire rd_fifo_req;
//wire [31:0] data_out;
wire full;
write_fifo wfifo(
	.aclr(ddr_vaild),
	.data(write_data),
	.rdclk(phy_clk_90_tt),
	.rdreq(rd_fifo_req),
	.wrclk(clk_150_90),
	.wrreq(write_req),
	.q(data_out),
	.rdfull(full),
	.wrfull(write_en_t)
	);	
	
//read fifo

always@(posedge phy_clk_90_tt or negedge reset)
begin
 if(~reset)
 begin
  startw<=1'b0;
 end
 else if(cntw==4'd4)
 begin
  startw<=1'b0;
 end
 else if(empty)
 begin
  startw<=1'b1;
 end
end


always@(posedge phy_clk_90_tt or negedge reset)
begin
 if(~reset)
 begin
  local_rdata<=32'b0;
  write_fifo<=1'b0;
  cntw<=4'b0;
 end
 else if(startw)
 begin
 
 if(cntw==4'd4)
 begin
  cntw<=4'b0;
  write_fifo<=1'b0;
 end
 else 
 begin
  cntw<=cntw+4'b1;
  write_fifo<=1'b1;
  local_rdata<=local_rdata+32'd9999;
 end
 end
end
//write fifo
always@(posedge phy_clk_90_tt or negedge reset)
begin
 if(~reset)
 begin
  startr<=1'b0;
 end
 else if(cntr==4'd4)
 begin
  startr<=1'b0;
 end
 else if(full)
 begin
  startr<=1'b1;
 end
end


always@(posedge phy_clk_90_tt or negedge reset)
begin
 if(~reset)
 begin
  read_fifo_req<=1'b0;
  cntr<=4'b0;
 end
 else if(startr)
 begin
 
 if(cntr==4'd4)
 begin
  cntr<=4'b0;
  read_fifo_req<=1'b0;
 end
 else 
 begin
  cntr<=cntr+4'b1;
  read_fifo_req<=1'b1;
 end
 end
end


/*
	
//wire [24:0] rd_addr;
//wire [24:0] wr_addr;
//wire read_en;//读准许信号，由于读完了一块下一块未写完
addr_fetch  addr_fetch11(
   .reset(reset),
	.clk(phy_clk),
	.rd_addr_up(rd_addr_up),//地址自增信号，来自mem brush
	.wr_addr_up(wr_addr_up),//严格控制 自增时才为1
	
	//input frist_block,//表示刚刚开始写，等该信号为1才可开始读
	
 	.rd_addr(rd_addr),
	.wr_addr(wr_addr),
	
	.rd_start_addr(rd_start_addr),
	.wr_start_addr(wr_start_addr),
	.ddr_vaild(ddr_vaild)//由men top给出 严格一个clk 更新地址
	);




	
ddr_test2  ddr_test211(

	.source_clk(clk_50_0),        //输入系统时钟50Mhz
	.rst_n(reset),
	
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
   .mem_we_n(mem_we_n) ,
   
   .phy_clk(phy_clk)	,
	

	//ad-ram的fifo  50mhz-166.7mhz
	/*full信号做为写入请求，写信号被接收后，由local ready充当fifo读取信号*/
	/*.w_req(full),
   .read_fifo(rd_fifo_req),
	.read_fifo_data(data_out),
	//ram-xiaobo的fifo 166.7mhz
	/*用r vaild做为fifo写入信号
	  empty做为ddr的读1信号*/
	/*.r_req(empty),
	.write_fifo(write_fifo),
	.local_rdata(local_rdata),
	//addr生成模块
	/*当接受读时更新addr 控制是否可读
	  当接受写时更新写addr*/
	/*.rd_addr(rd_addr),
	.wr_addr(wr_addr),
	.rd_addr_up(rd_addr_up),//地址自增信号，来自mem brush
	.wr_addr_up(wr_addr_up)//严格控制 自增时才为1//未加
);
	
*/
endmodule
