/*地址产生模块*/
//`define ddr2_addr 7//读写地址位宽，以B为单位
module addr_fetch(
   input reset,
	input clk,
	
	input rd_addr_up,//地址自增信号，来自mem brush
	input wr_addr_up,//严格控制 自增时才为1
	
	//input frist_block,//表示刚刚开始写，等该信号为1才可开始读
	
 	output [23:0] rd_addr,
	output [23:0] wr_addr,

	
	input [23:0] rd_start_addr,
	input [23:0] wr_start_addr,
	input ddr_vaild//由men top给出 严格一个clk 更新地址


);

wire rd_addr_en=rd_addr_up;
wire [23:0] rd_addr_next=rd_addr+24'd4;
sirv_gnrl_dfflre #(24) rd_addr_dfflre(rd_addr_en,rd_addr_next,rd_addr,clk,reset&(~ddr_vaild),rd_start_addr);

wire wr_addr_en=wr_addr_up;
wire [23:0] wr_addr_next=wr_addr+24'd4;
sirv_gnrl_dfflre #(24) wr_addr_dfflre(wr_addr_en,wr_addr_next,wr_addr,clk,reset&(~ddr_vaild),wr_start_addr);






/*
reg r_state;
localparam rwait=1'b0;
localparam rread=1'b1;



reg [`ddr2_addr-1:0] rd_addr_t;//2MB最小寻址单位是4B，共19位
reg [`ddr2_addr-1:0] wr_addr_t;
wire [`ddr2_addr-1:0] rd_addr_next=rd_addr_t+{{`ddr2_addr-3{1'b0}},rd_addr_up,2'b0};
wire [`ddr2_addr-1:0] wr_addr_next=wr_addr_t+{{`ddr2_addr-3{1'b0}},wr_addr_up,2'b0};
//复位
reg updata_addr;
reg force_addr;
assign rd_addr={{24-`ddr2_addr{1'b0}},rd_addr_t};
assign wr_addr={{24-`ddr2_addr{1'b0}},wr_addr_t};
always @(posedge clk or negedge reset)
begin 
 if(~reset)
 begin 
  rd_addr_t<=`ddr2_addr'b0;
  wr_addr_t<=`ddr2_addr'b0;
 end
 else if(updata_addr)//当rd addr未即时取完该块则需要舍弃后面的数据
 begin
  wr_addr_t<=wr_addr_t+{{(`ddr2_addr-3){1'b0}},wr_addr_up,2'b0};
  rd_addr_t<={wr_addr_t[`ddr2_addr-1],{(`ddr2_addr-1){1'b0}}};
 end
 else if(r_state==rread) 
 begin
  rd_addr_t<=rd_addr_next;
  wr_addr_t<=wr_addr_next;
 end
 else
  wr_addr_t<=wr_addr_next;
end


//写切换
wire [`ddr2_addr-2:0] wr_addr_end={{(`ddr2_addr-3){1'b1}},2'b00};
reg swich;
always@(posedge clk or negedge reset)
begin
 if(~reset)
  updata_addr<=1'b0;
 else if(swich)
  updata_addr<=1'b0;
 else if(wr_addr_t[`ddr2_addr-2:0]==wr_addr_end)
 begin
  swich<=1'b1;
  updata_addr<=1'b1;
 end
 else
  updata_addr<=1'b0;
  
 if(~reset)
  swich<=1'b0;
 else if(swich&wr_addr_t[`ddr2_addr-2:0]!=wr_addr_end)
  swich<=1'b0;
  
end

 

//读控制

always@(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  r_state<=rwait;
  read_en<=1'b0;
 end
 else begin
case(r_state)
rwait:begin
 if(updata_addr)
 begin 
  r_state<=rread;
  read_en<=1'b1;
 end
end
rread:begin
 if((rd_addr_t[`ddr2_addr-1]^rd_addr_next[`ddr2_addr-1])&(~updata_addr))
 begin
  r_state<=rwait;
  read_en<=1'b0;
 end
end

endcase
  end
  
  end
  







*/

/*

//read_en
always@(posedge clk or  negedge reset)
begin
 if(~reset)
  read_en<=1'b0;
 else if(updata_addr)
  read_en<=1'b1&n_frist_block;
 else if(rd_addr_next[17:0]==18'b0)
  read_en<=1'b0;
 else
  read_en<=1'b1;
end

//读转换
always@(posedge clk or negedge reset)
begin
 if(~reset)
  updata_addr<=1'b0;
 else if(wr_addr_t[18]^wr_addr_next[18])
  updata_addr<=1'b1&n_frist_block;
 else
  updata_addr<=1'b0;
end

//读强制转换--当读写同一块时
always @(posedge clk or negedge reset)
begin
 if(~reset)
 force_addr<=1'b0;
 else if(~(wr_addr_t[18]^rd_addr_t[18]))
  force_addr<=1'b1;
 else
  force_addr<=1'b0;
end
*/
/*

reg w_state;
reg next_w_state;
always@(posedge clk or negedge reset)
begin
 if(reset==1'b1)
   begin
   w_state<=1'b0;
	next_w_state<=1'b0;
	end
 else if(wr_addr_t[18]^wr_addr_next[18])
   
   next_w_state<=1'b1;
 else 
   next_w_state<=1'b0;
end

reg r_state;
always@(posedge clk or negedge reset)
begin
 if(reset==1'b1)
   r_state<=1'b0;
 else if(rd_addr_t^rd_addr_next[18])
   r_state<=~r_state;
end



wire r_w_xor= rd_addr_next[18]^wr_addr_next[18]&n_frist_block;
//read_en信号 读到了写区域
//读使能信号，当读完一块下一块还未加载完毕-》子集（当刚刚开始时候）
always@(posedge clk or negedge reset)
begin 
 if(~reset)
 begin
    read_en<=1'b0;
 end
 else
 begin
  read_en<=r_w_xor;
 end
end


//updata addr信号  写到了读区域
always@(posedge clk or negedge reset)
begin 
 if(~reset)
 begin
  updata_addr<=1'b0;
 end
 else
 begin
  updata_addr<=r_w_xor&;
 end
end
*/



endmodule
