module pc_mux2(in0,in1,jump,pc_mux2out);
	input [31:0]in0,in1;
	input jump;
	output [31:0]pc_mux2out;
	assign pc_mux2out=(jump)?in1:in0;
endmodule