module adc_module # (
    parameter CLK = 84,                // Clock frequency in MHz
    parameter ADC_FREQ = 42        // Desired sampling frequency in MHz
)(
    input clk_PSRAM,
    input [11:0] adc_out,
    input adc_OTR,
    input adc_enable,
    output reg adc_clk,
    output reg [11:0] adc_data
);
    
    //Counter_num must be 2 multiple
    localparam COUNTER_NUM = CLK/ADC_FREQ;
    // adc_clock_period = 1/ADC_FREQ / 1/clk_PSRAM  = clk_PSRAM / ADC_FREQ

    reg clock_counter = 1;
    reg data_available = 0;         //Flag that indicates ADC will output a valid number
    reg [3:0] delay_counter = 0;    //ADC needs 8 samples before asserting the right sample (8 clock delay)
    reg delay_end = 0;              //Flag that indicates 8 samples has passed

    always @(posedge clk_PSRAM) begin
        if(adc_enable) begin
            if (clock_counter == COUNTER_NUM >> 1) begin   // When frequencies match, change clock
                adc_clk <= ~adc_clk;
                clock_counter <= 1;
                if(delay_counter > 3'd7) begin
                    delay_end <= 1;     // Trash data has ended
                end
                else delay_counter <= delay_counter + 1'd1; // Sum counter
            end
            else clock_counter <= clock_counter + 1'd1;

            // 1 clock delay for stability (max output delay is 7ns; 84MHz clock period is ~12ns)
            if (adc_clk) data_available <= 1;

            if(data_available && delay_end) begin
                adc_data[11:0] <= adc_out[11:0];
            end
        end
        else begin
            data_available <= 0;
            delay_counter  <= 0;
            delay_end <= 0;
            clock_counter <= 1;
        end
    end
endmodule