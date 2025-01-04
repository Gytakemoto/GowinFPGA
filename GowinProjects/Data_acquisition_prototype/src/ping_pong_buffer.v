/* -------------------------------------------------------------------------- */
/*                              Ping Pong Buffer                              */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- 
Buffer that operates both writing and reading, developed in such way that it can
be done in different timing frequencies.

buffer_select is the flag responsible for switching between ping and pong buffers.

When buffer_select = 1, data will be written at buffer_a and read at buffer_b.
When both the writing buffer is full and the reading buffer is low, it switches.

-------------------------------------------------------------------------- */


module ping_pong_buffer #(
    parameter DATA_WIDTH = 16,           // Largura dos dados (número de bits por dado)
    parameter BUFFER_DEPTH = 256        // Profundidade de cada buffer (número de palavras)
)(
    input clk,
    input flag_write,               // Clock para o domínio de escrita
    input flag_read,                // Clock para o domínio de leitura
    input reset,                   // Sinal de reset
    input en_wr,            // Sinal para habilitar escrita
    input en_rd,
    input [DATA_WIDTH-1:0] write_data, // Dados de entrada para escrita

    
    output reg [DATA_WIDTH-1:0] read_data,  // Dados de saída para leitura
    output buffer_full,                 // Indica que o buffer ativo de escrita está cheio
    output buffer_empty                 // Indica que o buffer ativo de leitura está vazio
);

    // Memórias internas para os dois buffers
    reg [DATA_WIDTH-1:0] buffer_a [0:BUFFER_DEPTH-1];
    reg [DATA_WIDTH-1:0] buffer_b [0:BUFFER_DEPTH-1];

    // Ponteiros de leitura e escrita
    reg [$clog2(BUFFER_DEPTH)-1:0] write_pointer;  // Ponteiro para posição atual de escrita
    reg [$clog2(BUFFER_DEPTH)-1:0] read_pointer;   // Ponteiro para posição atual de leitura

    reg buffer_select;           // Indica qual buffer está ativo para leitura

    // Verifica se o buffer ativo de escrita está cheio
    assign buffer_full = write_pointer == BUFFER_DEPTH-1;

    // Verifica se o buffer ativo de leitura está vazio
    assign buffer_empty = read_pointer == BUFFER_DEPTH-1 ? 1:0;

    //Delay registers for posedge detection
    reg d_flag_write;
    reg d_flag_read;

    // Lógica de controle do ponteiro de escrita
    always @(posedge clk or posedge reset) begin

        if(reset) begin
                write_pointer <= 0;
                buffer_select <= 0;
                read_pointer <= 0;
                buffer_select <= 1;
                d_flag_write <= 0;
                d_flag_read <= 0;
        end else begin

            d_flag_write <= flag_write;
            d_flag_read <= flag_read;

            if(flag_write && !d_flag_write) begin
                if (en_wr) begin
                    if (buffer_select) begin
                        buffer_a[write_pointer] <= write_data; // Escreve no buffer B
                    end else begin
                        buffer_b[write_pointer] <= write_data; // Escreve no buffer A
                    end
                    write_pointer <= {write_pointer + 1'd1};
                end
            end

            // Lógica de controle do ponteiro de leitura
            if (flag_read && !d_flag_read) begin
                if (en_rd) begin
                    // Lê do buffer ativo para leitura
                    if (buffer_select) begin
                        read_data <= buffer_b[read_pointer];
                    end else begin
                        read_data <= buffer_a[read_pointer];
                    end
                    read_pointer <= {read_pointer + 1'd1};
                end
            end

            // Troca o buffer ativo quando o buffer atual está vazio
            if (buffer_full && buffer_empty) begin      //Awaits for writing and reading process, despite speed differences
                buffer_select <= ~buffer_select;        //Switching buffers for next cycle
                write_pointer <= 0;
                read_pointer <= 0;
            end
        end
    end
endmodule
