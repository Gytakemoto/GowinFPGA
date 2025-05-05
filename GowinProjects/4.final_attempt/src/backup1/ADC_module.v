module adc_module (
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
    reg debug;

    always @(posedge clk_PSRAM) begin
        if(adc_enable) begin
            if(!clk_ADC && !sent_once && delay_end) begin        //If adc_clk is at negative edge, triggers adc_ready one time
                adc_ready <= 1;
                adc_data[11:0] <= adc_out[11:0];
                
                /*
                debug <= ~debug;
                if(debug) adc_data[11:0] <= 12'hABC;
                else adc_data[11:0] <= 12'h123;
                */
                sent_once <= 1;
            end 
            else if(adc_ready) begin
                adc_ready <= 0;
            end
            else if (clk_ADC) sent_once <= 0;
        end
        else adc_ready <= 0;
    end

    always @(posedge clk_ADC) begin
        if(adc_enable) begin
            if(delay_counter > 4'd12) begin
                delay_end <= 1;     // Trash data has ended
            end
            else delay_counter <= delay_counter + 1'd1; // Sum counter
        end
        else begin
            delay_counter  <= 0;
            delay_end <= 0;
        end
    end
endmodule