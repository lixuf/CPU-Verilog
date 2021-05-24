module uarto_top(
input clk_150_0,
input start_req,
input end_req,

output reg read_req,
input read_vaild,
input [15:0] read_data,

input clkout,
input reset,
output reg [7:0] datain_uarto,
output reg wrsig_uarto,
input idle
);

reg [2:0] uarto_state;
localparam read_data_s=3'b0;
localparam wait_idle1=3'd1;
localparam sendh8=3'd2;
reg [1:0] cnt_wait;
localparam wait_idle2=3'd3;
localparam sendl8=3'd4;

wire prom_run=start_req&(~end_req);
reg read_state;
localparam read_start=1'b0;
reg [15:0] read_data_t;
localparam idle_read=1'b1;
always@(posedge clk_150_0 or negedge reset)
begin
 if(~reset)
 begin
 read_state<=1'b0;
 read_req<=1'b0;
 end
 else if(prom_run)
 
 case(read_state)
 read_start:begin
 if((uarto_state==read_data_s)&(~read_req))
 begin
  read_req<=1'b1;
 end
 if(read_vaild)
 begin
  read_req<=1'b0;
  read_state<=idle_read;
  read_data_t<=read_data;
 end
 end
 
 idle_read:begin
  if(uarto_state==sendl8)
  begin
   read_state<=1'b0;
  end
 end
 
 endcase
  else
  begin
   read_req<=1'b0;
  end
end








always@(posedge clkout or negedge reset)
begin
 if(~reset)
 begin
  uarto_state<=3'd0;
  wrsig_uarto<=1'b0;
  cnt_wait<=2'b0;
 end
 else if(prom_run)
 begin
 case(uarto_state)
 read_data_s:begin
  wrsig_uarto<=1'b0;
  if(read_state==idle_read)
  begin
   uarto_state<=wait_idle1;
  end
 end
 
 wait_idle1:begin
  cnt_wait<=2'b0;
  datain_uarto<=read_data_t[15:8];
  if(~idle)
  begin
   wrsig_uarto<=1'b1;
	uarto_state<=sendh8;
  end
 end
 
 sendh8:begin
   wrsig_uarto<=1'b0;
 if(cnt_wait!=2'b11)
 cnt_wait<=cnt_wait+2'b1;

  if(~idle&(cnt_wait==2'b11))
  begin
   uarto_state<=wait_idle2;
  end
 end
 
 wait_idle2:begin
  cnt_wait<=2'b0;
  datain_uarto<=read_data_t[7:0];
   wrsig_uarto<=1'b1;
	uarto_state<=sendl8;
 end
 
 sendl8:begin
  wrsig_uarto<=1'b0;
 if(cnt_wait!=2'b11)
 cnt_wait<=cnt_wait+2'b1;

  if(~idle&(cnt_wait==2'b11))
   uarto_state<=read_data_s;
 end
 endcase
 end
end


endmodule
