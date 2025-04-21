//Modulo controle de fluxo de comandos pela UART - a cada frame enviado confirma recebimento por acknowledge (ACK) ou falha por no acknowledge (NOACK)
//Se o NOACK é enviado, aguardada novas tentativas e caso não ocorra, erro é sinalizado. Timeout controla o tempo para envio e recebimento de comandos pela UART;
//Fluxo de dados é gerenciado pelo módulo 

module uart_control(
  input clk, //clock micro
  input [23:0] frameout, //comando a enviar 
  output reg [63:0] framein, //dados recebidos
  output reg framearrived, //vai a 1 durante 1 ciclo de clock se frame foi enviado pelo micro ao FPGA e recebido em framein ou enviado pela FPGA ao e confirmado pelo micro em frameout
  output reg frameready, //vai a 1 apos o envio
  input frametosend, //cloclar 1 em 1 ciclo de clock se tiver dados a enviar ao micro (frameout)
  output reg frameerror, //vai a 1 durante um ciclo de clock se houver erro no recebimento do frame enviado ao FPGA ou se após 3 tentativas o FPGA não recebe a confirmacao dos dados enviados ao micro
  input si, // pino serial in
  output so //pino serial out
);

reg u_writting=0;
reg [7:0] u_data_in;
reg [7:0] u_data_out;
wire u_readytoread;
wire u_readytosend;

uart uart(
  clk, //clock micro
  u_writting, //colocar em 1 durante um clock qdo tiver dados para enviar via seria ou
  u_data_out, //dados para enviar
  u_data_in, //dados recebidos
  si, // pino serial in
  so, //pino serial out
  u_readytoread, //vale 1 durante 1 clock qdo dados chegaram pela entrada serial in
  u_readytosend
);

localparam [7:0] ACK=8'h4F; //caracter O=ok
localparam [7:0] NOACK=8'h45; //caracter E=erro

localparam [2:0] IDDLE=0;
localparam [2:0] READCOMMAND=1;
localparam [2:0] SENDDATA=2;
localparam [2:0] CLEAN=3;

reg [2:0] step=0;

reg [4:0] bytesreceived=0;
reg [4:0] bytessent=0;
reg [63:0] datain;
reg [23:0] dataout;
reg error=0;
reg [1:0] try=0;
reg ready=1;
reg arrived=0;
reg [7:0] data_UART_in=0;
reg readytoread=0;
reg readytosend=0;

//timeout = SYS_CLOCK(84Mhz) / (CLOCK UART (2Mhz) / (10 bits * 64 bytes(frame)))= 26880d x 2 (aguarda duas vezes o tempo de frame) = 53760d = d200h
localparam [15:0] TIMEOUT=16'hd200;
reg [15:0] timeout=0;



always_ff @(posedge clk) begin    
    case (step)
        IDDLE: begin
               bytesreceived<=5'd0;
               bytessent<=5'd0;
               arrived<=0;
           //    ready<=1;
               error<=0;
               try<=2'd0;
               timeout<=16'd0;
               if (frametosend) begin //tem dados para enviar ao micro
                     ready<=0;
                     dataout<=frameout;   
                     step<=SENDDATA;
                     end
                else if (u_readytoread) begin
                     ready<=0;
                     datain<={56'd0,u_data_in[7:0]}; //captura o primeiro byte e espera os demais em READCOMMAND
                     bytesreceived<=bytesreceived+5'd1;
                     step<=READCOMMAND; 
                     end  
               end

        READCOMMAND: begin
                if (timeout>TIMEOUT) begin
                   if (u_readytosend && !u_writting) begin
                        u_data_out<=NOACK; //ocorreu timeout antes de receber todos os dados
                        u_writting<=1;
                        arrived<=1;
                        error<=1;
                        step<=CLEAN;
                        end
                    end
                    else if (bytesreceived<8) begin //frame de comando = 8 bytes = 64 bits
                         if (u_readytoread) begin
                            datain[63:0]<={datain[55:0], u_data_in[7:0]};
                            bytesreceived<=bytesreceived+5'd1;
                            ready<=0;
                            end
                    end 
                    else if (u_readytosend && !u_writting) begin
                            u_data_out<=ACK; //frame completo recebido
                            u_writting<=1;
                            arrived<=1;
                            error<=0;
                            step<=CLEAN;
                            end
                    end

        SENDDATA: begin
                if (timeout>TIMEOUT) begin
                    if (try==2'd3) begin //é a segunda tentativa de reenvio dos dados
                            error<=1;
                            step<=CLEAN;
                        end 
                        else begin //nao efetivou o envio, tentar mais 2 vezes
                            dataout<=frameout;
                            timeout<=0;
                            bytessent<=5'd0;
                            error<=0;
                            ready<=0;
                            try<=try+2'd1;
                        end
                end
                else if (bytessent<3) begin // 3 bytes = 24 bits
                        if (u_readytosend && !u_writting) begin
                        u_data_out[7:0]<=dataout[23:16];
                        dataout<=dataout<<8;
                        bytessent<=bytessent+5'd1;
                        u_writting<=1;
                        timeout<=0;
                        ready<=0;
                        error<=0;
                        end
                end
                else begin
             //           if (u_readytoread & !u_writting) begin
             //               if (u_data_in==ACK) begin //aguarda receber um ACK do micro para validar o envio
                            step<=CLEAN;
              //              end
             //               else timeout<=TIMEOUT+16'd1; //força a ocorrencia de timeout pois o byte q chegou nao é ACK
             //           end
                end
        end
        CLEAN: begin
                 timeout<=0;
                 bytesreceived<=5'd0;
                 bytessent<=5'd0;   
                 ready<=1;
                 try<=2'd0;
                 step<=IDDLE;
               end
     endcase
    if (arrived) arrived<=0;
    if (error) error<=0;
    if (u_writting) u_writting<=0;
    if (bytesreceived==0 && bytessent==0 && !ready) timeout<=0; else timeout<=timeout+16'd1; //incrementa tempo de espera por comando ou resposta de envio de dados
end

assign frameerror=error;
assign framearrived=arrived;
assign framein=datain;
assign frameready=ready && !u_readytoread;
endmodule