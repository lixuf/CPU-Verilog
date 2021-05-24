# 环境
quartus II 13.1 + modelsim
# 文件结构
## gen
通用模块，包括cdc和dff。
## commit
指令调度模块，也是本设计的主工程文件，使用quartus打开该文件中的工程文件即可使用本设计。但是，需要将file中重新把gen下面的文件加入，若想使用modesim仿真，我已经在项目中配置好了各个模块的仿真文件，在仿真设置中即可切换。
## ad
ad采集模块
## alu
通用运算模块
## clk_manger
时钟和同步复位管理模块
## decoder
指令解码器
## fir
fir滤波器运算通路
## int
中断等待调试模块
## jc
检测器模块
## men
存储介质管理模块
## move
数据搬移模块
## reg_file
寄存器组
## uarto
uart输出模块
## xb
小波分解运算通路
