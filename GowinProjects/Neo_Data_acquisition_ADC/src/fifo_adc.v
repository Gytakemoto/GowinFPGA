module fifo_adc #(
    parameter DATA_WIDTH = 16,  // Data width (can be set to 12 or 16 bits)
    parameter FIFO_DEPTH = 128   // FIFO depth (number of stored samples)
)(
    input wire clk,             // System clock
    
    // Write interface
    input wire wr_en,           // Write enable signal
    input wire [DATA_WIDTH-1:0] adc_data_in,  // Input data from ADC

    // Read interface
    input wire rd_en,           // Read enable signal
    output reg [DATA_WIDTH-1:0] data_out,     // Output data

    // FIFO status flags
    output reg debug,
    output reg full,           // FIFO full flag
    output reg empty           // FIFO empty flag
);

    // FIFO buffer memory
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1]; 

    // Read and write pointers
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr = 0;
    reg [$clog2(FIFO_DEPTH)-1:0] rd_ptr = 0;

    // Counter to track the number of stored elements
    reg [$clog2(FIFO_DEPTH)-1:0] count = 0;

    initial begin
        count <= 0;
        full <= 0;
        empty <= 1;
        debug <= 0;
    end

    // Write operation (store ADC data into FIFO)
    always @(posedge clk) begin
        if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= adc_data_in;  // Store input data
            wr_ptr <= (wr_ptr + 1) % FIFO_DEPTH; // Increment write pointer until maximum depth
        end
    end

    // Read operation (retrieve data from FIFO)
    always @(posedge clk) begin
        if (rd_en && !empty) begin
            data_out <= fifo_mem[rd_ptr]; // Output the data
            rd_ptr <= (rd_ptr + 1) % FIFO_DEPTH; // Increment read pointer unitl maximum depth
        end
    end

    // Count management to track FIFO occupancy
    always @(posedge clk) begin
        // Increment count on write if not full, unless simultaneously reading
        if (wr_en && !full && !(rd_en && !empty)) begin
            count <= count + 1;
        end 
        // Decrement count on read if not empty, unless simultaneously writing
        else if (rd_en && !empty && !(wr_en && !full)) begin
            count <= count - 1;
        end

        debug <= (count > FIFO_DEPTH/2) ? 1:0;
        full  <= (count == FIFO_DEPTH) ? 1:0; // Full when count reaches FIFO depth
        empty <= (count == 0)? 1:0;          // Empty when count is zero
    end

endmodule
