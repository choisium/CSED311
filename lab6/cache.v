`include "opcodes.v"
`include "cache_def.v"

module cache(clk, reset_n, cpu_req1, cpu_res1, cpu_req2, cpu_res2, ackOutput2);

	input clk;
	input reset_n;

    input [`CPU_REQ_SIZE-1:0] cpu_req1;   // CPU request input (CPU->cache)
    input [`CPU_REQ_SIZE-1:0] cpu_req2;   // CPU request input (CPU->cache)

    output [`CPU_RES_SIZE-1:0] cpu_res1;   // cache result (cache->CPU)
    output [`CPU_RES_SIZE-1:0] cpu_res2;   // cache result (cache->CPU)

	input ackOutput2;

    always @(*) begin
        $display("CPU_REQ1 - valid : %h, rw : %h, address : %h, data : %h", cpu_req1[`CPU_REQ_VALID], cpu_req1[`CPU_REQ_RW], cpu_req1[`CPU_REQ_ADDR], cpu_req1[`CPU_REQ_DATA]);
        $display("CPU_REQ1 - valid : %h, rw : %h, address : %h, data : %h", cpu_req1[`CPU_REQ_VALID], cpu_req1[`CPU_REQ_RW], cpu_req1[`CPU_REQ_ADDR], cpu_req1[`CPU_REQ_DATA]);
        $display("CPU_RES1 - ready : %h, data : %h", cpu_res1[`CPU_RES_READY], cpu_res1[`CPU_RES_DATA]);
        $display("CPU_RES2 - ready : %h, data : %h", cpu_res2[`CPU_RES_READY], cpu_res2[`CPU_RES_DATA]);
    end

endmodule
