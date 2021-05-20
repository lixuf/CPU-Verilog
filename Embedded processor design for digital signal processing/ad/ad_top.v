module ad_top(//ad读出来的数据需要锁存一下 
input clk,
input reset,
input ad_en,
input read_quite,

output reg read_req,
input read_ready,
input [15:0] read_data,

output reg write_req,
output reg [15:0] write_data

);


reg [15:0] data_in_reg;
reg move_state;
localparam read=1'b0;

localparam write=1'b1;


always@(posedge clk or negedge reset)
begin
 if(~reset)
 begin
  move_state<=1'b0;
  read_req<=1'b0;
  write_req<=1'b0;
 end
 else if(ad_en&(~read_quite))
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
  move_state<=write;
 end
 end
 
 write:begin
   write_req<=1'b1;
	write_data<=data_in_reg;
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

endmodule

