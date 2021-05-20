// data structures for cache tag & data

// tag_read, tag_write
`define CACHE_TAG_SIZE  16      // cache tag
`define CACHE_TAG_VALID 15      // valid bit
`define CACHE_TAG_DIRTY 14      // dirty bit
`define CACHE_TAG_RECENT 13     // Recently used 
`define CACHE_TAG       12:0    // tag bits

// tag_req, data_req
`define CACHE_REQ_SIZE  2       // cache request
`define CACHE_REQ_WE    1       // write enable
`define CACHE_REQ_INDEX 0     // 1-bit index

// data_read, data_write
`define CACHE_DATA_SIZE 64    // 64-bit cache line

`define WORD_TAG 15:3 // 13-bit tag
`define WORD_IDX 2  // 1-bit index
`define WORD_BO 1:0   // 2-bit block offset

// cache line : 4 word
`define BLOCK_WORD_1 63:48
`define BLOCK_WORD_2 47:32
`define BLOCK_WORD_3 31:16
`define BLOCK_WORD_4 15:0

`define BLOCK_WORD_1_C 47:0
`define BLOCK_WORD_2_C 31:0
`define BLOCK_WORD_3_C 63:32
`define BLOCK_WORD_4_C 63:16