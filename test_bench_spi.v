`timescale 1ns / 1ps

module spi_master_TB;

  parameter SPI_MODE = 3;             // CPOL = 1, CPHA = 1
  parameter CLKS_PER_HALF_BIT = 4;    // For 6.25 MHz SPI Clock
  parameter MAIN_CLK_DELAY = 2;       // 25 MHz Main Clock = 40 ns

  reg r_Rst_L = 1'b0;
  reg r_Clk   = 1'b0;

  // SPI Interface Signals
  wire w_SPI_Clk;
  wire w_SPI_MOSI;

  reg  [7:0] r_Master_TX_Byte = 8'h00;
  reg        r_Master_TX_DV   = 1'b0;
  wire       w_Master_TX_Ready;
  wire       r_Master_RX_DV;
  wire [7:0] r_Master_RX_Byte;

  // Clock Generator
  always #(MAIN_CLK_DELAY) r_Clk = ~r_Clk;

  // Instantiate the DUT (Device Under Test)
  spi_master #(
    .SPI_Mode(SPI_MODE),
    .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
  ) dut (
    .i_RST_L(r_Rst_L),
    .i_Clk(r_Clk),

    // Transmit signals
    .i_TX_Byte(r_Master_TX_Byte),
    .i_TX_DV(r_Master_TX_DV),
    .o_TX_Ready(w_Master_TX_Ready),

    // Receive signals
    .o_RX_DV(r_Master_RX_DV),
    .o_RX_Byte(r_Master_RX_Byte),

    // SPI signals
    .o_SPI_Clk(w_SPI_Clk),
    .i_SPI_MISO(w_SPI_MOSI),   // Loopback
    .o_SPI_MOSI(w_SPI_MOSI)
  );

  // Test Sequence
  initial begin
    // VCD file for waveform viewing
    $dumpfile("spi.vcd");
    $dumpvars(0, spi_master_TB);

    // Initial reset
    repeat(10) @(posedge r_Clk);
    r_Rst_L = 1'b0;
    repeat(10) @(posedge r_Clk);
    r_Rst_L = 1'b1;

    // --- Send Byte 0xC1 ---
    @(posedge r_Clk);
    r_Master_TX_Byte <= 8'hC1;
    r_Master_TX_DV   <= 1'b1;
    @(posedge r_Clk);
    r_Master_TX_DV   <= 1'b0;
    @(posedge w_Master_TX_Ready);
    $display("Sent 0xC1, Received 0x%02X", r_Master_RX_Byte);

    // --- Send Byte 0xBE ---
    @(posedge r_Clk);
    r_Master_TX_Byte <= 8'hBE;
    r_Master_TX_DV   <= 1'b1;
    @(posedge r_Clk);
    r_Master_TX_DV   <= 1'b0;
    @(posedge w_Master_TX_Ready);
    $display("Sent 0xBE, Received 0x%02X", r_Master_RX_Byte);

    // --- Send Byte 0xEF ---
    @(posedge r_Clk);
    r_Master_TX_Byte <= 8'hEF;
    r_Master_TX_DV   <= 1'b1;
    @(posedge r_Clk);
    r_Master_TX_DV   <= 1'b0;
    @(posedge w_Master_TX_Ready);
    $display("Sent 0xEF, Received 0x%02X", r_Master_RX_Byte);

    repeat(10) @(posedge r_Clk);
    $display("Simulation completed successfully.");
    $finish;
  end

endmodule
