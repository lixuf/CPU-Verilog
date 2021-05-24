module uart_r_ram(
input clk_50_0,
input reset,
input rx,
output [31:0] r_in,
input [3:0] rdaddress,
input rdclock,
output tx
);


wire [7:0] dataout;        //接收数据输出
wire rdsig;
wire dataerror;      //数据出错指示
wire frameerror;     //帧出错指示
wire clkout;
clkdiv clkdiv2(
.clk50(clk_50_0), 
.rst_n(reset), 
.clkout(clkout)
);

uartrx uartrx1
(.clk(clkout),
 .rst_n(reset), 
 .rx(rx), 
 .dataout(dataout), 
 .rdsig(rdsig),
 .dataerror(dataerror),
 .frameerror(frameerror)
 );
wire idle;
uarttx uarttx2
(
.clk(clkout),
.rst_n(reset), 
.datain(dataout),
.wrsig(rdsig), 
.idle(idle), 
.tx(tx)
);


 
reg [5:0] wraddress;
always @(posedge clkout or negedge reset)
begin
 if(~reset)
  wraddress<=6'b0;
 else if(rdsig)
  wraddress<=wraddress+6'b1;
end


ram_r ram_r1(
.data(dataout),
.rdaddress(rdaddress),
.rdclock(rdclock),
.wraddress(wraddress),
.wrclock(clkout),
.wren(rdsig),
.q(r_in)
);
 
 
 
 endmodule
 