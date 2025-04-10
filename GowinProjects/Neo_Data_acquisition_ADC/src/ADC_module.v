module adc_module # (
    parameter CLK = 60,                // Clock frequency in MHz
    parameter ADC_FREQ = 6        // Desired sampling frequency in MHz
)(
    input clk_PSRAM,
    input clk_ADC,
    input [11:0] adc_out,
    input adc_OTR,
    input adc_enable,
    output reg adc_ready,
    output reg [11:0] adc_data
);

    reg [4:0] delay_counter = 0;    //ADC needs 8 samples before asserting the right sample (8 clock delay)
    reg delay_end = 0;              //Flag that indicates 8 samples has passed
    reg sent_once;

    always @(posedge clk_PSRAM) begin
        if(adc_enable) begin
            if(!clk_ADC && !sent_once) begin        //If adc_clk is at negative edge, triggers adc_ready one time
                adc_ready <= 1;
                sent_once <= 1;
            end 
            else if(adc_ready) begin
                adc_ready <= 0;
            end
            else if (clk_ADC) sent_once <= 0;
        end
    end

    always @(posedge clk_ADC) begin
        if(adc_enable) begin
            if(delay_counter > 4'd7) begin
                delay_end <= 1;     // Trash data has ended
            end
            else delay_counter <= delay_counter + 1'd1; // Sum counter
        end
        else begin
            delay_counter  <= 0;
            delay_end <= 0;
        end

        if(delay_end) begin
            adc_data[11:0] <= adc_out[11:0];
        end
    end
endmodule