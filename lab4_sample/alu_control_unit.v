module alu_control_unit(inst, alu_op, clk, func_code, branch_type);
  input [15:0] inst;
  input alu_op;
  input clk;

  output reg [3:0] func_code;
  output reg [1:0] branch_type;
  wire [5:0] funct;
  wire [3:0] opcode;

  assign funct = inst[5:0];
  assign opcode = inst[15:12];

  always @(*) begin
    if (alu_op == 0) begin
      func_code = 4'b0000;
      case (opcode)
        0: branch_type = 4'b00; // bne
        1: branch_type = 4'b01; // bep
        2: branch_type = 4'b10; // bgz
        3: branch_type = 4'b11; // blz
      endcase
    end
    else begin
      if (opcode == 15) begin
        case (funct)
          0: func_code = 4'b0000; // ADD
          1: func_code = 4'b0001; // SUB
          2: func_code = 4'b0100; // AND
          3: func_code = 4'b0101; // ORR
          4: func_code = 4'b0011; // NOT
          5: func_code = 4'b1110; // TCP
          6: func_code = 4'b1010; // SHL
          7: func_code = 4'b1101; // SHR
          25: func_code = 4'b0010; // JPR
          26: func_code = 4'b0010; // JRL
        endcase
      end
      else begin
        case (opcode)
          4: func_code = 4'b0000; // ADI
          5: func_code = 4'b0101; // ORI
          6: func_code = 4'b0010; // LHI
          7: func_code = 4'b0000; // LWD
          8: func_code = 4'b0000; // SWD
          10: func_code = 4'b0010; // JAL
        endcase
      end

    end
  end
endmodule
