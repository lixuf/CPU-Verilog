module xb_l_top(
input clk,
input reset,
input [15:0]data_in,
input data_in_read,//写入有效信号
output [15:0] data_out_1_l,
output reg ready,//输出使能
input vaild,
input [15:0] xbl_reg0,
input [15:0] xbl_reg1,
input [15:0] xbl_reg2,
input [15:0] xbl_reg3,
input [15:0] xbl_reg4,
input [15:0] xbl_reg5,
input [15:0] xbl_reg6,
input [15:0] xbl_reg7
);


//分开奇偶
reg cnt;
reg data_in_readyl1;
reg data_in_readyl2;
always@(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  cnt<=1'b0;
  data_in_readyl1<=1'b0;
  data_in_readyl2<=1'b0;
 end
 else if(cnt==1'b0&data_in_read)//奇数,低通分解 高通重构
 begin

  data_in_readyl1<=1'b1;
  data_in_readyl2<=1'b0;
  cnt<=1'b1;
  end
 else if(cnt==1'b1&data_in_read)//偶数,高通分解 低通重构
 begin

  data_in_readyl1<=1'b0;
  data_in_readyl2<=1'b1;
  cnt<=1'b0;
  end
 else begin

  data_in_readyl1<=1'b0;
  data_in_readyl2<=1'b0;
 end
end


wire data_out_flagl2;
wire data_out_flagl1;
wire [15:0] data_outl1;
wire [15:0] data_outl2;

  


low lb_l_1_1(
  .clk(clk),
  .reset(reset),
 
  .data_in(data_in),
  .data_in_ready(data_in_readyl1),

  .data_out(data_outl1),
  .data_out_flag(data_out_flagl1),
  .xbl_reg0(xbl_reg0),
.xbl_reg1(xbl_reg1),
.xbl_reg2(xbl_reg2),
.xbl_reg3(xbl_reg3),
.xbl_reg4(xbl_reg4),
.xbl_reg5(xbl_reg5),
.xbl_reg6(xbl_reg6),
.xbl_reg7(xbl_reg7)
  );
  
  
low lb_l_2_1(
  .clk(clk),
  .reset(reset),
 
  .data_in(data_in),
  .data_in_ready(data_in_readyl2),
 
  .data_out(data_outl2),
  .data_out_flag(data_out_flagl2),
  .xbl_reg0(xbl_reg0),
.xbl_reg1(xbl_reg1),
.xbl_reg2(xbl_reg2),
.xbl_reg3(xbl_reg3),
.xbl_reg4(xbl_reg4),
.xbl_reg5(xbl_reg5),
.xbl_reg6(xbl_reg6),
.xbl_reg7(xbl_reg7)
  );
  





//wire [15:0] data_out_1_h;
//wire [15:0] data_out_1_l;

add_end addl(
.data1(data_outl1),
.data2(data_outl2),
.datao(data_out_1_l)
);



always @(posedge clk or negedge reset)
begin
 if((~reset))
 begin
 ready<=1'b0;
 end
 else if(data_out_flagl2) begin
 ready<=1'b1;
 end
 else begin
 ready<=1'b0;
 end
end




endmodule


