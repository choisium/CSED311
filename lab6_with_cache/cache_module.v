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
