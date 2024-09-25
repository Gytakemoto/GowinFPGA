#0
flag = 0
counter = 0

#1

-> Alteração no sinal de com_start top: Low p/ High
quad_start = 1
com_start = 1

-> flag = HIGH em #2

-> writing ou reading = HIGH em #2 (dependendo do sinal de read_write)

-> data_write = data_in em #2

-> data_out = 0 em #2

-> sendcommand = HIGH em #2

-> counter = 0 em #2

#2 (counter = 0)

quad_start = 0? (depende de quantos clocks duram o sinal - suponho 3)

(flag & sendcommand = true)

(flag & !sendcommand = false)

writing/reading = HIGH

-> mem_ce em LOW em #3

-> counter <= 1 em #3

-> mem_sio_reg = CMD[7:4] em #3 (counter = 1)

#3 (counter = 1)

writing/reading = HIGH

quad_start = 0? (depende de quantos clocks duram o sinal)

(flag & sendcommand = true)

(flag & !sendcommand = false)

-> counter <= 2 em #4

-> mem_sio_reg = CMD[3:0] em #4 (counter = 2)

#4 (counter = 2)

writing/reading = HIGH

(flag & sendcommand = true)

(flag & !sendcommand = false)

-> counter <= 3 em #5

-> mem_sio_reg = address[23:20] em #5 (counter = 3)

#5 (counter = 3)

writing/reading = HIGH

(flag & sendcommand = true)

(flag & !sendcommand = false)

-> counter <= 4 em #6

-> mem_sio_reg = address[19:16] em #6 (counter = 4)

#6 (counter = 4)

writing/reading = HIGH

(flag & sendcommand = true)

(flag & !sendcommand = false)

-> counter <= 5 em #7

-> mem_sio_reg = address[15:12] em #7 (counter = 5)

#7 (counter = 5)

writing/reading = HIGH

(flag & sendcommand = true)

endcommand = (flag & !sendcommand = false)

-> counter <= 6 em #8

-> mem_sio_reg = address[11:8] em #8 (counter = 6)

#8 (counter = 6)

writing/reading = HIGH

(flag & sendcommand = true)

endcommand = (flag & !sendcommand) = false

-> counter <=7 em #9

-> mem_sio_reg = address[7:4] em #9 (counter = 7)

#9 (counter = 7)

writing/reading = HIGH

(flag & sendcommand = true)

endcommand = (flag & !sendcommand) = false

-> counter <=7 em #10

-> mem_sio_reg = address[3:0] em #10 (counter = 8)

#10 (counter = 8)

(flag & sendcommand = true)

endcommand = (flag & !sendcommand) = false

-> counter <= 9 em #11

#SE reading HIGH
 mem_sio_reg <= zzzz em #11

#SE writing HIGH
-> mem_sio_reg = data[15:12] em #11 (counter = 9)

#11 (counter = 9)

(flag & sendcommand = true)

endcommand = (flag & !sendcommand) = false

-> counter <= 10 em #12

#SE reading HIGH
    mem_sio_reg <= zzzz em #12
#SE writing HIGH
-> mem_sio_reg = data[11:8] em #12 (counter 10)

#12 (counter = 10)

(flag & sendcommand = true)

endcommand = (flag & !sendcommand) = false

-> counter <= 11 em #13

#SE reading HIGH
    mem_sio_reg <= zzzz em #13
#SE writing HIGH
-> mem_sio_reg = data[7:4] em #13 (counter 11)

#13 (counter = 11)

(flag & sendcommand = true)

endcommand = (flag & !sendcommand) = false

-> counter <= 12 em #13

#SE reading HIGH
    mem_sio_reg <= zzzz em #14
#SE writing HIGH
-> mem_sio_reg = data[4:0] em #14 (counter 12)




