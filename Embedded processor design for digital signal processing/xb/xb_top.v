module xb_top(
input clk,
input reset,

input xb_en,
input read_quit,
input [7:0] select,

output reg read_req,
input read_ready,
input [15:0] read_data,

output reg write_req,
output reg [15:0] write_data,

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

reg [15:0] data_in_reg;
reg [1:0] move_state;
localparam read=2'b0;
localparam run=2'd1;
localparam write=2'd2;

reg run_vaild;
wire [15:0] run_out;
wire run_ready;
reg [3:0] cnt;
wire [3:0] wait_s=({4{select[0]}}&4'd2)
					|({4{select[1]}}&4'd4)
					|({4{select[2]}}&4'd8);
always@(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  cnt<=4'b0;
  move_state<=1'b0;
  run_vaild<=1'b0;
  read_req<=1'b0;
  write_req<=1'b0;
 end
 else if(xb_en&(~read_quit))
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
	cnt<=cnt+4'b1;
 end
 end
 
 run:begin
  run_vaild<=1'b0;
  if(cnt!=wait_s)
  begin
   move_state<=read;
  end
  else if(run_ready)
  begin
   cnt<=4'b0;
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




wire finish;
wire finish_g1;
wire finish_g2;
wire finish_g3;
wire [15:0] data_out_1_l;
wire [15:0] data_out_2_l;
wire [15:0] data_out_3_h;
assign run_out=({16{select[0]}}&data_out_1_l)
					|({16{select[1]}}&data_out_2_l)
					|({16{select[2]}}&data_out_3_h);
assign run_ready=(select[0]&finish_g1)
                 |(select[1]&finish_g2)
					  |(select[2]&finish_g3);
xb_top_3_grade  xb_top_3_grade1(
.phy_clk_0(clk),
.reset(reset),
.rd_data(data_in_reg),
.data_in_read(run_vaild),
.data_out_1_l(data_out_1_l),
.data_out_2_l(data_out_2_l),
.data_out_3_h(data_out_3_h),
.finish(finish),
.finish_g1(finish_g1),
.finish_g2(finish_g2),
.finish_g3(finish_g3),
.xbl_reg0(xbl_reg0),
.xbl_reg1(xbl_reg1),
.xbl_reg2(xbl_reg2),
.xbl_reg3(xbl_reg3),
.xbl_reg4(xbl_reg4),
.xbl_reg5(xbl_reg5),
.xbl_reg6(xbl_reg6),
.xbl_reg7(xbl_reg7),
.xbh_reg0(xbh_reg0),
.xbh_reg1(xbh_reg1),
.xbh_reg2(xbh_reg2),
.xbh_reg3(xbh_reg3),
.xbh_reg4(xbh_reg4),
.xbh_reg5(xbh_reg5),
.xbh_reg6(xbh_reg6),
.xbh_reg7(xbh_reg7)
);


endmodule
