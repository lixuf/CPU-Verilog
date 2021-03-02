`include "gen_defines.v"
module itcm_ctrl(
);



//lsu与itcm数据宽度转换
  //cmd输入通道 32bit-》64bit
  wire lsu_icb_cmd_valid;
  wire lsu_icb_cmd_ready;
  wire [`E203_ITCM_ADDR_WIDTH-1:0] lsu_icb_cmd_addr;
  wire lsu_icb_cmd_read;
  wire [`E203_ITCM_DATA_WIDTH-1:0] lsu_icb_cmd_wdata;
  wire [`E203_ITCM_DATA_WIDTH/8-1:0] lsu_icb_cmd_wmask;
  //rsp输出通道  64bit-》32bit  
  wire lsu_icb_rsp_valid;
  wire lsu_icb_rsp_ready;
  wire lsu_icb_rsp_err;
  wire [`E203_ITCM_DATA_WIDTH-1:0] lsu_icb_rsp_rdata; 
  //位宽转换器
  sirv_gnrl_icb_n2w # (
  .FIFO_OUTS_NUM   (`E203_ITCM_OUTS_NUM),
  .FIFO_CUT_READY  (0),
  .USR_W      (1),
  .AW         (`E203_ITCM_ADDR_WIDTH),
  .X_W        (32),
  .Y_W        (`E203_ITCM_DATA_WIDTH) 
  ) u_itcm_icb_lsu2itcm_n2w(
  .i_icb_cmd_valid        (lsu2itcm_icb_cmd_valid ),  
  .i_icb_cmd_ready        (lsu2itcm_icb_cmd_ready ),
  .i_icb_cmd_read         (lsu2itcm_icb_cmd_read ) ,
  .i_icb_cmd_addr         (lsu2itcm_icb_cmd_addr ) ,
  .i_icb_cmd_wdata        (lsu2itcm_icb_cmd_wdata ),
  .i_icb_cmd_wmask        (lsu2itcm_icb_cmd_wmask) ,
  .i_icb_cmd_burst        (2'b0)                   ,
  .i_icb_cmd_beat         (2'b0)                   ,
  .i_icb_cmd_lock         (1'b0),
  .i_icb_cmd_excl         (1'b0),
  .i_icb_cmd_size         (2'b0),
  .i_icb_cmd_usr          (1'b0),
   
  .i_icb_rsp_valid        (lsu2itcm_icb_rsp_valid ),
  .i_icb_rsp_ready        (lsu2itcm_icb_rsp_ready ),
  .i_icb_rsp_err          (lsu2itcm_icb_rsp_err)   ,
  .i_icb_rsp_excl_ok      ()   ,
  .i_icb_rsp_rdata        (lsu2itcm_icb_rsp_rdata ),
  .i_icb_rsp_usr          (),
                                                
  .o_icb_cmd_valid        (lsu_icb_cmd_valid ),  
  .o_icb_cmd_ready        (lsu_icb_cmd_ready ),
  .o_icb_cmd_read         (lsu_icb_cmd_read ) ,
  .o_icb_cmd_addr         (lsu_icb_cmd_addr ) ,
  .o_icb_cmd_wdata        (lsu_icb_cmd_wdata ),
  .o_icb_cmd_wmask        (lsu_icb_cmd_wmask) ,
  .o_icb_cmd_burst        ()                   ,
  .o_icb_cmd_beat         ()                   ,
  .o_icb_cmd_lock         (),
  .o_icb_cmd_excl         (),
  .o_icb_cmd_size         (),
  .o_icb_cmd_usr          (),
   
  .o_icb_rsp_valid        (lsu_icb_rsp_valid ),
  .o_icb_rsp_ready        (lsu_icb_rsp_ready ),
  .o_icb_rsp_err          (lsu_icb_rsp_err)   ,
  .o_icb_rsp_excl_ok      (1'b0)   ,
  .o_icb_rsp_rdata        (lsu_icb_rsp_rdata ),
  .o_icb_rsp_usr          (1'b0),

  .clk                    (clk   )                  ,
  .rst_n                  (rst_n )                 
  );
  
  
  
  
  
  
  
  
  
//外部访问与itcm的位宽转换
  //cmd输入 32bit-》64bit
  wire ext_icb_cmd_valid;
  wire ext_icb_cmd_ready;
  wire [`E203_ITCM_ADDR_WIDTH-1:0] ext_icb_cmd_addr;
  wire ext_icb_cmd_read;
  wire [`E203_ITCM_DATA_WIDTH-1:0] ext_icb_cmd_wdata;
  wire [`E203_ITCM_WMSK_WIDTH-1:0] ext_icb_cmd_wmask;
  //rsp输出 64bit-》32bit  
  wire ext_icb_rsp_valid;
  wire ext_icb_rsp_ready;
  wire ext_icb_rsp_err;
  wire [`E203_ITCM_DATA_WIDTH-1:0] ext_icb_rsp_rdata; 
  //位宽转换器
  sirv_gnrl_icb_n2w # (
  .USR_W      (1),
  .FIFO_OUTS_NUM   (`E203_ITCM_OUTS_NUM),
  .FIFO_CUT_READY  (0),
  .AW         (`E203_ITCM_ADDR_WIDTH),
  .X_W        (`E203_SYSMEM_DATA_WIDTH), 
  .Y_W        (`E203_ITCM_DATA_WIDTH) 
  ) u_itcm_icb_ext2itcm_n2w(
  .i_icb_cmd_valid        (ext2itcm_icb_cmd_valid ),  
  .i_icb_cmd_ready        (ext2itcm_icb_cmd_ready ),
  .i_icb_cmd_read         (ext2itcm_icb_cmd_read ) ,
  .i_icb_cmd_addr         (ext2itcm_icb_cmd_addr ) ,
  .i_icb_cmd_wdata        (ext2itcm_icb_cmd_wdata ),
  .i_icb_cmd_wmask        (ext2itcm_icb_cmd_wmask) ,
  .i_icb_cmd_burst        (2'b0)                   ,
  .i_icb_cmd_beat         (2'b0)                   ,
  .i_icb_cmd_lock         (1'b0),
  .i_icb_cmd_excl         (1'b0),
  .i_icb_cmd_size         (2'b0),
  .i_icb_cmd_usr          (1'b0),
   
  .i_icb_rsp_valid        (ext2itcm_icb_rsp_valid ),
  .i_icb_rsp_ready        (ext2itcm_icb_rsp_ready ),
  .i_icb_rsp_err          (ext2itcm_icb_rsp_err)   ,
  .i_icb_rsp_excl_ok      ()   ,
  .i_icb_rsp_rdata        (ext2itcm_icb_rsp_rdata ),
  .i_icb_rsp_usr          (),
                                                
  .o_icb_cmd_valid        (ext_icb_cmd_valid ),  
  .o_icb_cmd_ready        (ext_icb_cmd_ready ),
  .o_icb_cmd_read         (ext_icb_cmd_read ) ,
  .o_icb_cmd_addr         (ext_icb_cmd_addr ) ,
  .o_icb_cmd_wdata        (ext_icb_cmd_wdata ),
  .o_icb_cmd_wmask        (ext_icb_cmd_wmask) ,
  .o_icb_cmd_burst        ()                   ,
  .o_icb_cmd_beat         ()                   ,
  .o_icb_cmd_lock         (),
  .o_icb_cmd_excl         (),
  .o_icb_cmd_size         (),
  .o_icb_cmd_usr          (),
   
  .o_icb_rsp_valid        (ext_icb_rsp_valid ),
  .o_icb_rsp_ready        (ext_icb_rsp_ready ),
  .o_icb_rsp_err          (ext_icb_rsp_err)   ,
  .o_icb_rsp_excl_ok      (1'b0),
  .o_icb_rsp_rdata        (ext_icb_rsp_rdata ),
  .o_icb_rsp_usr          (1'b0),

  .clk                    (clk  ) ,
  .rst_n                  (rst_n)                 
  );
  
  
  
  
  
  
  
//汇合器  一共两个输入 lsu和外部访问，需要先经过位宽转换器转换
  //汇合器cmd通道，即汇合器将两方输入汇合后的输出
  wire arbt_icb_cmd_valid;
  wire arbt_icb_cmd_ready;
  wire [`E203_ITCM_ADDR_WIDTH-1:0] arbt_icb_cmd_addr;
  wire arbt_icb_cmd_read;
  wire [`E203_ITCM_DATA_WIDTH-1:0] arbt_icb_cmd_wdata;
  wire [`E203_ITCM_WMSK_WIDTH-1:0] arbt_icb_cmd_wmask;
  //汇合器rsp通道，即itcm返回的数据，即将经过汇合器返回给对应单元  
  wire arbt_icb_rsp_valid;
  wire arbt_icb_rsp_ready;
  wire arbt_icb_rsp_err;
  wire [`E203_ITCM_DATA_WIDTH-1:0] arbt_icb_rsp_rdata;
  //汇合器参数
  localparam ITCM_ARBT_I_NUM = 2;
  localparam ITCM_ARBT_I_PTR_W = 1;
  //汇合器cmd输入总线，即将两方输入汇合为总线形式然后经过选择其一输出，以达到汇合的效果
  wire [ITCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_valid;
  wire [ITCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_ready;
  wire [ITCM_ARBT_I_NUM*`E203_ITCM_ADDR_WIDTH-1:0] arbt_bus_icb_cmd_addr;
  wire [ITCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_read;
  wire [ITCM_ARBT_I_NUM*`E203_ITCM_DATA_WIDTH-1:0] arbt_bus_icb_cmd_wdata;
  wire [ITCM_ARBT_I_NUM*`E203_ITCM_WMSK_WIDTH-1:0] arbt_bus_icb_cmd_wmask;
  assign arbt_bus_icb_cmd_valid =
                             {ext_icb_cmd_valid,
                             lsu_icb_cmd_valid} ;
  assign arbt_bus_icb_cmd_addr =
                             {ext_icb_cmd_addr,
                             lsu_icb_cmd_addr};
  assign arbt_bus_icb_cmd_read =
                             {ext_icb_cmd_read,
                             lsu_icb_cmd_read};
  assign arbt_bus_icb_cmd_wdata =
                             {ext_icb_cmd_wdata,
                             lsu_icb_cmd_wdata};
  assign arbt_bus_icb_cmd_wmask =
                             {ext_icb_cmd_wmask,
                             lsu_icb_cmd_wmask};
  //汇合器rsp输出总线，即将itcm的输出组合成和输入宽度一致的总线，经过选择返回回去
  wire [ITCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_valid;
  wire [ITCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_ready;
  wire [ITCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_err;
  wire [ITCM_ARBT_I_NUM*`E203_ITCM_DATA_WIDTH-1:0] arbt_bus_icb_rsp_rdata;
  assign {ext_icb_cmd_ready,
         lsu_icb_cmd_ready
          } = arbt_bus_icb_cmd_ready;
  assign {ext_icb_rsp_valid,
          lsu_icb_rsp_valid
          } = arbt_bus_icb_rsp_valid;
  assign   {ext_icb_rsp_err,
           lsu_icb_rsp_err
            } = arbt_bus_icb_rsp_err;
  assign    {ext_icb_rsp_rdata,
              lsu_icb_rsp_rdata
             } = arbt_bus_icb_rsp_rdata;
  assign arbt_bus_icb_rsp_ready = { ext_icb_rsp_ready,
                                    lsu_icb_rsp_ready};
  //汇合器本体
  sirv_gnrl_icb_arbt # (
  .ARBT_SCHEME (0),
  .ALLOW_0CYCL_RSP (0),
  .FIFO_OUTS_NUM   (`E203_ITCM_OUTS_NUM),
  .FIFO_CUT_READY(0),
  .USR_W      (1),
  .ARBT_NUM   (ITCM_ARBT_I_NUM  ),
  .ARBT_PTR_W (ITCM_ARBT_I_PTR_W),
  .AW         (`E203_ITCM_ADDR_WIDTH),
  .DW         (`E203_ITCM_DATA_WIDTH) 
  ) u_itcm_icb_arbt(
  .o_icb_cmd_valid        (arbt_icb_cmd_valid )     ,
  .o_icb_cmd_ready        (arbt_icb_cmd_ready )     ,
  .o_icb_cmd_read         (arbt_icb_cmd_read )      ,
  .o_icb_cmd_addr         (arbt_icb_cmd_addr )      ,
  .o_icb_cmd_wdata        (arbt_icb_cmd_wdata )     ,
  .o_icb_cmd_wmask        (arbt_icb_cmd_wmask)      ,
  .o_icb_cmd_burst        ()     ,
  .o_icb_cmd_beat         ()     ,
  .o_icb_cmd_lock         ()     ,
  .o_icb_cmd_excl         ()     ,
  .o_icb_cmd_size         ()     ,
  .o_icb_cmd_usr          ()     ,
                                
  .o_icb_rsp_valid        (arbt_icb_rsp_valid )     ,
  .o_icb_rsp_ready        (arbt_icb_rsp_ready )     ,
  .o_icb_rsp_err          (arbt_icb_rsp_err)        ,
  .o_icb_rsp_rdata        (arbt_icb_rsp_rdata )     ,
  .o_icb_rsp_usr          (1'b0),
  .o_icb_rsp_excl_ok      (1'b0),
                               
  .i_bus_icb_cmd_ready    (arbt_bus_icb_cmd_ready ) ,
  .i_bus_icb_cmd_valid    (arbt_bus_icb_cmd_valid ) ,
  .i_bus_icb_cmd_read     (arbt_bus_icb_cmd_read )  ,
  .i_bus_icb_cmd_addr     (arbt_bus_icb_cmd_addr )  ,
  .i_bus_icb_cmd_wdata    (arbt_bus_icb_cmd_wdata ) ,
  .i_bus_icb_cmd_wmask    (arbt_bus_icb_cmd_wmask)  ,
  .i_bus_icb_cmd_burst    ({2*ITCM_ARBT_I_NUM{1'b0}}) ,
  .i_bus_icb_cmd_beat     ({2*ITCM_ARBT_I_NUM{1'b0}}) ,
  .i_bus_icb_cmd_lock     ({1*ITCM_ARBT_I_NUM{1'b0}}),
  .i_bus_icb_cmd_excl     ({1*ITCM_ARBT_I_NUM{1'b0}}),
  .i_bus_icb_cmd_size     ({2*ITCM_ARBT_I_NUM{1'b0}}),
  .i_bus_icb_cmd_usr      ({1*ITCM_ARBT_I_NUM{1'b0}}),

                                
  .i_bus_icb_rsp_valid    (arbt_bus_icb_rsp_valid ) ,
  .i_bus_icb_rsp_ready    (arbt_bus_icb_rsp_ready ) ,
  .i_bus_icb_rsp_err      (arbt_bus_icb_rsp_err)    ,
  .i_bus_icb_rsp_rdata    (arbt_bus_icb_rsp_rdata ) ,
  .i_bus_icb_rsp_usr      (),
  .i_bus_icb_rsp_excl_ok  (),
                             
  .clk                    (clk  )                     ,
  .rst_n                  (rst_n)
  );
  
  
