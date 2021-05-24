module fir_top(
input clk,
input reset,

input fir_en,
input read_quit,


output reg read_req,
input read_ready,
input [15:0] read_data,

output reg write_req,
output reg [15:0] write_data,

input [15:0] fir_reg_reg0,
input [15:0] fir_reg_reg1,
input [15:0] fir_reg_reg2,
input [15:0] fir_reg_reg3,
input [15:0] fir_reg_reg4,
input [15:0] fir_reg_reg5,
input [15:0] fir_reg_reg6,
input [15:0] fir_reg_reg7
);


reg [15:0] data_in_reg;
reg [1:0] move_state;
localparam read=2'b0;
localparam run=2'd1;
localparam write=2'd2;

reg run_vaild;
wire [15:0] run_out;
wire run_ready;
always@(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  move_state<=1'b0;
  run_vaild<=1'b0;
  read_req<=1'b0;
  write_req<=1'b0;
 end
 else if(fir_en&(~read_quit))
 begin
 case(move_state)
 
 read:begin
 write_req<=1'b0;
 if(~read_req)
  read_req<=1'b1;
 if(read_ready)
 begin
  data_in_reg<=read_data;
  read_req<=1'b0;
  move_state<=run;
  run_vaild<=1'b1;
 end
 
 end
 
 run:begin
  run_vaild<=1'b0;
  if(run_ready)
  begin
   run_vaild<=1'b0;
	move_state<=write;
  end
 end
 
 write:begin
   write_req<=1'b1;
	write_data<=run_out;
	move_state<=read;
 end
 
 endcase
 end
  else
  begin
   read_req<=1'b0;
	write_req<=1'b0;
  end
end



fir fir1(
.fir_reg_reg0(fir_reg_reg0),
.fir_reg_reg1(fir_reg_reg1),
.fir_reg_reg2(fir_reg_reg2),
.fir_reg_reg3(fir_reg_reg3),
.fir_reg_reg4(fir_reg_reg4),
.fir_reg_reg5(fir_reg_reg5),
.fir_reg_reg6(fir_reg_reg6),
.fir_reg_reg7(fir_reg_reg7),
.clk(clk),
.reset(reset),
.data_in(data_in_reg),
.data_in_ready(run_vaild),
.data_out(run_out),
.data_out_flag(run_ready)

);
endmodule
