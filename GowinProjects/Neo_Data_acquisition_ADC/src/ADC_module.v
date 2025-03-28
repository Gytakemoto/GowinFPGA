module adc_module # (
    parameter CLK = 60,                // Clock frequency in MHz
    parameter ADC_FREQ = 6        // Desired sampling frequency in MHz
)(
    input clk_PSRAM,
    input [11:0] adc_out,
    input adc_OTR,
    input adc_enable,
    output reg adc_clk,
    output reg adc_ready,
    output reg [11:0] adc_data
);
    
    //Counter_num must be 2 multiple
    localparam COUNTER_NUM = CLK/ADC_FREQ;
    // adc_clock_period = 1/ADC_FREQ / 1/clk_PSRAM  = clk_PSRAM / ADC_FREQ

    reg  [$clog2(COUNTER_NUM)-1:0] clock_counter = 1;
    reg data_available = 0;         //Flag that indicates ADC will output a valid number
    reg [4:0] delay_counter = 0;    //ADC needs 8 samples before asserting the right sample (8 clock delay)
    reg delay_end = 0;              //Flag that indicates 8 samples has passed
    reg d_adc_clk;

    always @(posedge clk_PSRAM) begin
        
        adc_ready <= 0;
        data_available <= 0;
        //d_adc_clk <= adc_clk;

        if(adc_enable) begin

            if (clock_counter == (COUNTER_NUM/2) - 1) begin
                adc_clk <= ~adc_clk;
                clock_counter <= 0;  // Reinicia de 0 para manter a simetria
                if(delay_counter > 4'd15) begin
                    delay_end <= 1;     // Trash data has ended
                end
                else delay_counter <= delay_counter + 1'd1; // Sum counter
            end
            else begin
                clock_counter <= clock_counter + 1;
            end

            // 1 clock delay for stability (max output delay is 7ns; 84MHz clock period is ~12ns)
            if (adc_clk && !clock_counter) data_available <= 1;

            //!maybe use assign statement for instanteneous attribution
            if(data_available && delay_end) begin
                adc_data[11:0] <= adc_out[11:0];
                adc_ready <= 1;
            end
        end
        else begin
            adc_ready <= 0;
            data_available <= 0;
            delay_counter  <= 0;
            delay_end <= 0;
            clock_counter <= 1;
            adc_clk <= 0;
        end
    end
endmodule