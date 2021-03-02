//该模块为存储器访问命令生成模块，用于控制存储器访存，包括汇合器，互斥判别器，分发器，很难实现
//汇合器是将多个输入模块的输入数据汇合，在经过选择信号选择并输出，达到了将多条总线汇合为一条总线的效果
//汇合器先将各个输入模块的输入组合成bus的形式，接入已经定义好的多选器模块，进行选择输出，代码中带有bus字样的即为
//汇合器的输入，之后输出为单根总线。另外汇合器还需要将rsp信号分发给对应的输入模块，采取的方式也是将rsp信号组合成总线的
//形式然后经过多路选择器分发。汇合器的cmd和rsp通道间还存在一个fifo用以存储分发信息，保证按顺序反馈，在后面的fifo中有详
//细说明。
//互斥判别器仅在指令为load-reserved和store-condition时执行，需要详细阅读这两条指令的说明(作者手册附录A)，后面代码部分也
//有详细说明。
//分发器与汇合器很相似。
//之后还需判断lsu是否需要结果写回和写回agu。
//本模块大量使用icb总线，需要详细阅读作者手册的icb总线部分。
`include "gen_defines.v"
module ex_lsu_ctrl(
  output lsu_ctrl_active,
//来自commit--用于在互斥检测器中清除有效位
  input  commit_mret,//产生异常返回指令
  input  commit_trap,//产生中断
//存储器范围--用于判断访问的地址是访问哪个存储器
  input [`E203_ADDR_SIZE-1:0] itcm_region_indic,
  input [`E203_ADDR_SIZE-1:0] dtcm_region_indic,
//LSU结果写回-当lsu无需写回AGU时才会写回结果
  output lsu_o_valid, 
  input  lsu_o_ready, 
  output [`E203_XLEN-1:0] lsu_o_wbck_wdat,
  output [`E203_ITAG_WIDTH -1:0] lsu_o_wbck_itag,
  output lsu_o_wbck_err , 
  //写入commit的，用于异常控制
  output lsu_o_cmt_buserr,
  output [`E203_ADDR_SIZE -1:0] lsu_o_cmt_badaddr,
  output lsu_o_cmt_ld,
  output lsu_o_cmt_st,
//AGU到LSU的icb通信总线
  //cmd
  input                          agu_icb_cmd_valid, 
  output                         agu_icb_cmd_ready, 
  input  [`E203_ADDR_SIZE-1:0]   agu_icb_cmd_addr, 
  input                          agu_icb_cmd_read,  
  input  [`E203_XLEN-1:0]        agu_icb_cmd_wdata, 
  input  [`E203_XLEN/8-1:0]      agu_icb_cmd_wmask, 
  input                          agu_icb_cmd_lock,
  input                          agu_icb_cmd_excl,
  input  [1:0]                   agu_icb_cmd_size,
  input                          agu_icb_cmd_back2agu,//仅当AMO和非对齐的访存需要写回AGU
  input                          agu_icb_cmd_usign,
  input  [`E203_ITAG_WIDTH -1:0] agu_icb_cmd_itag,
  //rsp
  output                         agu_icb_rsp_valid, 
  input                          agu_icb_rsp_ready, 
  output                         agu_icb_rsp_err  , 
  output                         agu_icb_rsp_excl_ok,
  output [`E203_XLEN-1:0]        agu_icb_rsp_rdata,
//EAI到LSU的icb总线--本芯片不支持EAI故无用
  input                          eai_mem_holdup,//无eai，一直为0
  //cmd
  input                          eai_icb_cmd_valid,
  output                         eai_icb_cmd_ready,
  input  [`E203_ADDR_SIZE-1:0]   eai_icb_cmd_addr, 
  input                          eai_icb_cmd_read, 
  input  [`E203_XLEN-1:0]        eai_icb_cmd_wdata,
  input  [`E203_XLEN/8-1:0]      eai_icb_cmd_wmask,
  input                          eai_icb_cmd_lock,
  input                          eai_icb_cmd_excl,
  input  [1:0]                   eai_icb_cmd_size,
  //rsp
  output                         eai_icb_rsp_valid,
  input                          eai_icb_rsp_ready,
  output                         eai_icb_rsp_err  ,
  output                         eai_icb_rsp_excl_ok,
  output [`E203_XLEN-1:0]        eai_icb_rsp_rdata,
//与DTCM的icb总线
  //cmd
  output                         dtcm_icb_cmd_valid,
  input                          dtcm_icb_cmd_ready,
  output [`E203_DTCM_ADDR_WIDTH-1:0]   dtcm_icb_cmd_addr, 
  output                         dtcm_icb_cmd_read, 
  output [`E203_XLEN-1:0]        dtcm_icb_cmd_wdata,
  output [`E203_XLEN/8-1:0]      dtcm_icb_cmd_wmask,
  output                         dtcm_icb_cmd_lock,
  output                         dtcm_icb_cmd_excl,
  output [1:0]                   dtcm_icb_cmd_size,
  //rsp
  input                          dtcm_icb_rsp_valid,
  output                         dtcm_icb_rsp_ready,
  input                          dtcm_icb_rsp_err  ,
  input                          dtcm_icb_rsp_excl_ok,
  input  [`E203_XLEN-1:0]        dtcm_icb_rsp_rdata,
//与iTCM的icb总线
  //cmd
  output                         itcm_icb_cmd_valid,
  input                          itcm_icb_cmd_ready,
  output [`E203_ITCM_ADDR_WIDTH-1:0]   itcm_icb_cmd_addr, 
  output                         itcm_icb_cmd_read, 
  output [`E203_XLEN-1:0]        itcm_icb_cmd_wdata,
  output [`E203_XLEN/8-1:0]      itcm_icb_cmd_wmask,
  output                         itcm_icb_cmd_lock,
  output                         itcm_icb_cmd_excl,
  output [1:0]                   itcm_icb_cmd_size,
  //rsp
  input                          itcm_icb_rsp_valid,
  output                         itcm_icb_rsp_ready,
  input                          itcm_icb_rsp_err  ,
  input                          itcm_icb_rsp_excl_ok  ,
  input  [`E203_XLEN-1:0]        itcm_icb_rsp_rdata,
//与biu的icb总线
  //cmd
  output                         biu_icb_cmd_valid,
  input                          biu_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   biu_icb_cmd_addr, 
  output                         biu_icb_cmd_read, 
  output [`E203_XLEN-1:0]        biu_icb_cmd_wdata,
  output [`E203_XLEN/8-1:0]      biu_icb_cmd_wmask,
  output                         biu_icb_cmd_lock,
  output                         biu_icb_cmd_excl,
  output [1:0]                   biu_icb_cmd_size,
  //rsp
  input                          biu_icb_rsp_valid,
  output                         biu_icb_rsp_ready,
  input                          biu_icb_rsp_err  ,
  input                          biu_icb_rsp_excl_ok  ,
  input  [`E203_XLEN-1:0]        biu_icb_rsp_rdata,


  input  clk,
  input  rst_n
);



///AGU到LSU
	///cmd通道  //输入到汇合器的cmd通道汇合并选通
		//握手   //无eai故eai_mem_holdup一直为0
		wire agu_icb_cmd_valid_pos;//来自AGU的读写请求信号  //该写法为优先级选择
		assign agu_icb_cmd_valid_pos = (~eai_mem_holdup) & agu_icb_cmd_valid;
		wire agu_icb_cmd_ready_pos;//写回AGU的读写         //eai优先级高，故无eai访问才可agu访问
		assign agu_icb_cmd_ready     = (~eai_mem_holdup) & agu_icb_cmd_ready_pos;
		//数据                        
		wire [USR_W-1:0] agu_icb_cmd_usr =//AGU的CMD通道的全部数据--输入到汇合器的输入端
      {
         agu_icb_cmd_back2agu//表示是否需要lsu写回agu  
        ,agu_icb_cmd_usign//表示是否为无符号操作
        ,agu_icb_cmd_read//表示是否需要读存储器
        ,agu_icb_cmd_size//基本访问单位
        ,agu_icb_cmd_itag//该指令在oitf中的位置
        ,agu_icb_cmd_addr//该指令访问的地址
        ,agu_icb_cmd_excl//该指令是否需要互斥
      };
		//还有其他数据，可在汇合器汇合部分即组成bus部分看到
	///rsp通道 //由汇合器的rsp通道分发出来的
	   //握手
		wire pre_agu_icb_rsp_valid;//读写请求反馈信号
      wire pre_agu_icb_rsp_ready;//读写请求反馈准许信号
		//数据
		wire pre_agu_icb_rsp_err  ;//错误码
      wire pre_agu_icb_rsp_excl_ok;//互斥执行成功
      wire [`E203_XLEN-1:0] pre_agu_icb_rsp_rdata;//读取到的数据
		wire pre_agu_icb_rsp_back2agu;//表示当需要lsu写回agu时 lsu是否完成写回agu的操作
      wire pre_agu_icb_rsp_usign;//以下同cmd
      wire pre_agu_icb_rsp_read;
      wire pre_agu_icb_rsp_excl;
      wire [2-1:0] pre_agu_icb_rsp_size;
		wire [`E203_ITAG_WIDTH -1:0] pre_agu_icb_rsp_itag;
		wire [`E203_ADDR_SIZE-1:0] pre_agu_icb_rsp_addr;
		wire [USR_W-1:0] pre_agu_icb_rsp_usr;//反馈的所有数据
		assign 
      {
         pre_agu_icb_rsp_back2agu  
        ,pre_agu_icb_rsp_usign
        ,pre_agu_icb_rsp_read
        ,pre_agu_icb_rsp_size
        ,pre_agu_icb_rsp_itag 
        ,pre_agu_icb_rsp_addr
        ,pre_agu_icb_rsp_excl 
      } = pre_agu_icb_rsp_usr;
		
		
		
		



//AGU，EAI和fpu的ICB总线经过汇合器汇合---本芯片未添加EAI，故eai_mem_holdup一直为0
///无浮点数和协处理器，故汇合器的浮点运算单元和协处理器的输入均为0
wire [USR_W-1:0] eai_icb_cmd_usr = {USR_W-1{1'b0}};
wire [USR_W-1:0] fpu_icb_cmd_usr = {USR_W-1{1'b0}};
wire [USR_W-1:0] fpu_icb_rsp_usr;
wire [USR_W-1:0] eai_icb_rsp_usr;
///汇合器参数
localparam LSU_ARBT_I_NUM   = 2;//输入接口的数量
localparam LSU_ARBT_I_PTR_W = 1;//单次输出的数量
localparam USR_W = (`E203_ITAG_WIDTH+6+`E203_ADDR_SIZE);//输入数据的宽度
localparam USR_PACK_EXCL = 0;//指明使用互斥位在第0位	
///汇合器的输入汇合--就是将多个输入组合成bus的形式然后用选择信号选择输出
	//CMD通道
	wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_valid;
	wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_ready;
	wire [LSU_ARBT_I_NUM*`E203_ADDR_SIZE-1:0] arbt_bus_icb_cmd_addr;
	wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_read;
	wire [LSU_ARBT_I_NUM*`E203_XLEN-1:0] arbt_bus_icb_cmd_wdata;//待写入的数据
	wire [LSU_ARBT_I_NUM*`E203_XLEN/8-1:0] arbt_bus_icb_cmd_wmask;//因为写入数据可能按字节或者半字
	wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_lock;            //需要遮住不写的部分防止改变其他位置的数据
	wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_excl;
	wire [LSU_ARBT_I_NUM*2-1:0] arbt_bus_icb_cmd_size;
	wire [LSU_ARBT_I_NUM*USR_W-1:0] arbt_bus_icb_cmd_usr;
	wire [LSU_ARBT_I_NUM*2-1:0] arbt_bus_icb_cmd_burst;
	wire [LSU_ARBT_I_NUM*2-1:0] arbt_bus_icb_cmd_beat;	
	wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_valid_raw;
   assign arbt_bus_icb_cmd_valid_raw =
                           {
                             agu_icb_cmd_valid
                           , eai_icb_cmd_valid
                           } ;
	assign arbt_bus_icb_cmd_valid =
                           {
                             agu_icb_cmd_valid_pos
                           , eai_icb_cmd_valid
                           } ;

   assign arbt_bus_icb_cmd_addr =
                           {
                             agu_icb_cmd_addr
                           , eai_icb_cmd_addr
                           } ;

   assign arbt_bus_icb_cmd_read =
                           {
                             agu_icb_cmd_read
                           , eai_icb_cmd_read
                           } ;

   assign arbt_bus_icb_cmd_wdata =
                           {
                             agu_icb_cmd_wdata
                           , eai_icb_cmd_wdata
                           } ;

   assign arbt_bus_icb_cmd_wmask =
                           {
                             agu_icb_cmd_wmask
                           , eai_icb_cmd_wmask
                           } ;
                         
   assign arbt_bus_icb_cmd_lock =
                           {
                             agu_icb_cmd_lock
                           , eai_icb_cmd_lock
                           } ;

   assign arbt_bus_icb_cmd_burst =
                           {
                             2'b0
                           , 2'b0
                           } ;

   assign arbt_bus_icb_cmd_beat =
                           {
                             1'b0
                           , 1'b0
                           } ;

   assign arbt_bus_icb_cmd_excl =
                           {
                             agu_icb_cmd_excl
                           , eai_icb_cmd_excl
                           } ;
                           
   assign arbt_bus_icb_cmd_size =
                           {
                             agu_icb_cmd_size
                           , eai_icb_cmd_size
                           } ;

   assign arbt_bus_icb_cmd_usr =
                           {
                             agu_icb_cmd_usr
                           , eai_icb_cmd_usr
                           } ;

   assign                   {
                             agu_icb_cmd_ready_pos
                           , eai_icb_cmd_ready
                           } = arbt_bus_icb_cmd_ready;
	//RSP通道--汇合的输出部分，需要将输入的数据拆分给各个输入模块
   wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_valid;
   wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_ready;
   wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_err;
   wire [LSU_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_excl_ok;
   wire [LSU_ARBT_I_NUM*`E203_XLEN-1:0] arbt_bus_icb_rsp_rdata;//读取到的数据
   wire [LSU_ARBT_I_NUM*USR_W-1:0] arbt_bus_icb_rsp_usr;
   assign                   {
                             pre_agu_icb_rsp_valid
                           , eai_icb_rsp_valid
                           } = arbt_bus_icb_rsp_valid;

   assign                   {
                             pre_agu_icb_rsp_err
                           , eai_icb_rsp_err
                           } = arbt_bus_icb_rsp_err;

   assign                   {
                             pre_agu_icb_rsp_excl_ok
                           , eai_icb_rsp_excl_ok
                           } = arbt_bus_icb_rsp_excl_ok;


   assign                   {
                             pre_agu_icb_rsp_rdata
                           , eai_icb_rsp_rdata
                           } = arbt_bus_icb_rsp_rdata;

   assign                   {
                             pre_agu_icb_rsp_usr
                           , eai_icb_rsp_usr
                           } = arbt_bus_icb_rsp_usr;

   assign arbt_bus_icb_rsp_ready = {
                             pre_agu_icb_rsp_ready
                           , eai_icb_rsp_ready
                           };
///汇合器本体定义
sirv_gnrl_icb_arbt # (
.ARBT_SCHEME (0),
.ALLOW_0CYCL_RSP (0),
.FIFO_OUTS_NUM   (`E203_LSU_OUTS_NUM),
.FIFO_CUT_READY  (0),
.ARBT_NUM   (LSU_ARBT_I_NUM),
.ARBT_PTR_W (LSU_ARBT_I_PTR_W),
.USR_W      (USR_W),
.AW         (`E203_ADDR_SIZE),
.DW         (`E203_XLEN) 
) u_lsu_icb_arbt(
.o_icb_cmd_valid        (arbt_icb_cmd_valid )     ,
.o_icb_cmd_ready        (arbt_icb_cmd_ready )     ,
.o_icb_cmd_read         (arbt_icb_cmd_read )      ,
.o_icb_cmd_addr         (arbt_icb_cmd_addr )      ,
.o_icb_cmd_wdata        (arbt_icb_cmd_wdata )     ,
.o_icb_cmd_wmask        (arbt_icb_cmd_wmask)      ,
.o_icb_cmd_burst        (arbt_icb_cmd_burst)     ,
.o_icb_cmd_beat         (arbt_icb_cmd_beat )     ,
.o_icb_cmd_excl         (arbt_icb_cmd_excl )     ,
.o_icb_cmd_lock         (arbt_icb_cmd_lock )     ,
.o_icb_cmd_size         (arbt_icb_cmd_size )     ,
.o_icb_cmd_usr          (arbt_icb_cmd_usr  )     ,

.o_icb_rsp_valid        (arbt_icb_rsp_valid )     ,
.o_icb_rsp_ready        (arbt_icb_rsp_ready )     ,
.o_icb_rsp_err          (arbt_icb_rsp_err)        ,
.o_icb_rsp_excl_ok      (arbt_icb_rsp_excl_ok)    ,
.o_icb_rsp_rdata        (arbt_icb_rsp_rdata )     ,
.o_icb_rsp_usr          (arbt_icb_rsp_usr   )     ,
                               
.i_bus_icb_cmd_ready    (arbt_bus_icb_cmd_ready ) ,
.i_bus_icb_cmd_valid    (arbt_bus_icb_cmd_valid ) ,
.i_bus_icb_cmd_read     (arbt_bus_icb_cmd_read )  ,
.i_bus_icb_cmd_addr     (arbt_bus_icb_cmd_addr )  ,
.i_bus_icb_cmd_wdata    (arbt_bus_icb_cmd_wdata ) ,
.i_bus_icb_cmd_wmask    (arbt_bus_icb_cmd_wmask)  ,
.i_bus_icb_cmd_burst    (arbt_bus_icb_cmd_burst)  ,
.i_bus_icb_cmd_beat     (arbt_bus_icb_cmd_beat )  ,
.i_bus_icb_cmd_excl     (arbt_bus_icb_cmd_excl )  ,
.i_bus_icb_cmd_lock     (arbt_bus_icb_cmd_lock )  ,
.i_bus_icb_cmd_size     (arbt_bus_icb_cmd_size )  ,
.i_bus_icb_cmd_usr      (arbt_bus_icb_cmd_usr  )  ,
                                
.i_bus_icb_rsp_valid    (arbt_bus_icb_rsp_valid ) ,
.i_bus_icb_rsp_ready    (arbt_bus_icb_rsp_ready ) ,
.i_bus_icb_rsp_err      (arbt_bus_icb_rsp_err)    ,
.i_bus_icb_rsp_excl_ok  (arbt_bus_icb_rsp_excl_ok),
.i_bus_icb_rsp_rdata    (arbt_bus_icb_rsp_rdata ) ,
.i_bus_icb_rsp_usr      (arbt_bus_icb_rsp_usr) ,
                             
.clk                    (clk  ),
.rst_n                  (rst_n)
);
///汇合器的输出/输入--cmd是输出汇合器进行之后的运算，rsp是输入汇合器分发给agu/fpu/eai
  ///cmd
	//握手
	wire arbt_icb_cmd_valid;
	wire arbt_icb_cmd_ready;
	//数据--就是将bus中数据按照选择信号选则输出
	wire [`E203_ADDR_SIZE-1:0] arbt_icb_cmd_addr;
   wire arbt_icb_cmd_read;
   wire [`E203_XLEN-1:0] arbt_icb_cmd_wdata;
   wire [`E203_XLEN/8-1:0] arbt_icb_cmd_wmask;
   wire arbt_icb_cmd_lock;
   wire arbt_icb_cmd_excl;
   wire [1:0] arbt_icb_cmd_size;
   wire [1:0] arbt_icb_cmd_burst;
   wire [1:0] arbt_icb_cmd_beat;
   wire [USR_W-1:0] arbt_icb_cmd_usr;
  ///rsp--将反馈数据组成之后组成bus形式然后分发
   //握手
	wire arbt_icb_rsp_valid;
   wire arbt_icb_rsp_ready;
   //数据
	wire arbt_icb_rsp_err;
   wire arbt_icb_rsp_excl_ok;
   wire [`E203_XLEN-1:0] arbt_icb_rsp_rdata;
   wire [USR_W-1:0] arbt_icb_rsp_usr;
///汇合器中存放输入输出间的分发信息的fifo，当cmd握手就将分发信息压入fifo，当rsp握手则在fifo中提出一个分发信息
///fifo这种数据结构可以保证按顺序写回请求信号所对应的反馈信号，该fifo默认深度为1，表示可以有一个滞外指令
   //分发信息--除了以下的5个还有分发器输入的数据--即FIFO的入队信息
	///分发信息长度
	localparam SPLT_FIFO_W = (USR_W+5);
	///按照地址判断访问哪个存储器       //只需判断地址范围以上的位是否与地址范围的高位一致？？//是分发器的选择端口
	wire arbt_icb_cmd_itcm = (arbt_icb_cmd_addr[`E203_ITCM_BASE_REGION] ==  itcm_region_indic[`E203_ITCM_BASE_REGION]);
	wire arbt_icb_cmd_dtcm = (arbt_icb_cmd_addr[`E203_DTCM_BASE_REGION] ==  dtcm_region_indic[`E203_DTCM_BASE_REGION]);
	wire arbt_icb_cmd_dcache = 1'b0;//无cache，故一直为0                                             //若非I/DTCM则需要BIU的IO接口去外存取
	wire arbt_icb_cmd_biu    = (~arbt_icb_cmd_itcm) & (~arbt_icb_cmd_dtcm) & (~arbt_icb_cmd_dcache);//或者是访问外部设备寄存器
	///表示store-c是否执行成功
	//wire arbt_icb_cmd_scond_true;
	//fifo输出的信息--即入队的分发信息，把cmd对应到其rsp
	wire arbt_icb_rsp_biu;
   wire arbt_icb_rsp_dcache;
   wire arbt_icb_rsp_dtcm;
   wire arbt_icb_rsp_itcm;
   wire arbt_icb_rsp_scond_true;	
	//fifo的控制信号
	///fifo的操作--进/出 
	wire splt_fifo_wen = arbt_icb_cmd_valid & arbt_icb_cmd_ready;//cmd握手，进入fifo等待反馈
	wire splt_fifo_ren = arbt_icb_rsp_valid & arbt_icb_rsp_ready;//rsq握手，反馈信号到来，退出fifo，并分发回去
	///fifo入队
	wire splt_fifo_i_ready;//入队准许信号
   wire splt_fifo_i_valid = splt_fifo_wen;//入队请求信号
	///fifo出队
	wire splt_fifo_o_valid;//出队请求信号
   wire splt_fifo_o_ready = splt_fifo_ren;//出队准许信号
	///fifo状态
   wire splt_fifo_empty   = (~splt_fifo_o_valid);//表示队空
   wire splt_fifo_full    = (~splt_fifo_i_ready);//表示队满
   //fifo入队接口
	wire [SPLT_FIFO_W-1:0] splt_fifo_wdat;//入队数据
	assign splt_fifo_wdat =  {
          arbt_icb_cmd_biu,
          arbt_icb_cmd_dcache,
          arbt_icb_cmd_dtcm,
          arbt_icb_cmd_itcm,
          arbt_icb_cmd_scond_true,
          arbt_icb_cmd_usr 
          };
	//fifo出队接口
	wire [SPLT_FIFO_W-1:0] splt_fifo_rdat;//出队数据	
	assign   
      {
          arbt_icb_rsp_biu,
          arbt_icb_rsp_dcache,
          arbt_icb_rsp_dtcm,
          arbt_icb_rsp_itcm,
          arbt_icb_rsp_scond_true, 
          arbt_icb_rsp_usr 
          } = splt_fifo_rdat & {SPLT_FIFO_W{splt_fifo_o_valid}};
	//fifo本体
	sirv_gnrl_pipe_stage # (
    .CUT_READY(0),
    .DP(1),
    .DW(SPLT_FIFO_W)
   ) u_e203_lsu_splt_stage (
    .i_vld  (splt_fifo_i_valid),
    .i_rdy  (splt_fifo_i_ready),
    .i_dat  (splt_fifo_wdat ),
    .o_vld  (splt_fifo_o_valid),
    .o_rdy  (splt_fifo_o_ready),  
    .o_dat  (splt_fifo_rdat ),  
  
    .clk  (clk),
    .rst_n(rst_n)
   );
	
	
	

	
	
	
	
	
	
//互斥检测器--实现A指令中的load和store的互斥属性，即load相似与信号量的P操作，store相似于信号量的V操作
//当执行load-r时将互斥有效标志设置为，且访问地址写入互斥检测器，之后只有当store-c存储的地址与互斥检测器中的一样时
//才判断为执行成功，并写入以及清除掉互斥检测器的有效标志位，以此实现获取(load-r)与释放(stire-c)属性。
//除了正常清除互斥检测器中有效位之外，还有如下意外情况可清除有效位：异常，中断和mert
///互斥检测器
	//有效位
	wire excl_flg_r;
	wire excl_flg_clr;
	wire excl_flg_ena = excl_flg_set | excl_flg_clr;
   wire excl_flg_nxt = excl_flg_set | (~excl_flg_clr);
   sirv_gnrl_dfflr #(1) excl_flg_dffl (excl_flg_ena, excl_flg_nxt, excl_flg_r, clk, rst_n);
	//存入的地址
	wire [`E203_ADDR_SIZE-1:0] excl_addr_r;
	wire excl_addr_ena;
	wire [`E203_ADDR_SIZE-1:0] excl_addr_nxt;
	sirv_gnrl_dfflr #(`E203_ADDR_SIZE) excl_addr_dffl (excl_addr_ena, excl_addr_nxt, excl_addr_r, clk, rst_n);
	//一些需要的判断信号
	wire icb_cmdaddr_eq_excladdr = (arbt_icb_cmd_addr == excl_addr_r);//判断访问的地址是否与互斥检测器中的一样
///执行load-reserved-获取
   //当load-r发生 设置有效位
	wire excl_flg_set = splt_fifo_wen & arbt_icb_cmd_usr[USR_PACK_EXCL] & arbt_icb_cmd_read & arbt_icb_cmd_excl;
   //当load-r发生 把访问地址写入互斥检测器
	assign excl_addr_ena = excl_flg_set;
	assign excl_addr_nxt = arbt_icb_cmd_addr;
///执行store-condition-释放
   //判断store-c是否成功-执行成功即访问地址于互斥检测器中存储的一致
	wire arbt_icb_cmd_scond = arbt_icb_cmd_usr[USR_PACK_EXCL] & (~arbt_icb_cmd_read);//表示发生的是store-c
	wire arbt_icb_cmd_scond_true = arbt_icb_cmd_scond & icb_cmdaddr_eq_excladdr & excl_flg_r;//表示成功
	//当store-c执行成功时，清除有效位
	assign excl_flg_clr = (splt_fifo_wen & (~arbt_icb_cmd_read) & icb_cmdaddr_eq_excladdr & excl_flg_r) 
                    | commit_trap | commit_mret;//当发生意外情况时也清除
	//当store-c执行不成功的时候，为了防止写入将写入mask置为0
	wire [`E203_XLEN/8-1:0] arbt_icb_cmd_wmask_pos = 
      (arbt_icb_cmd_scond & (~arbt_icb_cmd_scond_true)) ? {`E203_XLEN/8{1'b0}} : arbt_icb_cmd_wmask;

		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
//分发器
  //来自汇合器的输入
  ///判断输入是否有效
  wire cmd_diff_branch = 1'b0;//只有一个滞外操作，无需考虑
  wire arbt_icb_cmd_addi_condi = (~splt_fifo_full) & (~cmd_diff_branch);//？？
  ///握手
     //分发器传来的读写请求信号
	  wire arbt_icb_cmd_valid_pos = arbt_icb_cmd_addi_condi & arbt_icb_cmd_valid;
	  //当完成数据传输传回分发器的读写请求完成信号
	  wire arbt_icb_cmd_ready_pos;
	  assign arbt_icb_cmd_ready_pos = all_icb_cmd_ready;
	  assign arbt_icb_cmd_ready = arbt_icb_cmd_addi_condi & arbt_icb_cmd_ready_pos;
  //传输的数据
  wire all_icb_cmd_ready;
  assign all_icb_cmd_ready = //表示全部存储器读写请求准备完成 
            (biu_icb_cmd_ready ) //选到的存储器操作完才置为1
          & (dtcm_icb_cmd_ready) //其他存储器一直为1
          & (itcm_icb_cmd_ready);
  wire all_icb_cmd_ready_excp_biu;//表示除了biu其他存储器读写准备情况
  assign all_icb_cmd_ready_excp_biu =  
            1'b1
          & (dtcm_icb_cmd_ready) 
          & (itcm_icb_cmd_ready) ;
  wire all_icb_cmd_ready_excp_dcach;//表示除了dcache其他存储器读写准备情况
  assign all_icb_cmd_ready_excp_dcach =  
            (biu_icb_cmd_ready ) 
          & (dtcm_icb_cmd_ready) 
          & (itcm_icb_cmd_ready) ;
  wire all_icb_cmd_ready_excp_dtcm;//表示除了DTCN其他存储器读写准备情况
  assign all_icb_cmd_ready_excp_dtcm =  
            (biu_icb_cmd_ready ) 
          & 1'b1
          & (itcm_icb_cmd_ready) ;
  wire all_icb_cmd_ready_excp_itcm;//表示除了ITCM其他存储器读写准备情况
  assign all_icb_cmd_ready_excp_itcm =  
            (biu_icb_cmd_ready ) 
          & (dtcm_icb_cmd_ready) 
          & 1'b1;
  //分发接口
  ///DTCM
  assign dtcm_icb_cmd_valid = arbt_icb_cmd_valid_pos & arbt_icb_cmd_dtcm & all_icb_cmd_ready_excp_dtcm;//读写请求
  assign dtcm_icb_cmd_addr  = arbt_icb_cmd_addr [`E203_DTCM_ADDR_WIDTH-1:0];//访问的地址
  assign dtcm_icb_cmd_read  = arbt_icb_cmd_read ;//是否为读操作 1=读 0=写
  assign dtcm_icb_cmd_wdata = arbt_icb_cmd_wdata;//写入的数据
  assign dtcm_icb_cmd_wmask = arbt_icb_cmd_wmask_pos;//写操作的mask
  assign dtcm_icb_cmd_lock  = arbt_icb_cmd_lock ;//是否上锁
  assign dtcm_icb_cmd_excl  = arbt_icb_cmd_excl ;//是否互斥访问
  assign dtcm_icb_cmd_size  = arbt_icb_cmd_size ;//基本访问尺寸  //下同
  ///ITCM
  assign itcm_icb_cmd_valid = arbt_icb_cmd_valid_pos & arbt_icb_cmd_itcm & all_icb_cmd_ready_excp_itcm;
  assign itcm_icb_cmd_addr  = arbt_icb_cmd_addr [`E203_ITCM_ADDR_WIDTH-1:0]; 
  assign itcm_icb_cmd_read  = arbt_icb_cmd_read ; 
  assign itcm_icb_cmd_wdata = arbt_icb_cmd_wdata;
  assign itcm_icb_cmd_wmask = arbt_icb_cmd_wmask_pos;
  assign itcm_icb_cmd_lock  = arbt_icb_cmd_lock ;
  assign itcm_icb_cmd_excl  = arbt_icb_cmd_excl ;
  assign itcm_icb_cmd_size  = arbt_icb_cmd_size ;
  ///biu
  assign biu_icb_cmd_valid = arbt_icb_cmd_valid_pos & arbt_icb_cmd_biu & all_icb_cmd_ready_excp_biu;
  assign biu_icb_cmd_addr  = arbt_icb_cmd_addr ; 
  assign biu_icb_cmd_read  = arbt_icb_cmd_read ; 
  assign biu_icb_cmd_wdata = arbt_icb_cmd_wdata;
  assign biu_icb_cmd_wmask = arbt_icb_cmd_wmask_pos;
  assign biu_icb_cmd_lock  = arbt_icb_cmd_lock ;
  assign biu_icb_cmd_excl  = arbt_icb_cmd_excl ;
  assign biu_icb_cmd_size  = arbt_icb_cmd_size ; 
  
//分发器写回汇合器的反馈信号
assign {
          arbt_icb_rsp_valid //读写反馈请求信号
        , arbt_icb_rsp_err //错误码
        , arbt_icb_rsp_excl_ok //互斥执行成功
        , arbt_icb_rsp_rdata //读出的数据
         } =
            ({`E203_XLEN+3{arbt_icb_rsp_biu}} &
                        { biu_icb_rsp_valid 
                        , biu_icb_rsp_err 
                        , biu_icb_rsp_excl_ok 
                        , biu_icb_rsp_rdata 
                        }
            ) 
             
          | ({`E203_XLEN+3{arbt_icb_rsp_dtcm}} &
                        { dtcm_icb_rsp_valid 
                        , dtcm_icb_rsp_err 
                        , dtcm_icb_rsp_excl_ok 
                        , dtcm_icb_rsp_rdata 
                        }
            ) 
            
          | ({`E203_XLEN+3{arbt_icb_rsp_itcm}} &
                        { itcm_icb_rsp_valid 
                        , itcm_icb_rsp_err 
                        , itcm_icb_rsp_excl_ok 
                        , itcm_icb_rsp_rdata 
                        }
            ) 
             ;
assign biu_icb_rsp_ready    = arbt_icb_rsp_biu    & arbt_icb_rsp_ready;
assign dtcm_icb_rsp_ready   = arbt_icb_rsp_dtcm   & arbt_icb_rsp_ready;
assign itcm_icb_rsp_ready   = arbt_icb_rsp_itcm   & arbt_icb_rsp_ready;




//分发器与AGU的通信接口--利用icb协议中rsp通道
	//握手   //pre_agu_icb_rsp_back2agu表示需要写回AGU
	assign agu_icb_rsp_valid = pre_agu_icb_rsp_valid & pre_agu_icb_rsp_back2agu;//读写反馈请求信号
   assign pre_agu_icb_rsp_ready =//读写反馈请求准许信号  //包括lsu写回的
      pre_agu_icb_rsp_back2agu ?  agu_icb_rsp_ready : lsu_o_ready;
   //数据
	assign agu_icb_rsp_err   = pre_agu_icb_rsp_err  ;//错误码
   assign agu_icb_rsp_excl_ok = pre_agu_icb_rsp_excl_ok ;//互斥成功
   assign agu_icb_rsp_rdata = pre_agu_icb_rsp_rdata;//读取的数据
		
//分发器的lsu写回控制
	//握手   //当不需要写回AGU则需要LSU写回结果
	assign lsu_o_valid = pre_agu_icb_rsp_valid & (~pre_agu_icb_rsp_back2agu);//读写请求信号
	//写回准许信号在与AGU的通信接口的握手中
	//数据
	assign lsu_o_wbck_itag   = pre_agu_icb_rsp_itag;//itag 该指令在oitf中的位置  
	wire [`E203_XLEN-1:0] sc_excl_wdata = arbt_icb_rsp_scond_true ? `E203_XLEN'd0 : `E203_XLEN'd1;//如果store-c成功向结果寄存器写入0
																																 //不成功则写入0
	assign lsu_o_wbck_wdat   = ((~pre_agu_icb_rsp_read) & pre_agu_icb_rsp_excl) ? sc_excl_wdata :          
	         ( ({`E203_XLEN{rsp_lbu}} & {{24{          1'b0}}, rdata_algn[ 7:0]})//根据指令判断是写回store-c的结果寄存器还是读出数据
          | ({`E203_XLEN{rsp_lb }} & {{24{rdata_algn[ 7]}}, rdata_algn[ 7:0]})
          | ({`E203_XLEN{rsp_lhu}} & {{16{          1'b0}}, rdata_algn[15:0]})
          | ({`E203_XLEN{rsp_lh }} & {{16{rdata_algn[15]}}, rdata_algn[15:0]}) 
          | ({`E203_XLEN{rsp_lw }} & rdata_algn[31:0]));
	assign lsu_o_wbck_err    = pre_agu_icb_rsp_err;//错误码
	//读出数据的对齐mask
	wire [`E203_XLEN-1:0] rdata_algn = 
      (pre_agu_icb_rsp_rdata >> {pre_agu_icb_rsp_addr[1:0],3'b0});
	//判断写回数据的基本尺寸和有无符号  //pre_agu_icb_rsp_usign表示有符号操作
	wire rsp_lbu = (pre_agu_icb_rsp_size == 2'b00) & (pre_agu_icb_rsp_usign == 1'b1);
   wire rsp_lb  = (pre_agu_icb_rsp_size == 2'b00) & (pre_agu_icb_rsp_usign == 1'b0);
   wire rsp_lhu = (pre_agu_icb_rsp_size == 2'b01) & (pre_agu_icb_rsp_usign == 1'b1);
   wire rsp_lh  = (pre_agu_icb_rsp_size == 2'b01) & (pre_agu_icb_rsp_usign == 1'b0);
   wire rsp_lw  = (pre_agu_icb_rsp_size == 2'b10);
	//写入commit进行异常处理
	assign lsu_o_cmt_buserr  = pre_agu_icb_rsp_err;//访存错误异常
   assign lsu_o_cmt_badaddr = pre_agu_icb_rsp_addr;//访存地址错误
   assign lsu_o_cmt_ld=  pre_agu_icb_rsp_read;//load指令产生产生访存错误
   assign lsu_o_cmt_st= ~pre_agu_icb_rsp_read;//store指令产生访存错误
	
	assign lsu_ctrl_active = (|arbt_bus_icb_cmd_valid_raw) | splt_fifo_o_valid;//表示lsu正在运行

endmodule