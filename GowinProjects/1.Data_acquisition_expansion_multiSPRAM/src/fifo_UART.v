module fifo_UART #(
    parameter DATA_WIDTH = 16,  // Data width (can be set to 12 or 16 bits)
    parameter FIFO_DEPTH = 32   // FIFO depth (number of stored samples)
)(
    input wire clk,             // System clock
    input reset,
    
    // Write interface
    input wire wr_en,           // Write enable signal
    output reg [DATA_WIDTH-1:0] data_out,  // Input data from ADC

    // Read interface
    input wire rd_en,                           // Read enable signal
    input [DATA_WIDTH-1:0] data_in_1,     // Output data 1
    input [DATA_WIDTH-1:0] data_in_2,     // Output data 2
    input [DATA_WIDTH-1:0] data_in_3,     // Output data 3
    input [DATA_WIDTH-1:0] data_in_4,     // Output data 4

    // FIFO status flags
    //output reg debug,
    output reg full,                            // FIFO full flag
    output reg empty                            // FIFO empty flag
);

    // FIFO buffer memory
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];


    // Read and write pointers
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr = 0;
    reg [$clog2(FIFO_DEPTH)-1:0] rd_ptr = 0;

    // Counter to track the number of stored elements
    reg [$clog2(FIFO_DEPTH):0] count = 0;

    initial begin
        count <= 0;
        full <= 0;
        empty <= 1;
    end

    // Write operation (store PSRAM data into FIFO)
    always @(posedge clk) begin
        if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= data_in_1;
            fifo_mem[(wr_ptr + 1) % FIFO_DEPTH] <= data_in_2;
            fifo_mem[(wr_ptr + 2) % FIFO_DEPTH] <= data_in_3;
            fifo_mem[(wr_ptr + 3) % FIFO_DEPTH] <= data_in_4;
            wr_ptr <= (wr_ptr + 4) % FIFO_DEPTH;
            count <= count + 4;
        end

        // Read operation (retrieve data from FIFO to UART)
        if (rd_en && !empty) begin
            data_out <= fifo_mem[rd_ptr];
            rd_ptr <= (rd_ptr + 1) % FIFO_DEPTH;
            if (count > 0) count <= count - 1;
        end

        // Count management to track FIFO occupancy
            // Increment count on write if not full, unless simultaneously reading
            // Write 4 data when there is no read
            if (wr_en && !full && !(rd_en && !empty)) begin
                count <= count + 4;
            end 
            // Read 1 data when there is no write
            else if (rd_en && !empty && !(wr_en && !full)) begin
                if (count > 0) count <= count - 1;
            end
            // Simultaneously read & write
            else if (wr_en && !full && rd_en && !empty) begin
                count <= count + 3;  // +4 escrita, -1 leitura
            end

        if(reset) begin
            count <= 0;
            wr_ptr <= 0;
            rd_ptr <= 0;
        end

        full  <= (count > FIFO_DEPTH - 4) ? 1:0;   // Full when FIFO can't store another 4 data
        empty <= (count == 0)? 1:0;                  // "Empty" when empty haha
    end
endmodule
