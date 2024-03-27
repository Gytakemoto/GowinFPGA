module adc_mem_driver2(
  input clk,
  
  //input [22:0] addr,                //endereco para leitura
  input [22:0] size_add,            //tamanho aquisicao

  input write_strobe,               //1 para escrita
  input read_strobe,                //1 para leitura
  output reg out_ready,             // nao escuta comandos quando baixo

  output reg [23:0] fifo_out,        //amostras que estão na fifo obtidas da memória (128 posicoes de 8 bits)
  input fifo_read_enable,            //enable de leitura da fifo
  output reg fifo_empty,             //1 se vazio

  
  //conexões da memoria com a placa tang nano 1k
  input [7:0] mem_150us_clock_count, // contagem para atingir 150us que é o tempo de startup da memoria  
  inout wire [3:0] mem_sio,         // sio[0] pin 40, sio[1] pin 39, sio[2] pin 38, sio[3] pin 41
  output wire ce_n,                 // pin 42
  output wire mem_clk,              // pin 6

 //conexao com o conversor ADC
  input wire [11:0] adc_out_pins,   //pinos dos dados adc - em analise ainda
  output wire adc_clock_pin         //pino de clock do adc - a definir ainda
);

//Parametros PSRAM
  localparam [7:0] PS_CMD_READ  = 8'hEB;
  localparam [7:0] PS_CMD_WRITE = 8'h38;

//Sequencia de Inicializacao em MODO SPI
  localparam [2:0] STEP_DELAY = 0;  
  localparam [2:0] STEP_RSTEN = 1;
  localparam [2:0] STEP_RST = 2;
  localparam [2:0] STEP_SPI2QPI = 3;
  localparam [2:0] STEP_IDLE = 4;
  reg [2:0] step=0;
  reg initialized = 0;

//Estados fundamentais - inicializa com SPIMODE e depois muda automaticamente para QSPIMODE
  localparam [2:0] SPIMODE=0;
  localparam [2:0] QSPIMODE=1;
  localparam [2:0] WRITING=2;
  localparam [2:0] READING=3;
  reg [2:0] stepmode=0;
  reg stop_clk=0;

    reg [23:0] fifo_in;                      
//    reg [7:0] fifo_out;
 //   reg fifo_read_enable;
 //   reg fifo_write_enable;
    reg fifo_reset=0;
//    wire fifo_empty;
    wire fifo_full;
  //  reg fifo_read_enable=0;
    reg fifo_write_enable=0;

//FIFO para leitura em blocos de 64x24


fifo_top fifo(
		.Data(fifo_in), //input [23:0] Data
		.Reset(fifo_reset), //input Reset
		.WrClk(clk), //input WrClk
		.RdClk(clk), //input RdClk
		.WrEn(fifo_write_enable), //input WrEn
		.RdEn(fifo_read_enable), //input RdEn
		.Q(fifo_out), //output [23:0] Q
		.Empty(fifo_empty), //output Empty
		.Full(fifo_full) //output Full
	);


//Parametros ADC
  wire driver_adc_ready; // quando vai de 0-1 tem 2 amostras disponiveis para uso
  wire driver_adc_enable; //se 0 ADC off, se 1 ADC on
  wire [23:0] adc_data_in;
  reg adc_enable=0;
  reg [23:0] adc_data; //local das amostras aquisitadas
  //reg adc_data_avaliable=0;
  reg acq_on=0;
//Interface ADC construída por Dotto
adc adc(
    clk,
    driver_adc_enable,
    driver_adc_ready,
    8'd13, //divide por (13+1)*2=28 para aquisitar = 84/28=3Mhz
    adc_data_in, //para sincronizar com a memoria serao aquisitados 2 amostras de 12 bits para cada adcready=1
    adc_out_pins,
    adc_clock_pin
);


 //registradores e conexões usadas pelo bloco SPI 
  wire command_ce_n;
  reg command_strobe = 0;
  reg [7:0] command;
  wire command_ready;
  wire command_line;

 //Interface SPI - otimizada para poucas LUTs / 300MHz obtida da WEB e modificada
 spi_command spi_command(
    clk,
    command,
    command_strobe,
    command_ready,
    command_line,
    command_ce_n
  );


//Registradores usados na leitura e escrita
  reg reading = 0;
  reg writing = 0;
  reg [15:0] counter = 0; 
  reg [22:0] counterdata=0;
  reg [23:0] data_read;
  reg [22:0] address=23'b0; //endereço será gerado pelo codigo
  reg oldstrobe=0; //usado para garantir que antes da fifo_empty houve um writing

//Registradores intermediarios da memoria antes de WIRE por assign
 // reg [15:0] mem_data_out;
  reg [3:0] mem_sio_out=0;
  reg mem_sio_outputen;
  reg mem_ce_n=1;  //CE desabitita em 1 - estado inicial
  wire ready;

  reg [11:0] teste=0;

  //todos os assigns - conexões WIRE
  assign mem_clk = (stop_clk) ? 1'b0:~clk; //clock geral para memoria externa
  assign ready = !reading && !writing && mem_ce_n; //pronto se não está escrevendo, lendo e a memoria está desabilitada CE=1
  assign out_ready = initialized && ready; //saida pronta quando inicializado e ready=1 (acabou a execucao de evento)
  assign ce_n = command_ce_n && mem_ce_n; //CE é a junção dos modos SPI e QSPI
  assign mem_sio = command_ce_n           /*se usando SPI - command_ce_n=0 - saida será command_line si[0] com s[1]..s[3] = 'Z', Se 1 - saida será QSPI sio[4]...si[0] qdo outputen=0 e Z qdo outputen=1 */
    ? (mem_sio_outputen ? mem_sio_out : 4'hZ ) 
    : ({ 3'bzzz, command_line });  
//  assign data_out = mem_data_out;
  assign driver_adc_enable= adc_enable;
 
  always_ff @(posedge clk) begin
      case (stepmode)
      //SPIMODE - sequencia de inicializacao da memoria PSRAM
        SPIMODE: begin
        if (!initialized) 
            if ( command_ready && !command_strobe) 
                case (step)
                    STEP_DELAY: begin 
                        // aguarda 150uS para o RESET do dispositivo                       
                       // if( !button0 ) counter <= counter + 16'd1;
                        counter <= counter + 16'd1;
                        if ( counter[15:8] == mem_150us_clock_count ) begin            
                            step <= STEP_RSTEN;
                            end
                        end
                    STEP_RSTEN: begin                    
                        command <= spi_command.PS_CMD_RSTEN;
                        command_strobe <= 1;
                        step <= STEP_RST;
                        end
                    STEP_RST: begin
                        command <= spi_command.PS_CMD_RST;
                        command_strobe <= 1;
                        step <= STEP_SPI2QPI;
                        end      
                    STEP_SPI2QPI: begin
                        command <= spi_command.PS_CMD_QPI;
                        command_strobe <= 1;
                        step <= STEP_IDLE;
                        end
                    STEP_IDLE: begin
                        initialized <= 1;
                        stepmode<=QSPIMODE;
                        end
                endcase
      if ( command_strobe ) command_strobe <= 0;       
      end
        
//Escrita e leitura em modo QSPI
        QSPIMODE: begin
            if ( ready ) begin      
                if (read_strobe) begin //gera leitura se solicitado ou fifo vazia desde que tenha ocorrido uma escrita writing antes
                    reading <= 1; 
                    counter <= 0;
                    stop_clk<=0;
                  //  fifo_reset<=1; //limpa FIFO para armazenar 64 x 24 bits da posicao addr
                    end
                else if ( write_strobe ) begin
                    writing <= 1;
                    counter <= 0;
                    stop_clk<=0;
                    oldstrobe<=1;
                    address<=0;
            //        data_write <= data_in; //para primeiro testes mantive o padrao utilizado anteriormente - a ser salvo na memoria 16 bits
                    end
                end
            else begin
                counter <= counter + 16'd1;
                case (counter) 
                    0: begin 
                        mem_ce_n <= 0;
                        mem_sio_outputen <= 1;
                        mem_sio_out <= reading ? PS_CMD_READ[7:4] : PS_CMD_WRITE[7:4];
                        end
                    1: mem_sio_out <= reading ? PS_CMD_READ[3:0] : PS_CMD_WRITE[3:0];
                    2: mem_sio_out <= {1'b0,address[22:20]};
                    3: mem_sio_out <= address[19:16];
                    4: mem_sio_out <= address[15:12];
                    5: mem_sio_out <= address[11:8];
                    6: mem_sio_out <= address[7:4];
                    7: begin
                        mem_sio_out <= address[3:0];
                        if (writing) begin
                                adc_enable<=1;
                                counter<=0;
                                counterdata<=0;
                                stop_clk=0; //para de gerar clock na memoria e aguarda chegada de amostras
                                stepmode<=WRITING; //muda de estado aqui, pois no proximo clock comeca a gravar
                                end
                        end
                    default: begin
                        if ( reading ) begin
                            if ( counter > 16'd13 ) begin // Aguarda 6 clocks adicionais para os dados da RAM se tornarem disponiveis na leitura, sendo o 5 ciclos + 1 de mudanca de estado
                                mem_sio_outputen <= 0;
                                counter<=0;
                                counterdata<=0;
                                fifo_reset<=0;
                                stepmode<=READING;
                                end
                             end 
                        end
                 endcase    
             end
         end
        //Sequencia de leitura
        READING: begin
            if (reading) begin  
            stop_clk<=0;
          //  mem_data_out = {mem_data_out[11:0], mem_sio}; // testando para 16 bits apenas 4 ciclos de 4 bits
            data_read<={data_read[19:0], mem_sio [3:0]};
           // data_read<={data_read[19:0], teste [3:0]};
           // teste<=teste<<4;
            if ( counter == 16'd6 ) begin
               // fifo_in<=data_read;
                fifo_in<=teste;
                fifo_write_enable<=1;
                counter<=0;
               teste<=teste+12'd1;
                counterdata<=counterdata+23'd3;                     
                end 
                else begin
                    counter <= counter + 16'd1;
                    fifo_write_enable<=0;   
                        if (counterdata==90) begin //tamanho da fifo projetada para 64x24
                            address<=address+counterdata;
                            reading<=0;
                            counter<=0;
                            counterdata<=0;
                         end
                   end
            end
            else begin 
                mem_ce_n<=1;
                stop_clk<=1;
                stepmode<=QSPIMODE;
                end
            end
        //Sequencia de Escrita
        //Aguarda Aquisicao de amostras e vai salvando na memoria;
        WRITING: begin
            if(writing) begin
                if(driver_adc_ready) begin //amostras chegaram pelo ADC
                                acq_on<=1;
                                adc_data<=adc_data_in; //captura amostra do ADC
                                adc_data<=teste;
                                teste<=teste+12'd1;
                                end
                else if (acq_on) begin
                    stop_clk=0; //chegou amostras, ativa clock da memoria para salvar duas amostras na memoria (24 bits) 12bits+12bits para otimizar o espaço
                    //{mem_sio_out, data_write[15:4]} <= data_write; // testando para 16 bits apenas 4 ciclos de 4 bits
                    {mem_sio_out, adc_data[23:4]} <= adc_data;
                              if ( counter == 16'd6 ) begin
                                    counterdata<=counterdata+23'd3; //incrementa 2 amostras
                                    acq_on<=0;
                                    counter<=0;
                                 //   stop_clk<=1; //- checar se não seria aqui ou embaixo... avaliar posteriormente no teste
                                    if (counterdata>=size_add) begin
                                        //finaliza tudo! Armazenamento finalizado!
                                        adc_enable<=0;
                                        writing <= 0;
                                        end 
                                    end else counter <= counter + 16'd1;
                  end
                  else stop_clk<=1;

            end
            else begin 
                mem_ce_n<=1;
                stop_clk<=1;
                stepmode<=QSPIMODE;
            end
        end
        endcase
    if (fifo_write_enable) fifo_write_enable<=0;

end

         
endmodule


