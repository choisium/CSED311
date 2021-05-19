`include "opcodes.v"
`include "cache_def.v"

module instr_cache(clk, reset_n, cpu_read_m1, cpu_address1, cpu_data1, cpu_inputReady1, 
        read_m1, address1, data1, inputReady1, cpu_valid1);

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
    reg [`WORD_SIZE-1:0] cpu_res_data1;
    reg [`WORD_SIZE-1:0] data_way1;
    reg [`WORD_SIZE-1:0] data_way2;
    reg cpu_res_inputReady1;

    reg [`WORD_SIZE-1:0] mem_req_addr1;
    reg mem_req_read1;

    // Assign 
    // mem_req, data1
    assign read_m1 = mem_req_read1;
    assign address1 = mem_req_addr1;

    // cpu_res, data1
    assign cpu_inputReady1 = cpu_res_inputReady1;
    assign cpu_ackOutput1 = 1'b0;
    assign cpu_data1 = cpu_res_data1;

    localparam 
        CHECK = 2'b00,
        ALLOCATE = 2'b01;

    // state register
    reg [1:0] vstate, rstate;

    /*interface signals to tag memory*/
    wire [`CACHE_TAG_SIZE-1:0] tag_read_way1;     //tag read result
    wire [`CACHE_TAG_SIZE-1:0] tag_read_way2;     //tag read result
    reg [`CACHE_TAG_SIZE-1:0] tag_write_way1;     //tag write data
    reg [`CACHE_TAG_SIZE-1:0] tag_write_way2;     //tag write data
    reg [`CACHE_REQ_SIZE-1:0] tag_req;      //tag request

    /*interface signals to cache data memory*/
    wire [`CACHE_DATA_SIZE-1:0] data_read_way1;  //cache line read data
    wire [`CACHE_DATA_SIZE-1:0] data_read_way2;  //cache line read data
    reg [`CACHE_DATA_SIZE-1:0] data_write_way1;  //cache line write data
    reg [`CACHE_DATA_SIZE-1:0] data_write_way2;  //cache line write data
    reg [`CACHE_REQ_SIZE-1:0] data_req;     //data req

    wire HIT_way1;
    wire VALID_way1;
    wire DIRTY_way1;
    wire RECENT_way1;

    wire HIT_way2;
    wire VALID_way2;
    wire DIRTY_way2;
    wire RECENT_way2;

    assign HIT_way1 = cpu_address1[`WORD_TAG] == tag_read_way1[`CACHE_TAG];
    assign VALID_way1 = tag_read_way1[`CACHE_TAG_VALID];
    assign DIRTY_way1 = tag_read_way1[`CACHE_TAG_DIRTY];
    assign RECENT_way1 = tag_read_way1[`CACHE_TAG_RECENT];

    assign HIT_way2 = cpu_address1[`WORD_TAG] == tag_read_way2[`CACHE_TAG];
    assign VALID_way2 = tag_read_way2[`CACHE_TAG_VALID];
    assign DIRTY_way2 = tag_read_way2[`CACHE_TAG_DIRTY];
    assign RECENT_way2 = tag_read_way2[`CACHE_TAG_RECENT];

    reg UPDATE_WAY1;    // tag, data will be written in way 1
    reg UPDATE_WAY2;    // tag, data will be written in way 2

    always @(*) begin
        vstate = rstate;

        tag_write_way1 = 0;
        tag_write_way2 = 0;
        data_write_way1 = 0;
        data_write_way2 = 0;

        // tag read by default, direct map index
        tag_req[`CACHE_REQ_WE] = 0;
        tag_req[`CACHE_REQ_INDEX] = cpu_address1[`WORD_IDX];

        // data read by default, direct map index
        data_req[`CACHE_REQ_WE] = 0;
        data_req[`CACHE_REQ_INDEX] = cpu_address1[`WORD_IDX];

        // read correct word from cache (way 1)
        case(cpu_address1[`WORD_BO])
            2'b00: data_way1 = data_read_way1[`BLOCK_WORD_1];
            2'b01: data_way1 = data_read_way1[`BLOCK_WORD_2];
            2'b10: data_way1 = data_read_way1[`BLOCK_WORD_3];
            2'b11: data_way1 = data_read_way1[`BLOCK_WORD_4];
        endcase

        // read correct word from cache (way 2)
        case(cpu_address1[`WORD_BO])
            2'b00: data_way2 = data_read_way2[`BLOCK_WORD_1];
            2'b01: data_way2 = data_read_way2[`BLOCK_WORD_2];
            2'b10: data_way2 = data_read_way2[`BLOCK_WORD_3];
            2'b11: data_way2 = data_read_way2[`BLOCK_WORD_4];
        endcase
        
        // correlate write and read; when write, write same tag and data if nothing changed 
        tag_write_way1 = tag_read_way1;
        tag_write_way2 = tag_read_way2;
        data_write_way1 = data_read_way1;
        data_write_way2 = data_read_way2;

        // choose right data way
        cpu_res_data1 = HIT_way1? data_way1 : data_way2;

        // memory request address (sampled from CPU request)
        mem_req_addr1 = {cpu_address1[15:2], 2'b0};

        // cpu_res
        cpu_res_inputReady1 = 0;

        // Cache FSM
        case (rstate)

            // Check Cache hit? miss?
            CHECK: begin
                               
                // no memory request
                mem_req_read1 = 0;

                // Initialize UPDATE reg
                UPDATE_WAY1 = 0;
                UPDATE_WAY2 = 0;

                // If no CPU request, maintain at CHECK state
                if(!cpu_valid1) begin
                    vstate = CHECK;
                end else begin
                    // cache hit (tag match and cache entry is valid)
                    if((HIT_way1 && VALID_way1) || (HIT_way2 && VALID_way2)) begin
                        cpu_res_inputReady1 = 1;

                        if((HIT_way1 && VALID_way1)) begin

                            // Way1 HIT : Update Recent bit => way1 : 1, way2 = 0
                            tag_write_way1[`CACHE_TAG_RECENT] = 1;
                            tag_write_way2[`CACHE_TAG_RECENT] = 0;

                        end else begin

                            // Way2 HIT :Update Recent bit => way1 : 0, way2 = 1
                            tag_write_way1[`CACHE_TAG_RECENT] = 0;
                            tag_write_way2[`CACHE_TAG_RECENT] = 1;
                        end

                        // update tag
                        tag_req[`CACHE_REQ_WE] = 1;

                        // finished
                        vstate = CHECK;
                    end

                    // cache miss
                    else begin

                        if(!RECENT_way1 && !RECENT_way2) begin
                            // if both way is not used, allocate to way 1
                            tag_write_way1[`CACHE_TAG_RECENT] = 1;
                            tag_write_way1[`CACHE_TAG_VALID] = 1;
                            tag_write_way1[`CACHE_TAG] = cpu_address1[`WORD_TAG];

                            tag_write_way2[`CACHE_TAG_RECENT] = 0;

                            UPDATE_WAY1 = 1;
                            UPDATE_WAY2 = 0;
                        end 

                        else if (!RECENT_way1) begin 
                            // evict way 1
                            tag_write_way1[`CACHE_TAG_RECENT] = 1;
                            tag_write_way1[`CACHE_TAG_VALID] = 1;
                            tag_write_way1[`CACHE_TAG] = cpu_address1[`WORD_TAG];

                            tag_write_way2[`CACHE_TAG_RECENT] = 0;

                            UPDATE_WAY1 = 1;
                            UPDATE_WAY2 = 0;
                        end

                        else begin 
                            // evict way 2
                            tag_write_way1[`CACHE_TAG_RECENT] = 0;

                            tag_write_way2[`CACHE_TAG_RECENT] = 1;
                            tag_write_way2[`CACHE_TAG_VALID] = 1;
                            tag_write_way2[`CACHE_TAG] = cpu_address1[`WORD_TAG];

                            UPDATE_WAY1 = 0;
                            UPDATE_WAY2 = 1;
                        end

                        // update tag
                        tag_req[`CACHE_REQ_WE] = 1;

                        // generate memory request on miss
                        mem_req_read1 = 1;
                        
                        // wait until new block allocated
                        vstate = ALLOCATE;
                    end
                end
            end

            // wait for allocating a new cache line
            ALLOCATE: begin

                // memory responded
                if (inputReady1) begin

                    // update cache line data
                    if (!UPDATE_WAY1 && !UPDATE_WAY2) begin // not happen
                        $display("ALLOCATE ERROR");
                    end 
                
                    else if (UPDATE_WAY1) begin // update way1 
                        data_write_way1 = data1;
                    end 
                
                    else begin // update way 2
                        data_write_way2 = data1;
                    end

                    // update cache line data
                    data_req[`CACHE_REQ_WE] = 1;

                    // re-compare tag for write miss
                    vstate = CHECK;
                end
                else begin
                    vstate = ALLOCATE;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (!reset_n)
            rstate <= CHECK;
        else
            rstate <= vstate;
    end

    // connect cache tag/data memory
    dm_cache_data cache_data(
        .clk(clk),
        .reset_n(reset_n),
        .data_req(data_req),
        .data_write_way1(data_write_way1),
        .data_write_way2(data_write_way2),
        .data_read_way1(data_read_way1),
        .data_read_way2(data_read_way2)
    );

    dm_cache_tag cache_tag(
        .clk(clk),
        .reset_n(reset_n),
        .tag_req(tag_req),
        .tag_write_way1(tag_write_way1),
        .tag_write_way2(tag_write_way2),
        .tag_read_way1(tag_read_way1),
        .tag_read_way2(tag_read_way2)
    );

endmodule
