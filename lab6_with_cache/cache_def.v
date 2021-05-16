// data structures for cache tag & data

`define CACHE_TAG_SIZE  14      // cache tag
`define CACHE_TAG_VALID 13      // valid bit
`define CACHE_TAG_DIRTY 12      // dirty bit
`define CACHE_TAG       11:0    // tag bits

`define CACHE_REQ_SIZE  3       // cache request
`define CACHE_REQ_WE    2       // write enable
`define CACHE_REQ_INDEX 1:0     // 2-bit index

`define CACHE_DATA_SIZE 63:0    // 64-bit cache line

// data structures for CPU<->Cache controller interface

// CPU request (CPU->cache controller)
`define CPU_REQ_SIZE 34
`define CPU_REQ_VALID 33        // valid request
`define CPU_REQ_RW 32           // request type : 0 = read, 1 = write
`define CPU_REQ_ADDR 31:16      // 16-bit request addr
`define CPU_REQ_DATA 15:0       // 16-bit request data (used when write)

// memory request (cache controller->memory)
`define MEM_REQ_SIZE  82
`define MEM_REQ_VALID 81        // valid request
`define MEM_REQ_RW    80        // request type : 0 = read, 1 = write
`define MEM_REQ_ADDR 79:64      // 16-bit request addr
`define MEM_REQ_DATA 63:0       // 64-bit(4 word) request data (used when write)

// data structures for cache controller<->memory interface

// Cache result (cache controller->cpu)
`define CPU_RES_SIZE 18
`define CPU_RES_READY 17        // input ready
`define CPU_RES_ACK 16          // ackOutput
`define CPU_RES_DATA 15:0       // 16-bit data

// memory controller response (memory -> cache controller)
`define MEM_DATA_SIZE 66
`define MEM_DATA_READY 65        // input ready
`define MEM_DATA_ACK 64          // ackOutput
`define MEM_DATA 63:0            // 64-bit read back data

// cache line : 4 word
`define BLOCK_WORD_1 63:48
`define BLOCK_WORD_2 47:32
`define BLOCK_WORD_3 31:16
`define BLOCK_WORD_4 15:0
