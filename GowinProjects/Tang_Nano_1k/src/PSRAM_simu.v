//File created to simulate PSRAM module in a Icarus Verilog simulation environment
`timescale 1ns/1ps

//Clock generator *** simulation only
module clk_gen (
	input enable,

	output reg clk
);

//Local parameters
localparam PHASE = 0;							//Phase
localparam DUTY = 50;							//Duty cycle
parameter real FREQ = 27;
parameter real clk_pd = 1/(FREQ * 1e6) * 1e9; 			//Clock period in ns
parameter real clk_on = DUTY/100.0 * clk_pd;  			//On state in ns depending on duty cycle
parameter real clk_off = (100 - DUTY)/100.0 * clk_pd; 	//Off state in ns depending on duty cycle
parameter real quarter = clk_pd/4;
parameter real start_dly = quarter * PHASE/90;			//Delay depending on clock PHASE

//Variables
reg start_clk;		//Control clock output depending on clock enable

//Debug in terminal
/*
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
*/

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

//##############################################################################################################


//Memory driver: interprets commands based on Datasheet
module mem_driver(
	input mem_clk,
	input [7:0] command,
	input [3:0] step,
	input com_start,
	
	output endcommand,
	output reg mem_ce,
	output reg [3:0] mem_sio
);

//Reinitialization commands
parameter [7:0] CMD_RSTEN = 8'h66;
parameter [7:0] CMD_RST = 8'h99;
parameter [7:0] SPI2QPI = 8'h35;

//Variables
reg [3:0] counter;
reg sendcommand;						//Flag indicates when sending a command

//Initial conditions
initial begin
	counter <= 0;
	sendcommand <= 0;
	mem_ce <= 1;
end

//When com_start turns high, starts communication
always @(posedge com_start) begin
	if(com_start) begin
		sendcommand <= 1;
	end
end

always @(negedge mem_clk) begin
	//$display(psram.STEP_RSTEN);
	if (sendcommand) mem_ce <= 0;

	if (sendcommand) begin
		mem_sio[0] <= command[7-counter];
		mem_sio[1] <= 1'bz;
		counter <= counter + 1'd1;
		$display("O valor do comando eh %b", command);
		$display("agora mem_ce eh",mem_ce);
		$display("O comando para o contador %d eh %d", counter, command[7-counter]);
		$display("o valor de sendcommand eh %d", sendcommand);
	end
	
	//End of command of 7 bits
	if (counter > 3'd7) begin
		sendcommand <= 0;
		counter <= 0;
		mem_ce <= 1;
	end
end

assign endcommand = (~com_start && sendcommand) || (com_start && ~sendcommand);
// END COMMAND truth table: XOR topology
//				com_start					sendcommand				  endcommand
//						0									 0								  0
//						0									 1									x
//						1									 0									1
//						1									 1									0
endmodule


//PSRAM "TOP module"
module psram(
	input mem_clk,
  	input startbu,              // start button to initialize PSRAM
	
	output mem_ce,        		// pin 
	output reg [3:0] step,		//*** simulation only
	output reg [7:0] command,	//*** simularion only

	inout [3:0] mem_sio    	// sio[0] pin 22, sio[1] pin 23, sio[2] pin 24, sio[3] pin 21
);

//Local parameters
localparam [2:0] STEP_DELAY = 0; //First state, wait for 150us
localparam [2:0] STEP_RSTEN = 1; //Second state, RSTEN operation
localparam [2:0] STEP_RST = 2;   //Third state, RST state
localparam [2:0] STEP_SPI2QPI = 3;
localparam [2:0] STEP_IDLE = 4;

//Variables
//reg [3:0] step = STEP_DELAY;  //indicates the current operation
									//0: 150us required delay
									//1: Reset enable (RSTEN) step
									//2: Reset (RST) step
									//3: Idle normal operation state

reg [15:0] timer = 0;			//Counter
//reg [7:0] command;				//SPI/QPI 8 bit command

reg start = 0;				  	//Start initialization, when button pressed

reg com_start = 0;				//Communication status
															//0: End the communication
															//1: Start the communication

mem_driver PSRAM_com(
	.mem_clk(mem_clk),
	.command(command),
	.step(step),
	.mem_sio(mem_sio),
	.mem_ce(mem_ce),
	.com_start(com_start),
	.endcommand(endcommand)
);

initial begin
	step <= STEP_DELAY;
	timer <= 0;
	com_start <= 0;
	//command <= 8'd0;
end

always @(posedge mem_clk) begin

	if(startbu) begin
		 start = 1;			//Detect button pressed
	end

	if(start && step != STEP_IDLE) begin		//Begin initialization if mem isn't idle, startbu was pressed and message isn't being sent
		case(step)
			STEP_DELAY: begin
				timer <= timer + 1;
				if(timer[15:8] == 8'h32) begin 		// #32h = #50d. 50 * 256 (thus the 8-bit swap) = 12.800 clocks inputs. At 84Mhz, we have a t ~= 152 us.
					step <= STEP_RSTEN;
					timer <= 16'b0;					//Reset timer
				end
        	end
			STEP_RSTEN: begin
				//$display("entrou no step rsten");
				command <= PSRAM_com.CMD_RSTEN;
				com_start <= 1;
				if(endcommand) begin
					step <= STEP_RST;
					com_start <= 0;
				end
			end
			STEP_RST: begin
				command <= PSRAM_com.CMD_RST;
				com_start <= 1;
				if(endcommand) begin
					step <= STEP_SPI2QPI;
					com_start <= 0;
				end
			end
			STEP_SPI2QPI: begin
				command <= 8'h35;
				com_start <= 1;
				$display("dentro do step, o comando eh %b", command);
				if(endcommand) begin
					step <= STEP_IDLE;
					com_start <= 0;
				end 
			end
		endcase	
	end
end
endmodule