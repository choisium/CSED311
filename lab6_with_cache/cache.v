`include "opcodes.v"
`include "cache_def.v"

/*cache: data memory, single port, 4 blocks*/
module dm_cache_data(clk, data_req, data_write, data_read);
    
    input clk;
    input [`CACHE_REQ_SIZE-1:0] data_req;      // data request/command, e.g. RW, valid
    input [`CACHE_DATA_SIZE-1:0] data_write;   // write port
    output [`CACHE_DATA_SIZE-1:0] data_read;   // read port

    reg [`CACHE_DATA_SIZE-1:0] data_mem[3:0];

    initial begin
        data_mem[0] = 0;
        data_mem[1] = 0;
        data_mem[2] = 0;
        data_mem[3] = 0;
    end

    assign data_read = data_mem[data_req[`CACHE_REQ_INDEX]];
    
    always @(posedge clk) begin
        if (data_req[`CACHE_REQ_WE])
            data_mem[data_req[`CACHE_REQ_INDEX]] <= data_write;
    end
endmodule

/*cache: tag memory, single port, 4 blocks*/
module dm_cache_tag(clk, tag_req, tag_write, tag_read);

    input clk;
    input [`CACHE_REQ_SIZE-1:0] tag_req;      //tag request
    input [`CACHE_TAG_SIZE-1:0] tag_write;    //tag write data
    output [`CACHE_TAG_SIZE-1:0] tag_read;     //tag read result

    reg [`CACHE_TAG_SIZE-1:0] tag_mem[3:0];

    initial begin
        tag_mem[0] = 0;
        tag_mem[1] = 0;
        tag_mem[2] = 0;
        tag_mem[3] = 0;
    end
    
    assign tag_read = tag_mem[tag_req[`CACHE_REQ_INDEX]];
    
    always @(posedge clk) begin
        if (tag_req[`CACHE_REQ_WE])
            tag_mem[tag_req[`CACHE_REQ_INDEX]] <= tag_write;
    end
endmodule


module cache(clk, reset_n, cpu_read_m1, cpu_address1, cpu_data1, cpu_inputReady1, 
        cpu_read_m2, cpu_write_m2, cpu_address2, cpu_data2, cpu_inputReady2, cpu_ackOutput2,
        read_m1, address1, data1, inputReady1, read_m2, write_m2, address2, data2, inputReady2, ackOutput2,
        cpu_valid1, cpu_valid2, valid1, valid2);

	input clk;
	input reset_n;

    // I/O between CPU
    input cpu_read_m1;
	input [`WORD_SIZE-1:0] cpu_address1;
	input cpu_read_m2;
	input cpu_write_m2;
	input [`WORD_SIZE-1:0] cpu_address2;

	output [`WORD_SIZE-1:0] cpu_data1;
	inout [`WORD_SIZE-1:0] cpu_data2;

	output cpu_inputReady1;
    wire cpu_ackOutput1;
	output cpu_inputReady2;
    output cpu_ackOutput2;

    // I/O between Memory
    output read_m1;
	output [`WORD_SIZE-1:0] address1;
	output read_m2;
	output write_m2;
	output [`WORD_SIZE-1:0] address2;

	input [4*`WORD_SIZE-1:0] data1;
	inout [4*`WORD_SIZE-1:0] data2;

	input inputReady1;
	input inputReady2;
	input ackOutput2;

    input cpu_valid1;
    input cpu_valid2;
    output valid1;
    reg valid1;
    output valid2;

    // Internal reg
    wire cpu_req_rw1;
    reg [`WORD_SIZE-1:0] cpu_res_data1;
    reg cpu_res_inputReady1;

    reg [`WORD_SIZE-1:0] mem_req_addr1;
    reg [4*`WORD_SIZE-1:0] mem_req_data1;
    reg mem_req_read1;

    // Internal Assign
    assign cpu_req_rw1 = !cpu_read_m1;

    // Assign 
    // mem_req, data1
    assign read_m1 = mem_req_read1;
    assign address1 = mem_req_addr1;

    // cpu_res, data2
    assign {cpu_inputReady1, cpu_ackOutput1, cpu_data1} = {cpu_res_inputReady1, 1'b0, cpu_res_data1};
    
    // data2
    assign read_m2 = cpu_read_m2;
    assign write_m2 = cpu_write_m2;
    assign address2 = cpu_address2;

    assign data2 = read_m2? 'bz: {4{cpu_data2}};
    assign cpu_data2 = read_m2 && inputReady2 ? data2[`BLOCK_WORD_1] : 'bz;


    assign cpu_inputReady2 = inputReady2;
    assign cpu_ackOutput2 = ackOutput2;

    // assign valid1 = 1;
    assign valid2 = 1;

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
        mem_req_addr1 = cpu_address1;

        // memory request data (write)
        mem_req_data1 = data_read;
        mem_req_read1 = 1;

        // cpu_res
        cpu_res_inputReady1 = 0;

        // Cache FSM
        case (rstate)
            
            // Idle State
            IDLE: begin
                // If CPU request, compare cache tag
                valid1 = 0;

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

                    // cache line is dirty if write
                    tag_write[`CACHE_TAG_DIRTY] = cpu_req_rw1;

                    // generate memory request on miss
                    valid1 = 1;

                    // compulsory miss(cold miss)
                    if (tag_read[`CACHE_TAG_VALID] == 1'b0 || tag_read[`CACHE_TAG_DIRTY] == 1'b0)
                        // wait until new block allocated
                        vstate = ALLOCATE;
                    else begin
                        // miss with dirty line

                        // write back address
                        
                        // wait until write is completed
                        vstate = WRITE_BACK;
                    end
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

            // wait for writing back dirty cache line
            WRITE_BACK: begin
                
                // write back is completed
                /*issue new memory request (allocating a new line)*/
                valid1 = 1;
                mem_req_read1 = 1;
                vstate = ALLOCATE;
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
