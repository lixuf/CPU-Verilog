`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    ad7606 
//////////////////////////////////////////////////////////////////////////////////
module ad7606(
   input        		clk,                  //50mhz
	input        		rst_n,
	
	input [15:0] 		ad_data,            //ad7606 采样数据
	input        		ad_busy,            //ad7606 忙标志位 
   input        		first_data,         //ad7606 第一个数据标志位 	    
	output [2:0] 		ad_os,              //ad7606 过采样倍率选择
	output reg   		ad_cs,              //ad7606 AD cs
	output reg   		ad_rd,              //ad7606 AD data read
	output reg   		ad_reset,           //ad7606 AD reset
	output reg   		ad_convstab,         //ad7606 AD convert start

	output reg [15:0] ad_ch,
	
	output reg data_flag,
	//tool
	output [3:0] state_out,
	
	output reg clr_fifo
	
		

    );



reg [15:0]  cnt=16'b1111111111111100;
reg [5:0] i;
reg [3:0] state;

assign state_out=state;//tool

parameter IDLE=4'd0;
parameter AD_CONV=4'd1;
parameter Wait_1=4'd2;
parameter Wait_busy=4'd3;
parameter READ_CH1=4'd4;
parameter READ_CH2=4'd5;
parameter READ_CH3=4'd6;
parameter READ_CH4=4'd7;
parameter READ_CH5=4'd8;
parameter READ_CH6=4'd9;
parameter READ_CH7=4'd10;
parameter READ_CH8=4'd11;
parameter READ_DONE=4'd12;

assign ad_os=3'b000;

//AD 复位电路
always@(posedge clk)
 begin
    if(cnt<16'hff) begin//一开始是ffff
        cnt<=cnt+1;
        ad_reset<=1'b1;
      end
      else
        ad_reset<=1'b0;       
   end

always @(posedge clk) 
 begin
	 if (ad_reset==1'b1) begin 
			 state<=IDLE; 
			 ad_ch<=0;
          clr_fifo<=1'b0;
			 ad_cs<=1'b1;
			 ad_rd<=1'b1; 
			 ad_convstab<=1'b1;
			 i<=0;
			 data_flag<=1'b0;
	 end		 
	 else begin
		  case(state)
		  IDLE: begin
		      clr_fifo<=1'b0;
		       data_flag<=1'b0;
				 ad_cs<=1'b1;
				 ad_rd<=1'b1; 
				 ad_convstab<=1'b1; 
				 if(i==20) begin
					 i<=0;			 
					 state<=AD_CONV;
				 end
				 else 
					 i<=i+1'b1;
		  end
		  AD_CONV: begin	
	          data_flag<=1'b0;	  
				 if(i==2) begin                        //等待2个clock
					 i<=0;			 
					 state<=Wait_1;
					 ad_convstab<=1'b1;       				 
				 end
				 else begin
					 i<=i+1'b1;
					 ad_convstab<=1'b0;                     //启动AD转换
				 end
		  end
		  Wait_1: begin 
             data_flag<=1'b0;		  
				 if(i==5) begin                           //等待5个clock, 等待busy信号为高
					 i<=0;
					 state<=Wait_busy;
				 end
				 else 
					 i<=i+1'b1;
		  end		 
		  Wait_busy: begin   
             data_flag<=1'b0;		  
				 if(ad_busy==1'b0) begin                    //等待busy信号为低
					 i<=0;
		          clr_fifo<=1'b1;			 
					 state<=READ_CH1;
				 end
		  end
		  READ_CH1: begin 
		       clr_fifo<=1'b0;
				 ad_cs<=1'b0;                              //cs信号有效	  
				 if(i==3) begin
				    data_flag<=1'b1;
					 ad_rd<=1'b1;
					 i<=0;
					 ad_ch<=ad_data;                        //读CH1
					 state<=READ_CH2;				 
				 end
				 else begin
				    data_flag<=1'b0;
					 ad_rd<=1'b0;	
					 i<=i+1'b1;
				 end
		  end
		  READ_CH2: begin 
				 if(i==3) begin
				   data_flag<=1'b1;
					 ad_rd<=1'b1;
					 i<=0;
					 ad_ch<=ad_data;                        //读CH2
					 state<=READ_CH3;				 
				 end
				 else begin
				 data_flag<=1'b0;
					 ad_rd<=1'b0;	
					 i<=i+1'b1;
				 end
		  end
		  READ_CH3: begin 
				 if(i==3) begin
				 data_flag<=1'b1;
					 ad_rd<=1'b1;
					 i<=0;
					 ad_ch<=ad_data;                        //读CH3
					 state<=READ_CH4;				 
				 end
				 else begin
				 data_flag<=1'b0;
					 ad_rd<=1'b0;	
					 i<=i+1'b1;
				 end
		  end
		  READ_CH4: begin 
				 if(i==3) begin
				 data_flag<=1'b1;
					 ad_rd<=1'b1;
					 i<=0;
					 ad_ch<=ad_data;                        //读CH4
					 state<=READ_CH5;				 
				 end
				 else begin
				 data_flag<=1'b0;
					 ad_rd<=1'b0;	
					 i<=i+1'b1;
				 end
		  end
		  READ_CH5: begin 
				 if(i==3) begin
				 data_flag<=1'b1;
					 ad_rd<=1'b1;
					 i<=0;
					 ad_ch<=ad_data;                        //读CH5
					 state<=READ_CH6;				 
				 end
				 else begin
				 data_flag<=1'b0;
					 ad_rd<=1'b0;	
					 i<=i+1'b1;
				 end
		  end
		  READ_CH6: begin 
				 if(i==3) begin
				 data_flag<=1'b1;
					 ad_rd<=1'b1;
					 i<=0;
					 ad_ch<=ad_data;                        //读CH6
					 state<=READ_CH7;				 
				 end
				 else begin
				 data_flag<=1'b0;
					 ad_rd<=1'b0;	
					 i<=i+1'b1;
				 end
		  end
		  READ_CH7: begin 
				 if(i==3) begin
				 data_flag<=1'b1;
					 ad_rd<=1'b1;
					 i<=0;
					 ad_ch<=ad_data;                        //读CH7
					 state<=READ_CH8;				 
				 end
				 else begin
				 data_flag<=1'b0;
					 ad_rd<=1'b0;	
					 i<=i+1'b1;
				 end
		  end
		  READ_CH8: begin 
				 if(i==3) begin
				 data_flag<=1'b1;
					 ad_rd<=1'b1;
					 i<=0;
					 ad_ch<=ad_data;                        //读CH8
					 state<=READ_DONE;				 
				 end
				 else begin
				 data_flag<=1'b0;
					 ad_rd<=1'b0;	
					 i<=i+1'b1;
				 end
		  end
		  READ_DONE:begin
		  data_flag<=1'b0;
					 ad_rd<=1'b1;	 
					 ad_cs<=1'b1;
					 state<=IDLE;
		  end		
		  default:	begin
		  data_flag<=1'b0;
		  state<=IDLE;
		  end
		  endcase	
    end	  
				 
 end

endmodule
