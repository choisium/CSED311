`include "opcodes.v" 	   

module control_unit (instr, alu_src, reg_write, mem_read, mem_to_reg, mem_write, jp, branch, pc_to_reg, rt_write, zero_extended);
input [`WORD_SIZE-1:0] instr;
output reg alu_src;
output reg reg_write;
output reg mem_read;
output reg mem_to_reg;
output reg mem_write;
output reg jp;
output reg branch;
output reg pc_to_reg;
output reg rt_write;
output reg zero_extended;

wire [3:0] opcode;
assign opcode = instr[15:12];
wire [5:0] func_code;
assign func_code = instr[5:0];


always @(*) begin
    // reset each control value;s
    alu_src = 0;
    reg_write = 0;
    mem_read = 0;
    mem_to_reg = 0;
    mem_write = 0;
    jp = 0;
    branch = 0;
    pc_to_reg = 0;
    rt_write = 0;
    zero_extended = 0;
    case (opcode)
        `ALU_OP, `JPR_OP, `JRL_OP: begin     // R-type Instructions
            case (func_code)
                `INST_FUNC_JPR: begin        // JPR
                    reg_write = 0;
                    jp = 1;
                    pc_to_reg = 0;
                end
                `INST_FUNC_JRL: begin        // JRL
                    reg_write = 0;
                    jp = 1;
                    pc_to_reg = 0;
                end
                default: begin               // ALU operations
                    reg_write = 1;
                    jp = 0;
                    pc_to_reg = 0;
                end
            endcase
        end
        `ADI_OP, `LHI_OP: begin
            alu_src = 1;
            reg_write = 1;
            rt_write = 1;
        end
        `ORI_OP: begin
            alu_src = 1;
            reg_write = 1;
            rt_write = 1;
            zero_extended = 1;
        end
        `LWD_OP: begin
            alu_src = 1;
            reg_write = 1;
            rt_write = 1;
            mem_read = 1;
            mem_to_reg = 1;
        end
        `SWD_OP: begin
            alu_src = 1;
            mem_write = 1;
        end
        `BNE_OP, `BEQ_OP: begin
            branch = 1;
        end
        `BGZ_OP, `BLZ_OP: begin
            alu_src = 1;
            branch = 1;
        end
        `JMP_OP: begin
            jp = 1;
        end
        `JAL_OP: begin
            jp = 1;
            pc_to_reg = 1;
        end

        default: begin
                alu_src = 0;
                reg_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
                mem_write = 0;
                jp = 0;
                branch = 0;
                pc_to_reg = 0;
                rt_write = 0;
	    end
    endcase

	// NOTE: This is for test! Before submit, delete this code!
    $display("opcode: %d", opcode);
    $display("alu_src: %d, reg_write: %d, mem_read: %d, mem_to_reg: %d, mem_write: %d, jp: %d, branch: %d, pc_to_reg: %d, rt_write: %d",
            alu_src, reg_write, mem_read, mem_to_reg, mem_write, jp, branch, pc_to_reg, rt_write);
    // NOTE END
end


endmodule