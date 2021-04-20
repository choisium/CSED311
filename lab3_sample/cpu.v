`include "opcodes.v" 	   

module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output readM;									
	output writeM;								
	output reg [`WORD_SIZE-1:0] address;	
	inout [`WORD_SIZE-1:0] data;		
	input ackOutput;								
	input inputReady;								
	input reset_n;									
	input clk;			
	
	reg [`WORD_SIZE-1:0] pc, next_pc;
	reg [3:0] opcode;
	reg [1:0] rs, rt, rd;
	reg [5:0] func;
	reg [7:0] imm;
	reg [`WORD_SIZE-1:0] sign_extended_imm;
	reg [11:0] target_addr;
	reg IF, signal_mask;
	reg pc_to_reg;

	reg [2:0] ALU_func;
	reg [`WORD_SIZE-1:0] load_data;

	wire [`WORD_SIZE-1:0] A, B, C;
	wire [1:0] write_reg;
	wire [`WORD_SIZE-1:0] wb;
	wire [`WORD_SIZE-1:0] read_out1, read_out2;
	wire alu_src, reg_write, mem_read, mem_to_reg, mem_write, jal, branch;
	wire in_out_control = (mem_write == 1 && IF != 1 && inputReady != 1);
	assign readM = IF | (mem_read & signal_mask & ~inputReady);
	assign writeM = mem_write & signal_mask & ~inputReady;
  	assign data = in_out_control == 1 ? read_out2 : `WORD_SIZE'bz;
	assign A = opcode == `LHI_OP? sign_extended_imm : read_out1;
	assign B = alu_src ? (opcode == `LHI_OP ? 8 :sign_extended_imm) : (func == `INST_FUNC_SHL || func == `INST_FUNC_SHR)? 1 : read_out2;
	assign wb = pc_to_reg ? pc : (mem_to_reg ? load_data : C);
	assign write_reg = pc_to_reg ? 2 : (alu_src ? rt : rd);
	
	//Use register file module
	register_file REGFILE (
		.clk(clk),
		.read1(rs), 
		.read2(rt), 
		.write_reg(write_reg), 
		.reg_write(reg_write), 
		.write_data(wb), 
		.read_out1(read_out1),
		.read_out2(read_out2));
	//Use ALU module
	alu ALU (.A(A), .B(B), .funcCode(ALU_func), .C(C));
	control_unit CONTROL (.opcode(opcode), .alu_src(alu_src),
	 .reg_write(reg_write), .mem_read(mem_read), .mem_to_reg(mem_to_reg), 
	 .mem_write(mem_write), .jal(jal), .branch(branch));

	//initailization 
	initial begin
		signal_mask <= 0;
		address <= 0;
		pc <= 0;
		IF <= 0;
		ALU_func <= 0;
		opcode <= 0;
		next_pc <= 0;
		load_data <= 0;
	end

	always @(*) begin
		//Sign extender
		if(imm[7] == 1) sign_extended_imm = {8'hff, imm};
		else sign_extended_imm = {8'h00, imm};
		if(opcode == `ALU_OP) begin
			case(func)
				`INST_FUNC_ADD: begin ALU_func = `FUNC_ADD; end
				`INST_FUNC_SUB:begin ALU_func = `FUNC_SUB; end
				`INST_FUNC_AND:begin ALU_func = `FUNC_AND; end
				`INST_FUNC_ORR: begin ALU_func = `FUNC_ORR; end
				`INST_FUNC_NOT: begin ALU_func = `FUNC_NOT; end
				`INST_FUNC_TCP: begin ALU_func = `FUNC_TCP; end
				`INST_FUNC_SHL: begin ALU_func = `FUNC_SHL; end
				`INST_FUNC_SHR: begin ALU_func = `FUNC_SHR; end
			endcase
		end
		else if(opcode == `ADI_OP) begin ALU_func = `FUNC_ADD; end
		else if(opcode == `ORI_OP) begin ALU_func = `FUNC_ORR; end
		else if(opcode == `LHI_OP) begin ALU_func = `FUNC_SHL; end
	end

	//Instruction fetch OR LOAD
	always @(posedge inputReady) begin
		if(IF == 1)begin
			opcode <= data[`WORD_SIZE-1:12];
			target_addr <= data[11:0];
			rs <= data[11:10];
			rt <= data[9:8];
			rd <= data[7:6];
			func <= data[5:0];
			imm <= data[7:0];
			IF <= 0;			
		end
		else begin
			load_data <= data;
			signal_mask <= 0;
		end
	end

	//OFF writeM
	always @(posedge ackOutput) begin
		signal_mask <= 0;
	end

	//Type control after instruction fetch
	always @(negedge clk) begin
		signal_mask <= 1;
		if(mem_read | mem_write) begin
			address <= read_out1 + sign_extended_imm;
		end
		if(opcode == `ALU_OP && func == `INST_FUNC_JRL) begin
			pc_to_reg <= 1;
			next_pc <= read_out1;
		end
		else if(opcode == `ALU_OP && func == `INST_FUNC_JPR) begin
 			next_pc <= read_out1; 
		end
		else if (jal) begin
			if(opcode == `JAL_OP) begin
				pc_to_reg <= 1;
			end
			next_pc <= {4'd0, target_addr};
		end
		else if(branch) begin
			control_branch();
		end 
	end

	//Clock 
	always @(posedge clk) begin
		if(!reset_n) begin
			address <= 0;
			pc <= 0;
			IF <= 0;
			ALU_func <= 0;
			opcode <= 0;
			next_pc <= 0;
		end
		else begin
			signal_mask <= 0;
			next_pc <= next_pc + 1;
			IF <= 1;
			pc <= next_pc;
			address <= next_pc;
			pc_to_reg <= 0;
		end
	end

	task control_branch;
		begin
			case(opcode) 
				`BNE_OP: begin
					if(read_out1 != read_out2) next_pc <= next_pc + sign_extended_imm;
				end
				`BEQ_OP: begin
					if(read_out1 == read_out2) next_pc <= next_pc + sign_extended_imm;
				end
				`BGZ_OP: begin
					if(read_out1 > 0) next_pc <= next_pc + sign_extended_imm;
				end
				`BLZ_OP: begin
					if(read_out1 <= read_out2) pc = next_pc + sign_extended_imm;
				end
			endcase
		end
	endtask

endmodule							  																		  