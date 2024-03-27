module controle (
  input sys_clk,

 //Conexões físicas com o chip de memoria PSRAM LY68L6400 e adc paralelo de 12 bits
  inout wire [3:0] mem_sio,   // sio[0] pin 22, sio[1] pin 23, sio[2] pin 24, sio[3] pin 21
  output wire mem_ce_n,       // pin 19
  output wire mem_clk,         // pin 20
  input [11:0] adc_out,
  output wire adc_clock,

 //Conexões com o micro controlador
 input  micro_si,
 output reg micro_so,
 output wire led_r
);

  

  wire clk;

  Gowin_rPLL oscillator(
    .clkout(clk),
    .clkin(sys_clk)
  );


  wire ctr_ready;
  reg [22:0] ctr_size_add;
  reg ctr_write_strobe = 0;
  reg ctr_read_strobe = 0;
 
  wire [23:0] ctr_fifo_out;
  reg ctr_fifo_read_enable=0;

  wire ctr_fifo_empty;

  adc_mem_driver2 adc_mem_driver(
  clk,
  
  ctr_size_add,                //tamanho aquisicao

  ctr_write_strobe,            //1 para escrita
  ctr_read_strobe,             //1 para leitura
  ctr_ready,                   // nao escuta comandos quando baixo

  ctr_fifo_out,                //amostras que estão na fifo obtidas da memória (128 posicoes de 8 bits)
  ctr_fifo_read_enable,         //enable de leitura da fifo
  ctr_fifo_empty,              //1 se vazio

  
  //conexões da memoria com a placa tang nano 1k
  8'h47,                       // contagem para atingir 150us que é o tempo de startup da memoria  - valor 4700h - 150us em 120Mhz
  mem_sio,                     // sio[0] pin 40, sio[1] pin 39, sio[2] pin 38, sio[3] pin 41
  mem_ce_n,                    // pin 42
  mem_clk,                     // pin 6

 //conexao com o conversor ADC
  adc_out,                     //pinos dos dados adc - em analise ainda
  adc_clock                    //pino de clock do adc - a definir ainda
);


//Composicao do FRAME de ENVIO e RECEBIMENTO
//data_in - [ADR22..ADR0][PRESAMPLE15..PRESAMPLE0][TR11..TR0][TIPOTRIG3..TIPOTRIG0][FR4..FR0][PROC3..PROC0] - total frame 23+16+12+4+5+4=64bits
//data_out - [DATA23...DATA0] - 24bits
reg [22:0] addsize;
reg [15:0] presamples;
reg [11:0] trigger;
reg [3:0] trig_type;
reg [4:0] frame_points;
reg [3:0] processing;


//Controle fluxo UART - modulo uart_control
reg micro_frametosend=0;
reg [23:0] micro_frameout;
reg [63:0] micro_framein;

uart_control uart_control(
  clk, //clock micro
  micro_frameout, //comando a enviar 
  micro_framein, //dados recebidos
  micro_framearrived, //vai a 1 durante 1 ciclo de clock se frame foi enviado pelo micro ao FPGA e recebido em framein ou enviado pela FPGA ao e confirmado pelo micro em frameout
  micro_frameready, //vai a 1 apos o envio
  micro_frametosend, //cloclar 1 em 1 ciclo de clock se tiver dados a enviar ao micro (frameout)
  micro_frameerror, //vai a 1 durante um ciclo de clock se houver erro no recebimento do frame enviado ao FPGA ou se após 3 tentativas o FPGA não recebe a confirmacao dos dados enviados ao micro
  micro_si, // pino serial in
  micro_so //pino serial out
);


  localparam [3:0] WAITCOMMAND = 0;
  localparam [3:0] SAVESAMPLES = 1;
  localparam [3:0] PREPAREREAD = 2;
  localparam [3:0] PREPAREFIFO = 3;
  localparam [3:0] SENDMICRO = 4;
  localparam [3:0] WAITTOSEND = 5;
  reg [3:0] step=0;
  reg ledr=1;

  reg [11:0] teste1=0;

always @(posedge clk) begin
 if ( ctr_ready && !ctr_read_strobe && !ctr_write_strobe) begin
    case (step)
    WAITCOMMAND: begin  
                 if(micro_framearrived && !micro_frameerror) begin //verifica se chegou algum frame pela UART
                    {addsize, presamples, trigger, trig_type, frame_points, processing}<= micro_framein;
                    step<=SAVESAMPLES;
                    end else ledr<=1;
                 end
    SAVESAMPLES: begin //Faz aquisicao e salva na memoria ADDSIZE amostras
                 addsize<=23'd93;
                 ctr_size_add<=23'd93;//addsize; //usa ADDSIZE para obter o numero de amostras a serem aquisitadas
                 ctr_write_strobe<=1;
                 ctr_read_strobe<=0;
                 step<=PREPAREREAD;
                 end
    PREPAREREAD: begin //Executa procedimento de leitura da memoria e preenche a FIFO com dados do setor
                 ctr_write_strobe<=0;
                 ctr_read_strobe<=1;
                 step<=SENDMICRO;
                 end
    //PREPAREFIFO:  begin
                //gera pulso de clock na FIFO para coletar amostras
   //             if (!ctr_fifo_empty) begin
   //                 ledr<=0;
   //                 step<=SENDMICRO;
   //                 end 
                   // else step<=PREPAREREAD;
   //             end

    SENDMICRO:  begin
                if (micro_frameready && !micro_frametosend && !ctr_fifo_read_enable) begin
                if (!ctr_fifo_empty) begin
                addsize<=addsize-23'd3;
                if (addsize>0) begin
                    //envia para o micro amostras da FIFO
                    ctr_fifo_read_enable<=1;
                   // micro_frameout<=ctr_fifo_out;
                    micro_frameout<={teste1[11:0],teste1[11:0]};
                    teste<=teste+12'd1;
                    micro_frametosend<=1; 
                    end
                    else step<=WAITCOMMAND;
                end
                  else begin
                    step<=PREPAREREAD; //mudei prepara read por waitcommand
                    end
                end 
                end
    
    endcase

end

    if (ctr_read_strobe) ctr_read_strobe <= 0;
    if (ctr_write_strobe) ctr_write_strobe <= 0;
    if (ctr_fifo_read_enable) ctr_fifo_read_enable<=0;
    if (micro_frametosend) micro_frametosend<=0;
end

assign led_r=ledr;

endmodule
