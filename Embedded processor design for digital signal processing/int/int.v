module int_ins(
input vaild,//涓€鐩翠负楂鐩村埌ready鍥炲幓
output ready,

input clk,
input clk50,
input reset,
input button,
output tx,
input button_start,
input int_en,

input [15:0] xbh_reg0,
input [15:0] xbh_reg1,
input [15:0] xbh_reg2,
input [15:0] xbh_reg3,
input [15:0] xbh_reg4,
input [15:0] xbh_reg5,
input [15:0] xbh_reg6,
input [15:0] xbh_reg7,
input [15:0] xbl_reg0,
input [15:0] xbl_reg1,
input [15:0] xbl_reg2,
input [15:0] xbl_reg3,
input [15:0] xbl_reg4,
input [15:0] xbl_reg5,
input [15:0] xbl_reg6,
input [15:0] xbl_reg7,
input [15:0] fir_reg_reg0,
input [15:0] fir_reg_reg1,
input [15:0] fir_reg_reg2,
input [15:0] fir_reg_reg3,
input [15:0] fir_reg_reg4,
input [15:0] fir_reg_reg5,
input [15:0] fir_reg_reg6,
input [15:0] fir_reg_reg7,
input [15:0] des_addr_reg0 ,
input [15:0] des_addr_reg1 ,
input [15:0] sor_addr_reg0,
input [15:0] sor_addr_reg1,
input [15:0] lreg_reg,
input [15:0] lr_reg0,
input [15:0] lr_reg1,
input [15:0] lr_reg2,
input [15:0] lr_reg3,
input [15:0] hr_reg0,
input [15:0] hr_reg1,
input [15:0] hr_reg2,
input [15:0] hr_reg3,

//uarto澶嶇敤
output clkout,
input [7:0] datain_uarto,
input uarto_en,
input wrsig_uarto,
output idle
);
wire [73:0] reg_cnt;
/*
wire [15:0] reg_bus [36:0];
assign reg_bus[0]=xbh_reg0;
assign reg_bus[1]=xbh_reg1;
assign reg_bus[2]=xbh_reg2;
assign reg_bus[3]=xbh_reg3;
assign reg_bus[4]=xbh_reg4;
assign reg_bus[5]=xbh_reg5;
assign reg_bus[6]=xbh_reg6;
assign reg_bus[7]=xbh_reg7;
assign reg_bus[8]=xbl_reg0;
assign reg_bus[9]=xbl_reg1;
assign reg_bus[10]=xbl_reg2;
assign reg_bus[11]=xbl_reg3;
assign reg_bus[12]=xbl_reg4;
assign reg_bus[13]=xbl_reg5;
assign reg_bus[14]=xbl_reg6;
assign reg_bus[15]=xbl_reg7;
assign reg_bus[16]=fir_reg_reg0;
assign reg_bus[17]=fir_reg_reg1;
assign reg_bus[18]=fir_reg_reg2;
assign reg_bus[19]=fir_reg_reg3;
assign reg_bus[20]=fir_reg_reg4;
assign reg_bus[21]=fir_reg_reg5;
assign reg_bus[22]=fir_reg_reg6;
assign reg_bus[23]=fir_reg_reg7;
assign reg_bus[24]=des_addr_reg0;
assign reg_bus[25]=des_addr_reg1;
assign reg_bus[26]=sor_addr_reg0;
assign reg_bus[27]=sor_addr_reg1;
assign reg_bus[28]=lreg_reg;
assign reg_bus[29]=lr_reg0;
assign reg_bus[30]=lr_reg1;
assign reg_bus[31]=lr_reg2;
assign reg_bus[32]=lr_reg3;
assign reg_bus[33]=hr_reg0;
assign reg_bus[34]=hr_reg1;
assign reg_bus[35]=hr_reg2;
assign reg_bus[36]=hr_reg3;
*/


//ready鍙兘鏈夌偣闂
//涓轰簡浠跨湡鏇存敼鏃堕挓
clkdiv clkdiv1(clk50, reset, clkout);
//assign clkout=clk50;
wire vaild_syn;
cdc #(2,1) vaild_cdc(clkout,vaild,vaild_syn);




reg wrsig_t;
reg reg_cnt_en_t;
reg quit_flag;
localparam wait_vaild=3'b0;
localparam wait_idle=3'd1;
localparam send=3'd2;
localparam quit=3'd3;
localparam wait_idle_high=3'd4;
reg [2:0] reg_state;
always@(posedge clkout or negedge reset)
begin
 if(~reset)
 begin
  reg_state<=3'b0;
  wrsig_t<=1'b0;
  reg_cnt_en_t<=1'b0;
  quit_flag<=1'b0;
 end
 else if(int_en)
 begin
 
 case(reg_state)
 
 wait_vaild:begin
 if(vaild_syn&(~button_start))
 begin
  reg_state<=wait_idle;
 end
 
 end
 
 
 wait_idle:begin
  reg_cnt_en_t<=1'b0;
  if(~idle)
  begin
   if(quit_flag)
	  reg_state<=quit;
	else
	 begin
	  wrsig_t<=1'b1;
     reg_state<=wait_idle_high;
	 end
  end
 end
 
 wait_idle_high:begin
 wrsig_t<=1'b0;
 if(idle)
  reg_state<=send;
 end
 
 
 send:begin
  reg_cnt_en_t<=1'b0;
  wrsig_t<=1'b0;
  reg_state<=wait_idle;
  if(reg_cnt[73])
  begin
   quit_flag<=1'b1;
  end
  reg_cnt_en_t<=1'b1;
 end
 
 quit:begin
  quit_flag<=1'b0;
  if((~button)&(~idle))
  begin
   reg_state<=3'b0;
  end
 end
 
 
 endcase
 end

end

wire ready1;
wire ready2;
wire if_ready_en=(reg_state==quit);
wire if_send=(reg_state==send);
wire ready_reset=reset;
wire ready1_en=~if_ready_en;
wire ready2_en=~if_ready_en;
wire ready1_next=~button;
wire ready2_next=ready1;
sirv_gnrl_dfflr #(1) ready1_dfflr(ready1_en,ready1_next,ready1,clk,ready_reset);
sirv_gnrl_dfflr #(1) ready2_dfflr(ready2_en,ready2_next,ready2,clk,ready_reset);
wire ready_t=(ready1^ready2)&ready1;//涓婂崌娌块┍鍔

reg ready_o;
reg cnt_ready;
always@(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  ready_o<=1'b0;
  cnt_ready<=1'b0;
 end
 else if(ready_t)
 begin
  ready_o<=1'b1;
  cnt_ready<=1'b1;
 end
 else if(cnt_ready)
 begin
  cnt_ready<=1'b0;
 end
 else
 begin
  ready_o<=1'b0;
 end
end
assign ready=ready_o;
wire reg_cnt_en=reg_cnt_en_t;
wire [73:0] reg_cnt_next=(reg_cnt[73])?73'b1:reg_cnt<<1;

sirv_gnrl_dfflr1 #(74) reg_cnt_dfflr1(reg_cnt_en,reg_cnt_next,reg_cnt,clkout,reset);






wire [7:0] datain = ({8{reg_cnt[0]}}&xbh_reg0[15:8])
|({8{reg_cnt[1]}}&xbh_reg0[7:0])
|({8{reg_cnt[2]}}&xbh_reg1[15:8])
|({8{reg_cnt[3]}}&xbh_reg1[7:0])
|({8{reg_cnt[4]}}&xbh_reg2[15:8])
|({8{reg_cnt[5]}}&xbh_reg2[7:0])
|({8{reg_cnt[6]}}&xbh_reg3[15:8])
|({8{reg_cnt[7]}}&xbh_reg3[7:0])
|({8{reg_cnt[8]}}&xbh_reg4[15:8])
|({8{reg_cnt[9]}}&xbh_reg4[7:0])
|({8{reg_cnt[10]}}&xbh_reg5[15:8])
|({8{reg_cnt[11]}}&xbh_reg5[7:0])
|({8{reg_cnt[12]}}&xbh_reg6[15:8])
|({8{reg_cnt[13]}}&xbh_reg6[7:0])
|({8{reg_cnt[14]}}&xbh_reg7[15:8])
|({8{reg_cnt[15]}}&xbh_reg7[7:0])
|({8{reg_cnt[16]}}&xbl_reg0[15:8])
|({8{reg_cnt[17]}}&xbl_reg0[7:0])
|({8{reg_cnt[18]}}&xbl_reg1[15:8])
|({8{reg_cnt[19]}}&xbl_reg1[7:0])
|({8{reg_cnt[20]}}&xbl_reg2[15:8])
|({8{reg_cnt[21]}}&xbl_reg2[7:0])
|({8{reg_cnt[22]}}&xbl_reg3[15:8])
|({8{reg_cnt[23]}}&xbl_reg3[7:0])
|({8{reg_cnt[24]}}&xbl_reg4[15:8])
|({8{reg_cnt[25]}}&xbl_reg4[7:0])
|({8{reg_cnt[26]}}&xbl_reg5[15:8])
|({8{reg_cnt[27]}}&xbl_reg5[7:0])
|({8{reg_cnt[28]}}&xbl_reg6[15:8])
|({8{reg_cnt[29]}}&xbl_reg6[7:0])
|({8{reg_cnt[30]}}&xbl_reg7[15:8])
|({8{reg_cnt[31]}}&xbl_reg7[7:0])
|({8{reg_cnt[32]}}&fir_reg_reg0[15:8])
|({8{reg_cnt[33]}}&fir_reg_reg0[7:0])
|({8{reg_cnt[34]}}&fir_reg_reg1[15:8])
|({8{reg_cnt[35]}}&fir_reg_reg1[7:0])
|({8{reg_cnt[36]}}&fir_reg_reg2[15:8])
|({8{reg_cnt[37]}}&fir_reg_reg2[7:0])
|({8{reg_cnt[38]}}&fir_reg_reg3[15:8])
|({8{reg_cnt[39]}}&fir_reg_reg3[7:0])
|({8{reg_cnt[40]}}&fir_reg_reg4[15:8])
|({8{reg_cnt[41]}}&fir_reg_reg4[7:0])
|({8{reg_cnt[42]}}&fir_reg_reg5[15:8])
|({8{reg_cnt[43]}}&fir_reg_reg5[7:0])
|({8{reg_cnt[44]}}&fir_reg_reg6[15:8])
|({8{reg_cnt[45]}}&fir_reg_reg6[7:0])
|({8{reg_cnt[46]}}&fir_reg_reg7[15:8])
|({8{reg_cnt[47]}}&fir_reg_reg7[7:0])
|({8{reg_cnt[48]}}&des_addr_reg0[15:8])
|({8{reg_cnt[49]}}&des_addr_reg0[7:0])
|({8{reg_cnt[50]}}&des_addr_reg1[15:8])
|({8{reg_cnt[51]}}&des_addr_reg1[7:0])
|({8{reg_cnt[52]}}&sor_addr_reg0[15:8])
|({8{reg_cnt[53]}}&sor_addr_reg0[7:0])
|({8{reg_cnt[54]}}&sor_addr_reg1[15:8])
|({8{reg_cnt[55]}}&sor_addr_reg1[7:0])
|({8{reg_cnt[56]}}&lreg_reg[15:8])
|({8{reg_cnt[57]}}&lreg_reg[7:0])
|({8{reg_cnt[58]}}&lr_reg0[15:8])
|({8{reg_cnt[59]}}&lr_reg0[7:0])
|({8{reg_cnt[60]}}&lr_reg1[15:8])
|({8{reg_cnt[61]}}&lr_reg1[7:0])
|({8{reg_cnt[62]}}&lr_reg2[15:8])
|({8{reg_cnt[63]}}&lr_reg2[7:0])
|({8{reg_cnt[64]}}&lr_reg3[15:8])
|({8{reg_cnt[65]}}&lr_reg3[7:0])
|({8{reg_cnt[66]}}&hr_reg0[15:8])
|({8{reg_cnt[67]}}&hr_reg0[7:0])
|({8{reg_cnt[68]}}&hr_reg1[15:8])
|({8{reg_cnt[69]}}&hr_reg1[7:0])
|({8{reg_cnt[70]}}&hr_reg2[15:8])
|({8{reg_cnt[71]}}&hr_reg2[7:0])
|({8{reg_cnt[72]}}&hr_reg3[15:8])
|({8{reg_cnt[73]}}&hr_reg3[7:0]);



wire [7:0] dataint_r;
wire [7:0] dataint_next=datain;
wire dataint_en=wrsig_t;
sirv_gnrl_dfflr#(8) dataint_reg(dataint_en,dataint_next,dataint_r,clkout,reset);
wire [7:0] dataint=(uarto_en)?datain_uarto:dataint_r;
wire wrsig=(uarto_en)?wrsig_uarto:wrsig_t;

uarttx uarttx1(clkout, reset, dataint, wrsig, idle, tx);


endmodule

