module pc_nadd(pc_naddin1,pc_naddin2,pc_naddout);
	input [31:0] pc_naddin1,pc_naddin2;
	output [31:0] pc_naddout;
	reg[31:0] pc_naddout;
	always@(pc_naddin2)
	begin
	 pc_naddout<=pc_naddin2+pc_naddin1;
	end
endmodule