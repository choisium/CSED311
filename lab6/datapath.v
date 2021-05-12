`include "opcodes.v"
`include "register_file.v"
`include "alu.v"
`include "control_unit.v" 
`include "branch_predictor.v"
`include "hazard.v"
`include "util.v"
`include "immediate_generator.v"
`include "forwarding_unit.v"

module datapath(clk, reset_n, read_m1, address1, data1, read_m2, write_m2, address2, data2, num_inst, output_port, is_halted);

	input clk;
	input reset_n;

	output read_m1;
	output [`WORD_SIZE-1:0] address1;
	output read_m2;
	output write_m2;
	output [`WORD_SIZE-1:0] address2;

	input [`WORD_SIZE-1:0] data1;
	inout [`WORD_SIZE-1:0] data2;

	output reg [`WORD_SIZE-1:0] num_inst;
	output reg [`WORD_SIZE-1:0] output_port;
	output is_halted;

	//TODO: implement datapath of pipelined CPU

	// PC
	reg[`WORD_SIZE-1:0] pc;
	wire[`WORD_SIZE-1:0] pc_nxt;  // predicted_pc

	wire new_inst_if;

	// IF/ID pipeline register & ID stage wire and reg
	reg[`WORD_SIZE-1:0] pc_id, instr;
	

	// IF/ID control signals
	wire halt_id, use_rs, use_rt; wire[1:0] reg_dest;
	wire alu_src_id, branch_id; wire[1:0] pc_src_id, alu_branch_type_id; wire[3:0] alu_func_code_id; // to EX
	wire mem_read_id, mem_write_id; // to MEM
	wire reg_write_id, wwd_id; wire[1:0] reg_src_id; reg new_inst_id; // to MEM
	wire stall;

	// ID additional wire and reg
	wire[`WORD_SIZE-1:0] rf_rs, rf_rt, immed_id;
	wire[1:0] rd_id;

	// ID/EX pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_ex, rf_rs_ex, rf_rt_ex, immed_ex;
	reg[11:0] target;
	reg[1:0] rs_ex, rt_ex, rd_ex;
	
	wire [`WORD_SIZE-1:0] actual_taken_pc; // for always taken predictor

	// ID/EX pipeline control signals
	reg alu_src_ex, branch_ex; reg[1:0] pc_src_ex, alu_branch_type_ex; reg[3:0] alu_func_code_ex; // to EX
	reg mem_read_ex, mem_write_ex; // to MEM
	reg halt_ex, wwd_ex, new_inst_ex, reg_write_ex; reg[1:0] reg_src_ex; // to WB
		
	// EX additional wire and reg
	wire[`WORD_SIZE-1:0] alu_out_ex, pc_branch, rf_rs_forwarded, rf_rt_forwarded, alu_operand_B;
	wire alu_overflow_flag, alu_bcond;
	wire[`WORD_SIZE-1:0] actual_pc;
	wire [1:0] forward_a, forward_b;

	// EX/MEM pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_mem, rf_rs_mem, rf_rt_mem, alu_out_mem;
	reg[1:0] rd_mem;
		
	// EX/MEM control signals
	reg mem_read_mem, mem_write_mem; // to EX
	reg halt_mem, wwd_mem, new_inst_mem, reg_write_mem; reg[1:0] reg_src_mem; // to MEM

	// MEM additional wire and reg
	reg[`WORD_SIZE-1:0] mem_read_data;

	// MEM/WB pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_wb, rf_rs_wb, alu_out_wb;
	reg[1:0] rd_wb;
	
	// MEM/WB control signals
	reg halt_wb, wwd_wb, new_inst_wb, reg_write_wb; reg[1:0] reg_src_wb;

	// WB additional wire and reg
	wire[`WORD_SIZE-1:0] write_data_wb;

	// flush
	reg fcond1, fcond2, fcond3;
	reg flush;

	// halt
	reg halt;
	
	// memory stall
	reg instr_stall, mem_data_stall;

	initial begin
		pc <= 0;
		num_inst <= 0; output_port <= 0;

		// IF/ID pipeline
		pc_id <= 0; instr <= 0;
		new_inst_id <= 0;

		// ID/EX pipeline register
		target <= 0; pc_ex <= 0; rf_rs_ex <= 0; rf_rt_ex <= 0;  immed_ex <= 0;
		rs_ex <= 0; rt_ex <= 0; rd_ex <= 0;
		
		// EX control
		alu_src_ex <= 0; branch_ex <= 0; pc_src_ex <= 0; alu_branch_type_ex <= 0; alu_func_code_ex <= 0;
		mem_read_ex <= 0; mem_write_ex <= 0; 
		halt_ex <= 0; wwd_ex <= 0; new_inst_ex <= 0; reg_write_ex <= 0; reg_src_ex <= 0; 

		// EX/MEM pipeline register
		pc_mem <= 0; rf_rs_mem <= 0; rf_rt_mem <= 0; alu_out_mem <= 0; 
		rd_mem <= 0; 
		
		// EX/MEM control signals
		mem_read_mem <= 0; mem_write_mem <= 0; 
		halt_mem <= 0; wwd_mem <= 0; new_inst_mem <= 0; reg_write_mem <=0; reg_src_mem <= 0;

		// MEM/WB control signals
		pc_wb <= 0; rf_rs_wb <= 0; alu_out_wb <= 0;
		rd_wb <= 0;

		// MEM/WB control signals
		halt_wb <= 0; wwd_wb <= 0; new_inst_wb <= 0; reg_write_wb <= 0; reg_src_wb <= 0;

		// halt
		halt <= 0;

		// memory stall
		instr_stall <= 0; mem_data_stall <= 0;
	end


	// get memory data
	assign read_m1 = 1;
	assign address1 = pc;
	assign write_m2 = mem_write_mem;
	assign read_m2 = mem_read_mem;
	assign address2 = alu_out_mem;
	assign data2 = read_m2? `WORD_SIZE'bz: rf_rt_mem;
	
	always @(*) begin
		if (!reset_n) begin
			instr_stall = 0;
			mem_data_stall = 0;
		end else begin
			if (data1 === `WORD_SIZE'bz) begin
				instr_stall = 1;
			end else begin
				instr_stall = 0;
			end
			
			if (data2 === `WORD_SIZE'bz) begin
				mem_data_stall = 1;
			end else begin
				mem_data_stall = 0;
			end
		end
	end

	// instruction memory
	always @(posedge clk) begin
		if (!reset_n) begin
			instr <= 0;
		end else if(stall || instr_stall || mem_data_stall) begin
			instr <= instr;
		end else begin
			instr <= data1;
		end
	end

	// data memory
	always @(posedge clk ) begin
		if (!reset_n) begin
			mem_read_data <= 0;
		end else begin
			if (read_m2 && mem_data_stall) begin
				mem_read_data <= mem_read_data;
			end else if (read_m2) begin
				mem_read_data <= data2;
			end
		end
	end

	// set flush
	always @(*) begin
		fcond1 = (pc_id != `WORD_SIZE'hffff) && (actual_pc != pc_id);
		fcond2 = (pc_id != 0);
		fcond3 = (pc_ex != `WORD_SIZE'hffff);

		flush = (fcond1 & fcond2 & fcond3) ? 1: 0;
	end
	
	// set halt
	assign is_halted = halt;

	// get branch always taken pc
	assign actual_taken_pc = branch_ex ? (pc_ex + `WORD_SIZE'b1 + immed_ex) : (pc_src_ex == 2'b01 ? {pc_ex[15:12], target} : rf_rs_forwarded);

	// update pipeline register
	always @(posedge clk) begin
		if (!reset_n) begin
			pc <= 0;
			num_inst <= 0; output_port <= 0;

			// IF/ID pipeline
			pc_id <= 0; instr <= 0;
			new_inst_id <= 0;

			// ID/EX pipeline register
			target <= 0; pc_ex <= 0; rf_rs_ex <= 0; rf_rt_ex <= 0;  immed_ex <= 0;
			rs_ex <= 0; rt_ex <= 0; rd_ex <= 0;
			
			// EX control
			alu_src_ex <= 0; branch_ex <= 0; pc_src_ex <= 0; alu_branch_type_ex <= 0; alu_func_code_ex <= 0;
			mem_read_ex <= 0; mem_write_ex <= 0;
			halt_ex <= 0; wwd_ex <= 0; new_inst_ex <= 0; reg_write_ex <= 0; reg_src_ex <= 0; 

			// EX/MEM pipeline register
			pc_mem <= 0; rf_rs_mem <= 0; rf_rt_mem <= 0; alu_out_mem <= 0; 
			rd_mem <= 0; 
			
			// EX/MEM control signals
			mem_read_mem <= 0; mem_write_mem <= 0;
			halt_mem <= 0; wwd_mem <= 0; new_inst_mem <= 0; reg_write_mem <=0; reg_src_mem <= 0;

			// MEM/WB control signals
			pc_wb <= 0; rf_rs_wb <= 0; alu_out_wb <= 0;
			rd_wb <= 0;

			// MEM/WB control signals
			halt_wb <= 0; wwd_wb <= 0; new_inst_wb <= 0; reg_write_wb <= 0; reg_src_wb <= 0;

			// halt
			halt <= 0;
		end
		else begin
			// update pc
			if(!flush && (stall || instr_stall || mem_data_stall)) begin
				pc <= pc;
			end else begin
				pc <= pc_nxt;
			end

			// update IF/ID pipeline register (instr from data)
			if(!flush && !stall && !instr_stall && !mem_data_stall) begin
				pc_id <= pc;
				new_inst_id <= new_inst_if;
			end else if(!flush && (stall || instr_stall || mem_data_stall)) begin // stall
				pc_id <= pc_id;
				new_inst_id <= new_inst_id;
			end	else begin // flush
				pc_id <= ~0;
				new_inst_id <= 0;
			end
			
			// update ID/EX pipeline register
			if(!flush & !stall & !instr_stall & !mem_data_stall) begin
				target <= instr[11:0]; pc_ex <= pc_id; rf_rs_ex <= rf_rs; rf_rt_ex <= rf_rt; immed_ex <= immed_id;
				rs_ex <= instr[11:10]; rt_ex <= instr[9:8]; rd_ex <= rd_id;
			end else if (mem_data_stall) begin
				target <= target; pc_ex <= pc_ex; rf_rs_ex <= rf_rs_ex; rf_rt_ex <= rf_rt_ex; immed_ex <= immed_ex;
				rs_ex <= rs_ex; rt_ex <= rt_ex; rd_ex <= rd_ex;
			end else begin
				pc_ex <= ~0;
				target <= 0; rf_rs_ex <= 0; rf_rt_ex <= 0; immed_ex <= 0;
				rs_ex <= 0; rt_ex <= 0; rd_ex <= 0;
			end
			
			// update ID/EX control
			if(!flush && !stall && !instr_stall && !mem_data_stall && pc_id != `WORD_SIZE'hffff) begin
				alu_src_ex <= alu_src_id; branch_ex <= branch_id; pc_src_ex <= pc_src_id; 
				alu_branch_type_ex <= alu_branch_type_id; alu_func_code_ex <= alu_func_code_id;
				mem_read_ex <= mem_read_id; mem_write_ex <= mem_write_id;
				halt_ex <= halt_id; wwd_ex <= wwd_id; new_inst_ex <= new_inst_id; reg_write_ex <= reg_write_id; reg_src_ex <= reg_src_id;
			end else if (mem_data_stall) begin
				alu_src_ex <= alu_src_ex; branch_ex <= branch_ex; pc_src_ex <= pc_src_ex;
				alu_branch_type_ex <= alu_branch_type_ex; alu_func_code_ex <= alu_func_code_ex;
				mem_read_ex <= mem_read_ex; mem_write_ex <= mem_write_ex;
				halt_ex <= halt_ex; wwd_ex <= wwd_ex; new_inst_ex <= new_inst_ex; reg_write_ex <= reg_write_ex; reg_src_ex <= reg_src_ex;
			end else begin
				alu_src_ex <= 0; branch_ex <= 0; pc_src_ex <= 0; 
				alu_branch_type_ex <= 0; alu_func_code_ex <= 4'd15;
				mem_read_ex <= 0; mem_write_ex <= 0;
				halt_ex <= 0; wwd_ex <= 0; new_inst_ex <= 0; reg_write_ex <= 0; reg_src_ex <= 0; 
			end

			// update EX/MEM pipeline register
			if (!mem_data_stall) begin
				pc_mem <= pc_ex; rf_rs_mem <= rf_rs_forwarded; rf_rt_mem <= rf_rt_ex; alu_out_mem <= alu_out_ex;
				rd_mem <= rd_ex;
			end else begin
				pc_mem <= pc_mem; rf_rs_mem <= rf_rs_mem; rf_rt_mem <= rf_rt_mem; alu_out_mem <= alu_out_mem;
				rd_mem <= rd_mem;
			end

			// update EX/MEM control signals
			if (!mem_data_stall) begin
				mem_read_mem <= mem_read_ex; mem_write_mem <= mem_write_ex;
				halt_mem <= halt_ex; wwd_mem <= wwd_ex; new_inst_mem <= new_inst_ex; reg_write_mem <= reg_write_ex; reg_src_mem <= reg_src_ex;
			end else begin
				mem_read_mem <= mem_read_mem; mem_write_mem <= mem_write_mem;
				halt_mem <= halt_mem; wwd_mem <= wwd_mem; new_inst_mem <= new_inst_mem; reg_write_mem <= reg_write_mem; reg_src_mem <= reg_src_mem;
			end

			// update MEM/WB pipeline register
			pc_wb <= pc_mem; rf_rs_wb <= rf_rs_mem; alu_out_wb <= alu_out_mem;
			rd_wb <= rd_mem;

			// update MEM/WB control signals
			if (!mem_data_stall) begin
				halt_wb <= halt_mem; wwd_wb <= wwd_mem; new_inst_wb <= new_inst_mem; reg_write_wb <= reg_write_mem; reg_src_wb <= reg_src_mem;
			end else begin
				halt_wb <= 0; wwd_wb <= 0; new_inst_wb <= 0; reg_write_wb <= 0; reg_src_wb <= 0;
			end

			// halt
			halt <= halt_wb;
		end
	end

	always @(posedge clk) begin
		if (wwd_wb) begin
			output_port <= rf_rs_wb;
		end

		if (new_inst_wb) begin
			num_inst <= num_inst + 1;
		end
	end

	// choose one of branch predictors
	// branch_predictor_always_not_taken BranchPredictor(
	// 	.clk(clk),
	// 	.reset_n(reset_n),
	// 	.PC(pc),
	// 	.is_flush(flush),
	// 	.is_BJ_type(1'b0),
	// 	.actual_next_PC(actual_pc),
	// 	.actual_PC(pc_ex),
	// 	.next_PC(pc_nxt)
	// );

	// branch_predictor_always_taken BranchPredictor(
	// 	.clk(clk),
	// 	.reset_n(reset_n),
	// 	.PC(pc),
	// 	.is_flush(flush),
	// 	.is_BJ_type(branch_ex || (pc_src_ex != 2'b0)),
	// 	.actual_taken_PC(actual_taken_pc),
	// 	.actual_next_PC(actual_pc),
	// 	.actual_PC(pc_ex),
	// 	.next_PC(pc_nxt)
	// );

	branch_predictor_global_predictor BranchPredictor(
		.clk(clk),
		.reset_n(reset_n),
		.PC(pc),
		.is_flush(flush),
		.is_BJ_type(branch_ex || (pc_src_ex != 2'b0)),
		.actual_taken_PC(actual_taken_pc),
		.actual_next_PC(actual_pc),
		.actual_PC(pc_ex),
		.next_PC(pc_nxt)
	);

	control_unit ControlUnit(
		.opcode(instr[15:12]),
		.func_code(instr[5:0]),
		.clk(clk),
		.reset_n(reset_n),
		.halt(halt_id),
		.wwd(wwd_id),
		.new_inst(new_inst_if),
		.use_rs(use_rs),
		.use_rt(use_rt),
		.alu_src(alu_src_id),
		.branch(branch_id),
		.mem_read(mem_read_id),
		.mem_write(mem_write_id),
		.reg_write(reg_write_id),
		.pc_src(pc_src_id),
		.reg_dest(reg_dest),
		.reg_src(reg_src_id),
		.alu_branch_type(alu_branch_type_id),
		.alu_func_code(alu_func_code_id)
	);

	register_file RegisterFile(
		.clk(clk),
		.reset_n(reset_n),
		.read1(instr[11:10]),
		.read2(instr[9:8]),
		.dest(rd_wb),
		.reg_write(reg_write_wb),
		.write_data(write_data_wb),
		.read_out1(rf_rs),
		.read_out2(rf_rt)
	);

	alu ALU(
		.A(rf_rs_forwarded),
		.B(alu_operand_B),
		.func_code(alu_func_code_ex),
		.branch_type(alu_branch_type_ex),
		.alu_out(alu_out_ex),
		.overflow_flag(alu_overflow_flag),
		.bcond(alu_bcond)
	);

	immediate_generator ImmGen(
		.opcode(instr[15:12]),
		.imm(instr[7:0]),
		.immediate(immed_id)
	);

	mux2_1 MUX_branch(
		.sel(branch_ex & alu_bcond),
		.i1(pc_ex + `WORD_SIZE'b1),
		.i2(pc_ex + `WORD_SIZE'b1 + immed_ex),
		.o(pc_branch)
	);

	mux4_1 MUX_pc_src(
		.sel(pc_src_ex),
		.i1(pc_branch),
		.i2({pc_ex[15:12], target}),
		.i3(rf_rs_forwarded),
		.i4(pc_branch),
		.o(actual_pc)
	);

	mux2_1 MUX_alu_src(
		.sel(alu_src_ex),
		.i1(rf_rt_forwarded),
		.i2(immed_ex),
		.o(alu_operand_B)
	);

	mux4_1 #(.DATA_WIDTH(2)) MUX_reg_dest(
		.sel(reg_dest),
		.i1(instr[7:6]),
		.i2(instr[9:8]),
		.i3(2'b10),
		.i4(instr[7:6]),
		.o(rd_id)
	);

	mux4_1 MUX_reg_src(
		.sel(reg_src_wb),
		.i1(alu_out_wb),
		.i2(mem_read_data),
		.i3(pc_wb + `WORD_SIZE'b1),
		.i4(alu_out_wb),
		.o(write_data_wb)
	);

	hazard_detect HazardDetectionUnit(
		.IFID_IR(instr),
		.IDEX_rd(rd_ex),
		.use_rs(use_rs),
		.use_rt(use_rt),
		.IDEX_M_mem_read(mem_read_ex),
		.is_stall(stall)
	);

	forwarding_unit ForwardingUnit(
		.rs_EX(rs_ex),
		.rt_EX(rt_ex),
		.rd_MEM(rd_mem),
		.reg_write_MEM(reg_write_mem),
		.rd_WB(rd_wb),
		.reg_write_WB(reg_write_wb),
		.forward_A(forward_a),
		.forward_B(forward_b)
	);

	mux4_1 MUX_forwarding_a(
		.sel(forward_a),
		.i1(rf_rs_ex),
		.i2(alu_out_mem),
		.i3(write_data_wb),
		.i4(rf_rs_ex),
		.o(rf_rs_forwarded)
	);

	mux4_1 MUX_forwarding_b(
		.sel(forward_b),
		.i1(rf_rt_ex),
		.i2(alu_out_mem),
		.i3(write_data_wb),
		.i4(rf_rt_ex),
		.o(rf_rt_forwarded)
	);

endmodule

