`include "opcodes.v"



module control_unit(opcode, func_code, clk, pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_to_reg, pc_src, halt, wwd, new_inst, reg_write, alu_src_A, alu_src_B, alu_op);

  input [3:0] opcode;
  input [5:0] func_code;
  input clk;
  //alu_src_A: 0: PC, 1: PC 4-bit, 2: register A, 3: 16b'0
  //alu_src_B: 0: register B. 1: 1. 2: imm, 3: target addr
  //pc_src: 0: next PC from ALU, 1: next PC from ALUOut
  //reg_write 0: None, 1: rs, 2: rt, 3: rd
  //alu_op: 0: add, 1: not add 
  output reg pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_to_reg, pc_src, halt, wwd, new_inst;
  output reg [1:0] reg_write, alu_src_A, alu_src_B;
  output reg alu_op;

  reg [4:0] state_current;
  reg [4:0] state_next;

  wire [3:0] opcode;
  wire [5:0] func_code;

  initial begin
      state_next = 31;
      pc_write_cond = 0;
      pc_write = 0;
      i_or_d = 0;
      mem_read = 0; 
      mem_to_reg = 0;
      mem_write = 0; 
      ir_write = 0; 
      pc_to_reg = 0; 
      pc_src = 0;
      reg_write = 0;
      alu_src_A = 0;
      alu_src_B = 0;
      alu_op = 0;
      halt = 0;
      wwd = 0;
      new_inst = 0;
  end

  always @(posedge clk) begin
    state_current <= state_next;
  end


  always @(*) begin
    case(state_current)
      30: begin
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 1; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 1; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 1;
        alu_op = 0;
        halt = 0;
        wwd = 0;
        case(opcode)
          
          `ADI_OP: state_next = 1;
          `ORI_OP: state_next = 1;
          `LHI_OP: state_next = 1;
          `LWD_OP: state_next = 1;     
          `SWD_OP: state_next = 1;
          `BNE_OP: state_next = 10;
          `BEQ_OP: state_next = 10; 
          `BGZ_OP: state_next = 10; 
          `BLZ_OP: state_next = 10;
          `JMP_OP: state_next = 9;
          `JAL_OP: state_next = 11;

          `ALU_OP: begin
              case(func_code)
                `INST_FUNC_JPR: state_next = 15;
                `INST_FUNC_JRL: state_next = 12;
                `INST_FUNC_WWD: state_next = 19;
                `INST_FUNC_HLT: state_next = 18;
                default: state_next = 1;
              endcase
          end   
          default: state_next = 31; 
        endcase
      end
      31: begin
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 1; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 1; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 1;
        alu_op = 0;
        halt = 0;
        wwd = 0;
        case(opcode)
          `ADI_OP: state_next = 1;
          `ORI_OP: state_next = 1;
          `LHI_OP: state_next = 1;
          `LWD_OP: state_next = 1;     
          `SWD_OP: state_next = 1;
          `BNE_OP: state_next = 10;
          `BEQ_OP: state_next = 10; 
          `BGZ_OP: state_next = 10; 
          `BLZ_OP: state_next = 10;
          `JMP_OP: state_next = 9;
          `JAL_OP: state_next = 11;

          `ALU_OP: begin
              case(func_code)
                `INST_FUNC_JPR: state_next = 15;
                `INST_FUNC_JRL: state_next = 12;
                `INST_FUNC_WWD: state_next = 19;
                `INST_FUNC_HLT: state_next = 18;
                default: state_next = 1;
              endcase
          end   
          default: state_next = 30; 
        endcase
      end
      29: begin // neg edge mem read
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 1; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 1; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0;
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 0;
      end
      0: begin
        pc_write_cond = 0;
        pc_write = 1;
        i_or_d = 0;
        mem_read = 1; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 1; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 1;
        alu_op = 0;
        halt = 0;
        wwd = 0;
        new_inst = 1;
        case(opcode)
          `ADI_OP: state_next = 1;
          `ORI_OP: state_next = 1;
          `LHI_OP: state_next = 1;
          `LWD_OP: state_next = 1;     
          `SWD_OP: state_next = 1;
          `BNE_OP: state_next = 10;
          `BEQ_OP: state_next = 10; 
          `BGZ_OP: state_next = 10; 
          `BLZ_OP: state_next = 10;
          `JMP_OP: state_next = 9;
          `JAL_OP: state_next = 11;

          `ALU_OP: begin
              case(func_code)
                `INST_FUNC_JPR: state_next = 15;
                `INST_FUNC_JRL: state_next = 12;
                `INST_FUNC_WWD: state_next = 19;
                `INST_FUNC_HLT: state_next = 18;
                default: state_next = 1;
              endcase
          end
          default: state_next = 31;   
        endcase
      end

      1: begin // register fetch
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        case(opcode)
          `ALU_OP: state_next = 3;
          `LWD_OP: state_next = 2;
          `SWD_OP: state_next = 2;
          `LHI_OP: state_next = 17;
          `WWD_OP: state_next = 19;
          default: state_next = 6;
        endcase
          
      end

      2: begin // IType 
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 2;
        alu_src_B = 2;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        case(opcode)
          `LWD_OP: state_next = 4;
          `SWD_OP: state_next = 5;
        endcase
      end


      3: begin // Rtype
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 2;
        alu_src_B = 0;
        alu_op = 1; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 7;
      end


      4: begin // load
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 1;
        mem_read = 1; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 8;
      end


      5: begin // store
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 1;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 1; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 29;
      end


      6: begin // ADI, ORI type
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 2;
        alu_src_B = 2;
        alu_op = 1; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 20;
      end


      7: begin // rd WB
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 3;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 29;
      end


      8: begin // rt memory WB
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 1;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 2;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 29;
      end


      9: begin // PC+target
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 1;
        alu_src_B = 3;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 13;
      end

      10: begin // PC+ imm
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 2;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 14;

      end

      11: begin // PC+target & pc_to_reg
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 1; 
        pc_src = 0;
        reg_write = 3;
        alu_src_A = 1;
        alu_src_B = 3;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 13;

      end

      12: begin // PC = reg & pc_to_reg
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 1; 
        pc_src = 0;
        reg_write = 3;
        alu_src_A = 2;
        alu_src_B = 0;
        alu_op = 1; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 16;
      end

      13: begin // JMP or JAL
        pc_write_cond = 0;
        pc_write = 1;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 1;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 29;

      end

      14: begin // Bxx
        pc_write_cond = 1;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 1;
        reg_write = 0;
        alu_src_A = 2;
        alu_src_B = 0;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 29;

      end

      15: begin // PC = reg
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 2;
        alu_src_B = 0;
        alu_op = 1; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 16;

      end

      16: begin // JPR or JRL
        pc_write_cond = 0;
        pc_write = 1;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 1;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0; 
        halt = 0;
        wwd = 0;
        new_inst = 0;
        state_next = 29;

      end

      17: begin // LHI
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 3;
        alu_src_B = 0;
        alu_op = 1;
        halt = 0;
        wwd = 0; 
        new_inst = 0;
        state_next = 20;

      end

      18: begin // halt
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0;
        halt = 1;
        wwd = 0; 
        new_inst = 0;
        state_next = 18;

      end

      19: begin // wwd rs -> ouputport
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 0;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0; 
        halt = 0;
        wwd = 1;
        new_inst = 0;
        state_next = 29;
      end

      20: begin // rt WB
        pc_write_cond = 0;
        pc_write = 0;
        i_or_d = 0;
        mem_read = 0; 
        mem_to_reg = 0;
        mem_write = 0; 
        ir_write = 0; 
        pc_to_reg = 0; 
        pc_src = 0;
        reg_write = 2;
        alu_src_A = 0;
        alu_src_B = 0;
        alu_op = 0; 
        new_inst = 0;
        state_next = 29;
      end
    endcase
  end


endmodule


