module add(
input [24:0] data0,
input [24:0] data1,
input [24:0] data2,
input [24:0] data3,
input [24:0] data4,
input [24:0] data5,
input [24:0] data6,
input [24:0] data7,

output [15:0] datao
);
wire [31:0] data_t0=data0[24]?{8'b11111111,data0[23:0]}:{7'b0,data0[24:0]};
wire [31:0] data_t1=data1[24]?{8'b11111111,data1[23:0]}:{7'b0,data1[24:0]};
wire [31:0] data_t2=data2[24]?{8'b11111111,data2[23:0]}:{7'b0,data2[24:0]};
wire [31:0] data_t3=data3[24]?{8'b11111111,data3[23:0]}:{7'b0,data3[24:0]};
wire [31:0] data_t4=data4[24]?{8'b11111111,data4[23:0]}:{7'b0,data4[24:0]};
wire [31:0] data_t5=data5[24]?{8'b11111111,data5[23:0]}:{7'b0,data5[24:0]};
wire [31:0] data_t6=data6[24]?{8'b11111111,data6[23:0]}:{7'b0,data6[24:0]};
wire [31:0] data_t7=data7[24]?{8'b11111111,data7[23:0]}:{7'b0,data7[24:0]};
wire [31:0] datao_tt=data_t0+
data_t1+
data_t2+
data_t3+
data_t4+
data_t5+
data_t6+
data_t7;
wire [15:0] datao_t=datao_tt[31:16];
//wire [27:0] datao_tt={datao_t[27],datao_t[27]?~datao_t[26:0]+27'b1:datao_t[26:0]};
assign datao=datao_t;

endmodule

