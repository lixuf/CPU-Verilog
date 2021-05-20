//组合逻辑，第一级流水状态机控制
module decoder(
input [31:0] r_in,//输入指令


//输出的控制信号
//修改寄存器
output [7:0] xbh_en,//在一级流水处锁存
output [7:0] xbl_en,
output [7:0] fir_reg_en,
output [1:0] des_addr_en,
output [1:0] sor_addr_en,
output len_en,
output [3:0] lr_en,
output [3:0] hr_en,
output [15:0] operand,
//指令部分
////ad
output ad_en,
output des,
output [7:0] select,
////小波分解,fir滤波器指令,uart输出指令
output xb_en,
output fir_en,
output uarto_en,
output [7:0] channel,//控制ad通道
output [1:0] source,//介质选择 10 ad 01 ram 00 ddr
//output [7:0] select,
////中值滤波指令
output zlb_en,
//output [1:0] source,
////存储器搬移指令
output move_en,
//output dir,//00为 ddr->ram  01  ram->ddr
////中断等待指令
output int_en,
////检测器启用指令
output jc_en
//output [7:0] channel,


);
wire [6:0]  funct=	 r_in[31:25];
assign  operand=	 r_in[22:7];
assign			des=		 r_in[15];
assign      select=	 r_in[14:7];
wire [7:0]  channel1=	 r_in[24:17];
wire [1:0]  source1=	 r_in[16:15];
wire [1:0]	sourcez=  r_in[8:7];
//assign			dir=		 r_in[7];
wire [7:0] channelj= r_in[14:7];



wire funct_0000000=(funct==7'b0000000);
wire funct_0000001=(funct==7'b0000001);
wire funct_0000010=(funct==7'b0000010);
wire funct_0000011=(funct==7'b0000011);
wire funct_0000100=(funct==7'b0000100);
wire funct_0000101=(funct==7'b0000101);
wire funct_0000110=(funct==7'b0000110);
wire funct_0000111=(funct==7'b0000111);
wire funct_0001000=(funct==7'b0001000);
wire funct_0001001=(funct==7'b0001001);
wire funct_0001010=(funct==7'b0001010);
wire funct_0001011=(funct==7'b0001011);
wire funct_0001100=(funct==7'b0001100);
wire funct_0001101=(funct==7'b0001101);
wire funct_0001110=(funct==7'b0001110);
wire funct_0001111=(funct==7'b0001111);
wire funct_0010000=(funct==7'b0010000);
wire funct_0010001=(funct==7'b0010001);
wire funct_0010010=(funct==7'b0010010);
wire funct_0010011=(funct==7'b0010011);
wire funct_0010100=(funct==7'b0010100);
wire funct_0010101=(funct==7'b0010101);
wire funct_0010110=(funct==7'b0010110);
wire funct_0010111=(funct==7'b0010111);
wire funct_0011000=(funct==7'b0011000);
wire funct_0011001=(funct==7'b0011001);
wire funct_0011010=(funct==7'b0011010);
wire funct_0011011=(funct==7'b0011011);
wire funct_0100000=(funct==7'b0100000);
wire funct_0100011=(funct==7'b0100011);
wire funct_0100100=(funct==7'b0100100);
wire funct_0100101=(funct==7'b0100101);
wire funct_0100110=(funct==7'b0100110);
wire funct_0100111=(funct==7'b0100111);
wire funct_0101000=(funct==7'b0101000);
wire funct_0101001=(funct==7'b0101001);
wire funct_0101010=(funct==7'b0101010);
wire funct_0011100=(funct==7'b0011100);
wire funct_0011101=(funct==7'b0011101);
wire funct_0011110=(funct==7'b0011110);
wire funct_0101100=(funct==7'b0101100);
wire funct_0011111=(funct==7'b0011111);
wire funct_0101011=(funct==7'b0101011);
wire funct_0100001=(funct==7'b0100001);
wire funct_0100010=(funct==7'b0100010);





assign xbh_en=
{
funct_0000000,
funct_0000001,
funct_0000010,
funct_0000011,
funct_0000100,
funct_0000101,
funct_0000110,
funct_0000111};

assign xbl_en=
{
funct_0001000,
funct_0001001,
funct_0001010,
funct_0001011,
funct_0001100,
funct_0001101,
funct_0001110,
funct_0001111};

assign fir_reg_en=
{
funct_0010000,
funct_0010001,
funct_0010010,
funct_0010011,
funct_0010100,
funct_0010101,
funct_0010110,
funct_0010111};

assign des_addr_en=
{
funct_0011000,
funct_0011001};

assign sor_addr_en=
{
funct_0011010,
funct_0011011};

assign len_en=
funct_0100000;

assign lr_en=
{
funct_0100011,
funct_0100100,
funct_0100101,
funct_0100110};

assign hr_en=
{
funct_0100111,
funct_0101000,
funct_0101001,
funct_0101010};

assign ad_en=
funct_0011100;

assign xb_en=
funct_0011101;

assign fir_en=
funct_0011110;

assign uarto_en=
funct_0101100;

assign zlb_en=
funct_0011111;

assign move_en=
funct_0101011;

assign int_en=
funct_0100001;

assign jc_en=
funct_0100010;


assign source=(ad_en)?2'b10:(funct_0011111|move_en)?sourcez:source1;
assign channel=(funct_0100010|funct_0011100)?channelj:channel1;

endmodule
