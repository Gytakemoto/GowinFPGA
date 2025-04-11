module spi_micro( // 12 reg 7 lut 300MHz max - encontrado na WEB e adaptado
  input clk, //clock micro
  input rw, //0 read - 1 write
  input enable,
  input [23:0] data_out,
  output reg [63:0] data_in,
  inout sio, //pino serial in e out
 // output so, //pino serial out
  output reg ready
);

//Composicao do FRAME de ENVIO e RECEBIMENTO
//data_in - [ADR22..ADR0][PRESAMPLE15..PRESAMPLE0][TR11..TR0][TIPOTRIG3..TIPOTRIG0][FR4..FR0][PROC3..PROC0] - total frame 23+16+12+4+5+4=64bits
//data_out - [DATA23...DATA0] - 24bits
//ready - 0 - pode pulsar o clock, dados disponíveis, 1- aguardar


  reg [63:0] shifter_in=0;
  reg [23:0] shifter_out=0;
  reg [6:0]  flux_ctr = 0; //de 1 a 64 - controle de fluxo
  reg running = 0;
  reg [23:0] capture=0;

  always_ff @(posedge clk) begin       
   if(enable) begin 
    if ( ready ) begin
            if (rw) shifter_out <= data_out; //shifter_out <= data_out;
            shifter_in<=0;
            running<=1;
            flux_ctr <= 0;      
            end
            else if ( running ) begin
                   if (rw) begin
                   if ( flux_ctr == 7'd23 )  running <= 0; 
                   else begin 
                        flux_ctr <= flux_ctr + 1'd1;    
                        shifter_out<=shifter_out<<1;
                        end
                    end
                    else begin
                        if ( flux_ctr == 7'd64 ) 
                        begin
                      //  capture<=shifter_in[63:40];
                        running <= 0;
                        end
                        else begin
                            flux_ctr<=flux_ctr + 1'd1;
                            shifter_in <= {shifter_in[62:0], sio};
                        end
                    
            end
       end
    end 
    else running<=0;
  end

  assign data_in=shifter_in;
  assign sio = rw?shifter_out[23]:1'bZ;  
  assign ready = ~running;
endmodule
