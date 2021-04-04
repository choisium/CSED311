`include "opcodes.v"

module control_unit(opcode, func_code, clk, reset_n, pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_to_reg, pc_src, halt, wwd, new_inst, reg_write, alu_src_A, alu_src_B, alu_op);
  input [3:0] opcode;
  input [5:0] func_code;
  input clk;
  input reset_n;

  output reg pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_src;
  //additional control signals. pc_to_reg: to support JAL, JRL. halt: to support HLT. wwd: to support WWD. new_inst: new instruction start
  output reg pc_to_reg, halt, wwd, new_inst;
  output reg [1:0] reg_write, alu_src_A, alu_src_B;
  output reg alu_op;

  // state register
  reg [4:0] current_state, next_state;

  // localparam for states
  localparam IF = 5'd0;
  localparam ID = 5'd1;
  localparam R_EX = 5'd2;
  localparam R_WB = 5'd3;
  localparam I_EX = 5'd4;
  localparam I_WB = 5'd5;
  localparam MEM_EX = 5'd6;
  localparam LD_MEM = 5'd7;
  localparam LD_WB = 5'd8;
  localparam SD_MEM = 5'd9;
  localparam BCheck = 5'd10;
  localparam BComplete = 5'd11;
  localparam JAL = 5'd12;
  localparam JMP = 5'd13;
  localparam JRL = 5'd14;
  localparam JPR = 5'd15;
  localparam WWD = 5'd16;
  localparam HLT = 5'd17;

  initial begin
    current_state <= 0;
    next_state <= 0;
  end

  // update state 
  always @(posedge clk) begin
    if (!reset_n)
      current_state <= 0;
    else begin
      current_state <= next_state;
    end
  end

  // logic for next state
  always @(*) begin
    case(current_state)
        IF: next_state = ID;
        ID: begin
          case(opcode) 
              4'd15: begin // R-Type
                case(func_code)
                  `INST_FUNC_JPR: next_state = JPR;
                  `INST_FUNC_JRL: next_state = JRL;
                  `INST_FUNC_WWD: next_state = WWD;
                  `INST_FUNC_HLT: next_state = HLT;
                  default: next_state = R_EX;
                endcase
              end
            `ADI_OP, `ORI_OP, `LHI_OP: next_state = I_EX;
            `LWD_OP, `SWD_OP: next_state = MEM_EX;
            `BNE_OP, `BEQ_OP, `BGZ_OP, `BLZ_OP: next_state = BCheck;
            `JAL_OP: next_state = JAL;
            `JMP_OP: next_state = JMP;
            default: next_state = HLT; // no use; exception
          endcase
        end
        R_EX: next_state = R_WB;
        I_EX: next_state = I_WB;
        MEM_EX: begin
          case(opcode) 
            `LWD_OP: next_state = LD_MEM;
            `SWD_OP: next_state = SD_MEM;
          endcase
        end
        LD_MEM: next_state = LD_WB;
        BCheck: next_state = BComplete;
        HLT: next_state = HLT;
        default: begin 
          next_state = IF; // leaf node states -> IF
        end
    endcase
  end

  // control signal for current state
  always @(*) begin
    
    // reset each control values
    pc_write_cond = 0;
    pc_write = 0;
    i_or_d = 0;
    mem_read = 0;
    mem_to_reg = 0;
    mem_write = 0;
    ir_write = 0;
    pc_src = 0;
    pc_to_reg = 0;
    halt = 0;
    wwd = 0;
    new_inst = 0;
    reg_write = 2'b00;
    alu_src_A = 2'b00;
    alu_src_B = 2'b00;
    alu_op = 0;
    
    case (current_state) 
      
      IF: begin
        mem_read = 1;
        i_or_d = 0;
        ir_write = 1;
        pc_write = 1;
        alu_src_A = 2'b00;
        alu_src_B = 2'b01;
        alu_op = 0;
        new_inst = 0;
      end
      
      ID: begin
        alu_src_A = 2'b00;
        alu_src_B = 2'b11;
        alu_op = 0;
      end
      
      R_EX: begin
        alu_src_A = 2'b01;
        alu_src_B = 2'b00;
        alu_op = 1;
      end
      
      R_WB: begin
        reg_write = 2'b01;
        mem_to_reg = 0;
        new_inst = 1;
      end
      
      I_EX: begin
        alu_src_A = 2'b01;
        alu_src_B = 2'b10;
        alu_op = 1;
      end
      
      I_WB: begin
        reg_write = 2'b10;
        mem_to_reg = 0;
        new_inst = 1;
      end
      
      MEM_EX: begin
        alu_src_A = 2'b01;
        alu_src_B = 2'b10;
        alu_op = 0;
      end

      LD_MEM: begin
        mem_read = 1;
        i_or_d = 1;
      end

      LD_WB: begin
        reg_write = 2'b10;
        mem_to_reg = 1;
        new_inst = 1;
      end

      SD_MEM: begin
        mem_write = 1;
        i_or_d = 1;
        new_inst = 1;
      end

      BCheck: begin
        alu_src_A = 2'b01;
        alu_src_B = 2'b00;
        alu_op = 1; 
      end

      BComplete: begin
        alu_src_A = 2'b00;
        alu_src_B = 2'b10;
        pc_write_cond = 1;
        pc_src = 0;
        alu_op = 0;
        new_inst = 1;
      end

      JAL: begin
        pc_to_reg = 1;
        reg_write = 2'b11;
        pc_write = 1;
        pc_src = 1;
        new_inst = 1;
      end

      JMP: begin
        pc_write = 1;
        pc_src = 1;
        new_inst = 1;
      end

      JRL: begin
        pc_to_reg = 1;
        reg_write = 2'b11;
        alu_src_A = 2'b01;
        alu_src_B = 2'b11;
        pc_write = 1;
        pc_src = 0;
        alu_op = 1;
        new_inst = 1;
      end

      JPR: begin
        alu_src_A = 2'b01;
        alu_src_B = 2'b11;
        pc_write = 1;
        pc_src = 0;
        alu_op = 1;
        new_inst = 1;
      end

      WWD: begin
        wwd = 1;
        alu_src_A = 2'b01;
        alu_src_B = 2'b11;
        alu_op = 1;
        new_inst = 1;
      end

      default: begin
        halt = 1;
        new_inst = 1;
      end
    endcase
  end

endmodule
