
`include "instruction_reg.v"
`include "accum.v"
`include "alu.v"
`include "datactl.v"
`include "adr.v"
`include "counter.v"
`include "machinectl.v"
`include "machine.v"
`include "clocker.v"

module cpu(clk,reset,halt,rd,wr,addr,data);
    input clk,reset;
    output rd,wr,addr,halt;
    inout data;
    wire clk,reset,halt;
    wire [7:0] data;
    wire [12:0] addr;
    wire rd,wr;
    wire clk1,fetch,alu_clk;
    wire [2:0] opcode;
    wire [12:0] ir_addr,pc_addr;
    wire [7:0] alu_out,accum;
    wire zero,inc_pc,load_acc,load_pc,load_ir,data_ena,contr_ena;
    
    
    
    
    clk_gen m_clk_gen(.clk(clk),
                      .reset(reset),
                      .fetch(fetch),
                      .alu_ena(alu_ena));
                      
                      
    register m_register(.data(data),
                        .ena(load_ir),
                        .rst(reset),
                        .clk(clk),
                        .opc_iradders({opcode,ir_addr}));
                        
    accum m_accum(.data(alu_out),
                  .ena(load_acc),
                  .clk(clk),
                  .rst(reset),
                  .accum(accum));
                  
    alu m_alu(.data(data),
              .accum(accum),
              .alu_ena(alu_ena),
	      .clk(clk),
              .opcode(opcode),
              .alu_out(alu_out),
              .zero(zero));
              
    machinectl m_machinectl(.ena(control_ena),
                            .fetch(fetch),
		       	    .clk(clk),
                            .rst(reset));
                            
    machine m_machine(.inc_pc(inc_pc),
                      .load_acc(load_acc),
                      .load_pc(load_pc),
                      .rd(rd),
                      .wr(wr),
                      .load_ir(load_ir),
                      .clk(clk),
                      .datactl_ena(data_ena),
                      .halt(halt),
                      .zero(zero),
                      .ena(contr_ena),
                      .opcode(opcode));
                      
    datactl m_datactl(.in(alu_out),
                      .data_ena(data_ena),
                      .data(data));
                      
    adr m_adr(.fetch(fetch),
              .ir_addr(ir_addr),
              .pc_addr(pc_addr),
              .addr(addr));
              
    counter m_counter(.ir_addr(ir_addr),
                      .load(load_pc),
                      .clock(inc_pc),
                      .rst(reset),
                      .pc_addr(pc_addr));
                      
  endmodule                                                                                                                                                          
                          
   


