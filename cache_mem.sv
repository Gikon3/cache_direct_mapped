module cache_mem #(
    parameter MEM_DEPTH = 8
    )
    (
    input   logic                   i_clk,
    input   logic                   i_nreset,

    input   logic                   i_write,
    input   logic   [MEM_DEPTH-1:0] i_addr,
    input   logic   [31:0]          i_data,
    output  logic   [31:0]          o_data
    );

    localparam MEM_SIZE = 2 ** MEM_DEPTH;

    logic   [31:0]  memory  [MEM_SIZE-1:0];

    always_latch
        if (!i_clk && i_nreset && i_write) memory[i_addr] <= i_data;

    assign o_data = memory[i_addr];

endmodule
