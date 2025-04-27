module Post_Process #(
    parameter DATA_WIDTH = 16  // Data width (can be set to 12 or 16 bits)
)(
    input clk,             // System clock
    input begin_PP,                         //Flag to begin Post_processing
    input end_PP,
    
    // Read interface
    input [63:0] data_in,       // input data 1

    input wr_clk,
    input rd_clk,

    output reg [15:0] data_out,       // Output data from BRAM: 16-bit data to be sent to UART
    output reg write_read,
    output reg bram_full,
    output reg bram_empty,
    output reg ended
);


reg [6:0] wr_ad = 0;        //Write address    
reg [8:0] rd_ad = 0;        //Read address

//reg [63:0] data_in;         //64-bit 4 message variable
reg [8:0] rd_max;
//assign rd_max = end_PP ? ((wr_ad) >> 2) - 1 : 11'd1024;;
//assign rd_max = end_PP ? 10'd100 : 11'd1024;
reg write_done;
reg reset;
wire [15:0] data_uart;

reg d_wr_clk;
reg d_rd_clk;
wire rising_wr_clk;
wire rising_rd_clk;
assign rising_wr_clk = wr_clk && !d_wr_clk;
assign rising_rd_clk = rd_clk && !d_rd_clk;

initial begin
	write_read <= 0;
    wr_ad <= 0;
    rd_ad <= 0;
end

Gowin_SDPB BRAM_uart (
    .dout(data_uart),
    .clka(wr_clk),
    .cea(begin_PP),
    .reseta(reset),
    .clkb(rd_clk),
    .ceb(begin_PP),
    .resetb(reset),
    .ada(wr_ad),
    .din(data_in),
    .adb(rd_ad)
    );


always @(posedge clk) begin

    reset <= !begin_PP;

    if(begin_PP) begin
        d_wr_clk <= wr_clk;
        if(!write_read) begin
            if(rising_wr_clk) begin 
                if(wr_ad == 8'hFF) bram_full <= 1;
                if(end_PP) begin
                    write_done <= 1;
                    //rd_max <= wr_ad;
                    rd_max <= (wr_ad << 2);
                end
                wr_ad <= wr_ad + 1'b1;
            end
        end
        else begin
            bram_full <= 0;
            wr_ad <= 0;
        end
    end
    else begin
        wr_ad <= 0;
        write_done <= 0;
        bram_full <= 0;
        d_wr_clk <= 0;
        rd_max <= 11'd1024;
    end 
end

always @(posedge clk) begin

    data_out <= data_uart;

    if(begin_PP) begin
        if(write_read) begin
            d_rd_clk <= rd_clk;
            if(rising_rd_clk) begin
                if(rd_ad == 10'h3FF) bram_empty <= 1;
                if(write_done && (rd_ad == rd_max - 1)) ended <= 1;
                rd_ad <= rd_ad + 1'b1;
            end
        end
        else begin 
            if(write_done) rd_ad <= 0;
            bram_empty <= 0;
        end
    end 
    else begin
        rd_ad <= 0;
        ended <= 0;
        bram_empty <= 0;
        d_rd_clk <= 0;
    end
end


always @(posedge clk) begin
    
    if(begin_PP) begin
        if(((bram_full || write_done) && !write_read)
             || (bram_empty && write_read)) begin
            write_read <= ~write_read;     //Force change because writing has ended!
        end
    end
    else write_read <= 0;

end

endmodule