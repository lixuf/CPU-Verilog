module jc(
	input jc_en,
	input clk,
	input reset,
	input botton,
	output reg led1,
	output reg led2,
	output reg led3,
	output reg led4,
	input [15:0] xb_write_data,
	input [15:0] fir_write_data,
	
	input  xb_write_req,
	input  fir_write_req,
	
	input [15:0] lr_reg0,
	input [15:0] lr_reg1,
	input [15:0] lr_reg2,
	input [15:0] lr_reg3,
	input [15:0] hr_reg0,
	input [15:0] hr_reg1,
	input [15:0] hr_reg2,
	input [15:0] hr_reg3
);

reg  [15:0] lr__reg0;
reg  [15:0] lr__reg1;
reg  [15:0] lr__reg2;
reg  [15:0] lr__reg3;
reg  [15:0] hr__reg0;
reg  [15:0] hr__reg1;
reg  [15:0] hr__reg2;
reg  [15:0] hr__reg3;



wire vaild=xb_write_req|fir_write_req;
wire [15:0] data_t=({16{xb_write_req}}&xb_write_data)
			  |({16{fir_write_req}}&fir_write_data);
wire [15:0] data=data_t[15]?(~data_t+16'b1):data_t;
			  
always@(posedge clk )
begin
 if(jc_en)
 begin
lr__reg0=lr_reg0;
lr__reg1=lr_reg1;
lr__reg2=lr_reg2;
lr__reg3=lr_reg3;
hr__reg0=hr_reg0;
hr__reg1=hr_reg1;
hr__reg2=hr_reg2;
hr__reg3=hr_reg3;
 end
end

always@(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  led1<=1'b1;
  led2<=1'b1;
  led3<=1'b1;
  led4<=1'b1;
 end
 else if(~botton)
begin
  led1<=1'b1;
  led2<=1'b1;
  led3<=1'b1;
  led4<=1'b1;
 end
 else if(vaild) begin
 if(~(lr__reg0<data&data<hr__reg0))
   led1<=1'b0;
 if(~(lr__reg1<data&data<hr__reg1))
   led2<=1'b0;
 if(~(lr__reg2<data&data<hr__reg2))
   led3<=1'b0;
 if(~(lr__reg3<data&data<hr__reg3))
   led4<=1'b0;
 end
end




endmodule

 
