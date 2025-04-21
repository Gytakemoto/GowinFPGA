module spi_command( // 12 reg 7 lut 300MHz max - encontrado na WEB e adaptado
  input clk,
  input [7:0] command,
  input strobe,
  output reg ready,
  output reg line,
  output reg ce_n
);

 //Comandos PSRAM de inicializacao
  localparam [7:0] PS_CMD_RSTEN = 8'h66;
  localparam [7:0] PS_CMD_RST   = 8'h99;
  localparam [7:0] PS_CMD_QPI   = 8'h35;

  reg [7:0] shifter;
  reg sendcommand = 0;
  reg [2:0] command_ctr = 0;

  always_ff @(posedge clk) begin       
    if ( ready && strobe ) begin
       sendcommand <= 1;    
       shifter <= command;
       command_ctr <= 0;      
    end
    else if ( sendcommand ) begin
      shifter <= shifter << 1;
      command_ctr <= command_ctr + 1'd1;
      if ( command_ctr == 3'd7 ) begin
        sendcommand <= 0;
      end
    end      
  end

  assign line = shifter[7];  
  assign ce_n = ~sendcommand;
  assign ready = ce_n;
endmodule
