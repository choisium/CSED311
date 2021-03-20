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
	wire [5:0] pc, pc_nxt;
	wire [`WORD_SIZE-1: 0] stable_data;

	// wire for control_unit
	wire alu_src, reg_write, mem_read, mem_to_reg, mem_write, jp, branch, pc_to_reg, rt_write, zero_extended;

	// wire for alu_control_unit
	wire [3:0] alu_func_code;
	
	// wire for memory_access
	wire [`WORD_SIZE-1:0] mem_address;	// memory size is 256
	wire [`WORD_SIZE-1:0] mem_data;



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
		.mem_address(mem_address),
		.mem_data(mem_data),
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

endmodule							  																		  