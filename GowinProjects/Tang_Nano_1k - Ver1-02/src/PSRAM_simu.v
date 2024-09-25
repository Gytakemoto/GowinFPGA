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
module mem_driver_simu(
	input mem_clk,
	input [7:0] command,
	input [3:0] step,
	input spi_start,
	input qpi_on,
	input [23:0] address,
	input read_sw,
	input write_sw,
	input [15:0] data_in,

	output reg [5:0] counter,
	output endcommand,
	output reg mem_ce,
	output reg [3:0] mem_sio,
	output reg [15:0] data_out
);

//Reinitialization commands
parameter [7:0] CMD_RSTEN = 8'h66;
parameter [7:0] CMD_RST = 8'h99;
parameter [7:0] SPI2QPI = 8'h35;

//Read & Write start commands
parameter [7:0] CMD_READ = 8'hEB;
parameter [7:0] CMD_WRITE = 8'h02;

//Variables
//reg [5:0] counter;
reg sendcommand;						//Flag indicates when sending a command
reg reading;							//Reg indicates when in a writing proccess
reg writing;							//Reg indicates when in a reading proccess
reg [15:0] data_write;

wire quad_start;
wire com_start;

assign quad_start = (~read_sw && write_sw) || (read_sw && ~write_sw);
assign com_start = quad_start || spi_start;

//Initial conditions
initial begin
	counter <= 0;
	sendcommand <= 0;
	mem_ce <= 1;
	reading <= 0;
	writing <= 0;
end

always @(negedge mem_clk) begin

	//When com_start turns high, starts communication
	if(com_start) begin

		sendcommand <= 1;
		counter <= 0;

		//Define reading or writing proccess
		if (quad_start) begin
			if (read_sw) begin
				reading <= 1;
			end
			else if (write_sw)  begin
				writing <= 1;
				data_write <= data_in;
			end
		end
	end

	//$display(psram.STEP_RSTEN);
	if (sendcommand) mem_ce <= 0;

	case(qpi_on)

		//SPI communication
		0: begin
			if (sendcommand) begin
				mem_sio[3:0] <= {3'bzzz,command[7-counter]}; //MSB first
				counter <= counter + 1'd1;
				//$display("O valor do comando eh %b", command);
				//$display("agora mem_ce eh",mem_ce);
				//$display("O comando para o contador %d eh %d", counter, command[7-counter]);
				//$display("o valor de sendcommand eh %d", sendcommand);
			end
			
			//End of command of 7 bits
			if (counter > 3'd7) begin
				sendcommand <= 0;
				counter <= 0;
				mem_ce <= 1;
			end
		end

		//QPI communication
		1: begin

			if(quad_start) begin

				counter <= counter + 1'd1;

				case (counter)

				//Operation command
				0: mem_sio <= reading ? CMD_READ[7:4] : CMD_WRITE[7:4];
				1: mem_sio <= reading ? CMD_READ[3:0] : CMD_WRITE[3:0];

				//Address command
				2: mem_sio <= address[23:20];
				3: mem_sio <= address[19:16];
				4: mem_sio <= address[15:12];
				5: mem_sio <= address[11:8];
				6: mem_sio <= address[7:4];
				7: mem_sio <= address[3:0];

				//Message
				default: begin

					if(reading) begin
						if(counter > 14 && counter <= 18) begin	//Wait for 6 clocks + taclk in read operation. See datasheet for more details.

						//*** simulation only
						case (counter)
							15: mem_sio <= 4'hA;
							16: mem_sio <= 4'hB;
							17: mem_sio <= 4'hC;
							18: mem_sio <= 4'hD;
						endcase
							data_out <= {data_out[11:0],mem_sio[3:0]}; //MSB is read first
							// data psram: x x x x  y y y y  z z z z  w w w w
							//
							//step 0:
							// data_out = _ _ _ _  _ _ _ _  _ _ _ _  _ _ _ _
							//
							// step 1:
							// mem_sio[3:0] = 4'b x x x x
							// data_out* = _ _ _ _  _ _ _ _  _ _ _ _  x x x x

							// step 2:
							// mem_sio[3:0] = 4'b y y y y
							// data_out = _ _ _ _  _ _ _ _  x x x x  y y y y
							//			-	   data_out*[11:0]     - mem_sio[3:0]
						end
						else if(counter >= 18) begin
							reading <= 0;
						end
						else mem_sio[3:0] <= 4'bzzzz;
					end
					else if(writing) begin
							if(counter < 12) begin
								{mem_sio, data_write[15:4]} <= data_write;								
								//data_write = x x x x  y y y y  z z z z  w w w w
								//
								//step1:
								//mem_sio = x x x x
								//data_write = y y y y  z z z z  w w w w  w w w w
								//
								//step 2:
								//mem_sio = y y y y
								//data_write = z z z z  w w w w  w w w w  w w w w

							end
							else begin
								writing <= 0;
							end
						data_out <= data_write; //*** simulation only
					end
					else begin //End of communication
						mem_sio[3:0] <= 4'bzzzz;
						counter <= 0;
						sendcommand <= 0;
						mem_ce <= 1;
					end
					end
				endcase
			end
		end
	endcase
end

//assign endcommand = (~(com_start || quad_start) && sendcommand) || ((com_start || quad_start) && ~sendcommand);
assign endcommand = (com_start) && ~sendcommand;
// END COMMAND truth table: XOR topology
//				com_start		    sendcommand			endcommand
//					0					 0				 	 0
//					0					 1				 	 x
//					1					 0					 1
//					1					 1					 0
endmodule


//PSRAM "TOP module"
module psram_simu(
	input mem_clk,
  input startbu,              // start button to initialize PSRAM
	input [23:0] address,
	input read_sw,
	input write_sw,
	input [15:0] data_in,
	
	output [5:0] counter,
	output endcommand,
	output mem_ce,        		// pin 
	output reg [3:0] step,		//*** simulation only
	output reg [7:0] command,	//*** simularion only
	output wire [15:0] data_out,

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

reg spi_start = 0;				//Control communication status during auto-initialization
															//0: End the communication
															//1: Start the communication

reg qpi_on;					//Communication mode
															//0: SPI communication
															//1: QPI communication

mem_driver_simu PSRAM_com(
	.mem_clk(mem_clk),
	.command(command),
	.step(step),
	.spi_start(spi_start),
	.qpi_on(qpi_on),
	.address(address),
	.read_sw(read_sw),
	.write_sw(write_sw),
	.data_in(data_in),

	.counter(counter),
	.endcommand(endcommand),
	.mem_ce(mem_ce),
	.mem_sio(mem_sio),
	.data_out(data_out)
);

initial begin
	step <= STEP_DELAY;
	timer <= 0;
	spi_start <= 0;
	//command <= 8'd0;
end

always @(posedge mem_clk) begin

	if(startbu) begin
		 start = 1;			//Detect button pressed
	end

	if(start) begin		//Begin initialization if mem isn't idle, startbu was pressed and message isn't being sent
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
				spi_start <= 1;
				qpi_on <= 0;
				if(endcommand) begin
					step <= STEP_RST;
					spi_start <= 0;
				end
			end
			STEP_RST: begin
				command <= PSRAM_com.CMD_RST;
				spi_start <= 1;
				qpi_on <= 0;
				if(endcommand) begin
					step <= STEP_SPI2QPI;
					spi_start <= 0;
				end
			end
			STEP_SPI2QPI: begin
				command <= PSRAM_com.SPI2QPI;
				spi_start <= 1;
				qpi_on <= 0;
				if(endcommand) begin
					step <= STEP_IDLE;
					spi_start <= 0;
				end 
			end
			STEP_IDLE: begin
				spi_start <= 0;
				qpi_on <= 1;
			end
		endcase	
	end
end
endmodule