module sign_extend(signin,signout,signout2);
	input [15:0] signin;
	output [31:0] signout,signout2;
	reg [31:0] signout,signout2;
	always@(signin)
	begin
	 if(signin[15])
           begin
	   signout={4'hffff,signin};
	   signout2=signout<<2;
	   end
	 else
	  begin
	   signout={4'h0000,signin};
	   signout2=signout<<2;
	  end
	end
endmodule