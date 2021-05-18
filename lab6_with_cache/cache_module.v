`include "cache_def.v"

/* 2-way set associative, 4 lines, data memory*/
module dm_cache_data(clk, reset_n, data_req, data_write_way1, data_write_way2, data_read_way1, data_read_way2);
    
    input clk;
    input reset_n;
    input [`CACHE_REQ_SIZE-1:0] data_req;      // data request/command, e.g. RW, valid
    input [`CACHE_DATA_SIZE-1:0] data_write_way1;   // write port
    input [`CACHE_DATA_SIZE-1:0] data_write_way2;   // write port
    output [`CACHE_DATA_SIZE-1:0] data_read_way1;   // read port way1
    output [`CACHE_DATA_SIZE-1:0] data_read_way2;   // read port way2

    reg [`CACHE_DATA_SIZE-1:0] data_mem[3:0];

    initial begin
        data_mem[0] = 0;
        data_mem[1] = 0;
        data_mem[2] = 0;
        data_mem[3] = 0;
    end

    assign data_read_way1 = data_mem[data_req[`CACHE_REQ_INDEX] + 0];
    assign data_read_way2 = data_mem[data_req[`CACHE_REQ_INDEX] + 2];
    
    always @(posedge clk) begin
        if(!reset_n) begin
            data_mem[0] = 0;
            data_mem[1] = 0;
            data_mem[2] = 0;
            data_mem[3] = 0;
        end
        else begin
            if (data_req[`CACHE_REQ_WE]) begin
                data_mem[data_req[`CACHE_REQ_INDEX] + 0] <= data_write_way1;
                data_mem[data_req[`CACHE_REQ_INDEX] + 2] <= data_write_way2;
            end
        end
    end
endmodule

/* 2-way set associative, 4 lines, tag memory*/
module dm_cache_tag(clk, reset_n, tag_req, tag_write_way1, tag_write_way2, tag_read_way1, tag_read_way2);

    input clk;
    input reset_n;
    input [`CACHE_REQ_SIZE-1:0] tag_req;      //tag request
    input [`CACHE_TAG_SIZE-1:0] tag_write_way1;    //tag write data
    input [`CACHE_TAG_SIZE-1:0] tag_write_way2;    //tag write data
    output [`CACHE_TAG_SIZE-1:0] tag_read_way1;     //tag read way1
    output [`CACHE_TAG_SIZE-1:0] tag_read_way2;     //tag read way2

    reg [`CACHE_TAG_SIZE-1:0] tag_mem[3:0];

    initial begin
        tag_mem[0] = 0;
        tag_mem[1] = 0;
        tag_mem[2] = 0;
        tag_mem[3] = 0;
    end
    
    assign tag_read_way1 = tag_mem[tag_req[`CACHE_REQ_INDEX] + 0];
    assign tag_read_way2 = tag_mem[tag_req[`CACHE_REQ_INDEX] + 2];
    
    always @(posedge clk) begin
        if(!reset_n) begin
            tag_mem[0] = 0;
            tag_mem[1] = 0;
            tag_mem[2] = 0;
            tag_mem[3] = 0;
        end
        else begin
            if (tag_req[`CACHE_REQ_WE]) begin
                tag_mem[tag_req[`CACHE_REQ_INDEX] + 0] <= tag_write_way1;
                tag_mem[tag_req[`CACHE_REQ_INDEX] + 2] <= tag_write_way2;
            end
        end
    end
endmodule
