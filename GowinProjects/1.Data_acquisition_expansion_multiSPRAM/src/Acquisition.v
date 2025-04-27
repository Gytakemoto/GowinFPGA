module Acquisition #(
    parameter DATA_WIDTH = 16,  // Data width (can be set to 12 or 16 bits)
    parameter FIFO_DEPTH = 32   // FIFO depth (number of stored samples)
)(
    input clk,             // System clock
    input begin_Acq,                         //Flag to begin Post_processing
    input end_Acq,
    
    // Read interface
    input [DATA_WIDTH-1:0] data_in_1,       // input data 1
    input [DATA_WIDTH-1:0] data_in_2,       // input data 2
    input [DATA_WIDTH-1:0] data_in_3,       // input data 3

    input wr_clk,
    input rd_clk,

    output [15:0] data_out,       // Output data from BRAM: 16-bit data to be sent to UART
    output reg write_read,                        // write_read flag
    output reg ended
);


reg [7:0] wr_ad = 0;        //Write address    
reg [9:0] rd_ad = 0;        //Read address

reg [63:0] data_in;         //64-bit 4 message variable

Gowin_SDPB BRAM_Acq (
    .dout(data_out),
    .clka(wr_clk),
    .cea(begin_PP),
    .reseta(!begin_PP),
    .clkb(rd_clk),
    .ceb(begin_PP),
    .resetb(rst),
    .ada(wr_ad),
    .din(data_in),
    .adb(rd_ad)
    );


always @(posedge clk) begin

    if(begin_PP) begin
        //Begin writing until limit
        if ((wr_ad == {8{1'b1}}) && !write_read) begin
            write_read <= ~write_read;
            rd_ad <= 0;
        end
        //Begin reading until limit
        else if ((rd_ad == {10{1'b1}}) && write_read) begin
            write_read <= ~write_read;
            wr_ad <= 0;
        end

        if(wr_clk && !write_read) begin 
            if(end_PP) begin
                write_read <= 1;     //Force change because writing has ended!
                rd_ad <= 0;
            end
            else begin
                if (wr_ad != {8{1'b1}}) wr_ad <= wr_ad + 1;
            end
        end
        if(rd_clk && write_read) begin
            if (end_PP && rd_ad == ((wr_ad+1) >> 4 - 1)) ended <= 1;            //If the samples read reached samples_written...
            else if (rd_ad != {10{1'b1}}) rd_ad <= rd_ad + 1;
        end
    
        if(end_PP && (rd_ad == wr_ad << 4)) ended <= 1;

        //64-bit message
        data_in <= {4'hF, data_in_1[15:12], data_in_2[15:12], data_in_3[15:12],
                   4'hF, data_in_1[10:8], data_in_2[10:8], data_in_3[10:8],
                   4'hF, data_in_1[7:4], data_in_2[7:4], data_in_3[7:4],
                   4'hF, data_in_1[3:0], data_in_2[3:0], data_in_3[3:0]};
    end 
    else begin
        write_read <= 0;
        data_in <= 0;
        ended <= 0;
    end
end
endmodule
