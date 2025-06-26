// SPI Master without chip select

module spi_master (i_RST_L , i_Clk , i_TX_Byte , i_TX_DV , o_RX_Byte , o_RX_DV , o_TX_Ready , i_SPI_MISO , o_SPI_Clk , o_SPI_MOSI ) ;

parameter SPI_Mode = 0 ;
parameter CLKS_PER_HALF_BIT = 2 ;

input i_RST_L , i_Clk , i_TX_DV ;
input [7:0] i_TX_Byte ;
input  i_SPI_MISO ;

output reg o_RX_DV , o_TX_Ready ;
output reg [7:0] o_RX_Byte ;
output reg o_SPI_Clk ;
output reg o_SPI_MOSI ;

// SPI Interface (all of these below runs on SPI Clock ie SCLK and not i_Clk)

wire CPOL ;
wire CPHA ;

reg [3:0] r_SPI_Clk_Count ;
reg r_SPI_Clk ;                // To store the clock of SPI before giving it to "o_SPI_Clk" 
reg [4:0] r_SPI_Clk_Edges ;    // 1 bit has 2 clock edges , so 8 bit has 16 clock edges (FOR CLOCK)
reg r_Leading_Edge ;
reg r_Trailing_Edge ;
reg r_TX_DV ;           // Basically stores "i_TX_DV" signal
reg [7:0] r_TX_Byte ;  // Basically stores "i_TX_Byte" data
reg [2:0] r_RX_Bit_Count ;   // Counter to count no. of bits received from MISO  (Receiving 1 bit per SPI clock)
reg [2:0] r_TX_Bit_Count ;   // Counter to count no. of bits transferred via MOSI (Transmitting 1 bit per SPI clock)

assign CPOL = (SPI_Mode == 2 || SPI_Mode == 3) ;
assign CPHA = (SPI_Mode == 1 || SPI_Mode == 3) ;


// TO GENERATE SPI CLOCK ( SCLK ) correct number of times when DV pulse comes (SO I AM INTERESTED IN THOSE VARIABLES RELATED WITH CLOCK)
// generates the SPI clock and controls when leading and trailing edges happen
always @ (posedge i_Clk or negedge i_RST_L)
    begin
        if (~i_RST_L)
            begin
                o_TX_Ready <= 0 ;
                r_SPI_Clk_Edges <= 0 ;
                r_Leading_Edge <= 0 ;
                r_Trailing_Edge <= 0 ;
                r_SPI_Clk <= CPOL ;   // Set Clock to its Ideal state
                r_SPI_Clk_Count <= 0 ;
            end
        
        else
            begin
                r_Leading_Edge <= 0 ;
                r_Trailing_Edge <= 0 ;

                if (i_TX_DV) 
                    begin
                        o_TX_Ready <= 0 ;
                        r_SPI_Clk_Edges <= 16 ;
                    end

                else if (r_SPI_Clk_Edges > 0)
                    begin
                        o_TX_Ready <= 0 ;

                        // Trailing Edge Condition
                        if (r_SPI_Clk_Count == (CLKS_PER_HALF_BIT*2 - 1))
                            begin
                                r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1 ;
                                r_Trailing_Edge <= 1'b1 ;
                                r_SPI_Clk_Count <= 0 ;
                                r_SPI_Clk <= ~ r_SPI_Clk ;
                            end

                        // Leading Edge Condition
                        else if (r_SPI_Clk_Count == (CLKS_PER_HALF_BIT - 1)) 
                            begin
                                r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1 ;
                                r_Leading_Edge <= 1'b1 ;
                                r_SPI_Clk_Count <= r_SPI_Clk_Count + 1 ;
                                r_SPI_Clk <= ~ r_SPI_Clk ;
                            end   

                        else
                            begin
                                r_SPI_Clk_Count <= r_SPI_Clk_Count + 1 ;  // No toggle yet → Just increment the counter
                            end    
                    end    
                
                else    
                    begin
                        o_TX_Ready <= 1'b1 ;    // When All Edges (16 edges since data is of 8 bits) Are Done (Transmission Complete)
                    end  
            end
    end

// This block captures the input byte "i_TX_Byte" into "r_TX_Byte" only when "i_TX_DV" is high, ensuring stable data during SPI transmission.
// It also delays "i_TX_DV" by 1 cycle into "r_TX_DV" to align timing with the rest of the logic.
always @ (posedge i_Clk or negedge i_RST_L) 
    begin
        if (~i_RST_L)
            begin
                r_TX_Byte <= 8'b0 ;
                r_TX_DV <= 0 ;
            end

        else
            begin
                r_TX_DV <= i_TX_DV ;  // Why? Because other blocks (like the MOSI logic) use "r_TX_DV", not "i_TX_DV", to avoid timing mismatch or race conditions
                if (i_TX_DV)
                    begin
                        r_TX_Byte <= i_TX_Byte ;
                    end
            end
    end 

// This block handles sending data bit by bit on the MOSI line
// It's built to handle both SPI modes with CPHA = 0 and CPHA = 1
always @ (posedge i_Clk or negedge i_RST_L)
    begin
        if (~i_RST_L)
            begin
                o_SPI_MOSI <= 0 ;            // clear the MOSI line
                r_TX_Bit_Count <= 3'b111 ;  // prepares to send the Most Significant Bit first
            end
        
        else
            begin
                // CASE 1 :  Ensures "r_TX_Bit_Count" is reset to 7 whenever "o_TX_Ready" is high — meaning transmission just completed and the master is now ready for a new byte.
                if (o_TX_Ready)
                    begin
                        r_TX_Bit_Count <= 3'b111 ;
                    end
                
                // CASE 2 :  Is mandatory to support SPI Mode 0 and Mode 2 (where CPHA = 0), because it ensures that the first bit is on the line before the first SPI clock edge occurs. Without this, the very first bit received by the slave would be invalid.
                else if (r_TX_DV & ~CPHA)
                    begin
                        o_SPI_MOSI <= r_TX_Byte[7] ;
                        r_TX_Bit_Count <= 3'b110 ;
                    end

                // CASE 3 : Continue shifting out remaining bits
                else if ((r_Leading_Edge & CPHA) | (r_Trailing_Edge & ~CPHA)) 
                    begin
                        r_TX_Bit_Count <= r_TX_Bit_Count - 1 ;
                        o_SPI_MOSI <= r_TX_Byte[r_TX_Bit_Count] ;
                    end   

            end
    end

// This block samples incoming MISO data bit-by-bit on the correct SPI clock edge, stores it into a register, and raises a data-valid pulse ("o_RX_DV") once the full 8-bit byte is received.
always @ (posedge i_Clk or negedge i_RST_L)
    begin
        if (~i_RST_L)
            begin
                o_RX_Byte <= 8'b0 ;
                o_RX_DV <= 0 ;
                r_RX_Bit_Count <= 3'b111 ;
            end

        else 
            begin
                o_RX_DV <= 1'b0 ;  // This ensures that the data-valid pulse is only high for one clock cycle when we finish a byte.
                
                if (o_TX_Ready)
                    begin
                        r_RX_Bit_Count <= 3'b111 ;
                    end

                else if ((r_Leading_Edge & ~CPHA) | (r_Trailing_Edge & CPHA))
                    begin
                        r_RX_Bit_Count <= r_RX_Bit_Count - 1 ;
                        o_RX_Byte[r_RX_Bit_Count] <= i_SPI_MISO ;

                        if (r_RX_Bit_Count == 0)
                            begin
                                o_RX_DV <= 1'b1 ;
                            end
                    end
                    
            end    
    end

// This block delays the SPI clock output by one FPGA clock cycle to align it with the rest of the output signals, especially MOSI.
always @ (posedge i_Clk or negedge i_RST_L) 
    begin
        if (~i_RST_L)
            begin
                o_SPI_Clk <= CPOL ;
            end
        
        else
            begin
                o_SPI_Clk <= r_SPI_Clk ;
            end
    end

endmodule