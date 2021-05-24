module high(
input [15:0] xbh_reg0,
input [15:0] xbh_reg1,
input [15:0] xbh_reg2,
input [15:0] xbh_reg3,
input [15:0] xbh_reg4,
input [15:0] xbh_reg5,
input [15:0] xbh_reg6,
input [15:0] xbh_reg7,

input clk,
input reset,

 
input [15:0] data_in,
input data_in_ready,

 
output reg [15:0] data_out,
output reg data_out_flag
);



reg [15:0] shift_reg[7:0];
  
 //乘法器
 wire [24:0] mul_data[7:0];
 wire [8:0] xishu[7:0];
 genvar i;
 generate
  for(i=0;i<8;i=i+1)
  begin: ver
    mul mul1(
	.dataa(shift_reg[i]),
	.datab(xishu[i]),
	.result(mul_data[i]));
  end
 endgenerate
 
 //系数
assign xishu[0]=xbh_reg0[8:0];
assign xishu[1]=xbh_reg1[8:0];
assign xishu[2]=xbh_reg2[8:0];
assign xishu[3]=xbh_reg3[8:0];
assign xishu[4]=xbh_reg4[8:0];
assign xishu[5]=xbh_reg5[8:0];
assign xishu[6]=xbh_reg6[8:0];
assign xishu[7]=xbh_reg7[8:0];
 
 //加法器
 wire [15:0] data_out_temp;
 add add1(
 .data0(mul_data[0]),
 .data1(mul_data[1]),
 .data2(mul_data[2]),
 .data3(mul_data[3]),
 .data4(mul_data[4]),
 .data5(mul_data[5]),
 .data6(mul_data[6]),
 .data7(mul_data[7]),
 .datao(data_out_temp));
 
 
 
 //移位寄存器

 reg [1:0] out_c;
 always@(posedge clk or negedge reset)
 begin
 
  if(~reset)
  begin
   out_c<=1'b0;
	data_out_flag<=1'b0;
   shift_reg[0]<=16'd0;
	shift_reg[1]<=16'd0;
	shift_reg[2]<=16'd0;
	shift_reg[3]<=16'd0;
	shift_reg[4]<=16'd0;
	shift_reg[5]<=16'd0;
	shift_reg[6]<=16'd0;
	shift_reg[7]<=16'd0;
  end
  else if(data_in_ready)
  begin
   out_c<=out_c+2'b1;
	data_out_flag<=1'b0;
   shift_reg[0]<=data_in;
	shift_reg[1]<=shift_reg[0];
	shift_reg[2]<=shift_reg[1];
	shift_reg[3]<=shift_reg[2];
	shift_reg[4]<=shift_reg[3];
	shift_reg[5]<=shift_reg[4];
	shift_reg[6]<=shift_reg[5];
	shift_reg[7]<=shift_reg[6];
  end
  else if(out_c==2'b11)
  begin
   data_out_flag<=1'b1;
	out_c<=2'b0;
	data_out<=data_out_temp;
  end
  else if(out_c!=2'b00)
   out_c<=out_c+2'b1;  
  else
  begin
   data_out_flag<=1'b0;
  end
  
  
 end
 
 endmodule


 