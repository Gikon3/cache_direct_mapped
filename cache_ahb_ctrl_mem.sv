module cache_ahb_ctrl_mem (
    input   logic           i_hclk,
    input   logic           i_hnreset,

    // AHB interface
    input   logic           i_hsel,

    input   logic   [31:0]  i_haddr,
    input   logic           i_hwrite,
    input   logic   [ 2:0]  i_hsize,
    input   logic   [ 2:0]  i_hburst,
    input   logic   [ 3:0]  i_hprot,
    input   logic   [ 1:0]  i_htrans,
    input   logic   [ 3:0]  i_hmaster,
    input   logic           i_hready,
    input   logic   [31:0]  i_hwdata,

    output  logic           o_hready,
    output  logic           o_hresp,
    output  logic   [31:0]  o_hrdata,

    // Config signals
    output  logic   [3:0]   o_hprot,

    // Mem interface
    input   logic           i_mem_ready,
    input   logic   [31:0]  i_mem_rdata,

    output  logic   [29:0]  o_mem_addr,
    output  logic           o_mem_rd
    );

    enum logic {IDLE, READ} state_list;

    logic           request;
    logic           next_request;
    logic   [31:0]  haddr;
    logic   [3:0]   hprot;

    logic           current_state;
    logic           next_state;
    logic           state_idle;
    logic           state_read;

    logic           mem_rd_reg;

    // AHB-Control signals
    assign request = i_hsel & i_htrans[1] & i_hready;
    assign next_request = o_hready & request;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) haddr <= 32'd0;
        else if (next_request) haddr <= i_haddr;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) hprot <= 'd0;
        else if (next_request) hprot <= i_hprot;

    assign o_hprot = state_idle && request ? i_hprot: hprot;

    assign o_hready = state_idle | (state_read & i_mem_ready);
    assign o_hresp = 1'b0;
    assign o_hrdata = state_read && i_mem_ready ? i_mem_rdata: 32'd0;

    // State machine
    assign state_idle = current_state == IDLE;
    assign state_read = current_state == READ;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) current_state <= IDLE;
        else current_state <= next_state;

    always_comb
        case (current_state)
            IDLE:
                case ({request, i_hwrite})
                    2'b10:
                        next_state = READ;
                    default:
                        next_state = IDLE;
                endcase
            READ:
                if (i_mem_ready && !request)
                    next_state = IDLE;
                else
                    next_state = READ;
            default:
                next_state = IDLE;
        endcase

    // Mem-Control signals
    assign o_mem_addr = state_idle && request ? i_haddr[31:2]: haddr[31:2];

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) mem_rd_reg <= 1'b0;
        else if (next_request) mem_rd_reg <= !i_hwrite;
        else if (i_mem_ready) mem_rd_reg <= 1'b0;

    assign o_mem_rd = state_idle && request ? !i_hwrite: mem_rd_reg;

endmodule
