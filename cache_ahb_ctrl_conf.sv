module cache_ahb_ctrl_conf (
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
    input   logic   [3:0]   i_hprot_mem,
    output  logic           o_bypass,
    output  logic           o_cache_dis
    );

    enum logic [1:0] {IDLE, WRITE, READ} state_list;

    logic   [31:0]  haddr;
    logic   [2:0]   hsize;
    logic           hsize_b;
    logic           hsize_hw;
    logic           hsize_w;
    logic           hsize_b0;
    logic           hsize_b1;
    logic           hsize_b2;
    logic           hsize_b3;
    logic           hsize_hw0;
    logic           hsize_hw1;
    logic           hsize_w0;
    logic           htrans1;

    logic   [ 1:0]  current_state;
    logic   [ 1:0]  next_state;
    logic           state_write;
    logic           state_read;

    logic           sel_cr_ctrl;
    logic           sel_cr_stat;
    logic           wr_cr_ctrl;
    logic           rd_cr_ctrl;
    logic           wr_cr_stat;
    logic           rd_cr_stat;

    logic   [31:0]  cr_ctrl;
    logic   [31:0]  cr_stat;

    // AHB-Control signals
    assign request = o_hready & i_hsel & i_htrans[1] & i_hready;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) haddr <= 32'd0;
        else if (request) haddr <= i_haddr;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) hsize <= 3'd0;
        else if (request) hsize <= i_hsize;

    assign hsize_b = hsize == 3'h0;
    assign hsize_hw = hsize == 3'h1;
    assign hsize_w = hsize == 3'h2;

    assign hsize_b0 = hsize_b && haddr[1:0] == 2'h0;
    assign hsize_b1 = hsize_b && haddr[1:0] == 2'h1;
    assign hsize_b2 = hsize_b && haddr[1:0] == 2'h2;
    assign hsize_b3 = hsize_b && haddr[1:0] == 2'h3;
    assign hsize_hw0 = hsize_hw && haddr[1:0] == 2'h0;
    assign hsize_hw1 = hsize_hw && haddr[1:0] == 2'h2;
    assign hsize_w0 = hsize_w && haddr[1:0] == 2'h0;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) htrans1 <= 1'b0;
        else if (request) htrans1 <= i_htrans[1];

    // State machine
    assign state_write = current_state == WRITE;
    assign state_read = current_state == READ;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) current_state <= IDLE;
        else current_state <= next_state;

    always_comb
        case (current_state)
            IDLE:
                case ({i_hsel, i_hwrite})
                    2'b10:
                        next_state = READ;
                    2'b11:
                        next_state = WRITE;
                    default:
                        next_state = IDLE;
                endcase
            WRITE:
                next_state = IDLE;
            READ:
                next_state = IDLE;
            default:
                next_state = IDLE;
        endcase

    // Mem-Config registers
    assign sel_cr_ctrl = haddr[4:2] == 3'h0;
    assign sel_cr_stat = haddr[4:2] == 3'h1;
    assign wr_cr_ctrl = htrans1 && state_write && sel_cr_ctrl;
    assign rd_cr_ctrl = htrans1 && state_read && sel_cr_ctrl;
    assign wr_cr_stat = htrans1 && state_write && sel_cr_stat;
    assign rd_cr_stat = htrans1 && state_read && sel_cr_stat;

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) cr_ctrl <= 'd0;
        else if (wr_cr_ctrl && hsize_b0) cr_ctrl[7:0] <= i_hwdata[7:0];
        else if (wr_cr_ctrl && hsize_b1) cr_ctrl[15:8] <= i_hwdata[15:8];
        else if (wr_cr_ctrl && hsize_b2) cr_ctrl[23:16] <= i_hwdata[23:16];
        else if (wr_cr_ctrl && hsize_b3) cr_ctrl[31:24] <= i_hwdata[31:24];
        else if (wr_cr_ctrl && hsize_hw0) cr_ctrl[15:0] <= i_hwdata[15:0];
        else if (wr_cr_ctrl && hsize_hw1) cr_ctrl[31:16] <= i_hwdata[31:16];
        else if (wr_cr_ctrl && hsize_w0) cr_ctrl[31:0] <= i_hwdata[31:0];

    always_ff @(posedge i_hclk, negedge i_hnreset)
        if (!i_hnreset) cr_stat <= 'd0;
        else if (wr_cr_stat && hsize_b0) cr_stat[7:0] <= i_hwdata[7:0];
        else if (wr_cr_stat && hsize_b1) cr_stat[15:8] <= i_hwdata[15:8];
        else if (wr_cr_stat && hsize_b2) cr_stat[23:16] <= i_hwdata[23:16];
        else if (wr_cr_stat && hsize_b3) cr_stat[31:24] <= i_hwdata[31:24];
        else if (wr_cr_stat && hsize_hw0) cr_stat[15:0] <= i_hwdata[15:0];
        else if (wr_cr_stat && hsize_hw1) cr_stat[31:16] <= i_hwdata[31:16];
        else if (wr_cr_stat && hsize_w0) cr_stat[31:0] <= i_hwdata[31:0];

    always_comb
        case ({rd_cr_ctrl, rd_cr_stat})
            2'b01:
                o_hrdata = cr_stat;
            2'b10:
                o_hrdata = cr_ctrl;
            default:
                o_hrdata = 32'd0;
        endcase

    assign o_hready = 1'b1;
    assign o_hresp = 1'b0;

    // Mem-Config signals
    assign o_bypass = !cr_ctrl[20];
    assign o_cache_dis = cr_ctrl[21] & i_hprot_mem[0];

endmodule
