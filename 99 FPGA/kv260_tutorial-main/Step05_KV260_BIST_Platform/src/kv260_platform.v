// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
// SPDX-License-Identifier: SHL-0.51

// Engineer:  KV260 Training Team
// Description: KV260 Platform Wrapper - Top-level for BIST Platform

module kv260_platform #(
    parameter PART_NUM = "xck26-sfvc784-2LV-c"
)(
    // System Clock from PS
    input  wire        sys_clk,        // 100MHz
    input  wire        sys_rstn,       // Active low
    
    // AXI GP0 (HPM0)
    input  wire        m_axi_gp0_clk,
    input  wire        m_axi_gp0_valid,
    output wire        m_axi_gp0_ready,
    input  wire [31:0] m_axi_gp0_addr,
    input  wire [1:0]  m_axi_gp0_prot,
    input  wire [31:0] m_axi_gp0_wdata,
    input  wire [3:0]  m_axi_gp0_wstrb,
    output wire [31:0] m_axi_gp0_rdata,
    output wire [1:0]  m_axi_gp0_resp,
    
    // AXI HP0 ( High Performance)
    input  wire        s_axi_hp0_clk,
    input  wire        s_axi_hp0_valid,
    output wire        s_axi_hp0_ready,
    input  wire [31:0] s_axi_hp0_addr,
    input  wire [5:0]  s_axi_hp0_size,
    input  wire [31:0] s_axi_hp0_wdata,
    output wire [31:0] s_axi_hp0_rdata,
    
    // PL User LEDs
    output wire [3:0]  user_led,
    
    // MIPI CSI-2 (if used)
    input  wire        csi_clk_p,
    input  wire        csi_clk_n,
    input  wire [3:0]  csi_data_p,
    input  wire [3:0]  csi_data_n,
    
    // DisplayPort
    output wire [2:0]  dp_lane,
    output wire        dp_clk,
    
    // Ethernet
    input  wire        eth_tx_clk,
    input  wire        eth_rx_clk,
    output wire        eth_tx_en,
    output wire [3:0]  eth_txd,
    input  wire        eth_rx_dv,
    input  wire [3:0]  eth_rxd
);

    // Internal clocks
    wire        pl_clk0;       // 100MHz
    wire        pl_clk1;       // 200MHz
    wire        pl_clk2;       // 400MHz
    wire        pl_resetn;
    wire        dcm_locked;
    
    // Internal signals for BIST
    wire        start_bist;
    wire        bist_done;
    wire [7:0] bist_status;
    wire [31:0] mem_addr;
    wire        mem_we;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    
    // BIST Controller Instance
    bist_controller #(
        .CLK_FREQ_MHZ(100)
    ) u_bist (
        .clk        (pl_clk0),
        .rstn       (pl_resetn),
        .start_bist (start_bist),
        .bist_done  (bist_done),
        .bist_status(bist_status),
        .mem_addr   (mem_addr),
        .mem_we     (mem_we),
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .status_led (user_led)
    );

    // Clock divider for 100MHz -> other frequencies
    reg [15:0] clk_div;
    always @(posedge sys_clk or negedge sys_rstn) begin
        if (!sys_rstn) begin
            clk_div <= 16'd0;
            pl_clk0 <= 1'b0;
            pl_clk1 <= 1'b0;
            pl_clk2 <= 1'b0;
        end else begin
            clk_div <= clk_div + 1;
            // 100MHz / 1 = 100MHz
            pl_clk0 <= sys_clk;
            // 100MHz / 2 = 50MHz
            pl_clk1 <= clk_div[0];
            // 100MHz / 4 = 25MHz
            pl_clk2 <= clk_div[1];
        end
    end
    
    assign dcm_locked = sys_rstn;
    assign pl_resetn = sys_rstn;
    assign start_bist = m_axi_gp0_valid && m_axi_gp0_ready;
    assign mem_rdata = 32'hDEADBEEF;
    
    // AXI GP0 ready (simplified)
    assign m_axi_gp0_ready = 1'b1;
    assign m_axi_gp0_rdata = {24'h0, bist_status};
    assign m_axi_gp0_resp = 2'b00;
    
    // AXI HP0 ready (simplified)
    assign s_axi_hp0_ready = 1'b1;
    assign s_axi_hp0_rdata = 32'h0;

endmodule