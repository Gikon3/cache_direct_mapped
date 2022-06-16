module cache #(
    parameter NUM_BLOCK = 3,
              NUM_WORD = 5
    )
    (
    input   logic           i_hclk,
    input   logic           i_hnreset,

    // AHB-Spifi interface
    input   logic           i_hsel_spifi,

    output  logic           o_hready_spifi,
    output  logic           o_hresp_spifi,
    output  logic   [31:0]  o_hrdata_spifi,

    output  logic           o_irq_spifi,
    output  logic           o_drqw_spifi,
    output  logic           o_drqr_spifi,

    // AHB-Config interface
    input   logic           i_hsel_conf,

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

    // AHB_Mem interface
    input   logic           i_hsel_m,

    input   logic   [31:0]  i_haddr_m,
    input   logic           i_hwrite_m,
    input   logic   [ 2:0]  i_hsize_m,
    input   logic   [ 2:0]  i_hburst_m,
    input   logic   [ 3:0]  i_hprot_m,
    input   logic   [ 1:0]  i_htrans_m,
    input   logic   [ 3:0]  i_hmaster_m,
    input   logic           i_hready_m,
    input   logic   [31:0]  i_hwdata_m,

    output  logic           o_hready_m,
    output  logic           o_hresp_m,
    output  logic   [31:0]  o_hrdata_m,

    // SPIFI interface
    input   logic           i_spifi_sck,
    input   logic   [ 3:0]  i_spifi_si,
    output  logic           o_spifi_sck,
    output  logic   [ 3:0]  o_spifi_so,
    output  logic   [ 3:0]  o_spifi_soen,
    output  logic           o_spifi_cs,
    output  logic           o_spifi_tri
    );

    logic           mem_ready;
    logic   [31:0]  mem_rdata;
    logic   [29:0]  mem_addr;
    logic           mem_rd;

    logic           slave_sel;
    logic   [29:0]  slave_addr;
    logic   [31:0]  slave_rdata;
    logic           slave_ready;

    logic   [3:0]   hprot_mem;
    logic           bypass;
    logic           cache_dis;
    logic   [31:0]  climit;

    logic           hsel_sl;
    logic   [31:0]  haddr_sl;
    logic           hwrite_sl;
    logic   [2:0]   hsize_sl;
    logic   [2:0]   hburst_sl;
    logic   [3:0]   hprot_sl;
    logic   [1:0]   htrans_sl;
    logic   [3:0]   hmaster_sl;
    logic           hready_sl_o;
    logic   [31:0]  hwdata_sl;
    logic           hready_sl_i;
    logic           hresp_sl;
    logic   [31:0]  hrdata_sl;

    // TODO connect to spifi
    //assign climit = spifi_to_cache.regs.Regs[4];
     assign climit = 32'h0000_1FFF; //Galimov 08/07/2020
    cache_ahb_ctrl_conf cache_ahb_ctrl_conf (
        .i_hclk (i_hclk),
        .i_hnreset (i_hnreset),

        .i_hsel (i_hsel_conf),
        .i_haddr (i_haddr),
        .i_hwrite (i_hwrite),
        .i_hsize (i_hsize),
        .i_hburst (i_hburst),
        .i_hprot (i_hprot),
        .i_htrans (i_htrans),
        .i_hmaster (i_hmaster),
        .i_hready (i_hready),
        .i_hwdata (i_hwdata),
        .o_hready (o_hready),
        .o_hresp (o_hresp),
        .o_hrdata (o_hrdata),

        .i_hprot_mem (hprot_mem),
        .o_bypass (bypass),
        .o_cache_dis (cache_dis)
        );

    cache_ahb_ctrl_mem cache_ahb_ctrl_mem (
        .i_hclk (i_hclk),
        .i_hnreset (i_hnreset),

        .i_hsel (i_hsel_m),
        .i_haddr (i_haddr_m),
        .i_hwrite (i_hwrite_m),
        .i_hsize (i_hsize_m),
        .i_hburst (i_hburst_m),
        .i_hprot (i_hprot_m),
        .i_htrans (i_htrans_m),
        .i_hmaster (i_hmaster_m),
        .i_hready (i_hready_m),
        .i_hwdata (i_hwdata_m),
        .o_hready (o_hready_m),
        .o_hresp (o_hresp_m),
        .o_hrdata (o_hrdata_m),

        .o_hprot (hprot_mem),

        .i_mem_ready (mem_ready),
        .i_mem_rdata (mem_rdata),
        .o_mem_addr (mem_addr),
        .o_mem_rd (mem_rd)
        );

    cache_mem_top #(NUM_BLOCK, NUM_WORD) cache_mem_top (
        .i_clk (i_hclk),
        .i_nreset (i_hnreset),

        .i_bypass (bypass),
        .i_cache_dis (cache_dis),

        .i_mem_addr (mem_addr),
        .i_mem_rd (mem_rd),
        .o_mem_ready (mem_ready),
        .o_mem_rdata (mem_rdata),

        .o_slave_sel (slave_sel),
        .o_slave_addr (slave_addr),
        .i_slave_rdata (slave_rdata),
        .i_slave_ready (slave_ready),

        .i_climit (climit)
        );

    cache_ahb_ctrl_out cache_ahb_ctrl_out (
        .i_hclk (i_hclk),
        .i_hnreset (i_hnreset),

        .i_sel (slave_sel),
        .i_addr (slave_addr),
        .o_rdata (slave_rdata),
        .o_ready (slave_ready),

        .o_hsel (hsel_sl),
        .o_haddr (haddr_sl),
        .o_hwrite (hwrite_sl),
        .o_hsize (hsize_sl),
        .o_hburst (hburst_sl),
        .o_hprot (hprot_sl),
        .o_htrans (htrans_sl),
        .o_hmaster (hmaster_sl),
        .o_hready (hready_sl_o),
        .o_hwdata (hwdata_sl),
        .i_hready (hready_sl_i),
        .i_hresp (hresp_sl),
        .i_hrdata (hrdata_sl)
        );

    spifi_top spifi_to_cache (
        .IRQ_o (o_irq_spifi),
        .DRQw_o (o_drqw_spifi),
        .DRQr_o (o_drqr_spifi),
        //AHB Lite bus
        .HCLK (i_hclk),
        .HRESETn (i_hnreset),
        .HSEL_i (i_hsel_spifi),
        .HREADY_i (i_hready),
        .HADDR_i (i_haddr),
        .HWRITE_i (i_hwrite),
        .HSIZE_i (i_hsize),
        .HBURST_i (i_hburst),
        .HPROT_i (i_hprot),
        .HTRANS_i (i_htrans),
        .HMASTLOCK_i (i_hmaster[0]),
        .HWDATA_i (i_hwdata),
        .HRDATA_o (o_hrdata_spifi),
        .HREADY_o (o_hready_spifi),
        .HRESP_o (o_hresp_spifi),
        //AHB Memory bus
        .HSEL_im (hsel_sl),
        .HREADY_im (hready_sl_o),
        .HADDR_im (haddr_sl),
        .HWRITE_im (hwrite_sl),
        .HSIZE_im (hsize_sl),
        .HBURST_im (hburst_sl),
        .HPROT_im (hprot_sl),
        .HTRANS_im (htrans_sl),
        .HMASTLOCK_im (hmaster_sl[0]),
        .HWDATA_im (hwdata_sl),
        .HRDATA_om (hrdata_sl),
        .HREADY_om (hready_sl_i),
        .HRESP_om (),
        //SPIFI Signals
        .SPIFI_CS_o (o_spifi_cs),
        .SPIFI_SCK_o (o_spifi_sck),
        .SPIFI_SCK_i (i_spifi_sck),
        .SPIFI_SI_i (i_spifi_si),
        .SPIFI_SO_o (o_spifi_so),
        .SPIFI_SO_oe (o_spifi_soen),
        .Tri_o (o_spifi_tri)
        );

endmodule
