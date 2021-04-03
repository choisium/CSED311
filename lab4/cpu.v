`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

module cpu(clk, reset_n, read_m, write_m, address, data, num_inst, output_port, is_halted);
	input clk;
	input reset_n;
	
	output read_m;
	output write_m;
	output [`WORD_SIZE-1:0] address;

	inout [`WORD_SIZE-1:0] data;

	output reg [`WORD_SIZE-1:0] num_inst;		// number of instruction executed (for testing purpose)
	output [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
	output is_halted;

	// pc state
	reg[`WORD_SIZE-1:0] pc, instruction;

	// control_unit
	wire pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_src;
	wire pc_to_reg, halt, wwd, new_inst;
	wire [1:0] reg_write, alu_src_A, alu_src_B;
	wire alu_op;

	// temporary data
	reg[`WORD_SIZE-1:0] mem_write_data;

	initial begin
		pc <= 0;
		instruction <= 0;
		mem_write_data <= 0;
	end

	always @(posedge clk) begin
		if (!reset_n)
			pc <= 0;
		else if (pc_write) begin
			$display("update pc %d <- %d", pc, pc + 1);
			pc <= pc + 1;
		end
		else
			pc <= pc;
	end

	assign read_m = mem_read;
	assign write_m = mem_write;
	assign address = pc;
	assign data = read_m? `WORD_SIZE'bz: mem_write_data;

	always @(posedge clk) begin
		if (!reset_n)
			instruction <= 0;
		else if (ir_write) begin
			$display("fetch instruction %h <- %h", instruction, data);
			instruction <= data;
		end
		else
			instruction <= instruction;
	end

	always @(posedge clk) begin
		if (!reset_n)
			num_inst <= 0;
		else if (new_inst) begin
			$display("instruction done %d <- %d", num_inst, num_inst + 1);
			num_inst <= num_inst + 1;
		end
		else
			num_inst <= num_inst;
	end


	control_unit ControlUnit(
		.opcode(instruction[15:12]),
		.func_code(instruction[5:0]),
		.clk(clk),
		.pc_write_cond(pc_write_cond),
		.pc_write(pc_write),
		.i_or_d(i_or_d),
		.mem_read(mem_read),
		.mem_to_reg(mem_to_reg),
		.mem_write(mem_write),
		.ir_write(ir_write),
		.pc_src(pc_src),
		.pc_to_reg(pc_to_reg),
		.halt(halt),
		.wwd(wwd),
		.new_inst(new_inst),
		.reg_write(reg_write),
		.alu_src_A(alu_src_A),
		.alu_src_B(alu_src_B),
		.alu_op(alu_op)
	);

endmodule
