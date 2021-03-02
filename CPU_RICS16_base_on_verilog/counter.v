module counter(pc_addr,load,clock,rst,ir_addr);
input load,clock,rst;
input [12:0]ir_addr;
output [12:0]pc_addr;
reg [12:0]pc_addr;
always@(posedge clock or posedge rst)
begin
  if(rst)
    pc_addr<=13'b0000000000000;
  else
    if(load)
      pc_addr<=ir_addr;
    else
      pc_addr<=pc_addr+1;
end
endmodule