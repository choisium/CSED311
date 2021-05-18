`include "opcodes.v"
`include "cache_def.v"
`include "cache_module.v"

module instr_cache(clk, reset_n, cpu_read_m1, cpu_address1, cpu_data1, cpu_inputReady1, 
        read_m1, address1, data1, inputReady1, cpu_valid1, valid1);

	input clk;
	input reset_n;

    // I/O between CPU
    input cpu_read_m1;
	input [`WORD_SIZE-1:0] cpu_address1;
	output [`WORD_SIZE-1:0] cpu_data1;

	output cpu_inputReady1;
    wire cpu_ackOutput1;

    // I/O between Memory
    output read_m1;
	output [`WORD_SIZE-1:0] address1;
	input [4*`WORD_SIZE-1:0] data1;
	input inputReady1;

    input cpu_valid1;

    // Internal reg
    wire cpu_req_rw1;
    reg [`WORD_SIZE-1:0] cpu_res_data1;
    reg cpu_res_inputReady1;

    reg [`WORD_SIZE-1:0] mem_req_addr1;
    reg mem_req_read1;

    // Assign 
    // mem_req, data1
    assign read_m1 = mem_req_read1;
    assign address1 = mem_req_addr1;

    // cpu_res, data1
    assign {cpu_inputReady1, cpu_ackOutput1, cpu_data1} = {cpu_res_inputReady1, 1'b0, cpu_res_data1};

    localparam 
        IDLE = 2'b00,
        COMPARE_TAG = 2'b01,
        ALLOCATE = 2'b10,
        WRITE_BACK = 2'b11;

    // state register
    reg [1:0] vstate, rstate;

    /*interface signals to tag memory*/
    wire [`CACHE_TAG_SIZE-1:0] tag_read;     //tag read result
    reg [`CACHE_TAG_SIZE-1:0] tag_write;    //tag write data
    reg [`CACHE_REQ_SIZE-1:0] tag_req;      //tag request

    /*interface signals to cache data memory*/
    wire [`CACHE_DATA_SIZE-1:0] data_read;  //cache line read data
    reg [`CACHE_DATA_SIZE-1:0] data_write;  //cache line write data
    reg [`CACHE_REQ_SIZE-1:0] data_req;     //data req

    always @(*) begin
        vstate = rstate;
        tag_write = 0;

        // read tag by default
        tag_req[`CACHE_REQ_WE] = 0;

        // direct map index for tag
        tag_req[`CACHE_REQ_INDEX] = cpu_address1[3:2];

        // read current cache line by default
        data_req[`CACHE_REQ_WE] = 0;

        // direct map index for cache data
        data_req[`CACHE_REQ_INDEX] = cpu_address1[3:2];

        // modify correct word based on address
        data_write = data_read;

        // read correct word from cache
        case(cpu_address1[1:0])
            2'b00: cpu_res_data1 = data_read[`BLOCK_WORD_1];
            2'b01: cpu_res_data1 = data_read[`BLOCK_WORD_2];
            2'b10: cpu_res_data1 = data_read[`BLOCK_WORD_3];
            2'b11: cpu_res_data1 = data_read[`BLOCK_WORD_4];
        endcase

        // memory request address (sampled from CPU request)
        mem_req_addr1 = {cpu_address1[15:2], 2'b0};

        // cpu_res
        cpu_res_inputReady1 = 0;

        // Cache FSM
        case (rstate)
            
            // Idle State
            IDLE: begin
                // If CPU request, compare cache tag
                if(cpu_valid1)
                    vstate = COMPARE_TAG;
            end

            // Compare tag state
            COMPARE_TAG: begin

                // cache hit (tag match and cache entry is valid)
                if(cpu_address1[`WORD_TAG] == tag_read[`CACHE_TAG] && tag_read[`CACHE_TAG_VALID]) begin
                    cpu_res_inputReady1 = 1;

                    // write hit

                    // xaction is finished
                    vstate = IDLE;
                end

                // cache miss
                else begin
                    
                    // generate new tag
                    tag_req[`CACHE_REQ_WE] = 1;
                    tag_write[`CACHE_TAG_VALID] = 1;

                    // new tag
                    tag_write[`CACHE_TAG] = cpu_address1[`WORD_TAG];

                    // generate memory request on miss
                    valid1 = 1;

                    // compulsory miss(cold miss)
                    if (tag_read[`CACHE_TAG_VALID] == 1'b0 || tag_read[`CACHE_TAG_DIRTY] == 1'b0)
                        // wait until new block allocated
                        vstate = ALLOCATE;
                end
            end

            // wait for allocating a new cache line
            ALLOCATE: begin
                
                // memory responded
                if (inputReady1) begin
                    
                    // re-compare tag for write miss
                    vstate = COMPARE_TAG;
                    data_write = data1;

                    // update cache line data
                    data_req[`CACHE_REQ_WE] = 1;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (!reset_n)
            rstate <= IDLE;
        else
            rstate <= vstate;
    end

    // connect cache tag/data memory
    dm_cache_data cache_data(
        .clk(clk),
        .data_req(data_req),
        .data_write(data_write),
        .data_read(data_read)
    );

    dm_cache_tag cache_tag(
        .clk(clk),
        .tag_req(tag_req),
        .tag_write(tag_write),
        .tag_read(tag_read)
    );

endmodule
