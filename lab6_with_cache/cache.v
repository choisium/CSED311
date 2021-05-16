`include "opcodes.v"
`include "cache_def.v"

module cache(clk, reset_n, cpu_req1, cpu_res1, cpu_req2, cpu_res2, mem_req1, mem_req2, mem_data1, mem_data2);

	input clk;
	input reset_n;

    // CPU request input (CPU->cache)
    input [`CPU_REQ_SIZE-1:0] cpu_req1;
    input [`CPU_REQ_SIZE-1:0] cpu_req2;

    // cache result (cache->CPU)
    output [`CPU_RES_SIZE-1:0] cpu_res1;
    output [`CPU_RES_SIZE-1:0] cpu_res2;

    // memory request (cache->memory)
    output [`MEM_REQ_SIZE-1:0] mem_req1;
    output [`MEM_REQ_SIZE-1:0] mem_req2;

    // memory response (memory->cache)
    input [`MEM_DATA_SIZE-1:0] mem_data1; 
    input [`MEM_DATA_SIZE-1:0] mem_data2;

    assign mem_req1[`MEM_REQ_VALID] = cpu_req1[`CPU_REQ_VALID];
    assign mem_req1[`MEM_REQ_RW] = cpu_req1[`CPU_REQ_RW];
    assign mem_req1[`MEM_REQ_ADDR] = cpu_req1[`CPU_REQ_ADDR];
    assign mem_req1[`MEM_REQ_DATA] = 0;

    assign mem_req2[`MEM_REQ_VALID] = cpu_req2[`CPU_REQ_VALID];
    assign mem_req2[`MEM_REQ_RW] = cpu_req2[`CPU_REQ_RW];
    assign mem_req2[`MEM_REQ_ADDR] = cpu_req2[`CPU_REQ_ADDR];

    assign mem_req2[`BLOCK_WORD_1] = cpu_req2[`CPU_REQ_DATA];
    assign mem_req2[`BLOCK_WORD_2] = cpu_req2[`CPU_REQ_DATA];
    assign mem_req2[`BLOCK_WORD_3] = cpu_req2[`CPU_REQ_DATA];
    assign mem_req2[`BLOCK_WORD_4] = cpu_req2[`CPU_REQ_DATA];

    assign cpu_res1[`CPU_RES_READY] = mem_data1[`MEM_DATA_READY];
    assign cpu_res2[`CPU_RES_ACK] = mem_data1[`MEM_DATA_ACK];
    assign cpu_res1[`CPU_RES_DATA] = mem_data1[`BLOCK_WORD_1];

    assign cpu_res2[`CPU_RES_READY] = mem_data2[`MEM_DATA_READY];
    assign cpu_res2[`CPU_RES_ACK] = mem_data2[`MEM_DATA_ACK];
    assign cpu_res2[`CPU_RES_DATA] = mem_data2[`BLOCK_WORD_1];

    // always @(*) begin
    //     $display("CPU_REQ1 - valid : %h, rw : %h, address : %h, data : %h", cpu_req1[`CPU_REQ_VALID], cpu_req1[`CPU_REQ_RW], cpu_req1[`CPU_REQ_ADDR], cpu_req1[`CPU_REQ_DATA]);
    //     $display("CPU_REQ1 - valid : %h, rw : %h, address : %h, data : %h", cpu_req1[`CPU_REQ_VALID], cpu_req1[`CPU_REQ_RW], cpu_req1[`CPU_REQ_ADDR], cpu_req1[`CPU_REQ_DATA]);
    //     $display("CPU_RES1 - ready : %h, data : %h", cpu_res1[`CPU_RES_READY], cpu_res1[`CPU_RES_DATA]);
    //     $display("CPU_RES2 - ready : %h, data : %h", cpu_res2[`CPU_RES_READY], cpu_res2[`CPU_RES_DATA]);
    // end

endmodule
