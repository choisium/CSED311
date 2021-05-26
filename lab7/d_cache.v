`include "opcodes.v"
`include "cache_def.v"

module data_cache(clk, reset_n, cpu_read_m2, cpu_write_m2, cpu_address2, cpu_data2, cpu_inputReady2, cpu_ackOutput2,
        read_m2, write_m2, address2, data2, inputReady2, ackOutput2, cpu_valid2,
        i_read_m1, read_m1, address1, data1, inputReady1, busAccess);

    input clk;
	input reset_n;

    // I/O between CPU
	input cpu_read_m2;
	input cpu_write_m2;
	input [`WORD_SIZE-1:0] cpu_address2;
	inout [`WORD_SIZE-1:0] cpu_data2;

    input busAccess;

    wire cpu_ackOutput1;
   	output cpu_inputReady2;
    output cpu_ackOutput2;

    // I/O between Memory
	output read_m2;
	output write_m2;
	output [`WORD_SIZE-1:0] address2;
	inout [4*`WORD_SIZE-1:0] data2;

    input i_read_m1;
    output read_m1;
    output [`WORD_SIZE-1:0] address1;
    input [4*`WORD_SIZE-1:0] data1;

    input inputReady1;
	input inputReady2;
	input ackOutput2;

    input cpu_valid2;

    // Internal reg
    reg [`WORD_SIZE-1:0] cpu_res_data2;
    reg [`WORD_SIZE-1:0] data_way1;
    reg [`WORD_SIZE-1:0] data_way2;
    reg [`CACHE_DATA_SIZE-1:0] write_data;
    reg cpu_res_inputReady2;
    reg cpu_res_ackOutput2;

    reg [`WORD_SIZE-1:0] mem_req_addr1, mem_req_addr2;
    reg [`CACHE_DATA_SIZE-1:0] mem_req_data1, mem_req_data2;
    reg mem_req_read1;
    reg mem_req_read2;
    reg mem_req_write2;

    // Assign
    // mem_req, data2
    assign read_m1 = mem_req_read1;
    assign read_m2 = mem_req_read2;
    assign write_m2 = mem_req_write2;
    assign address1 = mem_req_addr1;
    assign address2 = mem_req_addr2;

    // cpu_res, data2
    assign cpu_inputReady2 = cpu_res_inputReady2;
    assign cpu_ackOutput2 = cpu_res_ackOutput2;
    assign cpu_data2 = cpu_read_m2? cpu_res_data2: 'bz;

    assign data2 = busAccess? (read_m2? 'bz: mem_req_data2): 'bz;

    localparam
        CHECK = 2'b00,
        ALLOCATE = 2'b01,
        WRITE_BACK = 2'b10,
        WRITE_ALLOCATE = 2'b11;

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

    wire CACHE_HIT;
    wire CACHE_MISS;
    wire WRITE_BACK_STAGE;

    wire [`WORD_TAG] ADDRESS_TAG;
    wire ADDRESS_IDX;
    wire [`WORD_BO] ADDRESS_BO;

    assign ADDRESS_TAG = cpu_address2[`WORD_TAG];
    assign ADDRESS_IDX = cpu_address2[`WORD_IDX];
    assign ADDRESS_BO = cpu_address2[`WORD_BO];

    assign HIT_way1 = ADDRESS_TAG == tag_read_way1[`CACHE_TAG];
    assign VALID_way1 = tag_read_way1[`CACHE_TAG_VALID];
    assign DIRTY_way1 = tag_read_way1[`CACHE_TAG_DIRTY];
    assign RECENT_way1 = tag_read_way1[`CACHE_TAG_RECENT];

    assign HIT_way2 = ADDRESS_TAG == tag_read_way2[`CACHE_TAG];
    assign VALID_way2 = tag_read_way2[`CACHE_TAG_VALID];
    assign DIRTY_way2 = tag_read_way2[`CACHE_TAG_DIRTY];
    assign RECENT_way2 = tag_read_way2[`CACHE_TAG_RECENT];

    assign CACHE_HIT = (HIT_way1 && VALID_way1) || (HIT_way2 && VALID_way2);
    assign CACHE_MISS = !CACHE_HIT;
    assign WRITE_BACK_STAGE = (rstate == WRITE_BACK);

    reg UPDATE_WAY1;    // tag, data will be written in way 1
    reg UPDATE_WAY2;    // tag, data will be written in way 2

    // to calculate hit ratio
    integer hit_count, memory_count;
    reg [`WORD_SIZE-1:0] previous_address;

    always @(*) begin
        vstate = rstate;

        tag_write_way1 = 0;
        tag_write_way2 = 0;
        data_write_way1 = 0;
        data_write_way2 = 0;

        // tag read by default, direct map index
        tag_req[`CACHE_REQ_WE] = 0;
        tag_req[`CACHE_REQ_INDEX] = ADDRESS_IDX;

        // data read by default, direct map index
        data_req[`CACHE_REQ_WE] = 0;
        data_req[`CACHE_REQ_INDEX] = ADDRESS_IDX;

        // read correct word from cache (way 1)
        case(ADDRESS_BO)
            2'b00: data_way1 = data_read_way1[`BLOCK_WORD_1];
            2'b01: data_way1 = data_read_way1[`BLOCK_WORD_2];
            2'b10: data_way1 = data_read_way1[`BLOCK_WORD_3];
            2'b11: data_way1 = data_read_way1[`BLOCK_WORD_4];
        endcase

        // read correct word from cache (way 2)
        case(ADDRESS_BO)
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
        cpu_res_data2 = HIT_way1? data_way1 : data_way2;

        // cpu_res
        cpu_res_inputReady2 = 0;
        cpu_res_ackOutput2 = 0;

        // Cache FSM
        case (rstate)

            // Check Cache hit? miss?
            CHECK: begin

                // no memory request
                mem_req_read1 = 0;
                mem_req_read2 = 0;
                mem_req_write2 = 0;

                // Initialize UPDATE reg
                UPDATE_WAY1 = 0;
                UPDATE_WAY2 = 0;

                // If no CPU request, maintain at CHECK state
                if(!cpu_valid2) begin
                    vstate = CHECK;
                end else begin
                    // cache hit (tag match and cache entry is valid)
                    if(CACHE_HIT) begin
                        // cache hit and read -> send data to cpu and update recent bit
                        if (cpu_read_m2) begin
                            cpu_res_inputReady2 = 1;

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
                        end

                        // cache hit and write -> write data to cache with dirty bit and update recent bit
                        else if (cpu_write_m2) begin
                            cpu_res_ackOutput2 = 1;

                            if((HIT_way1 && VALID_way1)) begin
                                // Way1 HIT: Write on way 1, set dirty bit
                                UPDATE_WAY1 = 1;
                                UPDATE_WAY2 = 0;

                                // write correct word using data2
                                case(ADDRESS_BO)
                                    2'b00: write_data = {cpu_data2, data_read_way1[`BLOCK_WORD_1_C]};
                                    2'b01: write_data = {data_read_way1[`BLOCK_WORD_1], cpu_data2, data_read_way1[`BLOCK_WORD_2_C]};
                                    2'b10: write_data = {data_read_way1[`BLOCK_WORD_3_C], cpu_data2, data_read_way1[`BLOCK_WORD_4]};
                                    2'b11: write_data = {data_read_way1[`BLOCK_WORD_4_C], cpu_data2};
                                endcase

                                data_write_way1 = write_data;

                                tag_write_way1[`CACHE_TAG_DIRTY] = 1;

                                // Update Recent bit => way1 : 1, way2 = 0
                                tag_write_way1[`CACHE_TAG_RECENT] = 1;
                                tag_write_way2[`CACHE_TAG_RECENT] = 0;

                            end else begin
                                // Way2 HIT: Write on way 2, set dirty bit
                                UPDATE_WAY1 = 0;
                                UPDATE_WAY2 = 1;

                                // write correct word using data2
                                case(ADDRESS_BO)
                                    2'b00: write_data = {cpu_data2, data_read_way2[`BLOCK_WORD_1_C]};
                                    2'b01: write_data = {data_read_way2[`BLOCK_WORD_1], cpu_data2, data_read_way2[`BLOCK_WORD_2_C]};
                                    2'b10: write_data = {data_read_way2[`BLOCK_WORD_3_C], cpu_data2, data_read_way2[`BLOCK_WORD_4]};
                                    2'b11: write_data = {data_read_way2[`BLOCK_WORD_4_C], cpu_data2};
                                endcase

                                data_write_way2 = write_data;

                                tag_write_way2[`CACHE_TAG_DIRTY] = 1;

                                // Update Recent bit => way1 : 0, way2 = 1
                                tag_write_way1[`CACHE_TAG_RECENT] = 0;
                                tag_write_way2[`CACHE_TAG_RECENT] = 1;
                            end

                            // update cache line data
                            data_req[`CACHE_REQ_WE] = 1;

                            // update tag
                            tag_req[`CACHE_REQ_WE] = 1;
                        end

                        // finished
                        vstate = CHECK;
                    end

                    // cache miss
                    else begin
                        if (busAccess) begin
                            if(!RECENT_way1 && !RECENT_way2) begin
                                // if both way is not used, allocate to way 1
                                UPDATE_WAY1 = 1;
                                UPDATE_WAY2 = 0;

                                // generate memory request on miss
                                mem_req_read2 = 1;
                                // memory request address (sampled from CPU request)
                                mem_req_addr2 = {cpu_address2[15:2], 2'b0};
                                // wait until new block allocated
                                vstate = ALLOCATE;
                            end

                            else if (!RECENT_way1) begin
                                // evict way 1
                                UPDATE_WAY1 = 1;
                                UPDATE_WAY2 = 0;

                                // if evict line is dirty, write back it to memory
                                if (VALID_way1 && DIRTY_way1) begin
                                    // generate memory write request for dirty line
                                    mem_req_write2 = 1;
                                    // memory request address (sampled from cache tag)
                                    mem_req_addr2 = {tag_read_way1[`CACHE_TAG], ADDRESS_IDX, 2'b00};
                                    mem_req_data2 = data_read_way1;
                                    if (!i_read_m1) begin
                                        // port 1 is not using. use port1 to read data
                                        mem_req_addr1 = {cpu_address2[15:2], 2'b0};
                                        mem_req_read1 = 1;

                                        vstate = WRITE_ALLOCATE;
                                    end else begin
                                        // wait until write back done
                                        vstate = WRITE_BACK;
                                    end
                                end

                                else begin
                                    // generate memory request on miss
                                    mem_req_read2 = 1;
                                    // memory request address (sampled from CPU request)
                                    mem_req_addr2 = {cpu_address2[15:2], 2'b0};
                                    // wait until new block allocated
                                    vstate = ALLOCATE;
                                end
                            end

                            else begin
                                // evict way 2
                                UPDATE_WAY1 = 0;
                                UPDATE_WAY2 = 1;

                                // if evict line is dirty, write back it to memory
                                if (VALID_way2 && DIRTY_way2) begin
                                    // generate memory write request for dirty line
                                    mem_req_write2 = 1;
                                    // memory request address (sampled from cache tag)
                                    mem_req_addr2 = {tag_read_way2[`CACHE_TAG], ADDRESS_IDX, 2'b00};
                                    mem_req_data2 = data_read_way2;
                                    if (!i_read_m1) begin
                                        // port 1 is not using. use port1 to read data
                                        mem_req_addr1 = {cpu_address2[15:2], 2'b0};
                                        mem_req_read1 = 1;

                                        vstate = WRITE_ALLOCATE;
                                    end else begin
                                        // wait until write back done
                                        vstate = WRITE_BACK;
                                    end
                                end

                                else begin
                                    // generate memory request on miss
                                    mem_req_read2 = 1;
                                    // memory request address (sampled from CPU request)
                                    mem_req_addr2 = {cpu_address2[15:2], 2'b0};
                                    // wait until new block allocated
                                    vstate = ALLOCATE;
                                end
                            end
                        end else begin
                            vstate = CHECK;
                        end
                    end
                end
            end

            // wait for allocating a new cache line
            ALLOCATE: begin

                // memory responded
                if (inputReady2) begin

                    if (cpu_write_m2) begin
                        case(ADDRESS_BO)
                            2'b00: write_data = {cpu_data2, data2[`BLOCK_WORD_1_C]};
                            2'b01: write_data = {data2[`BLOCK_WORD_1], cpu_data2, data2[`BLOCK_WORD_2_C]};
                            2'b10: write_data = {data2[`BLOCK_WORD_3_C], cpu_data2, data2[`BLOCK_WORD_4]};
                            2'b11: write_data = {data2[`BLOCK_WORD_4_C], cpu_data2};
                        endcase
                    end else begin
                        write_data = data2;
                    end

                    // read correct word from cache (way 1)
                    case(ADDRESS_BO)
                        2'b00: data_way1 = data2[`BLOCK_WORD_1];
                        2'b01: data_way1 = data2[`BLOCK_WORD_2];
                        2'b10: data_way1 = data2[`BLOCK_WORD_3];
                        2'b11: data_way1 = data2[`BLOCK_WORD_4];
                    endcase

                    // read correct word from cache (way 2)
                    case(ADDRESS_BO)
                        2'b00: data_way2 = data2[`BLOCK_WORD_1];
                        2'b01: data_way2 = data2[`BLOCK_WORD_2];
                        2'b10: data_way2 = data2[`BLOCK_WORD_3];
                        2'b11: data_way2 = data2[`BLOCK_WORD_4];
                    endcase

                    // update cache line data
                    if (!UPDATE_WAY1 && !UPDATE_WAY2) begin // not happen
                        $display("ALLOCATE ERROR");
                    end

                    else if (UPDATE_WAY1) begin // update way1
                        data_write_way1 = write_data;

                        tag_write_way1[`CACHE_TAG_RECENT] = 1;
                        tag_write_way1[`CACHE_TAG_VALID] = 1;
                        tag_write_way1[`CACHE_TAG] = ADDRESS_TAG;

                        tag_write_way2[`CACHE_TAG_RECENT] = 0;

                        if (cpu_write_m2) begin
                            tag_write_way1[`CACHE_TAG_DIRTY] = 1;
                            cpu_res_ackOutput2 = 1;
                        end else begin
                            tag_write_way1[`CACHE_TAG_DIRTY] = 0;
                            cpu_res_inputReady2 = 1;
                            cpu_res_data2 = data_way1;
                        end
                    end

                    else begin // update way 2
                        data_write_way2 = write_data;

                        tag_write_way1[`CACHE_TAG_RECENT] = 0;

                        tag_write_way2[`CACHE_TAG_RECENT] = 1;
                        tag_write_way2[`CACHE_TAG_VALID] = 1;
                        tag_write_way2[`CACHE_TAG] = ADDRESS_TAG;

                        if (cpu_write_m2) begin
                            tag_write_way2[`CACHE_TAG_DIRTY] = 1;
                            cpu_res_ackOutput2 = 1;
                        end else begin
                            tag_write_way2[`CACHE_TAG_DIRTY] = 0;
                            cpu_res_inputReady2 = 1;
                            cpu_res_data2 = data_way2;
                        end
                    end

                    // update cache line data
                    data_req[`CACHE_REQ_WE] = 1;

                    // update tag
                    tag_req[`CACHE_REQ_WE] = 1;

                    // re-compare tag for write miss
                    vstate = CHECK;
                end
                else begin
                    vstate = ALLOCATE;
                end
            end

            // wait until write back is done for dirty cache line
            WRITE_BACK: begin

                // memory responded
                if (ackOutput2) begin
                    // generate memory request on miss
                    mem_req_write2 = 0;
                    mem_req_read2 = 1;
                    // memory request address (sampled from CPU request)
                    mem_req_addr2 = {cpu_address2[15:2], 2'b0};

                    vstate = ALLOCATE;
                end
                else begin
                    vstate = WRITE_BACK;
                end
            end

            // wait for write back and allocating a new cache line
            WRITE_ALLOCATE: begin
                // memory responded
                if (ackOutput2 && inputReady1) begin
                    if (cpu_write_m2) begin
                        case(ADDRESS_BO)
                            2'b00: write_data = {cpu_data2, data1[`BLOCK_WORD_1_C]};
                            2'b01: write_data = {data1[`BLOCK_WORD_1], cpu_data2, data1[`BLOCK_WORD_2_C]};
                            2'b10: write_data = {data1[`BLOCK_WORD_3_C], cpu_data2, data1[`BLOCK_WORD_4]};
                            2'b11: write_data = {data1[`BLOCK_WORD_4_C], cpu_data2};
                        endcase
                    end else begin
                        write_data = data1;
                    end

                    // read correct word from cache (way 1)
                    case(ADDRESS_BO)
                        2'b00: data_way1 = data1[`BLOCK_WORD_1];
                        2'b01: data_way1 = data1[`BLOCK_WORD_2];
                        2'b10: data_way1 = data1[`BLOCK_WORD_3];
                        2'b11: data_way1 = data1[`BLOCK_WORD_4];
                    endcase

                    // read correct word from cache (way 2)
                    case(ADDRESS_BO)
                        2'b00: data_way2 = data1[`BLOCK_WORD_1];
                        2'b01: data_way2 = data1[`BLOCK_WORD_2];
                        2'b10: data_way2 = data1[`BLOCK_WORD_3];
                        2'b11: data_way2 = data1[`BLOCK_WORD_4];
                    endcase

                    // update cache line data
                    if (!UPDATE_WAY1 && !UPDATE_WAY2) begin // not happen
                        $display("ALLOCATE ERROR");
                    end

                    else if (UPDATE_WAY1) begin // update way1
                        data_write_way1 = write_data;

                        tag_write_way1[`CACHE_TAG_RECENT] = 1;
                        tag_write_way1[`CACHE_TAG_VALID] = 1;
                        tag_write_way1[`CACHE_TAG] = ADDRESS_TAG;

                        tag_write_way2[`CACHE_TAG_RECENT] = 0;

                        if (cpu_write_m2) begin
                            tag_write_way1[`CACHE_TAG_DIRTY] = 1;
                            cpu_res_ackOutput2 = 1;
                        end else begin
                            tag_write_way1[`CACHE_TAG_DIRTY] = 0;
                            cpu_res_inputReady2 = 1;
                            cpu_res_data2 = data_way1;
                        end
                    end

                    else begin // update way 2
                        data_write_way2 = write_data;

                        tag_write_way1[`CACHE_TAG_RECENT] = 0;

                        tag_write_way2[`CACHE_TAG_RECENT] = 1;
                        tag_write_way2[`CACHE_TAG_VALID] = 1;
                        tag_write_way2[`CACHE_TAG] = ADDRESS_TAG;

                        if (cpu_write_m2) begin
                            tag_write_way2[`CACHE_TAG_DIRTY] = 1;
                            cpu_res_ackOutput2 = 1;
                        end else begin
                            tag_write_way2[`CACHE_TAG_DIRTY] = 0;
                            cpu_res_inputReady2 = 1;
                            cpu_res_data2 = data_way2;
                        end
                    end

                    // update cache line data
                    data_req[`CACHE_REQ_WE] = 1;

                    // update tag
                    tag_req[`CACHE_REQ_WE] = 1;

                    // re-compare tag for write miss
                    vstate = CHECK;
                end else begin
                    vstate = WRITE_ALLOCATE;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (!reset_n) begin
            rstate <= CHECK;
            memory_count <= 0;
            hit_count <= 0;
            previous_address <= ~0;
        end else begin
            // update state
            rstate <= vstate;
            // update hit count and memory count
            if (cpu_valid2) begin
                previous_address <= cpu_address2;
                if (rstate == CHECK && previous_address != cpu_address2) begin
                    memory_count <= memory_count + 1;
                    if (vstate == CHECK) begin
                        hit_count <= hit_count + 1;
                    end
                end
            end
        end
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