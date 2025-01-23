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
    parameter BUFFER_DEPTH = 64        // Profundidade de cada buffer (número de palavras)
)(
    input clk,
    input flag_write,               // Clock para o domínio de escrita
    input flag_read,                // Clock para o domínio de leitura
    input reset,                   // Sinal de reset
    input en_wr,            // Sinal para habilitar escrita
    input en_rd,
    input [DATA_WIDTH-1:0] write_data, // Dados de entrada para escrita
    input first_pong,

    output reg [DATA_WIDTH-1:0] read_data,  // Dados de saída para leitura
    output reg read_cmp,
    output buffer_full,                 // Indica que o buffer ativo de escrita está cheio
    output buffer_empty,                 // Indica que o buffer ativo de leitura está vazio
    output reg stop_PP
);

    // Memórias internas para os dois buffers
    reg [DATA_WIDTH-1:0] buffer_a [0:BUFFER_DEPTH-1];
    reg [DATA_WIDTH-1:0] buffer_b [0:BUFFER_DEPTH-1];

    // Ponteiros de leitura e escrita
    reg [$clog2(BUFFER_DEPTH):0] write_pointer;  // Ponteiro para posição atual de escrita
    reg [$clog2(BUFFER_DEPTH):0] read_pointer;   // Ponteiro para posição atual de leitura

    reg buffer_select;           // Indica qual buffer está ativo para leitura

    // Verifica se o buffer ativo de escrita está cheio
    assign buffer_full = (write_pointer == BUFFER_DEPTH) ? 1:0;

    // Verifica se o buffer ativo de leitura está vazio
    assign buffer_empty = (read_pointer == BUFFER_DEPTH) ? 1:0;

    //Delay registers for posedge detection
    reg d_flag_write;
    reg d_flag_read;
    reg d_first_pong;
    reg last_switch;


    initial begin
        write_pointer <= 0;
        buffer_select <= 0;
        read_pointer <= 0;
        d_flag_write <= 0;
        d_flag_read <= 0;
        last_switch <= 0;
        stop_PP <= 0;
        read_cmp <= 0;
    end

    // Lógica de controle do ponteiro de escrita
    always @(posedge clk or posedge reset) begin

        if(reset) begin
                write_pointer <= 0;
                buffer_select <= 0;
                read_pointer <= 0;
                d_flag_write <= 0;
                d_flag_read <= 0;
                stop_PP <= 0;
                last_switch <= 0;
                read_cmp <= 0;
        end else begin

            d_flag_write <= flag_write;
            d_flag_read <= flag_read;
            d_first_pong <= first_pong;
            read_cmp <= 0;

            //After the first pong, switch buffers
            if(first_pong && !d_first_pong) begin
                buffer_select <= ~buffer_select;
                if(!en_wr) last_switch <= 1;
                else if (en_wr) write_pointer <= 0;
            end

            //Writing pointer
            if(flag_write && !d_flag_write && !buffer_full) begin
                if (en_wr) begin
                    if (buffer_select) begin
                        buffer_a[write_pointer] <= write_data; // Escreve no buffer B
                    end else begin
                        buffer_b[write_pointer] <= write_data; // Escreve no buffer A
                    end
                    if(write_pointer <= BUFFER_DEPTH-1) write_pointer <= {write_pointer + 1'd1};
                end
            end

            //Reading pointer
            if (flag_read && !d_flag_read && !buffer_empty) begin
                if (en_rd) begin                   
                    // Lê do buffer ativo para leitura
                    if (buffer_select) begin
                        read_data <= buffer_b[read_pointer];
                    end else begin
                        read_data <= buffer_a[read_pointer];
                    end

                    if(read_pointer <= BUFFER_DEPTH - 1) read_pointer <= {read_pointer + 1'd1};
                    
                    
                    //* If writing has finished and the ping-pong's been switched, these are the last couple data
                    if(last_switch) begin
                        //Finally, it's the last one!
                        if(read_pointer == write_pointer) begin
                            stop_PP <= 1;      //END Ping Pong Buffer because last data were transferred
                            //read_pointer <= 0;
                            //write_pointer <= 0;
                        end
                    end
                    
                end
            end

            if(d_flag_read && !flag_read) begin
                read_cmp <= 1;
            end

            if(en_wr && en_rd) begin    //Writing is enabled
            // Switching ping and pong buffers when both are finished
                if (buffer_full && buffer_empty) begin      //Awaits for writing and reading process, despite speed differences
                    buffer_select <= ~buffer_select;        //Switching buffers for next cycle
                    write_pointer <= 0;
                    read_pointer <= 0;
                end
            end
            //*When writing's finished, only reading matters!
            else if(en_rd && !en_wr) begin
                if(buffer_empty) begin
                    buffer_select <= ~buffer_select;        //Switching buffers for last cycle                    
                    read_pointer <= 0;                      //Resetting only read pointer cause we need write_pointer for stop_PP
                    last_switch <= 1;
                end
            end
        end
    end
endmodule
