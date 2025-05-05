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
    output reg step,
    output reg bram_full,
    output reg bram_empty,
    output reg rd_en,
    output reg ended
);

//Writing variables

reg d_wr_clk;

reg [4:0] wr_ad = 0;        //Write address    
reg reset;

//Reading variables
reg d_rd_clk;

reg [6:0] rd_ad = 0;        //Read address
reg [6:0] rd_ad_p = 0;
wire [15:0] data_uart;
reg [6:0] rd_max;

localparam WRITE = 0;
localparam READ = 1;

initial begin
	step <= WRITE;
    data_out <= 16'h0001;
    wr_ad <= 0;
    rd_ad <= 0;
    rd_en <= 0;
end

Gowin_SDPB BRAM_uart (
    .dout(data_uart),
    .clka(clk),
    .cea(step == WRITE),
    .reseta(reset),
    .clkb(clk),
    .ceb(step == READ),
    .resetb(reset),
    .ada(wr_ad),
    .din(data_in),
    .adb(rd_ad)
    );

always @(posedge clk) begin

    reset <= !begin_PP;

    if(begin_PP) begin

        //edge detectors
        d_wr_clk <= wr_clk;
        d_rd_clk <= rd_clk;
        
        case(step)
            WRITE: begin

                bram_empty <= 0;
               
                //Upon a write request, updates next address
                if(wr_clk && !d_wr_clk) begin 
                    if(wr_ad == 7'd31) begin
                        bram_full <= 1;
                        step <= READ;
                    end
                    wr_ad <= wr_ad + 1'b1;
                
                    if(end_PP) begin
                        rd_ad <= 0;
                        step <= READ;
                        if(wr_ad == 7'd0) ended <= 1; //When one more loop is not necessary
                        else rd_max <= (wr_ad << 2) - 1'b1;
                    end
                end
            end
            READ: begin
                bram_full <= 0;
                rd_en <= 1;

                //Retrieve current data_out
                data_out <= data_uart;

                if(rd_clk && !d_rd_clk) begin

                    //Upon a read request, updates next address
                    if(rd_ad == 7'd127) begin   
                        bram_empty <= 1;
                        step <= WRITE;
                        rd_en <= 0;
                    end
                    //if(bram_empty) ;
                    if(end_PP && (rd_ad == rd_max)) ended <= 1;
                    rd_ad <= rd_ad + 1'b1;
                end
            end
        endcase
    end
    else begin
        rd_ad <= 0;
        rd_max <= 0;
        rd_en <= 0;
        wr_ad <= 0;
        ended <= 0;
        bram_empty <= 0;
        bram_full <= 0;
        step <= WRITE;
    end
end
endmodule