`include "opcodes.v"

module alu_control_unit (instr, alu_func_code);
input [`WORD_SIZE-1:0] instr;
output reg [3:0] alu_func_code;

wire [3:0] opcode;
assign opcode = instr[15:12];
wire [5:0] func_code;
assign func_code = instr[5:0];


always @(*) begin
    case (opcode)
        `ALU_OP: begin
            alu_func_code = func_code;
        end
        `ADI_OP: begin
            alu_func_code = `FUNC_ADD;
        end
        `ORI_OP: begin
            alu_func_code = `FUNC_ORR;
        end
        // NOTE: Add alu_func_code below as you want!

   	    default: begin      // Don't use ALU
            alu_func_code = 4'd15;
	    end
    endcase


    $display("func_code: %d", alu_func_code);
end


endmodule