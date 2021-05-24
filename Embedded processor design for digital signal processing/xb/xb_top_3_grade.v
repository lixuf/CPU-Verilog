module xb_top_3_grade(
input phy_clk_0,
input reset,
input [15:0] rd_data,
input data_in_read,


output [15:0] data_out_1_l,
output [15:0] data_out_2_l,
output [15:0] data_out_3_h,

output reg finish,
output finish_g1,
output finish_g2,
output finish_g3,

input [15:0] xbl_reg0,
input [15:0] xbl_reg1,
input [15:0] xbl_reg2,
input [15:0] xbl_reg3,
input [15:0] xbl_reg4,
input [15:0] xbl_reg5,
input [15:0] xbl_reg6,
input [15:0] xbl_reg7,

input [15:0] xbh_reg0,
input [15:0] xbh_reg1,
input [15:0] xbh_reg2,
input [15:0] xbh_reg3,
input [15:0] xbh_reg4,
input [15:0] xbh_reg5,
input [15:0] xbh_reg6,
input [15:0] xbh_reg7
);



wire ready_g1;
wire ready_g2;
wire ready_g3;
assign finish_g1=ready_g1;
assign finish_g2=ready_g2;
assign finish_g3=ready_g3;



xb_l_top g1_l(
 .clk(phy_clk_0),
 .reset(reset),
 .data_in(rd_data),
 .data_in_read(data_in_read),
.data_out_1_l(data_out_1_l),
.ready(ready_g1),
.vaild(ready_g1),
.xbl_reg0(xbl_reg0),
.xbl_reg1(xbl_reg1),
.xbl_reg2(xbl_reg2),
.xbl_reg3(xbl_reg3),
.xbl_reg4(xbl_reg4),
.xbl_reg5(xbl_reg5),
.xbl_reg6(xbl_reg6),
.xbl_reg7(xbl_reg7)
);



xb_l_top g2_l( 
 .clk(phy_clk_0),
 .reset(reset),
 .data_in(data_out_1_l),
 .data_in_read(ready_g1),
.data_out_1_l(data_out_2_l),
.ready(ready_g2),
.vaild(ready_g2),
.xbl_reg0(xbl_reg0),
.xbl_reg1(xbl_reg1),
.xbl_reg2(xbl_reg2),
.xbl_reg3(xbl_reg3),
.xbl_reg4(xbl_reg4),
.xbl_reg5(xbl_reg5),
.xbl_reg6(xbl_reg6),
.xbl_reg7(xbl_reg7)
);

xb_h_top g3_h(
 .clk(phy_clk_0),
 .reset(reset),
 .data_in(data_out_2_l),
 .data_in_read(ready_g2),
.data_out_1_h(data_out_3_h),
.ready(ready_g3),
.vaild(ready_g3),
.xbh_reg0(xbh_reg0),
.xbh_reg1(xbh_reg1),
.xbh_reg2(xbh_reg2),
.xbh_reg3(xbh_reg3),
.xbh_reg4(xbh_reg4),
.xbh_reg5(xbh_reg5),
.xbh_reg6(xbh_reg6),
.xbh_reg7(xbh_reg7)

);

always@(posedge phy_clk_0 or negedge reset)
begin
 if(~reset)
  finish<=1'b0;
 else if(ready_g3)
  finish<=1'b1;
 else
  finish<=1'b0;
end

endmodule
