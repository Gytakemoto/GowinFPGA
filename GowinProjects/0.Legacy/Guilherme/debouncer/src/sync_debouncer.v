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
    parameter MAX_COUNT = 27000000

)
(
    input wire clock,
    input wire IN,
    output reg OUT
);
 
 localparam COUNTER_BITS = $clog2(MAX_COUNT);


 reg [COUNTER_BITS:0] shift;
 //shift: wait for stable
 always @ (posedge clock) 
 begin
   shift <= {shift,IN}; // N shift register
   if(~|shift)
     OUT <= 1'b0;
   else if(&shift)
     OUT <= 1'b1;
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