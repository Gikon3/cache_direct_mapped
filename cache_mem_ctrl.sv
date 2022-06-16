module cache_mem_ctrl #(
    parameter NUM_BLOCK = 3,
              NUM_WORD = 5
    )
    (
    input   logic                               i_clk,
    input   logic                               i_nreset,

    input   logic                               i_bypass,
    input   logic                               i_cache_dis,

    input   logic                               i_en,
    input   logic   [29:0]                      i_addr, // [29:8] - tag, [7:5] - block, [4:0] - word
    output  logic   [31:0]                      o_rdata,
    output  logic                               o_ready,

    output  logic                               o_mem_we,
    output  logic   [NUM_BLOCK+NUM_WORD-1:0]    o_mem_addr,
    output  logic   [31:0]                      o_mem_wdata,
    input   logic   [31:0]                      i_mem_rdata,

    output  logic                               o_slave_sel,
    output  logic   [29:0]                      o_slave_addr,
    input   logic   [31:0]                      i_slave_rdata,
    input   logic                               i_slave_ready,

    input   logic   [31:0]                      i_climit
    );

    localparam MEM_DEPTH = NUM_BLOCK + NUM_WORD;        // 8
    localparam MEM_SIZE = 2 ** MEM_DEPTH;               // 256
    localparam TAG_SIZE = 32 - 2 - MEM_DEPTH;           // 22
    localparam ADDR_MEM_SIZE = TAG_SIZE + NUM_BLOCK;    // 25
    localparam DUST_MEM_SIZE = 2 ** NUM_WORD;           // 32
    enum logic [2:0] {IDLE, READ, CTRL_LOAD, LOAD, BP} state_list;

    logic   [ 2:0]              current_state;
    logic   [ 2:0]              next_state;
    logic                       state_idle;
    logic                       state_read;
    logic                       state_ctrl_load;
    logic                       state_load;
    logic                       state_bypass;

    logic   [TAG_SIZE-1:0]      addr_tag;
    logic   [NUM_BLOCK-1:0]     addr_block;
    logic   [NUM_WORD-1:0]      addr_word;
    logic                       cache_area;
    logic                       miss_tag;
    logic                       miss_block;
    logic                       miss_word;
    logic                       miss_cache;
    logic   [ADDR_MEM_SIZE-1:0] addr_mem [MEM_DEPTH-1:0];
    logic   [DUST_MEM_SIZE-1:0] dust_mem [MEM_DEPTH-1:0];

    assign state_idle = current_state == IDLE;
    assign state_read = current_state == READ;
    assign state_ctrl_load = current_state == CTRL_LOAD;
    assign state_load = current_state == LOAD;
    assign state_bypass = current_state == BP;

    assign addr_tag = i_addr[29:MEM_DEPTH];
    assign addr_block = i_addr[MEM_DEPTH-1:NUM_WORD];
    assign addr_word = i_addr[NUM_WORD-1:0];
    assign cache_area = i_en && i_addr < i_climit[31:2];
    assign miss_tag = i_en && addr_tag != addr_mem[addr_block][ADDR_MEM_SIZE-1:NUM_BLOCK];
    assign miss_block = i_en && addr_block != addr_mem[addr_block][NUM_BLOCK-1:0];
    assign miss_word = i_en && dust_mem[addr_block][addr_word] != 1'b1;
    assign miss_cache = miss_tag | miss_block | miss_word | i_bypass | i_cache_dis | !cache_area;

    // State machine
    always_ff @(posedge i_clk, negedge i_nreset)
        if (!i_nreset) current_state <= IDLE;
        else current_state <= next_state;

    always_comb
        case (current_state)
            IDLE:
                case ({i_en, miss_cache})
                    2'b10:
                        next_state = READ;
                    2'b11:
                        next_state = CTRL_LOAD;
                    default:
                        next_state = IDLE;
                endcase
            READ:
                next_state = IDLE;
            CTRL_LOAD:
                if (i_bypass | i_cache_dis | !cache_area)
                    next_state = BP;
                else
                    next_state = LOAD;
            LOAD:
                if (i_slave_ready)
                    next_state = IDLE;
                else
                    next_state = LOAD;
            BP:
                if (i_slave_ready)
                    next_state = IDLE;
                else
                    next_state = BP;
            default:
                next_state = IDLE;
        endcase

    // Out signals
    assign o_rdata = state_read ? i_mem_rdata:
                     o_mem_we ? i_slave_rdata:
                     state_bypass ? i_slave_rdata: 32'd0;
    assign o_ready = state_read /*|| state_idle*/ ? 1'b1:
                     state_load ? i_slave_ready:
                     state_bypass ? i_slave_ready: 1'b0;

    // Mem-Control signals
    assign o_mem_we = state_load && i_slave_ready;
    assign o_mem_addr = state_read || o_mem_we ? {addr_block, addr_word}: 'd0;
    assign o_mem_wdata = i_slave_rdata;

    // Dustiness
    always_ff @(posedge i_clk, negedge i_nreset)
    //    if (!i_nreset) addr_mem <= {MEM_DEPTH{'d0}}; //Galimov 08/07/2020
          if (!i_nreset)  for (int j=0;j<8;j++)  addr_mem[j] <= 'd0; //Galimov 08/07/2020
        else if (state_load) addr_mem[addr_block] <= {addr_tag, addr_block};

    assign we_word_dust_mem = state_load & (miss_tag | miss_block);
    assign we_bit_dust_mem = state_load & miss_word & i_slave_ready;
    always_ff @(posedge i_clk, negedge i_nreset)
    //    if (!i_nreset) dust_mem <= {MEM_DEPTH{'d0}}; //Galimov 08/07/2020
          if (!i_nreset)  for (int k=0;k<8;k++) dust_mem[k] <= 'd0; //Galimov 08/07/2020
        else if (we_word_dust_mem) dust_mem[addr_block] <= 'd0;
        else if (we_bit_dust_mem) dust_mem[addr_block] <= dust_mem[addr_block] | ('d1 << addr_word);

    // Slave-Control signals
    assign o_slave_sel = state_ctrl_load;
    assign o_slave_addr = state_ctrl_load ? i_addr: 'd0;

endmodule
