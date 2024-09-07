module sync_debouncer(
    input wire clk,
    input wire button,
    output wire button_once
);

//Button synchronization with clk
sync sync_button(
    .clock(clk),
    .in(button),
    .out(button_sync)
);

//Button debouncing with clk
debouncer deb_button(
    .clock(clk),
    .IN(button_sync),
    .OUT(button_deb)
);

//Button activation only once
once sync_button_debounced(
    .clk(clk),
    .button(button_deb),
    .button_once(button_once)
);
endmodule

//Sync button press with internal clock
module sync
#(
    parameter SYNC_BITS = 3  // Number of bits in the synchronisation buffer (2 minimum).
)
(
    input wire clock,
    input wire in,     // Asynchronous input.
    output wire out    // Synchronous output.
);

    localparam SYNC_MSB = SYNC_BITS - 1;

    reg [SYNC_MSB : 0] sync_buffer;

    assign out = sync_buffer[SYNC_MSB];

    always @(posedge clock)
    begin
        sync_buffer[SYNC_MSB : 0] <= {sync_buffer[SYNC_MSB - 1 : 0], in};
    end

endmodule

module debouncer
#(
    parameter MAX_COUNT = 84000000

)
(
    input wire clock,
    input wire IN,
    output reg OUT
);
 
//Outputs minimum bit number to reach MAX_COUNT
 localparam COUNTER_BITS = $clog2(MAX_COUNT);


 reg [COUNTER_BITS:0] shift;
 //shift: wait for stable
 always @ (posedge clock) 
 begin
   shift <= {shift,IN}; // N shift register
   if(~|shift) OUT <= 1'b0;      //If none of the bits in "shift" are high, sets output LOW
   else if(&shift) OUT <= 1'b1;  // If all of the bits in "shift" are high, sets output HIGH
   else OUT <= OUT;
 end
 endmodule

module once (
    input clk,
    input button,
    output reg button_once
);

reg [3:0] resync;

always @ (posedge clk)
begin 
   resync <= {resync[2:0],button};  // This will clock in the inc_btn signal and remove metastability.
   button_once <= resync[3] & ~resync[2]; // Only high when the resync[3] was low and resent[2] is high.  
end


endmodule