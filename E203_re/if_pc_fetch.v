`include "gen_defines.v"

module if_pc_fetch(
	output[`PC_Size-1:0] inspect_pc,//当前正在执行的指令的pc，用于之后的异常等处理
	input  clk,
   input  rst_n,
	
	//复位
	input  [`PC_Size-1:0] pc_rtvec,//pc复位默认地址，由顶层给定
	
   //停止等待信号
	input  ifu_halt_req,//其他设备传来的停止请求信号
   output ifu_halt_ack,//向其他设备回传-停止信号确认
	
	
	//icb总线通信
	////与ift2icb
	//////cmd通道
	output ifu_req_valid,//主到从-读写请求信号
	input  ifu_req_ready,//从到主-读写准许信号
	output [`PC_Size-1:0] ifu_req_pc,//主到从-读地址
	output ifu_req_seq,//是否为自增
	output ifu_req_seq_rv32,//是否为32位还是16位
	output [`PC_Size-1:0] ifu_req_last_pc,//当前pc
	//////rsp通道
	input  ifu_rsp_valid,//从到主-读写反馈请求信号
	output ifu_rsp_ready,//主到从-读写反馈请求准许信号
	input  ifu_rsp_err,//错误码
	input  [`IR_Size-1:0] ifu_rsp_instr,//从到主-根据pc读到的指令
	
	////与exu 传输IR
	output [`IR_Size-1:0] ifu_o_ir,//主到从-输出IR
	output [`PC_Size-1:0] ifu_o_pc,//主到从-输出前一个pc
	   //各种信号
	output ifu_o_pc_vld,
	output [`RFIDX_WIDTH-1:0] ifu_o_rs1_indx,
	output [`RFIDX_WIDTH-1:0] ifu_o_rs2_indx,
	output ifu_o_prdt_taken,//表示是否采取跳转               
	output ifu_o_misalgn,//指令非对齐                  
	output ifu_o_buserr,//访存错误指示，来自ift2icb访问itcm                   
	output ifu_o_muldiv_b2b,// 
	
	output ifu_o_valid,//主到从-读写请求信号 
	input  ifu_o_ready,//从到主-读写请求准许信号
	
	////pipe_flush,流水线冲刷相关,若请求则将ex传来的reg替换给pc--jalr
	input pipe_flush_req,//是否有流水线冲刷发生
	output pipe_flush_ack,//对流水线冲刷信号的确认
	input   [`PC_Size-1:0] pipe_flush_pc//流水线冲刷，从ex送来的pc，是jalr指令的xn
	

);


//pc的复位信号--第一个寄存器是为了锁存住复位信号
wire reset_flag_r;
sirv_gnrl_dffrs #(1) reset_flag_dffrs (1'b0, reset_flag_r, clk, rst_n);//同步rst_n，该寄存器默认复位值为1
wire reset_req_r;                                                      //即rst_n为0则写入0为1则写入1
wire reset_req_set = (~reset_req_r) & reset_flag_r;
wire reset_req_clr = reset_req_r & ifu_req_hsked;//当pc传输完，复位信号会被清除，即进入下一个周期
wire reset_req_ena = reset_req_set | reset_req_clr;
wire reset_req_nxt = reset_req_set | (~reset_req_clr);
sirv_gnrl_dfflr #(1) reset_req_dfflr (reset_req_ena, reset_req_nxt, reset_req_r, clk, rst_n);



	
//停止信号--停止请求信号来自交付(commit)单元，halt_ack为停止确认信号，当成功暂停新pc的产生则向commit会送确认信号
//当停止请求信号置0才会从新取pc执行。当未取指令或者取完指令的时候才会确认停止信号。
wire halt_ack_set;//寄存器置位信号
wire halt_ack_clr;//寄存器清除信号
wire halt_ack_ena;//寄存器写入使能，当清除和置位任意发生则置1
wire halt_ack_r;//寄存器当前信号
wire halt_ack_nxt;//下个周期存入寄存器的信号

wire ifu_no_outs;//表示未取指令或者取完指令             //ifu_rsp_valid 为1表示上一条指令执行完成，还未进入下一个周期
assign ifu_no_outs   = (~out_flag_r) | ifu_rsp_valid;//out_flag_r 当该设备与ift2icb的cmd握手成功后置1，当其为0则表示还未开始取指令
assign halt_ack_set = ifu_halt_req & (~halt_ack_r) & ifu_no_outs;
assign halt_ack_clr = halt_ack_r & (~ifu_halt_req);
assign halt_ack_ena = halt_ack_set | halt_ack_clr;
assign halt_ack_nxt = halt_ack_set | (~halt_ack_clr);
sirv_gnrl_dfflr #(1) halt_ack_dfflr (halt_ack_ena, halt_ack_nxt, halt_ack_r, clk, rst_n);

assign ifu_halt_ack = halt_ack_r;//回传停止确认信号


	


//ex到ifu，pipe_flush是流水线冲刷信号，当分支预测错误、中断和异常发生时，则产生流水线冲刷，冲刷掉后续信号。
//pipe_flush_req表示有流水线冲刷请求，但是该请求很有可能发生在取指令之前，即还未向ift2icb发送pc，因此需要
//一个寄存器锁存住流水线冲刷请求信号直到向ift2icb发送pc
assign pipe_flush_ack = 1'b1;//表示可响应流水线冲刷请求
wire pipe_flush_hsked = pipe_flush_req & pipe_flush_ack;//握手信号，表明接收到流水群冲刷信号
wire dly_pipe_flush_req = dly_flush_r;//还未向ift2icb发送pc，需要一个寄存器锁存住流水线冲刷请求信号
wire pipe_flush_req_real = pipe_flush_req | dly_pipe_flush_req;//最终的流水线请求信号，参与流水线冲刷的控制
	//锁存住流水线冲刷信号，直到向ift2icb发送pc
	wire dly_flush_set;
   wire dly_flush_clr;
   wire dly_flush_ena;
   wire dly_flush_nxt;
	wire dly_flush_r;         //ifu_req_hsked表示准备好向ift2icb传输pc以取得指令
	assign dly_flush_set = pipe_flush_req & (~ifu_req_hsked);//当请求到来且还未发送pc则锁存冲刷请求
	assign dly_flush_clr = dly_flush_r & ifu_req_hsked;//当发送完pc，代表冲刷执行完成，则清除寄存器
   assign dly_flush_ena = dly_flush_set | dly_flush_clr;
   assign dly_flush_nxt = dly_flush_set | (~dly_flush_clr);
	sirv_gnrl_dfflr #(1) dly_flush_dfflr (dly_flush_ena, dly_flush_nxt, dly_flush_r, clk, rst_n);
															 

//向寄存器写入信息
////当ift2icb送来新的指令后需要改变的寄存器
	//ir_valid_set为寄存器写入控制信号，其为1才能写入
	////将ir_valid_set锁存住，下个clk做为下列寄存器输出至ex级的指示
	wire ir_valid_r;//当前寄存器存储的值
	wire ir_valid_clr;//清除信号，当传送完ir后，即ifu_ir_o_hsked==1，或者流水线冲刷发生
	wire ir_valid_nxt;
	wire ir_valid_ena;
	wire ir_valid_set;//当取完指令且无流水线冲刷则置位
	assign ir_valid_set  = ifu_rsp_hsked & (~pipe_flush_req_real);//ifu_rsp_hsked：表明按照pc取完指令						
	assign ir_valid_clr  = ifu_ir_o_hsked | (pipe_flush_hsked & ir_valid_r);
	assign ir_valid_ena  = ir_valid_set  | ir_valid_clr;//写使能，ir_valid_set：表明以取到IR达到发送IR的条件
	assign ir_valid_nxt  = ir_valid_set  | (~ir_valid_clr);//下一个信号值
	sirv_gnrl_dfflr #(1) ir_valid_dfflr (ir_valid_ena, ir_valid_nxt, ir_valid_r, clk, rst_n);	
	////表示是否发生错误
	wire ifu_err_nxt = ifu_rsp_err;
	wire ifu_err_r;
	sirv_gnrl_dfflr #(1) ifu_err_dfflr(ir_valid_set, ifu_err_nxt, ifu_err_r, clk, rst_n);
	////表示分支预测结果
	wire prdt_taken;  
	wire ifu_prdt_taken_r;
	sirv_gnrl_dfflr #(1) ifu_prdt_taken_dfflr (ir_valid_set, prdt_taken, ifu_prdt_taken_r, clk, rst_n);
	////乘除法的back2back
		//乘除法的back2back  mulh/mulhu/mulsu后接mul被视为back2back
		//DIV后接REM REM后接DIV DIVU后接REMU REMU后接DIVU 被视为back2back
		wire minidec_mul ;//来自minidec，表示相应操作
		wire minidec_div ;
		wire minidec_rem ;
		wire minidec_divu;
		wire minidec_remu;
		assign ifu_muldiv_b2b_nxt = 
				(
					 ( minidec_mul & dec2ifu_mulhsu)//dec2ifu_xxx表示ex级正在执行的指令
					 | ( minidec_div  & dec2ifu_rem)//minidec_xxxx表示当前指令
				  | ( minidec_rem  & dec2ifu_div)
				  | ( minidec_divu & dec2ifu_remu)
				  | ( minidec_remu & dec2ifu_divu)
				)                               //由于判断时寄存器还未更新因此
				& (ir_rs1idx_r == ir_rs1idx_nxt)//xxx_r表示上一条指令的寄存器索引
				& (ir_rs2idx_r == ir_rs2idx_nxt)//xxx_nxt表示当前指令的寄存器索引
				& (~(ir_rs1idx_r == ir_rdidx))
				& (~(ir_rs2idx_r == ir_rdidx));
	wire ifu_muldiv_b2b_nxt;
	wire ifu_muldiv_b2b_r;
	sirv_gnrl_dfflr #(1) ir_muldiv_b2b_dfflr (ir_valid_set, ifu_muldiv_b2b_nxt, ifu_muldiv_b2b_r, clk, rst_n);
	////IR寄存器，为了节省能耗，把32位分为高低16位，因为16位指令不需要高16位因此高16位无需变动，以节省能耗
	wire [`E203_INSTR_SIZE-1:0] ifu_ir_nxt = ifu_rsp_instr;//从ift2icb送来的新的指令
	wire [`E203_INSTR_SIZE-1:0] ifu_ir_r;
	wire minidec_rv32;//表示当前指令是否为32位指令
	wire ir_hi_ena = ir_valid_set & minidec_rv32;//仅当当前指令为32位指令，该使能信号才能置位，高16位才能写入
	wire ir_lo_ena = ir_valid_set;
	sirv_gnrl_dfflr #(`E203_INSTR_SIZE/2) ifu_hi_ir_dfflr (ir_hi_ena, ifu_ir_nxt[31:16], ifu_ir_r[31:16], clk, rst_n);
	sirv_gnrl_dfflr #(`E203_INSTR_SIZE/2) ifu_lo_ir_dfflr (ir_lo_ena, ifu_ir_nxt[15: 0], ifu_ir_r[15: 0], clk, rst_n);
   ////minidec解码ir，得出的所需的两个寄存器的索引，多用于冒险判断
	wire minidec_rs1en;
   wire minidec_rs2en;
   wire [`E203_RFIDX_WIDTH-1:0] minidec_rs1idx;
   wire [`E203_RFIDX_WIDTH-1:0] minidec_rs2idx;
	
	wire minidec_fpu        = 1'b0;//没有fpu，全置为0即可
   wire minidec_fpu_rs1en  = 1'b0;
   wire minidec_fpu_rs2en  = 1'b0;
   wire minidec_fpu_rs3en  = 1'b0;
   wire minidec_fpu_rs1fpu = 1'b0;
   wire minidec_fpu_rs2fpu = 1'b0;
   wire minidec_fpu_rs3fpu = 1'b0;
   wire [`E203_RFIDX_WIDTH-1:0] minidec_fpu_rs1idx = `E203_RFIDX_WIDTH'b0;
   wire [`E203_RFIDX_WIDTH-1:0] minidec_fpu_rs2idx = `E203_RFIDX_WIDTH'b0;
	
   wire [`E203_RFIDX_WIDTH-1:0] ir_rs1idx_r;
   wire [`E203_RFIDX_WIDTH-1:0] ir_rs2idx_r;
   wire bpu2rf_rs1_ena;//jalr若目标寄存器为除1和0号的其他寄存器，需要使用rs1读寄存器堆
	     //由minidec送来的rsXen决定是否使能该寄存器堆端口，本cpu不支持fpu故可以把fpu部分信号忽略，下面信号便可简化很多
   wire ir_rs1idx_ena = (minidec_fpu & ir_valid_set & minidec_fpu_rs1en & (~minidec_fpu_rs1fpu)) | ((~minidec_fpu) & ir_valid_set & minidec_rs1en) | bpu2rf_rs1_ena;
   wire ir_rs2idx_ena = (minidec_fpu & ir_valid_set & minidec_fpu_rs2en & (~minidec_fpu_rs2fpu)) | ((~minidec_fpu) & ir_valid_set & minidec_rs2en);
   wire [`E203_RFIDX_WIDTH-1:0] ir_rs1idx_nxt = minidec_fpu ? minidec_fpu_rs1idx : minidec_rs1idx;
   wire [`E203_RFIDX_WIDTH-1:0] ir_rs2idx_nxt = minidec_fpu ? minidec_fpu_rs2idx : minidec_rs2idx;
   sirv_gnrl_dfflr #(`E203_RFIDX_WIDTH) ir_rs1idx_dfflr (ir_rs1idx_ena, ir_rs1idx_nxt, ir_rs1idx_r, clk, rst_n);
   sirv_gnrl_dfflr #(`E203_RFIDX_WIDTH) ir_rs2idx_dfflr (ir_rs2idx_ena, ir_rs2idx_nxt, ir_rs2idx_r, clk, rst_n);
////当不是在取新指令前需改变的寄存器，也就是更新pc阶段
	///ir_pc_vld_set为pc更新控制信号
	////锁存住ir_pc_vld_set
	wire ir_pc_vld_set;//当无流水线冲刷且产生新的pc且不能与ir同时传输
	wire ir_pc_vld_clr;
	wire ir_pc_vld_ena;        //ifu_ir_i_ready表示传送完ir或者还未开始传输ir
	wire ir_pc_vld_r;          //pc_newpend_r当有新的pc存入pc寄存器中，该量会置1
	assign ir_pc_vld_set = pc_newpend_r & ifu_ir_i_ready & (~pipe_flush_req_real) ;
	assign ir_pc_vld_clr = ir_valid_clr;
	assign ir_pc_vld_ena = ir_pc_vld_set | ir_pc_vld_clr;
	assign ir_pc_vld_nxt = ir_pc_vld_set | (~ir_pc_vld_clr);
	sirv_gnrl_dfflr #(1) ir_pc_vld_dfflr (ir_pc_vld_ena, ir_pc_vld_nxt, ir_pc_vld_r, clk, rst_n);
	////当前指令对应的pc
	wire [`E203_PC_SIZE-1:0] pc_r;
   wire [`E203_PC_SIZE-1:0] ifu_pc_nxt = pc_r;
   wire [`E203_PC_SIZE-1:0] ifu_pc_r;
   sirv_gnrl_dfflr #(`E203_PC_SIZE) ifu_pc_dfflr (ir_pc_vld_set, ifu_pc_nxt,  ifu_pc_r, clk, rst_n);
	

//向ex级传输
///握手
assign ifu_o_valid  = ir_valid_r;//ir系列寄存器读写请求信号
wire ifu_ir_o_hsked = (ifu_o_valid & ifu_o_ready) ;//控制ifetch进入下一个周期，即清除掉ir_vaild
                                                   //当ex级用完这些数据即发送ifu_o_ready
assign ifu_o_pc_vld = ir_pc_vld_r;//当前指令对应的pc送入ex级请求
///数据
assign ifu_o_ir  = ifu_ir_r;//当前指令
assign ifu_o_pc  = ifu_pc_r;//当前指令对应的pc
assign ifu_o_misalgn = 1'b0;//从未发生过，指令非对齐
assign ifu_o_buserr  = ifu_err_r;//错误信息，访存取指错误
assign ifu_o_rs1idx = ir_rs1idx_r;//寄存器端口1
assign ifu_o_rs2idx = ir_rs2idx_r;//寄存器端口2
assign ifu_o_prdt_taken = ifu_prdt_taken_r;//表示分支预测是否为真
assign ifu_o_muldiv_b2b = ifu_muldiv_b2b_r;//乘除法b2b
	

//向ex级传输后，或者新的周期开始	ir_valid_r表示ir寄存器不为空 ir_valid_clr表示ir寄存器将被清空
assign ifu_ir_i_ready   = (~ir_valid_r) | ir_valid_clr;//表示ir寄存器准备好读写	
	

//jalr依赖检查，检测是否有非长指令访问jalr的目标寄存器(除了0和1号寄存器)产生raw冒险
//均连接至bpu
wire ir_empty = ~ir_valid_r;//ir_valid_r表示当前ir以及ir相关寄存器是否更新
wire ir_rs1en = dec2ifu_rs1en;//来自ex级的解码器，表示正在执行的指令是否占用寄存器堆1口
wire ir_rden = dec2ifu_rden;//来自ex级的解码器，表示正在执行的指令是否写回寄存器堆
wire [`E203_RFIDX_WIDTH-1:0] ir_rdidx = dec2ifu_rdidx;//来自ex级的解码器，表示正在执行的指令写回寄存器的索引
wire [`E203_RFIDX_WIDTH-1:0] minidec_jalr_rs1idx;//来自if级的minidec，表明jalr的目标寄存器索引
wire jalr_rs1idx_cam_irrdidx = ir_rden & (minidec_jalr_rs1idx == ir_rdidx) & ir_valid_r;
	                                     //当在ex级正在执行的命令其写回寄存器索引与jalr目标寄存器索引一致，则存在raw冒险

													 



//连线
wire minidec_bjp;
wire minidec_jal;
wire minidec_jalr;
wire minidec_bxx;
wire [`E203_XLEN-1:0] minidec_bjp_imm;
if_minidec u_if_minidec (
      .instr       (ifu_ir_nxt         ),

      .dec_rs1en   (minidec_rs1en      ),
      .dec_rs2en   (minidec_rs2en      ),
      .dec_rs1idx  (minidec_rs1idx     ),
      .dec_rs2idx  (minidec_rs2idx     ),

      .dec_rv32    (minidec_rv32       ),
      .dec_bjp     (minidec_bjp        ),
      .dec_jal     (minidec_jal        ),
      .dec_jalr    (minidec_jalr       ),
      .dec_bxx     (minidec_bxx        ),

      .dec_mulhsu  (),
      .dec_mul     (minidec_mul ),
      .dec_div     (minidec_div ),
      .dec_rem     (minidec_rem ),
      .dec_divu    (minidec_divu),
      .dec_remu    (minidec_remu),



      .dec_jalr_rs1idx (minidec_jalr_rs1idx),
      .dec_bjp_imm (minidec_bjp_imm    )

);

wire bpu_wait;//表示因为发生raw依赖或jalr需要读寄存器均需要等待一个周期
wire [`E203_PC_SIZE-1:0] prdt_pc_add_op1;//计算目标pc地址的两个加法器操作数  
wire [`E203_PC_SIZE-1:0] prdt_pc_add_op2;
if_bpu u_if_bpu(

    .pc                       (pc_r),
                              
    .dec_jal                  (minidec_jal  ),
    .dec_jalr                 (minidec_jalr ),
    .dec_bxx                  (minidec_bxx  ),
    .dec_bjp_imm              (minidec_bjp_imm  ),
    .dec_jalr_rs1idx          (minidec_jalr_rs1idx  ),

    .dec_i_valid              (ifu_rsp_valid),
    .ir_valid_clr             (ir_valid_clr),
                
    .oitf_empty               (oitf_empty),
    .ir_empty                 (ir_empty  ),
    .ir_rs1en                 (ir_rs1en  ),

    .jalr_rs1idx_cam_irrdidx  (jalr_rs1idx_cam_irrdidx),
  
    .bpu_wait                 (bpu_wait       ),  
    .prdt_taken               (prdt_taken     ),  
    .prdt_pc_add_op1          (prdt_pc_add_op1),  
    .prdt_pc_add_op2          (prdt_pc_add_op2),

    .bpu2rf_rs1_ena           (bpu2rf_rs1_ena),
    .rf2bpu_x1                (rf2ifu_x1    ),
    .rf2bpu_rs1               (rf2ifu_rs1   ),

    .clk                      (clk  ) ,
    .rst_n                    (rst_n )                 
);




//pc流
////pc顺序自增所需的偏移量
wire [2:0] pc_incr_ofst = minidec_rv32 ? 3'd4 : 3'd2;//判断是32位还是16位,32位偏移量为4，16位偏移量为2
////跳转
wire bjp_req = minidec_bjp & prdt_taken;//是否采取跳转寻址pc
////复位
wire ifu_reset_req = reset_req_r;
////加法器的两个输入，加法器输出最终的跳转结果
wire [`E203_PC_SIZE-1:0] pc_add_op1=    bjp_req            ? prdt_pc_add_op1 ://跳转指令
                               ifu_reset_req      ? pc_rtvec ://复位
                                                    pc_r     ;//顺序取指
																	 
wire [`E203_PC_SIZE-1:0] pc_add_op2=	 bjp_req 			  ? prdt_pc_add_op2 :
                               ifu_reset_req      ? `E203_PC_SIZE'b0 :
                                                    pc_incr_ofst ;

////计算下一个pc
wire [`PC_Size-1:0] pc_nxt_pre;//第一步
assign pc_nxt_pre = pc_add_op2 +pc_add_op2;
assign pc_nxt = //第二步，最终结果
               pipe_flush_req ? {pipe_flush_pc[`E203_PC_SIZE-1:1],1'b0} ://流水线冲刷
               dly_pipe_flush_req ? {pc_r[`E203_PC_SIZE-1:1],1'b0} ://因为流水线冲刷来的太早
               {pc_nxt_pre[`E203_PC_SIZE-1:1],1'b0};


//与ift2icb的icb通信					
	//是否产生取指的请求 
		//bpu_wait:因jalr指令使用除x0和x1以外的寄存器需要等待一个周期或产生raw依赖
		//ifu_halt_req 暂停信号
		//reset_flag_r 是否准许来自top的复位信号	
		wire ifu_new_req = (~bpu_wait) & (~ifu_halt_req) & (~reset_flag_r) ;
		//复位用复位默认pc取指令  流水线冲刷用流水线冲刷pc取指令
		wire ifu_req_valid_pre = ifu_new_req | ifu_reset_req | pipe_flush_req_real ;
		//产生新请求的时机--无未解决的请求或者反馈通道握手即清除掉flag
			//寄存器--表示有请求还未解决
			wire out_flag_set = ifu_req_hsked;//当存在新的读ir请求则置位
			wire out_flag_clr;
			assign out_flag_clr = ifu_rsp_hsked;//当该请求被完成则清除
			wire out_flag_ena = out_flag_set | out_flag_clr;
			wire out_flag_nxt = out_flag_set | (~out_flag_clr);
			wire out_flag_r;//寄存器当前值
		wire new_req_condi = (~out_flag_r) | out_flag_clr;
      assign ifu_no_outs   = (~out_flag_r) | ifu_rsp_valid;//与new_req_condi完全相同
	//IR是否准备好被覆盖--当流水线冲刷到来时，因为要冲刷掉该指令IR随时可被覆盖。当其他情况下，ifu_ir_i_ready表示IR寄存器以及
	//IR相关寄存器可被覆盖，bpu_wait表示等待一个周期
	wire ifu_rsp2ir_ready = (pipe_flush_req_real) ? 1'b1 : (ifu_ir_i_ready & ifu_req_ready & (~bpu_wait));
	//cmd通道
	///握手
	assign ifu_req_valid = ifu_req_valid_pre & new_req_condi;//向ift2icb发生读写请求信号
   wire ifu_req_hsked  = (ifu_req_valid & ifu_req_ready) ;//握手成功可以传输
   ///数据
	assign ifu_req_pc = pc_nxt;
	assign ifu_req_seq_rv32 = minidec_rv32;//顺序自增是否是32位
	assign ifu_req_seq = (~pipe_flush_req_real) & (~ifu_reset_req) & (~ifetch_replay_req) & (~bjp_req);//判断是否顺序自增，排除法
   assign ifu_req_last_pc = pc_r;//pc寄存器未更新时的pc，即当前指令的上一条，保存上一条pc
	//rsp通道
	///握手
	assign ifu_rsp_ready = ifu_rsp2ir_ready;//当IR可被覆盖时即可接受读写请求的反馈数据
	wire ifu_rsp_hsked  = (ifu_rsp_valid & ifu_rsp_ready) ;//握手成功

	
	
//PC寄存器
assign inspect_pc = pc_r;//pc寄存器当前的值，用于soc
wire pc_ena = ifu_req_hsked | pipe_flush_hsked;//当rsp握手成功即用PC读取完IR，则pc寄存器可以更新，当产生流水线冲刷pc也可以更新
sirv_gnrl_dfflr #(`E203_PC_SIZE) pc_dfflr (pc_ena, pc_nxt, pc_r, clk, rst_n);

//存储PC更新信号
wire pc_newpend_set = pc_ena;//pc_ena代表pc更新
wire pc_newpend_clr = ir_pc_vld_set;//当该PC取完指令会被存到IR系列的pc寄存器中，表示为当前执行指令的PC
                                    //送入后面的阶段用于异常中断函数调用等
wire pc_newpend_ena = pc_newpend_set | pc_newpend_clr;
wire pc_newpend_nxt = pc_newpend_set | (~pc_newpend_clr);
sirv_gnrl_dfflr #(1) pc_newpend_dfflr (pc_newpend_ena, pc_newpend_nxt, pc_newpend_r, clk, rst_n);

/*

//与其他块的连线
////mini_decoder
if_minidec u_if_minidec (
	//由pc_fetch输出至minidec
	.in_IR 		(ifu_ir_nxt		),
	//由minidex输入至pc_fetch
	////跳转相关
	.dec_if32	(minidec_if32	),
	.dec_ifj		(minidec_ifj	),
	.dec_jal		(minidec_jal	),
	.dec_jalr	(minidec_jalr	),
	.dec_bxx    (minidec_bxx   ),
	.dec_jalr_rs1_indx	(minidec_jalr_rs1_indx),
	.dec_bjp_imm			(minidec_bjp_imm		 )

);

////bpu
if_bpu u_if_bpu (
	//由fetch输出至bpu
	.in_PC			(pc_r			),
	
	//由minidec输出至bpu
	.dec_jal					(minidec_jal	),
	.dec_jalr				(minidec_jalr	),
	.dec_bxx					(minidec_bxx	),
	.dec_bjp_imm			(minidec_bjp_imm	),
	.dec_jalr_rs1_indx	(minidec_jalr_rs1_indx),
	
	//由bpu输出至fetch
	.bpu_wait				(bpu_wait		),
	.pred_taken				(prdt_taken		),
	.op1						(pred_op1		),
	.op2						(pred_op2		),
	
	//bpu中jalr所需的寄存器
	.rf2bpu_x1				(rf2bpu_x1		),
	.rf2bpu_rs1				(rf2bpu_rs1		)，
	
	.clk						(clk           ),
	.rst_n					(rst_n			)
	
);







//常数--很迷
assign ifu_rsp_need_replay = 1'b0;
wire ifu_rsp_need_replay;
assign ifetch_replay_req = 1'b0;
wire ifetch_replay_req;
assign pipe_flush_ack = 1'b1;







	
//pc流
////pc顺序自增所需的偏移量
wire [2:0] pc_incr_offset = minidec_if32 ? 3'd4 : 3'd2;//判断是32位还是16位,32位偏移量为4，16位偏移量为2
////跳转
wire bjp_req = minidec_ifj & prdt_taken;//是否采取跳转寻址pc
////复位
wire ifu_reset_req = reset_req_r;
////加法器的两个输入，加法器输出最终的跳转结果
wire [`PC_Size-1:0] pc_op1=    bjp_req            ? pred_op1 ://跳转指令
                               ifu_reset_req      ? pc_rtvec ://复位
                                                    pc_r     ;//顺序取指
																	 
wire [`PC_Size-1:0] pc_op2=	 bjp_req 			  ? pred_op2 :
                               ifu_reset_req      ? `PC_Size'b0 :
                                                    pc_incr_offset ;

////计算预计的下一个pc
wire [`PC_Size-1:0] pc_nxt_pre;
assign pc_nxt_pre = pc_op1 + pc_op2;

////下一个pc
wire pc_nxt = pipe_flush_req ? {pipe_flush_pc[`PC_Size-1:1],1'b0} ://ex产生流水线冲刷，使用ex送来的新pc值
                 dly_pipe_flush_req ? {pc_r[`PC_Size-1:1],1'b0} ://产生控制冒险，需要暂停一个时钟周期
                 {pc_nxt_pre[`PC_Size-1:1],1'b0};//顺序取址

////pc寄存器更新
//////存当前周期的pc
wire [`PC_Size-1:0] ifu_pc_nxt = pc_r;//准备写入的pc
wire [`PC_Size-1:0] ifu_pc_r;//当前reg里的pc
sirv_gnrl_dfflr #(`PC_Size) ifu_pc_dfflr (ir_pc_vld_set, ifu_pc_nxt,  ifu_pc_r, clk, rst_n);					  
														//该信号在ir中
//////真正的pc，存下一周期的pc
wire [`PC_Size-1:0] pc_r;//当前pc
wire pc_ena = ifu_req_hsked | pipe_flush_hsked;
sirv_gnrl_dfflr #(`PC_Size) pc_dfflr (pc_ena, pc_nxt, pc_r, clk, rst_n);

////ir寄存器更新
wire [`IR_Size-1:0] ifu_ir_r;//ir寄存器当前输出
wire minidec_if32;//来自minidec，表明是否为32位指令
wire ir_hi_ena = ir_valid_set & minidec_if32;//使能 //ir_valid_set在与exu传输ir部分
wire ir_lo_ena = ir_valid_set;
sirv_gnrl_dfflr #(`IR_Size/2) ifu_hi_ir_dfflr (ir_hi_ena, ifu_ir_nxt[31:16], ifu_ir_r[31:16], clk, rst_n);
sirv_gnrl_dfflr #(`IR_Size/2) ifu_lo_ir_dfflr (ir_lo_ena, ifu_ir_nxt[15: 0], ifu_ir_r[15: 0], clk, rst_n);
    //分高低字节存储，以实现16/32兼容










	 
//icb总线通讯


////pc_fetch与ift2icb，取IR
//////cmd通道																	 
wire ifu_new_req = (~bpu_wait) & (~ifu_halt_req) & (~reset_flag_r) ;
     //是否产生新的pc bpu_wait:因jalr指令使用除x0和x1以外的寄存器需要等待一个周期或产生raw依赖
		//ifu_halt_req 暂停信号
		//reset_flag_r 是否准许来自top的复位信号	 															 
wire ifu_req_valid_pre = ifu_new_req | ifu_reset_req | pipe_flush_req_real ;																	 
		//已准备好pc可以向从设备发起读写指令
		
wire out_flag_clr;																	 
wire out_flag_r;																	 
wire new_req_condi = (~out_flag_r) | out_flag_clr;//达成向从设备发起读取指令的条件

assign ifu_no_outs   = (~out_flag_r) | ifu_rsp_valid;//rsq
assign ifu_req_valid = ifu_req_valid_pre & new_req_condi;//表明可以向从设备发起读写指令
wire ifu_req_hsked  = (ifu_req_valid & ifu_req_ready) ;//cmd握手成功

      //握手成功发数据
assign ifu_req_pc    = pc_nxt;//下一个pc
assign ifu_req_seq = (~pipe_flush_req_real) & (~ifu_reset_req) & (~ifetch_replay_req) & (~bjp_req);
        //判断是否为顺序自增
assign ifu_req_seq_rv32 = minidec_if32;//标明是16位还是32位
assign ifu_req_last_pc = pc_r;//自增前的pc

//////rsq通道
wire ifu_rsp2ir_ready = (pipe_flush_req_real) ? 1'b1 : (ifu_ir_i_ready & ifu_req_ready & (~bpu_wait));
assign ifu_rsp_ready = ifu_rsp2ir_ready;//准备好接收从设备发来的读写反馈信号，也表明IR已经准备好
wire ifu_rsp_hsked  = (ifu_rsp_valid & ifu_rsp_ready) ;//握手成功

wire [`IR_Size-1:0] ifu_ir_nxt = ifu_rsp_instr;
   //传输用pc取得的指令给ir寄存器

	

/////////本次通信需要传输的各种信号
  
	//ifu_o_rs1/2_indx
	wire [`RFIDX_WIDTH-1:0] ir_rs1idx_r;
	wire [`RFIDX_WIDTH-1:0] ir_rs2idx_r;//以下部分mini的信号还未设置
	wire ir_rs1idx_ena = (minidec_fpu & ir_valid_set & minidec_fpu_rs1en & (~minidec_fpu_rs1fpu)) | ((~minidec_fpu) & ir_valid_set & minidec_rs1en) | bpu2rf_rs1_ena;
	wire ir_rs2idx_ena = (minidec_fpu & ir_valid_set & minidec_fpu_rs2en & (~minidec_fpu_rs2fpu)) | ((~minidec_fpu) & ir_valid_set & minidec_rs2en);
	wire [`RFIDX_WIDTH-1:0] ir_rs1idx_nxt = minidec_fpu ? minidec_fpu_rs1idx : minidec_rs1idx;
	wire [`RFIDX_WIDTH-1:0] ir_rs2idx_nxt = minidec_fpu ? minidec_fpu_rs2idx : minidec_rs2idx;
	sirv_gnrl_dfflr #(`RFIDX_WIDTH) ir_rs1idx_dfflr (ir_rs1idx_ena, ir_rs1idx_nxt, ir_rs1idx_r, clk, rst_n);
	sirv_gnrl_dfflr #(`RFIDX_WIDTH) ir_rs2idx_dfflr (ir_rs2idx_ena, ir_rs2idx_nxt, ir_rs2idx_r, clk, rst_n);
	
	//ifu_o_prdt_taken
	wire prdt_taken;  
	wire ifu_prdt_taken_r;
	sirv_gnrl_dfflr #(1) ifu_prdt_taken_dfflr (ir_valid_set, prdt_taken, ifu_prdt_taken_r, clk, rst_n);	
	
	//ifu_o_muldiv_b2b
   wire ifu_muldiv_b2b_nxt;
   wire ifu_muldiv_b2b_r;
   sirv_gnrl_dfflr #(1) ir_muldiv_b2b_dfflr (ir_valid_set, ifu_muldiv_b2b_nxt, ifu_muldiv_b2b_r, clk, rst_n);	
   assign ifu_muldiv_b2b_nxt = //部分mini的信号未实现
      (
        | ( minidec_div  & dec2ifu_rem)
        | ( minidec_rem  & dec2ifu_div)
        | ( minidec_divu & dec2ifu_remu)
        | ( minidec_remu & dec2ifu_divu)
      )
      & (ir_rs1idx_r == ir_rs1idx_nxt)
      & (ir_rs2idx_r == ir_rs2idx_nxt)
      & (~(ir_rs1idx_r == ir_rdidx))
      & (~(ir_rs2idx_r == ir_rdidx))
      ;
		
	
/////////握手-传输
assign ifu_o_valid  = ir_valid_r;
wire ifu_ir_o_hsked = (ifu_o_valid & ifu_o_ready) ;//握手成功
  //传输数据
assign ifu_o_ir  = ifu_ir_r;//传输IR
assign ifu_o_pc  = ifu_pc_r;//传输PC，这个pc是前一个周期的
assign ifu_o_misalgn = 1'b0;//需要定义的一个控制信号，但是手册说从未发送过，故为常数0
assign ifu_o_buserr  = ifu_err_r;//取IR时候的错误码
assign ifu_o_rs1_indx = ir_rs1idx_r;//这里为啥需要提前传一下，还需要研究，没弄明白，手册说是mask需要看fpu指令详细
assign ifu_o_rs2_indx = ir_rs2idx_r;
assign ifu_o_prdt_taken = ifu_prdt_taken_r;//来自bpu，表明是否采用pc的预测值
assign ifu_o_muldiv_b2b = ifu_muldiv_b2b_r;//没弄明白
assign ifu_o_pc_vld = ir_pc_vld_r;//没弄明白




*/
	

	
	
	


endmodule
