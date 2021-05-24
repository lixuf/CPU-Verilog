module cdc #(
    parameter DEST_SYNC_FF = 2,//最大为10
	 parameter DW = 1
  ) (
    input dest_clk,    
    input  [DW-1:0] src_in ,        
    output [DW-1:0] dest_out       
  );
  

wire [DW-1:0] reg_out[DEST_SYNC_FF-1:0];
  
genvar i;
generate
 for(i=0;i<DEST_SYNC_FF;i=i+1)begin:reg_c
 if(i==0) begin
	sirv_gnrl_dff#(DW) cdc_dff(src_in,reg_out[i],dest_clk);
 end
 else begin
  sirv_gnrl_dff#(DW) cdc_dff(reg_out[i-1],reg_out[i],dest_clk);
 end
 end
endgenerate

assign dest_out=reg_out[DEST_SYNC_FF-1];
	
 
endmodule
