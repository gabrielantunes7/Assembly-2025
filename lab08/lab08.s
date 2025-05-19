.data
input_file: .asciz "image.pgm"
buffer: .space 440      # bits assembled as bytes
msg1: .space 32         # 31 characters + '\0'
msg2_enc: .space 25     # 24 characters + '\0'
msg2_dec: .space 25
header_buf: .space 64   # temporary buffer for header

.text
.globl _start

_start:
    jal main
    li a0, 0
    li a7, 93           # exit
    ecall

main:
    addi sp, sp, -16    # allocate space for return address
    sw ra, 0(sp)        # save return address

    # open input file
    la a0, input_file   # load address of input file
    li a1, 2            # flag for read/write
    li a2, 0            # mode
    li a7, 1024         # syscall open
    ecall
    mv s0, a0           # s0 = file descriptor

    # read header (3 newlines)
    li t0, 0            # newline counter
    la t1, header_buf   # t1 = address of buffer for header
1:
    mv a0, s0           # file descriptor
    lw a1, t1           # buffer address
    li a2, 1            # read 1 byte
    li a7, 63           # syscall read
    ecall

    beqz a0, header_done  # if read returns 0 (eof), done
    lb t2, 0(t1)        # load byte from buffer
    li t4, 10           # ASCII newline
    addi t1, t1, 1      # move to next byte in buffer
    beq t2, t4, inc_newline  # if byte is newline, increment counter
    j 1b
inc_newline:
    addi t0, t0, 1      # increment newline counter
    li t3, 3
    beq t0, t3, header_done  # if 3 newlines, done
    j 1b                # else, continue reading
header_done:
    la t2, header_buf   # t2 = address of header buffer
    sub s1, t1, t2      # s1 = size of header (t1 - header_buf)

    # read first 440 LSB bits into bytes
    lw a0, s0           # file descriptor
    la a1, buffer       # buffer address
    li a2, 440          # read 440 bytes
    li a7, 63           # syscall read
    ecall

    # get msg1 (assemble each of the 31 bytes using 8 bits)
    la t0, buffer       # t0 = address of buffer
    la t1, msg1         # t1 = address of msg1
    li t2, 31           # number of chars to process
1:
    li t3, 8            # number of bits to process
    li t4, 0            # initialize msg1 char
2:
    lb t5, 0(t0)        # load byte from buffer
    andi t5, t5, 1      # get LSB
    slli t4, t4, 1      # shift msg1 char left
    or t4, t4, t5       # put LSB in msg1 char
    addi t0, t0, 1      # move to next pixel in buffer
    addi t3, t3, -1     # decrement bit counter
    bnez t3, 2b         # if bits left, continue
    sb t4, 0(t1)        # else, store msg1 char
    addi t1, t1, 1      # move to next char in msg1
    addi t2, t2, -1     # decrement char counter
    bnez t2, 1b         # if chars left, continue
    sb zero, 0(t1)      # else, null terminate msg1

    # get msg2 (same thing, but 24 bytes)
    la t1, msg2_enc     # t1 = address of msg2
    li t2, 24           # number of chars to process
1:
    li t3, 8            # number of bits to process
    li t4, 0            # initialize msg2 char
2:
    lb t5, 0(t0)        # load byte from buffer
    andi t5, t5, 1      # get LSB
    slli t4, t4, 1      # shift msg2 char left
    or t4, t4, t5       # put LSB in msg2 char
    addi t0, t0, 1      # move to next pixel in buffer
    addi t3, t3, -1     # decrement bit counter
    bnez t3, 2b         # if bits left, continue
    sb t4, 0(t1)        # else, store msg2 char
    addi t1, t1, 1      # move to next char in msg2
    addi t2, t2, -1     # decrement char counter
    bnez t2, 1b         # if chars left, continue
    sb zero, 0(t1)      # else, null terminate msg2

    la a0, msg1         # a0 = address of msg1
    jal write_str       # write msg1 to stdout

    mv a0, s0           # file descriptor
    li a7, 57           # syscall close
    ecall

    lw ra, 0(sp)        # load return address
    addi sp, sp, 16     # deallocate space

    ret

# atoi: Converts a string to an integer
# Input: a0 = address of string
# Output: a1 = integer value
atoi:
    li a1, 0             # initialize result to 0
    mv t1, a0            # t1 = string address
atoi_loop:
    lbu t0, 0(t1)        # load byte from string
    beqz t0, atoi_done   # if null terminator, done
    li t2, 48            # ASCII '0'
    sub t0, t0, t2       # convert ASCII to integer
    li t3, 10
    mul a1, a1, t3       # result = result * 10
    add a1, a1, t0       # result += digit
    addi t1, t1, 1       # move to next character
    j atoi_loop
atoi_done:
    ret

# itoa: Converts an integer to a string
# Input: a0 = integer value, a1 = address of buffer
# No output, the string is stored in the buffer
itoa:
   mv t0, a0            # t0 = integer value
   mv t1, a1            # t1 = buffer address
   li t2, 0             # t2 = digit counter
   addi sp, sp, -64     # allocate space for temporary buffer in stack
   mv t4, sp            # t4 = temporary buffer address
   beqz t0, itoa_zero   # if t0 == 0, handle zero case
itoa_loop:
    li t5, 10           # divisor
    rem t3, t0, t5      # t3 = t0 % 10 (last digit)
    divu t0, t0, t5     # t0 = t0 / 10 (remaining number)

    addi t3, t3, 48     # convert digit to ASCII
    sb t3, 0(t4)        # store digit in temporary buffer
    addi t4, t4, 1      # move to next position in temporary buffer
    addi t2, t2, 1      # increment digit counter

    bnez t0, itoa_loop  # if t0 != 0, continue loop
itoa_done:
    mv t4, sp           # t4 = temporary buffer address
    addi t5, t2, -1     # t5 = digit counter - 1 (last valid position)
    add t4, t4, t5      # move to last valid position in temporary buffer
itoa_reverse:
    lb t3, 0(t4)        # load byte from temporary buffer
    sb t3, 0(t1)        # store byte in result buffer
    addi t2, t2, -1     # decrement digit counter
    addi t4, t4, -1     # move to next byte in temporary buffer
    addi t1, t1, 1      # move to next byte in result buffer
    bnez t2, itoa_reverse # if digit counter != 0, continue loop

    sb zero, 0(t1)      # null terminate the string
    addi sp, sp, 64     # deallocate stack space
    ret
itoa_zero:
    li t3, 48           # ASCII '0'
    sb t3, 0(t1)        # store '0' in result buffer
    addi t1, t1, 1      # move to next byte in result buffer
    sb zero, 0(t1)      # null terminate the string
    addi sp, sp, 64     # deallocate stack space
    ret

# write_str: Writes a string to stdout
# Input: a0 = address of string
# Output: writes the string to stdout
write_str:
    mv t0, a0        # t0 = string[0]
count_loop:
    lbu t1, 0(t0)    # gets byte from string
    beqz t1, write   # if byte == 0 ('\0'), end of string
    addi t0, t0, 1   # next position
    j count_loop
write:
    sub a2, t0, a0   # a2 = string size (t0 - a0)
    mv a1, a0        # a1 = buffer (string[0])
    li a0, 1         # a0 = file descriptor = stdout (1)
    li a7, 64        # syscall write
    ecall
    ret