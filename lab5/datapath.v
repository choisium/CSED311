`include "opcodes.v"
`include "register_file.v"
`include "alu.v"
`include "control_unit.v" 
`include "branch_predictor.v"
`include "hazard.v"
`include "util.v"
`include "immediate_generator.v"

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
	wire halt, use_rs, use_rt; wire[1:0] reg_dest;
	wire alu_src_id, branch_id; wire[1:0] pc_src_id, alu_branch_type_id; wire[3:0] alu_func_code_id; // to EX
	wire mem_read_id, mem_write_id; // to MEM
	wire reg_write_id, wwd_id; wire[1:0] reg_src_id; reg new_inst_id; // to MEM
		
	// ID additional wire and reg
	wire[`WORD_SIZE-1:0] rf_rs, rf_rt, immed_id;
	wire[1:0] rd_id;

	// ID/EX pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_ex, rf_rs_ex, rf_rt_ex, immed_ex;
	reg[11:0] target;
	reg[1:0] rs_ex, rt_ex, rd_ex;

	// ID/EX pipeline control signals
	reg alu_src_ex, branch_ex; reg[1:0] pc_src_ex, alu_branch_type_ex; reg[3:0] alu_func_code_ex; // to EX
	reg mem_read_ex, mem_write_ex; // to MEM
	reg wwd_ex, new_inst_ex, reg_write_ex; reg[1:0] reg_src_ex; // to WB
		
	// EX additional wire and reg
	reg flush;
	wire[`WORD_SIZE-1:0] alu_out_ex, pc_branch, alu_operand_B;
	wire alu_overflow_flag, alu_bcond;
	wire[`WORD_SIZE-1:0] actual_pc;

	// EX/MEM pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_mem, rf_rs_mem, rf_rt_mem, alu_out_mem;
	reg[1:0] rd_mem;
		
	// EX/MEM control signals
	reg mem_read_mem, mem_write_mem; // to EX
	reg wwd_mem, new_inst_mem, reg_write_mem; reg[1:0] reg_src_mem; // to MEM

	// MEM/WB pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_wb, rf_rs_wb, alu_out_wb;
	reg[1:0] rd_wb;
	
	// MEM/WB control signals
	reg wwd_wb, new_inst_wb, reg_write_wb; reg[1:0] reg_src_wb;

	// WB additional wire and reg
	wire[`WORD_SIZE-1:0] write_data_wb;


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
		wwd_ex <= 0; new_inst_ex <= 0; reg_write_ex <= 0; reg_src_ex <= 0; 

		// EX/MEM pipeline register
		pc_mem <= 0; rf_rs_mem <= 0; rf_rt_mem <= 0; alu_out_mem <= 0; 
		rd_mem <= 0; 
		
		// EX/MEM control signals
		mem_read_mem <= 0; mem_write_mem <= 0; 
		wwd_mem <= 0; new_inst_mem <= 0; reg_write_mem <=0; reg_src_mem <= 0;

		// MEM/WB control signals
		pc_wb <= 0; rf_rs_wb <= 0; alu_out_wb <= 0;
		rd_wb <= 0;

		// MEM/WB control signals
		wwd_wb <= 0; new_inst_wb <= 0; reg_write_wb <= 0; reg_src_wb <= 0;
	end


	// get memory data
	assign read_m1 = 1;
	assign address1 = pc;
	assign write_m2 = 0;
	assign read_m2 = 0;
	assign address2 = 0;

	always @(posedge clk) begin
		if (!reset_n) begin
			instr <= 0;
		end
		else begin
			instr <= data1;
		end
	end

	reg fcond1, fcond2, fcond3;

	// set flush
	always @(*) begin
		assign fcond1 = (actual_pc != pc_id);
		assign fcond2 = (pc_id != 0);
		assign fcond3 = (pc_ex != `WORD_SIZE'hffff);

		assign flush = (fcond1 & fcond2 & fcond3) ? 1: 0;  
		$strobe("pc: %h, pc_id: %h, pc_ex: %h, pc_mem: %h, pc_wb: %h, actual_pc: %h", pc, pc_id, pc_ex, pc_mem, pc_wb, actual_pc);
		$strobe("new_inst_if: %h, new_inst_id: %h, new_inst_ex: %h, new_inst_mem: %h, new_inst_wb: %h", new_inst_if, new_inst_id, new_inst_ex, new_inst_mem, new_inst_wb);
	end

	// update pipeline register
	always @(posedge clk) begin
		$strobe("--- clk posedge --- pc: %h, pc_nxt: %h, instr: %h", pc, pc_nxt, instr);
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
			wwd_ex <= 0; new_inst_ex <= 0; reg_write_ex <= 0; reg_src_ex <= 0; 

			// EX/MEM pipeline register
			pc_mem <= 0; rf_rs_mem <= 0; rf_rt_mem <= 0; alu_out_mem <= 0; 
			rd_mem <= 0; 
			
			// EX/MEM control signals
			mem_read_mem <= 0; mem_write_mem <= 0; 
			wwd_mem <= 0; new_inst_mem <= 0; reg_write_mem <=0; reg_src_mem <= 0;

			// MEM/WB control signals
			pc_wb <= 0; rf_rs_wb <= 0; alu_out_wb <= 0;
			rd_wb <= 0;

			// MEM/WB control signals
			wwd_wb <= 0; new_inst_wb <= 0; reg_write_wb <= 0; reg_src_wb <= 0;
		end
		else begin
			// update pc
			pc <= pc_nxt;

			// update IF/ID pipeline register (instr from data)
			if(!flush) begin
				pc_id <= pc;
				new_inst_id <= new_inst_if;
			end else begin
				pc_id <= ~0;
				new_inst_id <= 0;
			end
			
			// update ID/EX pipeline register
			if(!flush) begin
				target <= instr[11:0]; pc_ex <= pc_id; rf_rs_ex <= rf_rs; rf_rt_ex <= rf_rt; immed_ex <= immed_id;
				rs_ex <= instr[11:10]; rt_ex <= instr[9:8]; rd_ex <= rd_id;
			end else begin
				pc_ex <= ~0;
				target <= 0; rf_rs_ex <= 0; rf_rt_ex <= 0; immed_ex <= 0;
				rs_ex <= 0; rt_ex <= 0; rd_ex <= 0;
			end
			
			// update EX control
			if(!flush) begin
				alu_src_ex <= alu_src_id; branch_ex <= branch_id; pc_src_ex <= pc_src_id; 
				alu_branch_type_ex <= alu_branch_type_id; alu_func_code_ex <= alu_func_code_id;
				mem_read_ex <= mem_read_id; mem_write_ex <= mem_write_id; 
				wwd_ex <= wwd_id; new_inst_ex <= new_inst_id; reg_write_ex <= reg_write_id; reg_src_ex <= reg_src_id; 
			end else begin
				alu_src_ex <= 0; branch_ex <= 0; pc_src_ex <= 0; 
				alu_branch_type_ex <= 0; alu_func_code_ex <= 4'd15;
				mem_read_ex <= 0; mem_write_ex <= 0; 
				wwd_ex <= 0; new_inst_ex <= 0; reg_write_ex <= 0; reg_src_ex <= 0; 
			end

			// update EX/MEM pipeline register
			pc_mem <= pc_ex; rf_rs_mem <= rf_rs_ex; rf_rt_mem <= rf_rt_ex; alu_out_mem <= alu_out_ex; 
			rd_mem <= rd_ex; 

			// update EX/MEM control signals
			mem_read_mem <= mem_read_ex; mem_write_mem <= mem_write_ex; 
			wwd_mem <= wwd_ex; new_inst_mem <= new_inst_ex; reg_write_mem <= reg_write_ex; reg_src_mem <= reg_src_ex;

			// update MEM/WB control signals
			pc_wb <= pc_mem; rf_rs_wb <= rf_rs_mem; alu_out_wb <= alu_out_mem;
			rd_wb <= rd_mem;

			// update MEM/WB control signals
			wwd_wb <= wwd_mem; new_inst_wb <= new_inst_mem; reg_write_wb <= reg_write_mem; reg_src_wb <= reg_src_mem;
		end
	end

	always @(posedge clk) begin
		if (wwd_wb) begin
			$strobe("rf_rs: %h, wwd_wb: %b, output_port: %h", rf_rs_wb, wwd_wb, output_port);
			output_port <= rf_rs_wb;
		end

		if (new_inst_wb) begin
			$strobe("new inst finished!");
			num_inst <= num_inst + 1;
		end
	end

	branch_predictor BranchPredictor(
		.clk(clk),
		.reset_n(reset_n),
		.PC(pc),
		.is_flush(flush),
		.is_BJ_type(1'b0),
		.actual_next_PC(`WORD_SIZE'b0),
		.actual_PC(actual_pc),
		.next_PC(pc_nxt)
	);

	control_unit ControlUnit(
		.opcode(instr[15:12]),
		.func_code(instr[5:0]),
		.clk(clk),
		.reset_n(reset_n),
		.halt(halt),
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
		.A(rf_rs_ex),
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
		.i2(pc_ex + immmed_id),
		.o(pc_branch)
	);

	mux4_1 MUX_pc_src(
		.sel(pc_src_ex),
		.i1(pc_branch),
		.i2({pc_ex[15:12], target}),
		.i3(rf_rs_ex),
		.i4(pc_branch),
		.o(actual_pc)
	);

	mux2_1 MUX_alu_src(
		.sel(alu_src_ex),
		.i1(rf_rt_ex),
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
		.i2(alu_out_wb),
		.i3(pc_wb),
		.i4(alu_out_wb),
		.o(write_data_wb)
	);

endmodule

