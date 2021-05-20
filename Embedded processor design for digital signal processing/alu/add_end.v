module add_end(
input [15:0] data1,
input [15:0] data2,
output [15:0] datao
);

wire [16:0] data1t={data1[15],data1};
wire [16:0] data2t={data2[15],data2};
wire [16:0] dataot=data1t+data2t;
wire [15:0] dataott=dataot[16:1];
assign datao=dataott;

endmodule
