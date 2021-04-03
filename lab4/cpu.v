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
	reg[`WORD_SIZE-1:0] pc, instruction, output_port_reg;

	// control_unit
	wire pc_write_cond, pc_write, i_or_d, mem_read, mem_to_reg, mem_write, ir_write, pc_src;
	wire pc_to_reg, halt, wwd, new_inst;
	wire [1:0] reg_write, alu_src_A, alu_src_B;
	wire alu_op;

	// immediate_generator
	wire[`WORD_SIZE-1:0] immediate;

	// register_file
	wire[`WORD_SIZE-1:0] reg_write_data;
	wire[`WORD_SIZE-1:0] reg_read_out1, reg_read_out2;

	// alu_control_unit
	wire[3:0] alu_func_code;
	wire[1:0] branch_type;

	//alu
	wire[`WORD_SIZE-1:0] alu_src_A_data, alu_src_B_data, alu_output;
	wire alu_overflow_flag, alu_bcond;
	reg[`WORD_SIZE-1:0] alu_output_reg;

	// mux
	wire[`WORD_SIZE-1:0] pc_1, pc_nxt;
	wire reg_write_control;
	wire[1:0] reg_write_address;

	// temporary data
	reg[`WORD_SIZE-1:0] mem_write_data;


	// initialization
	initial begin
		pc <= 0;
		instruction <= 0;
		mem_write_data <= 0;
		output_port_reg <= 0;
	end

	assign reg_write_control = reg_write != 0;

	// update pc
	assign pc_1 = pc + 1;

	always @(posedge clk) begin
		if (!reset_n)
			pc <= 0;
		else if (pc_write) begin
			$display("update pc %0d <- %0d", pc, pc_nxt);
			pc <= pc_nxt;
		end
		else
			pc <= pc;
	end

	// get instruction from memory
	assign read_m = mem_read;
	assign write_m = mem_write;
	assign address = pc;
	assign data = read_m? `WORD_SIZE'bz: mem_write_data;

	always @(posedge clk) begin
		if (!reset_n)
			instruction <= 0;
		else if (ir_write) begin
			$display("fetch instruction %0h <- %0h", instruction, data);
			instruction <= data;
		end
		else
			instruction <= instruction;
	end

	// update num_inst
	always @(posedge clk) begin
		if (!reset_n)
			num_inst <= 0;
		else if (new_inst) begin
			$display("instruction done %0d <- %0d\n\n", num_inst, num_inst + 1);
			num_inst <= num_inst + 1;
		end
		else
			num_inst <= num_inst;
	end

	// wwd
	assign output_port = output_port_reg;
	always @(posedge clk) begin
		if (!reset_n)
			output_port_reg <= 0;
		else if (wwd) begin
			$display("wwd: %0d <- %0d", output_port_reg, reg_read_out1);
			output_port_reg <= reg_read_out1;
		end
		else
			output_port_reg <= output_port_reg;

	end

	// alu
	always @(posedge clk) begin
		if (!reset_n)
			alu_output_reg <= 0;
		else
			alu_output_reg <= alu_output;	
	end

	always @(posedge clk) begin
		$display("immediate: %d, alu_output: %d, reg_write_data: %d", immediate, alu_output, reg_write_data);
	end


	control_unit ControlUnit(
		.opcode(instruction[15:12]),
		.func_code(instruction[5:0]),
		.clk(clk),
		.reset_n(reset_n),
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

	immediate_generator ImmGen(
		.opcode(instruction[15:12]),
		.imm(instruction[7:0]),
		.immediate(immediate)
	);

	register_file RegisterFile(
		.read1(instruction[11:10]),
		.read2(instruction[9:8]),
		.write_reg(reg_write_address),
		.write_data(reg_write_data),
		.reg_write(reg_write_control),
		.clk(clk),
		.read_out1(reg_read_out1),
		.read_out2(reg_read_out2)
	);

	alu_control_unit ALUControlUnit(
		.funct(instruction[5:0]),
		.opcode(instruction[15:12]),
		.ALUOp(alu_op),
		.clk(clk),
		.funcCode(alu_func_code),
		.branchType(branch_type)
	);

	alu ALU(
		.A(alu_src_A_data),
		.B(alu_src_B_data),
		.func_code(alu_func_code),
		.branch_type(branch_type),
		.C(alu_output),
		.overflow_flag(alu_overflow_flag),
		.bcond(alu_bcond)
	);

	mux2_1 MUX_pc_src(
		.sel({1'b0, pc_src}),
		.i1(pc_1),
		.i2({pc[15:12], instruction[11:0]}),
		.o(pc_nxt)
	);

	mux4_1 #(.DATA_WIDTH(2)) MUX_reg_write(
		.sel(reg_write),
		.i1(instruction[7:6]),
		.i2(instruction[7:6]),
		.i3(instruction[9:8]),
		.i4(2'b10),
		.o(reg_write_address)
	);

	mux2_1 MUX_alu_src_A(
		.sel(alu_src_A),
		.i1(pc),
		.i2(reg_read_out1),
		.o(alu_src_A_data)
	);

	mux4_1 MUX_alu_src_B(
		.sel(alu_src_B),
		.i1(alu_src_B_data),
		.i2(`WORD_SIZE'b1),
		.i3(immediate),
		.i4(`WORD_SIZE'b0),
		.o(alu_src_B_data)
	);

	mux2_1 MUX_mem_to_reg(
		.sel({1'b0, mem_to_reg}),
		.i1(alu_output_reg),
		.i2(alu_output_reg),
		.o(reg_write_data)
	);

endmodule
