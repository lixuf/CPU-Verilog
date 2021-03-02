`timescale 1ns/1ns
module	register(data,ena,clk,rst,opc_iradders);
input [7:0]data;
input ena;
input clk;
input rst;
output [15:0]opc_iradders;
reg [15:0] opc_iradders;
reg state;
always@(posedge clk)
begin
  if(rst)
     begin
       opc_iradders<=16'b0000000000000000;
       state<=1'b0;
     end
  else
     begin
       if(ena)
         begin
	   casex(state)
	     1'b0:	begin
			  opc_iradders[15:8]<=data;
			  state<=1'b1;
			end
	     1'b1:	begin
			  opc_iradders[7:0]<=data;
			  state<=1'b0;
			end
	     default:	begin
			  opc_iradders<=16'bxxxxxxxxxxxxxxxx;
			  state<=1'bx;
			end
	   endcase
	 end
        else
	 state<=1'b0;
     end
end
endmodule
		  