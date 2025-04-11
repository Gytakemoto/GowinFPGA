module uart( //modulo UART by Dotto
  input clk, //clock micro
  input writting, //colocar em 1 durante um clock qdo tiver dados para enviar via seria out
  input [7:0] data_out, //dados para enviar
  output reg [7:0] data_in, //dados recebidos
  input si, // pino serial in
  output so, //pino serial out
  output reg readytoread //vale 1 durante 1 clock qdo dados chegaram pela entrada serial in
);


//Parametros para 84Mhz de clock
  localparam [15:0] BAUDRATE  = 16'd728; // 84Mhz/728=115384bps 
  localparam [15:0] DELTA = 16'd1092; //centro do nivel logico do proximo bit 728+364=1092

//Estados Serial IN
localparam [2:0] STARTBITIN = 0;
localparam [2:0] DATAIN = 1;
localparam [2:0] WAITTIMEIN = 2;
localparam [2:0] STOPBITIN = 3;
reg [2:0] step_in=0;


//Estados Serial Out
localparam [2:0] WAITTIMEOUT = 0;
localparam [2:0] DATAOUT = 1;
localparam [2:0] STOPBITOUT = 2;
reg [2:0] step_out=0;

  reg readyIn=1;
  reg data_arrived=0;
  reg readyOut=1;
  reg [7:0] shifter_in=0;
  reg [8:0] shifter_out=0;
  reg [10:0] time_in=0;
  reg [10:0] time_out=0;
  reg [4:0] cntbit_in=0;
  reg [4:0] cntbit_out=0;
  

  always_ff @(posedge clk) begin       
            
            //Leitura pela serial
            if (readyIn) begin
                if (!si) begin//start bit
                    readyIn<=0;
                    time_in<=0;
                    cntbit_in<=0;
                    shifter_in<=0;
                    step_in<=STARTBITIN;
                    end
                if (data_arrived) data_arrived<=0;
                end
                else begin
                    case (step_in)
                        STARTBITIN: begin
                                if(time_in==DELTA) begin //aguarda ciclos até o centro do proximo bit
                                time_in<=0;
                                step_in<=DATAIN;
                                end
                                else time_in<=time_in+1;
                                end
                        DATAIN: begin
                                shifter_in <= {shifter_in[6:0], si};
                                cntbit_in<=cntbit_in+1;
                                time_in<=0;
                                if (cntbit_in==8) step_in<=STOPBITIN; else step_in<=WAITTIMEIN;
                                end
                        WAITTIMEIN: if (time_in==BAUDRATE) step_in<=DATAIN; else time_in<=time_in+1;
                        STOPBITIN: 
                                begin
                                if (time_in==BAUDRATE && si) begin
                                time_in<=0;
                                data_in<=shifter_in;
                                data_arrived<=1;
                                readyIn<=1;
                                end
                                else time_in<=time_in+1;
                                end
                    endcase
            end
            //Escrita 
            if (readyOut) begin
                if (writting) begin //Dados para enviar
                    readyOut<=0;
                    cntbit_out<=0;
                    time_out<=0;
                    shifter_out[8:0]<={1'b0, data_out[7:0]}; //acrescenta startbit no inicio do quadro para envio
                    step_out<=WAITTIMEOUT;
                    end
            end
            else begin
                    case(step_out)
                        WAITTIMEOUT: if (time_out==BAUDRATE) step_out<=DATAOUT; else time_out<=time_out+1;
                        DATAOUT: begin
                                 time_out<=0;
                                 shifter_out<=shifter_out<<1;
                                 cntbit_out<=cntbit_out+1;
                                 if(cntbit_out==8) step_out<=STOPBITOUT; else step_out<=WAITTIMEOUT;
                                 end
                        STOPBITOUT: begin
                                 if (time_out==BAUDRATE) begin
                                 time_out<=0;
                                 readyOut<=1;
                                 end
                                 else time_out<=time_out+1;
                                 end
                    endcase

            end

end

assign so = shifter_out[8] || readyOut;
assign readytoread = data_arrived;

endmodule


