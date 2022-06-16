module cache_mem_top #(
    parameter NUM_BLOCK = 3,
              NUM_WORD = 5
    )
    (
    input   logic           i_clk,
    input   logic           i_nreset,

    // Mem_config signals
    input   logic           i_bypass,
    input   logic           i_cache_dis,

    // Mem interface
    input   logic   [29:0]  i_mem_addr,
    input   logic           i_mem_rd,

    output  logic           o_mem_ready,
    output  logic   [31:0]  o_mem_rdata,

    // Slave interface
    output  logic           o_slave_sel,
    output  logic   [29:0]  o_slave_addr,
    input   logic   [31:0]  i_slave_rdata,
    input   logic           i_slave_ready,

    input   logic   [31:0]  i_climit
    );

    localparam MEM_DEPTH = NUM_BLOCK + NUM_WORD;

    logic                   mem_we;
    logic   [MEM_DEPTH-1:0] mem_addr;
    logic   [31:0]          mem_wdata;
    logic   [31:0]          mem_rdata;

    cache_mem_ctrl #(NUM_BLOCK, NUM_WORD) cache_mem_ctrl (
        .i_clk (i_clk),
        .i_nreset (i_nreset),

        .i_bypass (i_bypass),
        .i_cache_dis (i_cache_dis),

        .i_en (i_mem_rd),
        .i_addr (i_mem_addr),
        .o_rdata (o_mem_rdata),
        .o_ready (o_mem_ready),

        .o_mem_we (mem_we),
        .o_mem_addr (mem_addr),
        .o_mem_wdata (mem_wdata),
        .i_mem_rdata (mem_rdata),

        .o_slave_sel (o_slave_sel),
        .o_slave_addr (o_slave_addr),
        .i_slave_rdata (i_slave_rdata),
        .i_slave_ready (i_slave_ready),

        .i_climit (i_climit)
        );

    cache_mem #(MEM_DEPTH) cache_mem (
        .i_clk (i_clk),
        .i_nreset (i_nreset),

        .i_write (mem_we),
        .i_addr (mem_addr),
        .i_data (mem_wdata),
        .o_data (mem_rdata)
        );

endmodule
