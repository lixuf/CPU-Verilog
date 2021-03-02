//解码器，仅仅解码跳转相关部分，用以加速跳转的判断，以增加速度。
//复用了ex级的解码器，只需将用不到的输入置为0，输出悬空，编译器
//将去掉未用到的部分。


`include "gen_defines.v"

module if_minidec(
input [`IR_Size-1:0] instr,//指令

//输出至ifetch，用以得出该指令两个寄存器端口的索引值
output dec_rs1en,
output dec_rs2en,
output [`E203_RFIDX_WIDTH-1:0] dec_rs1idx,
output [`E203_RFIDX_WIDTH-1:0] dec_rs2idx,

//输出至ifetch，判断是否存在back2back
output dec_mulhsu,
output dec_mul   ,
output dec_div   ,
output dec_rem   ,
output dec_divu  ,
output dec_remu  ,



//输出至bpu
output dec_if32,//表示是否为32位指令，根据指令后两位判断
	//用于指示是何种跳转指令
	output dec_ifj,
	output dec_jal,//jal，jalr直接跳转
	output dec_jalr,
	output dec_bxx,//先判断后跳转的指令采取静态预测，只要立即数字段为正
						//(向后跳转)即跳转，反之不跳转
	//跳转所需的操作数
	output dec_bjp_imm,//立即数
	output dec_jalr_rs1idx//jalr目标寄存器索引
);

ex_decoder2 u_ex_decoder2(
.i_instr(instr),
.i_pc(`E203_PC_SIZE'b0),
.i_prdt_taken(1'b0), 
.i_muldiv_b2b(1'b0), 
.i_misalgn (1'b0),
.i_buserr  (1'b0),
.dbg_mode  (1'b0),
.dec_misalgn(),
.dec_buserr(),
.dec_ilegl(),
.dec_rs1x0(),
.dec_rs2x0(),
.dec_rs1en(dec_rs1en),
.dec_rs2en(dec_rs2en),
.dec_rdwen(),
.dec_rs1idx(dec_rs1idx),
.dec_rs2idx(dec_rs2idx),
.dec_rdidx(),
.dec_info(),  
.dec_imm(),
.dec_pc(),
.dec_mulhsu(dec_mulhsu),
.dec_mul   (dec_mul   ),
.dec_div   (dec_div   ),
.dec_rem   (dec_rem   ),
.dec_divu  (dec_divu  ),
.dec_remu  (dec_remu  ),
.dec_rv32(dec_rv32),
.dec_bjp (dec_bjp ),
.dec_jal (dec_jal ),
.dec_jalr(dec_jalr),
.dec_bxx (dec_bxx ),
.dec_jalr_rs1idx(dec_jalr_rs1idx),
.dec_bjp_imm    (dec_bjp_imm    )  
);

endmodule
