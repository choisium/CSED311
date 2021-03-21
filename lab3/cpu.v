`include "opcodes.v" 	   

module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output readM;									
	output writeM;								
	output [`WORD_SIZE-1:0] address;	
	inout [`WORD_SIZE-1:0] data;		
	input ackOutput;								
	input inputReady;								
	input reset_n;									
	input clk;			

	// state PC
	wire [`WORD_SIZE-1: 0] pc, pc_nxt;
	wire [`WORD_SIZE-1: 0] stable_data;

	// wire for control_unit
	wire alu_src, reg_write, mem_read, mem_to_reg, mem_write, branch, pc_to_reg, zero_extended;
	wire [1:0] rt_write, jp;

	// wire for alu_control_unit
	wire [3:0] alu_func_code;
	
	// wire for memory_access
	wire [`WORD_SIZE-1:0] mem_address;	// memory size is 256
	wire [`WORD_SIZE-1:0] mem_data;

	// wire for register_file
	wire [`WORD_SIZE-1:0] RF_read_out1, RF_read_out2;
	
	// wire for mux
	wire [1:0] MUX_rt_write_out;
	wire [`WORD_SIZE-1:0] MUX_pc_to_reg_out, MUX_mem_to_reg_out, MUX_alu_src_out, MUX_jp_out;
	wire [`WORD_SIZE-1:0] MUX_branch_high_out;

	// wire for immediate_generator
	wire [`WORD_SIZE-1:0] immediate;

	// wire for alu
	wire zero;
	wire [`WORD_SIZE-1:0] alu_result, adder_result;

	// reg and wire for constant literals
	reg [1:0] x2;
	reg [3:0] adder_func_code;
	wire branch_high;

	assign x2 = 2'b10;
	assign adder_func_code = `FUNC_ADD;
	assign branch_high = branch & zero;

	assign stable_data = (readM && inputReady) ? data: stable_data;

	// NOTE: This is for test! Before submit, delete this code!
	always @(*) begin
		// $strobe("data: %h", data);
		$strobe("stable_data: %h", stable_data);
	end
	// NOTE END

	memory_access MemoryAccess(
		.pc(pc),
		.pc_nxt(pc_nxt),
		.mem_read(mem_read),
		.mem_write(mem_write),
		.mem_address(alu_result),
		.mem_data(RF_read_out2),
		.readM(readM),
		.writeM(writeM),
		.address(address),
		.data(data),
		.ackOutput(ackOutput),
		.inputReady(inputReady),
		.reset_n(reset_n),
		.clk(clk)
	);

	control_unit ControlUnit(
		.instr(stable_data),
		.alu_src(alu_src),
		.reg_write(reg_write),
		.mem_read(mem_read),
		.mem_to_reg(mem_to_reg),
		.mem_write(mem_write),
		.jp(jp),
		.branch(branch),
		.pc_to_reg(pc_to_reg),
		.rt_write(rt_write)
	);
	
	alu_control_unit ALUControlUnit(
		.instr(stable_data),
		.alu_func_code(alu_func_code)
	);

	register_file RegisterFile(
		.read_out1(RF_read_out1),
		.read_out2(RF_read_out2),
		.read1(stable_data[11:10]),
		.read2(stable_data[9:8]),
		.write_reg(MUX_rt_write_out),
		.write_data(MUX_pc_to_reg_out),
		.reg_write(reg_write),
		.clk(clk)
	);

	mux4to1 #(.DATA_WIDTH(2)) MUX_rt_write(
		.in1(stable_data[7:6]),
		.in2(stable_data[9:8]),
		.in3(x2),
		.in4(x2),
		.sel(rt_write),
		.out(MUX_rt_write_out)
	);

	mux2to1 MUX_pc_to_reg(
		.in1(MUX_mem_to_reg_out),
		.in2(pc_nxt),
		.sel(pc_to_reg),
		.out(MUX_pc_to_reg_out)
	);

	immediate_generator ImmGen(
		.instr(stable_data),
		.immediate(immediate)
	);

	mux2to1 MUX_alu_src(
		.in1(RF_read_out2),
		.in2(immediate),
		.sel(alu_src),
		.out(MUX_alu_src_out)
	);

	alu ALU(
		.alu_input_1(RF_read_out1),
		.alu_input_2(MUX_alu_src_out),
		.alu_func_code(alu_func_code),
		.alu_output(alu_result),
		.zero(zero)
	);

	mux2to1 MUX_mem_to_reg(
		.in1(alu_result),
		.in2(stable_data),
		.sel(mem_to_reg),
		.out(MUX_mem_to_reg_out)
	);

	alu Adder(
		.alu_input_1(pc),
		.alu_input_2(immediate),
		.alu_func_code(adder_func_code),
		.alu_output(adder_result),
		.zero()
	);

	mux2to1 MUX_branch_high(
		.in1(pc_nxt),
		.in2(adder_result),
		.sel(branch_high),
		.out(MUX_branch_high_out)
	);
	
	mux4to1 MUX_jp(
		.in1(MUX_branch_high_out),
		.in2({pc[15:12], stable_data[11:0]}),
		.in3(alu_result),		
		.in4(alu_result),
		.sel(jp),
		.out(MUX_jp_out)
	);	


endmodule							  																		  