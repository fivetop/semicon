// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
// SPDX-License-Identifier: SHL-0.51

// Engineer:  KV260 Training Team
// Description: AXI GPIO Controller - Controls LEDs via AXI GPIO IP

module axi_gpio_control (
    input  wire        clk,            // System clock
    input  wire        rstn,           // Active low reset
    
    // AXI4-Lite Interface
    input  wire [31:0] s_axi_awaddr,   // Write address
    input  wire        s_axi_awvalid,  // Write address valid
    output wire        s_axi_awready,  // Write address ready
    input  wire [31:0] s_axi_wdata,    // Write data
    input  wire        s_axi_wvalid,   // Write data valid
    output wire        s_axi_wready,   // Write data ready
    output wire [1:0]  s_axi_bresp,    // Write response
    output wire        s_axi_bvalid,   // Write response valid
    input  wire        s_axi_bready,   // Write response ready
    
    input  wire [31:0] s_axi_araddr,   // Read address
    input  wire        s_axi_arvalid,  // Read address valid
    output wire        s_axi_arready,  // Read address ready
    output wire [31:0] s_axi_rdata,    // Read data
    output wire [1:0]  s_axi_rresp,    // Read response
    output wire        s_axi_rvalid,   // Read data valid
    input  wire        s_axi_rready,   // Read data ready
    
    // GPIO Output
    output wire [3:0]  gpio_out         // LED outputs
);

    // Register addresses
    localparam ADDR_GPIO_DATA = 32'h0;
    localparam ADDR_GPIO_DIR  = 32'h4;
    localparam ADDR_GPIO_MASK = 32'h8;
    
    // Internal registers
    reg [3:0]  gpio_data_reg;
    reg [3:0]  gpio_dir_reg;   // 1=output, 0=input
    reg [3:0]  gpio_mask_reg;
    
    // Write address handshake
    reg aw_ready;
    assign s_axi_awready = aw_ready;
    
    // Write data handshake
    reg w_ready;
    assign s_axi_wready = w_ready;
    
    // Write response
    reg b_valid;
    assign s_axi_bvalid = b_valid;
    assign s_axi_bresp = 2'b00;  // OKAY
    
    // Read address handshake
    reg ar_ready;
    assign s_axi_arready = ar_ready;
    
    // Read data
    reg [31:0] r_data;
    assign s_axi_rdata = r_data;
    reg r_valid;
    assign s_axi_rvalid = r_valid;
    assign s_axi_rresp = 2'b00;  // OKAY
    
    // State machine for write
    typedef enum logic [1:0] {
        WR_IDLE,
        WR_WRITE,
        WR_RESPONSE
    } wr_state_t;
    wr_state_t wr_state;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_state <= WR_IDLE;
            aw_ready <= 1'b0;
            w_ready <= 1'b0;
            b_valid <= 1'b0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    if (s_axi_awvalid) begin
                        aw_ready <= 1'b1;
                        if (s_axi_wvalid) begin
                            w_ready <= 1'b1;
                            wr_state <= WR_WRITE;
                        end
                    end
                end
                WR_WRITE: begin
                    aw_ready <= 1'b0;
                    w_ready <= 1'b0;
                    // Write to register
                    if (s_axi_awaddr[5:2] == 2'b00) begin
                        gpio_data_reg <= s_axi_wdata[3:0];
                    end else if (s_axi_awaddr[5:2] == 2'b01) begin
                        gpio_dir_reg <= s_axi_wdata[3:0];
                    end
                    wr_state <= WR_RESPONSE;
                end
                WR_RESPONSE: begin
                    b_valid <= 1'b1;
                    if (s_axi_bready) begin
                        b_valid <= 1'b0;
                        wr_state <= WR_IDLE;
                    end
                end
            endcase
        end
    end
    
    // State machine for read
    typedef enum logic {
        RD_IDLE,
        RD_READ
    } rd_state_t;
    rd_state_t rd_state;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rd_state <= RD_IDLE;
            ar_ready <= 1'b0;
            r_valid <= 1'b0;
            r_data <= 32'h0;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    if (s_axi_arvalid) begin
                        ar_ready <= 1'b1;
                        rd_state <= RD_READ;
                    end
                end
                RD_READ: begin
                    ar_ready <= 1'b0;
                    // Read from register
                    if (s_axi_araddr[5:2] == 2'b00) begin
                        r_data <= {{28{1'b0}}, gpio_data_reg};
                    end else if (s_axi_araddr[5:2] == 2'b01) begin
                        r_data <= {{28{1'b0}}, gpio_dir_reg};
                    end
                    r_valid <= 1'b1;
                    if (s_axi_rready) begin
                        r_valid <= 1'b0;
                        rd_state <= RD_IDLE;
                    end
                end
            endcase
        end
    end
    
    // GPIO output
    assign gpio_out = gpio_data_reg;

endmodule
