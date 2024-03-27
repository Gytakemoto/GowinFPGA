//teste de modulo ADC by Dotto
//clock do ADC = adcclk
module adc (
    input clk,
    input adc_enable,
    output adc_ready,
    input [7:0] adc_clock_div, 
    output reg [23:0] adc_data_double, //para sincronizar com a memoria serao aquisitados 2 amostras de 12 bits
    input wire [11:0] adc_pins,
    output reg adc_clock_pin
);


  localparam [1:0] STEP_ADC_A = 0;
  localparam [1:0] STEP_ADC_B = 1;
  reg [7:0] counterADC = 0; 
  reg [1:0] stepADC = 0;
  reg initialized = 0;
  reg readyADC=0;
  reg [23:0] adc_data;
  reg [11:0] adc_data_temp;
  reg adcclk=0;

assign adc_data_double [23:0] = adc_data [23:0];
assign adc_ready = readyADC;
assign adc_clock_pin = adcclk;

//Temporizacao para o clock do ADC
always_ff @(posedge clk) begin //divide o clock baseado na temporizacao do sistema
    if (counterADC==adc_clock_div) begin
        adcclk=~adcclk;
        if (adcclk) //transicao de clock para 1
        case (stepADC)
            STEP_ADC_A: begin
                adc_data_temp [11:0] <= adc_pins [11:0];
                stepADC<=STEP_ADC_B;
                end

            STEP_ADC_B: begin
                adc_data [23:0] <= {adc_data_temp [11:0], adc_pins[11:0]};
            //    adc_data [23:12] <= adc_pins [11:0];
                readyADC<=1;
                stepADC<=STEP_ADC_A;
            end
        endcase
        counterADC<=8'd0;
    end
    else begin 
        if(adc_enable) counterADC<=counterADC+8'd1; 
            else begin
                counterADC<=8'd0;
                initialized<=0;
            end
        readyADC<=0;
        end
end
endmodule
