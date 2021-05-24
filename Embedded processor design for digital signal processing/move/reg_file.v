module reg_file(
input clk,
input reset,
output ready,//直接连给主cpu rsp通道的vaild
input vaild,//直接与主cpu发来的vaild相连

input [7:0] xbh_en,//在一级流水处锁存
input [7:0] xbl_en,
input [7:0] fir_reg_en,
input [1:0] des_addr_en,
input [1:0] sor_addr_en,
input len_en,
input [3:0] lr_en,
input [3:0] hr_en,
input [15:0] operant,
input ready_en,//5.7 挪到了外面

output [15:0] xbh_reg0,
output [15:0] xbh_reg1,
output [15:0] xbh_reg2,
output [15:0] xbh_reg3,
output [15:0] xbh_reg4,
output [15:0] xbh_reg5,
output [15:0] xbh_reg6,
output [15:0] xbh_reg7,
output [15:0] xbl_reg0,
output [15:0] xbl_reg1,
output [15:0] xbl_reg2,
output [15:0] xbl_reg3,
output [15:0] xbl_reg4,
output [15:0] xbl_reg5,
output [15:0] xbl_reg6,
output [15:0] xbl_reg7,
output [15:0] fir_reg_reg0,
output [15:0] fir_reg_reg1,
output [15:0] fir_reg_reg2,
output [15:0] fir_reg_reg3,
output [15:0] fir_reg_reg4,
output [15:0] fir_reg_reg5,
output [15:0] fir_reg_reg6,
output [15:0] fir_reg_reg7,
output [15:0] des_addr_reg0 ,
output [15:0] des_addr_reg1 ,
output[15:0] sor_addr_reg0,
output[15:0] sor_addr_reg1,
output [15:0] lreg_reg,
output [15:0] lr_reg0,
output [15:0] lr_reg1,
output [15:0] lr_reg2,
output [15:0] lr_reg3,
output [15:0] hr_reg0,
output [15:0] hr_reg1,
output [15:0] hr_reg2,
output [15:0] hr_reg3

);
//返回ready 置高1clk

//这些位基本都搞反了
wire ready_r;
sirv_gnrl_dffr#(1) ready_dffr(vaild,ready_r,clk,reset);
assign ready=ready_r;

wire [36:0] len={xbh_en,xbl_en,fir_reg_en,des_addr_en,sor_addr_en,len_en,lr_en, hr_en};
wire [15:0] reg_r[0:36];
assign  xbh_reg0=reg_r[0];
assign
  xbh_reg1=reg_r[1];
assign
  xbh_reg2=reg_r[2];
assign
  xbh_reg3=reg_r[3];
assign
  xbh_reg4=reg_r[4];
assign
  xbh_reg5=reg_r[5];
assign
  xbh_reg6=reg_r[6];
assign
  xbh_reg7=reg_r[7];
assign
  xbl_reg0=reg_r[8];
assign
  xbl_reg1=reg_r[9];
assign
  xbl_reg2=reg_r[10];
assign
  xbl_reg3=reg_r[11];
assign
  xbl_reg4=reg_r[12];
assign
  xbl_reg5=reg_r[13];
assign
  xbl_reg6=reg_r[14];
assign
  xbl_reg7=reg_r[15];
assign
  fir_reg_reg0=reg_r[16];
assign
  fir_reg_reg1=reg_r[17];
assign
  fir_reg_reg2=reg_r[18];
assign
  fir_reg_reg3=reg_r[19];
assign
  fir_reg_reg4=reg_r[20];
assign
  fir_reg_reg5=reg_r[21];
assign
  fir_reg_reg6=reg_r[22];
assign
  fir_reg_reg7=reg_r[23];
assign
  des_addr_reg0 =reg_r[24];
assign
  des_addr_reg1 =reg_r[25];
assign
 sor_addr_reg0=reg_r[26];
assign
 sor_addr_reg1=reg_r[27];
assign
  lreg_reg=reg_r[28];
assign
  lr_reg0=reg_r[29];
assign
  lr_reg1=reg_r[30];
assign
  lr_reg2=reg_r[31];
assign
  lr_reg3=reg_r[32];
assign
  hr_reg0=reg_r[33];
assign
  hr_reg1=reg_r[34];
assign
  hr_reg2=reg_r[35];
 assign
  hr_reg3=reg_r[36];

genvar i;
generate 
 for(i=0;i<37;i=i+1) begin:reg37//36-i是因为位是反这的
  sirv_gnrl_dfflr#(16) reg_dfflr(len[36-i]&vaild,operant,reg_r[i],clk,reset);
 end
endgenerate

endmodule
