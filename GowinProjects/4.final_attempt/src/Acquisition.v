module acquisition #(
    parameter ACQ_DEPTH = 8
)(
    input clk,             // System clock
    input begin_acq,                         //Flag to begin Post_processing
    
    // Read interface
    output reg [15:0] data_out_1,       // input data 1
    output reg [15:0] data_out_2,       // input data 2
    output reg [15:0] data_out_3,       // input data 3

    input rd_clk,
    input wr_clk,

    input [11:0] data_in,       // Output data from BRAM: 16-bit data to be sent to UART
    output reg BRAM_empty                        // write_read flag
);




//wire BRAM_empty;

//assign BRAM_empty = samples_to_read == 0 ? 1:0;

//Read variables
reg d_rd_clk;
wire rising_rd_clk;
    assign rising_rd_clk = rd_clk && !d_rd_clk;
wire falling_rd_clk;
    assign falling_rd_clk = !rd_clk && d_rd_clk;
reg [8:0] rd_ad = 0;        //Read address
reg read;                   // 1-clock delay
reg [ACQ_DEPTH-1:0] samples_to_read = 0;

//Write variables
reg d_wr_clk;
wire rising_wr_clk;
    assign rising_wr_clk = wr_clk && !d_wr_clk;
reg [10:0] wr_ad = 0;        //Write address    
reg [2:0] samples_written = 0;


wire [47:0] data_psram;
reg reset;

Gowin_SDPB1 BRAM_acq (
    .dout(data_psram),
    .clka(wr_clk),
    .cea(!reset),
    .reseta(reset),
    .clkb(rd_clk),
    .ceb(!reset),
    .resetb(reset),
    .ada(wr_ad),
    .din(data_in),
    .adb(rd_ad)
    );


always @(posedge clk) begin

    reset <= begin_acq;

    if(begin_acq) begin      
        
        d_rd_clk <= rd_clk;
        read <= 0;
        
        if(rising_rd_clk) begin 
            rd_ad <= rd_ad + 1'b1;
            read <= 1;
        end
        else if(falling_rd_clk) begin
            //64-bit message
           data_out_1 <= {data_psram[47:44], data_psram[35:32], data_psram[23:20], data_psram[11:8]};
           data_out_2 <= {data_psram[43:40], data_psram[31:28], data_psram[19:16], data_psram[7:4]};
           data_out_3 <= {data_psram[39:36], data_psram[27:24], data_psram[15:12], data_psram[3:0]};
        end
           
    end 
    else begin
        rd_ad <= 0;
        data_out_1 <= 0;
        data_out_2 <= 0;
        data_out_3 <= 0;
    end
end

//Write
always @(posedge clk) begin
    
    if(begin_acq) begin

        d_wr_clk <= wr_clk;

        if(rising_wr_clk) begin
            wr_ad <= wr_ad + 1'b1;
        end   
    end
    else begin
        wr_ad <= 0;
    end
end

//Samples-to-read
always @(posedge clk) begin
    
    BRAM_empty <= samples_to_read == 0 ? 1 : 0;

    if(begin_acq) begin
        
        if(rising_wr_clk) begin

            samples_written <= samples_written + 1'b1;

            if(samples_written == 3'd3) begin
                samples_written <= 3'd0;
                if(!rising_rd_clk) samples_to_read <= samples_to_read + 1'b1;
            end
        end        
        else if(rising_rd_clk) samples_to_read <= samples_to_read - 1'b1; 
    end
    else begin
        samples_to_read <= 0;
        samples_written  <= 0;
        BRAM_empty <= 0;
    end
end
endmodule
