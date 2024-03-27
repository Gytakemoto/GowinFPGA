module psram(
	input clk,                  // memory clock
    input startbu,              // start button to initialize PSRAM
	inout wire [3:0] mem_sio,   // sio[0] pin 22, sio[1] pin 23, sio[2] pin 24, sio[3] pin 21
	output wire mem_ce_n,       // pin 
	output wire mem_clk         // pin 
);

localparam [2:0] STEP_DELAY = 0; //First state, wait for 150us
localparam [2:0] STEP_RSTEN = 1; //Second state, RSTEN operation
localparam [2:0] STEP_RST = 2; //Third state, RST state

reg [2:0] step; //indicates the current operation
//0: 150us required delay
//1: Reset enable (RSTEN) step
//2: Reset (RST) step
//3: Idle normal operation state

reg [1:0] initialized = 0; //indicates the initialization state

always @(posedge clk) begin
	if(!initialized) begin
		case(step)
			STEP_DELAY: begin
					
            end
		endcase	
	end
end



endmodule