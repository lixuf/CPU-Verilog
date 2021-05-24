module xb_h_top(
input clk,
input reset,
input [15:0]data_in,
input data_in_read,//写入有效信号
output [15:0] data_out_1_h,
output reg ready,//输出使能
input vaild,
input [15:0] xbh_reg0,
input [15:0] xbh_reg1,
input [15:0] xbh_reg2,
input [15:0] xbh_reg3,
input [15:0] xbh_reg4,
input [15:0] xbh_reg5,
input [15:0] xbh_reg6,
input [15:0] xbh_reg7
);


//分开奇偶
reg cnt;
reg data_in_readyh1;
reg data_in_readyh2;
always@(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  cnt<=1'b0;
  data_in_readyh1<=1'b0;
  data_in_readyh2<=1'b0;
 end
 else if(cnt==1'b0&data_in_read)//奇数,低通分解 高通重构
 begin
  data_in_readyh1<=1'b1;
  data_in_readyh2<=1'b0;
  cnt<=1'b1;
  end
 else if(cnt==1'b1&data_in_read)//偶数,高通分解 低通重构
 begin
   data_in_readyh1<=1'b0;
  data_in_readyh2<=1'b1;
  cnt<=1'b0;
  end
 else begin
  data_in_readyh1<=1'b0;
  data_in_readyh2<=1'b0;
 end
end


wire data_out_flagh2;
wire data_out_flagh1;
wire [15:0] data_outh1;
wire [15:0] data_outh2;
high lb_h_1_1(
  .clk(clk),
  .reset(reset),
 
  .data_in(data_in),
  .data_in_ready(data_in_readyh1),

 
  .data_out(data_outh1),
  .data_out_flag(data_out_flagh1),
  .xbh_reg0(xbh_reg0),
  .xbh_reg1(xbh_reg1),
.xbh_reg2(xbh_reg2),
.xbh_reg3(xbh_reg3),
.xbh_reg4(xbh_reg4),
.xbh_reg5(xbh_reg5),
.xbh_reg6(xbh_reg6),
.xbh_reg7(xbh_reg7)
  );
  
  
high lb_h_2_1(
  .clk(clk),
  .reset(reset),
 
  .data_in(data_in),
  .data_in_ready(data_in_readyh2),
 
  .data_out(data_outh2),
  .data_out_flag(data_out_flagh2),
  .xbh_reg0(xbh_reg0),
  .xbh_reg1(xbh_reg1),
.xbh_reg2(xbh_reg2),
.xbh_reg3(xbh_reg3),
.xbh_reg4(xbh_reg4),
.xbh_reg5(xbh_reg5),
.xbh_reg6(xbh_reg6),
.xbh_reg7(xbh_reg7)
  );
  







//wire [15:0] data_out_1_h;
//wire [15:0] data_out_1_l;
add_end addh(
.data1(data_outh1),
.data2(data_outh2),
.datao(data_out_1_h)
 );


always @(posedge clk or negedge reset)
begin
 if((~reset))
 begin
 ready<=1'b0;
 end
 else if(data_out_flagh2) begin
 ready<=1'b1;
 end
 else begin
 ready<=1'b0;
 end
end


endmodule


