//O LED integrado do Tang Nano é ativado em nível lógico LOW. Então, temos que as cores reproduzidas serão:
//G B R -> led[2] led[1] led[0]
//0 0 0 -> Branco
//0 0 1 -> Ciano
//0 1 0 -> Amarelo
//0 1 1 -> Verde
//1 0 0 -> Roxo
//1 0 1 -> Azul
//1 0 0 -> Vermelho
//1 1 1 -> Deligado


module led (
    input sys_clk, //Definindo o sinal de clock
    input sys_rst_n, //Definindo sinal de reset borda de descida
    output reg [2:0] led // 110 R, 101 B, 011 G 
)

reg [31:0] counter;
reg [2:0] full;
assign led[2:0] = full[2:0]; 
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        counter <= 31'd0;
      //  led <= 3'b110;
        full <= 3'b000;
    end
    else if (counter < 31'd1350_0000)       // 0.5s delay
        counter <= counter + 1;
    else begin
        counter <= 31'd0;
        full <= full +1;
       // led[2:0] <= full[2:0];
    end
end

endmodule
