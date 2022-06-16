module cache_ahb_ctrl_out (
    input   logic           i_hclk,
    input   logic           i_hnreset,

    // Control interface
    input   logic           i_sel,
    input   logic   [29:0]  i_addr,
    output  logic   [31:0]  o_rdata,
    output  logic           o_ready,

    // AHB-Out interface
    output  logic           o_hsel,

    output  logic   [31:0]  o_haddr,
    output  logic           o_hwrite,
    output  logic   [ 2:0]  o_hsize,
    output  logic   [ 2:0]  o_hburst,
    output  logic   [ 3:0]  o_hprot,
    output  logic   [ 1:0]  o_htrans,
    output  logic   [ 3:0]  o_hmaster,
    output  logic           o_hready,
    output  logic   [31:0]  o_hwdata,

    input   logic           i_hready,
    input   logic           i_hresp,
    input   logic   [31:0]  i_hrdata
    );

    enum logic {IDLE, READ} state_list;

    logic           current_state;
    logic           next_state;
    logic           state_idle;
    logic           state_read;

    // State machine
    assign state_idle = current_state == IDLE;
    assign state_read = current_state == READ;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) current_state <= IDLE;
        else current_state <= next_state;

    always_comb
        case (current_state)
            IDLE:
                if (i_sel)
                    next_state = READ;
                else
                    next_state = IDLE;
            READ:
                if (i_hready)
                    next_state = IDLE;
                else
                    next_state = READ;
            default:
                next_state = IDLE;
        endcase

    // AHB-Out signals
    assign o_hsel = state_idle & i_sel;
    assign o_haddr = {i_addr, 2'h0};
    assign o_hwrite = 1'b0;
    assign o_hsize = 3'h2;
    assign o_hburst = 3'h0;
    assign o_hprot = 4'h1;
    assign o_htrans = 2'h2;
    assign o_hmaster = 4'h0;
    assign o_hready = i_hready;
    assign o_hwdata = 32'd0;

    // Out signals
    assign o_rdata = state_read ? i_hrdata: 32'd0;
    assign o_ready = state_idle | (state_read & i_hready);

endmodule
