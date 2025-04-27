module fifo_adc #(
    parameter DATA_WIDTH = 16,  // Data width (can be set to 12 or 16 bits)
    parameter FIFO_DEPTH = 128   // FIFO depth (number of stored samples)
)(
    input wire clk,             // System clock
    input reset,
    
    // Write interface
    input wire wr_en,           // Write enable signal
    input wire [DATA_WIDTH-1:0] adc_data_in,  // Input data from ADC

    // Read interface
    input wire rd_en,                           // Read enable signal
    output reg [DATA_WIDTH-1:0] data_out_1,     // Output data 1
    output reg [DATA_WIDTH-1:0] data_out_2,     // Output data 2
    output reg [DATA_WIDTH-1:0] data_out_3,     // Output data 3
    output reg [DATA_WIDTH-1:0] data_out_4,     // Output data 4

    // FIFO status flags
    output reg debug,
    output reg full,                            // FIFO full flag
    output reg empty                            // FIFO empty flag
);

    // FIFO buffer memory
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1]; 

    // Read and write pointers
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr = 0;
    reg [$clog2(FIFO_DEPTH)-1:0] rd_ptr = 0;

    // Counter to track the number of stored elements
    reg [$clog2(FIFO_DEPTH):0] count = 0;

    reg batch;

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

    // Read operation (retrieve data from FIFO)
        if (rd_en && !empty) begin
            if(batch == 0) begin
                data_out_1 <= fifo_mem[rd_ptr]; // Output the data
                data_out_2 <= fifo_mem[(rd_ptr + 1) % FIFO_DEPTH];
                batch <= ~batch;
            end
            if (batch == 1) begin
                data_out_3 <= fifo_mem[(rd_ptr)];
                data_out_4 <= fifo_mem[(rd_ptr + 1) % FIFO_DEPTH];
                batch <= ~batch;
            end
            rd_ptr <= (rd_ptr + 2) % FIFO_DEPTH; // Increment read pointer unitl maximum depth
        end

    // Count management to track FIFO occupancy
        // Increment count on write if not full, unless simultaneously reading
        //! Talvez mudar a condição de empty
        if (wr_en && !full && !(rd_en && !empty)) begin
            count <= {count + 2};
        end 
        // Decrement count on read if not empty, unless simultaneously writing
        else if (rd_en && !empty && !(wr_en && !full)) begin
            if (count > 0) count <= {count - 1};
        end
        //Simultaneously writing & reading
        else if (wr_en && !full && rd_en && !empty) begin
            count <= count - 1;  // +1 escrita, -4 leitura
        end

        if(reset) begin
            count <= 0;
        end

        debug <= (count > FIFO_DEPTH/2) ? 1:0;
        full  <= (count == FIFO_DEPTH) ? 1:0;   // Full when count reaches FIFO depth
        empty <= (count < 4)? 1:0;              // "Empty" when buffer has less than 4 samples. count is NOT an index, but a COUNTER!
    end

endmodule
