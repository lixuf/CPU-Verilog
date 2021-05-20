module xpm_cdc_single #(
    parameter DEST_SYNC_FF = 2//最大为10
  ) (
    input dest_clk,    
    input src_in ,        
    output dest_out       
  );
  

wire reg_out[DEST_SYNC_FF-1:0];
  
genvar i;
generate
 for(i=0;i<DEST_SYNC_FF;i=i+1)begin:reg_c
 if(i==0) begin
	sirv_gnrl_dff#(1) cdc_dff(src_in,reg_out[i],dest_clk);
 end
 else begin
  sirv_gnrl_dff#(1) cdc_dff(reg_out[i-1],reg_out[i],dest_clk);
 end
 end
endgenerate

assign dest_out=reg_out[DEST_SYNC_FF-1];
	
 
endmodule
