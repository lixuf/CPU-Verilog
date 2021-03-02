//该模块为分支预测模块，主要用于预测是否需要跳转，和确保用于计算目标地址的寄存器无RAW依赖。
//无条件跳转指令默认跳转，有条件跳转指令的条件下，当目标地址即立即数为正数则跳转，反之则不跳。
//仅当jalr需要判断raw依赖。还需根据当前指令得出计算目标地址的两个操作数，送至公共数据通路的加法器计算。



`include "gen_defines.v"

module if_bpu(//还未处理冲突//使用静态预测，每次均向后跳转
input [`PC_Size-1:0] in_PC,
input clk,
input rst_n,
input dec_i_valid,

//来自minidec
input dec_jal,
input dec_jalr,
input dec_bxx,
input [`XLEN-1:0] dec_bjp_imm,
input [`RFIDX_WIDTH-1:0] dec_jalr_rs1_indx,

//jalr所需的寄存器
output bpu2rf_rs1_ena,//表示需要去
input [`XLEN-1:0] rf2bpu_x1,//从regfile直接引过来的寄存器，方便jalr调用
input [`XLEN-1:0] rf2bpu_rs1,//从寄存器堆读取到的寄存器，由


//输出到加法器
output [`PC_Size-1:0] op1,
output [`PC_Size-1:0] op2,

//输出控制信号
output bpu_wait,//冲突需等待一个时钟周期，可能发生在jalr
output pred_taken//预测为是否需要跳转

//来自ex级
input  oitf_empty,//表示无长指令执行
input  ir_empty,//表示无非长指令执行
input  ir_rs1en,//当前正在执行的指令待写入的寄存器索引
input  jalr_rs1idx_cam_irrdidx,//表示有非长指令访问x1未写回

//来自ifetch 表示非长指令执行完毕
input  ir_valid_clr,
  
);


//判断是否跳转
assign pred_taken=(	dec_jal	|	dec_jalr	|	(	dec_bxx	&	dec_bjp_imm[`XLEN-1]	));
							//jal和jalr直接跳转  bxx需要判断imm符号位，为正则跳转

							
//判断jalr所用的寄存器
///x0是常数0，因此无需去寄存器堆取
wire dec_jalr_rs1x0 =( dec_jalr_rs1_indx == `RFIDX_WIDTH'b0 );
///risc-v规定将x1和x5视作RAS，即做为函数调用所用的指令，需要压栈操作，一般使用x1
///故将x1旁路过来，做加速处理，以提高速度。
wire dec_jalr_rs1x1 =( dec_jalr_rs1_indx == `RFIDX_WIDTH'b1 );
wire dec_jalr_rs1xn =( ~dec_jalr_rs1x0 ) & ( ~dec_jalr_rs1x1 );


//判断x1以及xn是否存在RAW冲突，以判断当jalr发生的时候是否需要等待
//我们默认oitf不为空，即有长指令正在执行就默认存在RAW
//对于x1，只要有指令执行且该指令访问x1则默认有raw存在
//对于xn，只要有指令执行则默认有raw存在
//jalr_rs1idx_cam_irrdidx表示有非长指令访问x1未写回
//ir_empty表示存在非长指令正在执行
wire jalr_rs1x1_dep = dec_i_valid & dec_jalr & dec_jalr_rs1x1 & ((~oitf_empty) | (jalr_rs1idx_cam_irrdidx));
wire jalr_rs1xn_dep = dec_i_valid & dec_jalr & dec_jalr_rs1xn & ((~oitf_empty) | (~ir_empty));
//对jalr_rs1xn_dep的补充，jalr_rs1xn_dep当有非长指令存在就默认有raw依赖，太粗糙，因此当非常指令已经写回，
//或者不写回则清除掉jalr_rs1xn_dep
//ir_valid_clr表示指令已经执行完毕等待下个周期到来清除掉
//ir_rs1en表示结果需要写回
wire jalr_rs1xn_dep_ir_clr = (jalr_rs1xn_dep & oitf_empty & (~ir_empty)) & (ir_valid_clr | (~ir_rs1en));  
//jalr所读寄存器(x1或者其他寄存器)存在RAW冲突需要暂停一个周期，去寄存器堆读寄存器也需要暂停一个周期
assign bpu_wait = jalr_rs1x1_dep | jalr_rs1xn_dep | rs1xn_rdrf_set;//rs1xn_rdrf_set表示需要去寄存器堆读某个寄存器




//存储是否要读rs1指示的寄存器
wire rs1xn_rdrf_r;//表示当前寄存器所存储的值     当无数据冲突(访问的寄存器不存在raw)和无资源冲突(dec_i_valid)的时候则使用第一个读端口读寄存器
wire rs1xn_rdrf_set = (~rs1xn_rdrf_r) & dec_i_valid & dec_jalr & dec_jalr_rs1xn & ((~jalr_rs1xn_dep) | jalr_rs1xn_dep_ir_clr);
wire rs1xn_rdrf_clr = rs1xn_rdrf_r;
wire rs1xn_rdrf_ena = rs1xn_rdrf_set |   rs1xn_rdrf_clr;
wire rs1xn_rdrf_nxt = rs1xn_rdrf_set | (~rs1xn_rdrf_clr);
sirv_gnrl_dfflr #(1) rs1xn_rdrf_dfflrs(rs1xn_rdrf_ena, rs1xn_rdrf_nxt, rs1xn_rdrf_r, clk, rst_n);
//表示征用寄存器堆的第一个接口读寄存器
assign bpu2rf_rs1_ena = rs1xn_rdrf_set;





//加法器部分--为了节省面积，复用共享数据通路的加法器
////op1 需要if-else判断是哪个指令
assign op1=	(dec_bxx|dec_jal) ? in_PC[`PC_Szie-1:0]//bxx和jal只需要pc即可
			:  (dec_jalr&dec_jalr_rs1x0) ? `PC_Size'b0//jalr的需要寄存器的值作为基址，0号寄存器
			:	(dec_jalr&dec_jalr_rs1x1) ? rf2bpu_x1[`PC_Size-1:0]//1号寄存器
			:	rf2bpu_rs1[`PC_Size-1:0];//其他编号的寄存器

////op2固定输入，无需判断
assign op2= dec_bjp_imm[`PC_Size-1:0];

endmodule
