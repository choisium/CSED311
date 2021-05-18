// data structures for cache tag & data

// tag_read, tag_write
`define CACHE_TAG_SIZE  14      // cache tag
`define CACHE_TAG_VALID 13      // valid bit
`define CACHE_TAG_DIRTY 12      // dirty bit
`define CACHE_TAG       11:0    // tag bits

// tag_req, data_req
`define CACHE_REQ_SIZE  3       // cache request
`define CACHE_REQ_WE    2       // write enable
`define CACHE_REQ_INDEX 1:0     // 2-bit index

// data_read, data_write
`define CACHE_DATA_SIZE 64    // 64-bit cache line

`define WORD_TAG 15:4 // 12-bit tag
`define WORD_IDX 3:2  // 2-bit index
`define WORD_BO 1:0   // 2-bit block offset

// cache line : 4 word
`define BLOCK_WORD_1 63:48
`define BLOCK_WORD_2 47:32
`define BLOCK_WORD_3 31:16
`define BLOCK_WORD_4 15:0
