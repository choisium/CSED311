`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

module cpu(clk, reset_n, read_m, write_m, address, data, num_inst, output_port, is_halted);
	input clk;
	input reset_n;
	
	output read_m;
	output write_m;
	output [`WORD_SIZE-1:0] address;
	inout [`WORD_SIZE-1:0] data;

	output reg [`WORD_SIZE-1:0] num_inst;		// number of instruction during execution (for debuging & testing purpose)
	output reg [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
	output is_halted;


	// pc register
	reg [15:0] pc;
	wire [15:0] pc_next;
	
	// flags
	wire pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_to_reg, pc_src, halt, wwd, new_inst;
	wire [1:0] reg_write, alu_src_A, alu_src_B;
	wire alu_op;

	// input for registers
	wire [15:0] write_data;

	// ouput of registers
	wire [15:0] reg_A, reg_B, reg_inst, reg_mem, reg_ALU, read_data1, read_data2;

	// instruction parsing
	wire [3:0] opcode;
	wire [1:0] rs, rt, rd;
	wire [5:0] func_code;
	wire [7:0] immediate;
	wire [11:0] target_addr;

	// alu input
	wire [15:0] alu_input_A;
	wire [15:0] alu_input_B;
	wire [3:0] alu_func_code;


	// alu ouput
	wire [15:0] alu_result;
	wire overflow_flag;
	wire bcond;
	wire [1:0] branch_type;
	// wire [1:0] bcondz;

	// control unit
	control_unit CC (opcode, func_code, clk, pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_to_reg, pc_src, halt, wwd, new_inst, reg_write, alu_src_A, alu_src_B, alu_op);
	alu_control_unit AC (reg_inst, alu_op, clk, alu_func_code, branch_type);


	// alu
	alu AA(alu_input_A, alu_input_B, alu_func_code, branch_type, alu_result, overflow_flag, bcond);

	// register
	register RR(rs, rt, rd, write_data, reg_write, clk, read_data1, read_data2);
	ir_register RI(data, ir_write, clk, reg_inst);
	mem_register RM(data, clk, reg_mem);
	A_register RA(read_data1, clk, reg_A);
	B_register RB(read_data2, clk, reg_B);
	alu_out_register RAO(alu_result, clk, reg_ALU);


	// mux
	mux4_1 ALUA (alu_src_A, pc, {pc[15:12], 12'b000000000000}, read_data1, {immediate, 8'b00000000}, alu_input_A);
	mux4_1 ALUB (alu_src_B, read_data2, 16'b0000000000000001, {{8{immediate[7]}}, immediate}, {4'b0000, target_addr}, alu_input_B);


	// instruction parsing
	assign opcode = reg_inst[15:12];
	assign rs = reg_inst[11:10];
	assign rt = reg_inst[9:8];
	assign rd = pc_to_reg ? 2 : reg_inst[7:6];
	assign func_code = reg_inst[5:0];
	assign immediate = reg_inst[7:0];
	assign target_addr = reg_inst[11:0];


	assign pc_next = pc_src ? reg_ALU : alu_result;
	assign is_halted = halt;

	assign read_m = mem_read;
	assign write_m = mem_write;

	assign data = read_m ? 16'bz : reg_B;
	assign address = i_or_d ? reg_ALU : pc;

	assign write_data = pc_to_reg ? pc : (mem_to_reg ? reg_mem : reg_ALU);

	initial begin
		num_inst = 0;
		pc = 0;
	end

	always @(posedge clk) begin
		if (pc_write || (pc_write_cond && (bcond) )) begin
			pc <= pc_next;
		end
		if (new_inst)
			num_inst <= num_inst+1;
		if (wwd)
			output_port <= read_data1;
	end
endmodule






