module top (
input clksys,
input si,
output reg LEDR,
output reg LEDG,
output wire so
); 


wire clk;

localparam [2:0] READ=0;
localparam [2:0] WRITEA=1;
localparam [2:0] WRITEB=2;
localparam [2:0] WRITEC=3;
localparam [2:0] WAITCLOCKS=4;
localparam [2:0] WAITCLOCKSREAD=5;
localparam [2:0] FIFOREAD=6;
localparam [2:0] WAITTOSEND=7;

reg [2:0] step=0;

 Gowin_rPLL Gowin_CLK(
        .clkout(clk), //output clkout
        .clkin(clksys) //input clkin
    );


reg [23:0] Data_i;
wire [23:0] Q_o;
wire Empty_o;
wire Full_o;
reg wEn=0;
reg rEn=0;
reg Reset=0;
fifo_top fifo(
		.Data(Data_i), //input [23:0] Data
		.Reset(Reset), //input Reset
		.WrClk(clk), //input WrClk
		.RdClk(clk), //input RdClk
		.WrEn(wEn), //input WrEn
		.RdEn(rEn), //input RdEn
		.Q(Q_o), //output [23:0] Q
		.Empty(Empty_o), //output Empty
		.Full(Full_o) //output Full
	);


reg [63:0] u_framein;
reg [23:0] u_frameout;
reg u_frametosend=0;
reg [7:0] datainput=0;
reg u_frameerror;
reg [63:0] datain;
reg arrived=0;
reg ledr=1;
reg ledg=1;
reg [2:0] temp=0;
//reg frameerror=0;
//reg framearrived=0;

uart_control uart_control(
  clk, //clock micro
  u_frameout, //comando a enviar 
  u_framein, //dados recebidos
  u_framearrived, //vai a 1 durante 1 ciclo de clock se frame foi enviado pelo micro ao FPGA e recebido em framein ou enviado pela FPGA ao e confirmado pelo micro em frameout
  u_frameready,
  u_frametosend, //cloclar 1 em 1 ciclo de clock se tiver dados a enviar ao micro (frameout)
  u_frameerror, //vai a 1 durante um ciclo de clock se houver erro no recebimento do frame enviado ao FPGA ou se após 3 tentativas o FPGA não recebe a confirmacao dos dados enviados ao micro
  si, // pino serial in
  so //pino serial out
);

always @(posedge clk) begin

//frameerror<=u_frameerror;
//framearrived<=u_framearrived;

end

always_ff @(posedge clk) begin    
 case (step)
    READ: begin
        if(u_framearrived && !u_frameerror) begin
          //      Reset<=1;
                datain<=u_framein;
                step<=WRITEA;
                ledg<=1;
                end
     end
     WRITEA: begin
         if (u_frameready && !u_frametosend && !Reset) begin
            u_frameout<=24'h313233;//datain[63:40];
         //   Data_i<=datain[63:40];
         //   wEn<=1;
            u_frametosend<=1;
        //    ledg<=0;
            step<=WRITEB;
            end
      end
    WRITEB: begin
        if (u_frameready && !u_frametosend && !wEn) begin
            u_frameout<=24'h343536;//datain[39:16];
       //     Data_i<=datain[39:16];
       //     wEn<=1;
            u_frametosend<=1;
       //     ledg<=0;
            step<=WRITEC;
            end
      end
    WRITEC: begin
        if (u_frameready && !u_frametosend && !wEn) begin
            u_frameout<=24'h003738;//{8'b0,datain[15:0]};
        //    Data_i<={8'b0,datain[15:0]};
        //    wEn<=1;
            u_frametosend<=1;
            ledg<=0;
            step<=READ;
            end
      end
         WAITCLOCKS: begin
            if (!wEn) begin
            temp<=temp+3'd1;
            if (temp==3'd3) begin
                        temp<=3'd0;
                        step<=WAITCLOCKSREAD; 
                        end
                else begin
                   Data_i<=24'h414141;
                   wEn<=1;
                   end
            end
      end
        WAITCLOCKSREAD: begin
            if (!rEn) begin
            temp<=temp+3'd1;
            if (temp==3'd1) step<=FIFOREAD; 
                else begin
                  // u_frameout<=Q_o;
                   rEn<=1;
                   end
            end
      end
    FIFOREAD: begin
            if (!rEn && !wEn && u_frameready && !u_frametosend) begin
            if (!Empty_o) begin
                    u_frameout<=Q_o;
                    rEn<=1;
                    u_frametosend<=1;
                    ledg<=0;
                    end
            else step<=READ;
            end
      end  

endcase
 if (u_frameerror) ledr<=0;
 if (u_frametosend) u_frametosend<=0;

if (wEn) wEn<=0;
if (rEn) rEn<=0;
if (Reset) Reset<=0;
end


assign LEDR=ledr;
assign LEDG=ledg;
endmodule