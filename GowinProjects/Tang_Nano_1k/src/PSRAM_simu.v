//File created to simulate PSRAM module in a Icarus Verilog simulation environment

//Clock generator *** simulation only
`timescale 1ns/1ps

module clk_gen (
	input enable,
	output reg clk
);
localparam PHASE = 0;							//Phase
localparam DUTY = 50;							//Duty cycle
 

parameter real FREQ = 27;
parameter real clk_pd = 1/(FREQ * 1e6) * 1e9; 			//Clock period in ns
parameter real clk_on = DUTY/100.0 * clk_pd;  			//On state in ns depending on duty cycle
parameter real clk_off = (100 - DUTY)/100.0 * clk_pd; 	//Off state in ns depending on duty cycle
parameter real quarter = clk_pd/4;
parameter real start_dly = quarter * PHASE/90;			//Delay depending on clock PHASE

reg start_clk;

initial begin
	$display("FREQ = %0d MHz", FREQ);
	$display("PHASE = %0d deg", PHASE);
	$display("DUTY = %0d %%", DUTY);

	$display("PERIOD = %0.3f ns", clk_pd);
	$display("CLK_ON = %0.3f ns", clk_on);
	$display("CLK_OFF = %0.3f ns", clk_off);
	$display("QUARTER = %0.3f ns", quarter);
	$display("START_DELAY = %0.3f ns", start_dly);
end

initial begin
	clk <= 0;
	start_clk <= 0;
end

always @ (posedge enable or negedge enable) begin
	if(enable) begin
		#(start_dly) start_clk = 1;
	end
	else begin
		#(start_dly) start_clk = 0;
	end
end

always @ (posedge start_clk) begin
	
	if (start_clk == 1) begin

		clk = 1;

		while (start_clk) begin
			#(clk_on) clk = 0;
			#(clk_off) clk = 1;
		end

		clk = 0;
	end
end
endmodule

module psram(
	input clk,                   // memory clock <= 84 MHz
  input startbu,               // start button to initialize PSRAM
	inout wire [3:0] mem_sio,    // sio[0] pin 22, sio[1] pin 23, sio[2] pin 24, sio[3] pin 21
	output wire mem_ce,        // pin 
	input wire mem_clk,          // pin 
	output reg [3:0] step
);

localparam [2:0] STEP_DELAY = 0; //First state, wait for 150us
localparam [2:0] STEP_RSTEN = 1; //Second state, RSTEN operation
localparam [2:0] STEP_RST = 2;   //Third state, RST state

//step = STEP_DELAY; 	//indicates the current operation
								//0: 150us required delay
								//1: Reset enable (RSTEN) step
								//2: Reset (RST) step
								//3: Idle normal operation state

reg [15:0] timer = 0;
reg [7:0] command;
reg start = 0;				  	//start initialization
reg msg_sw = 0;						//allows to send message
reg sleepy_mem = 1; 			//indicates whether the PSRAM is initialized
						  						//1: sleep mode
						  						//0: active memory

initial begin 
	step <= STEP_DELAY;
end

always @(posedge clk) begin

	if(startbu) start = 1;			//detect button pressed

	if(sleepy_mem && start && !msg_sw) begin			//begin initialization if mem is sleepy, startbu was pressed and message isn't being sent
		case(step)
			STEP_DELAY: begin
				if(timer[15:8] == 8'h32) begin 		// #32h = #50d. 50 * 256 (thus the 8-bit swap) = 12.800 clocks inputs. At 84Mhz, we have a t ~= 152 us.
					step <= STEP_RSTEN;
					timer <= 16'b0;
					end
					timer <= timer + 1;
        end
			/*STEP_RSTEN: begin
				command <= mem_driver.CMD_RSTEN;
			end
			STEP_RST: begin
				command <= CMD_RST;
			end*/
		endcase	
	end

	if(msg_sw == 1) msg_sw <= 0; 					//if message was sent, disable it
end
endmodule