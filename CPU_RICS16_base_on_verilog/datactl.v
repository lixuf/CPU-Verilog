module datactl(in,data_ena,data);
output[7:0] data;
input [7:0]in;
input data_ena;
assign data=data_ena?in:8'bxxxx_xxxx;
endmodule