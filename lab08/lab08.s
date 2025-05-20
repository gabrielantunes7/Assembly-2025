.data
input_file: .asciz "image.pgm"
buffer: .space 4109     # buffer for reading the file
msg1: .space 32         # 31 characters + '\0'
# Message 1 is: "Length is the key. Allan Turing", which means the key for the Caesar cipher is 12
msg2_enc: .space 25     # 24 characters + '\0'
msg2_dec: .space 25
header_buf: .space 64   # temporary buffer for header
newline: .asciz "\n"

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

    # read the input file
    mv a0, s0           # file descriptor
    la a1, buffer       # buffer address
    li a2, 4109         # read 4109 bytes (header, 13 bytes + image, 4096 bytes)
    li a7, 63           # syscall read
    ecall

    # get msg1 (assemble each of the 31 bytes using 8 bits)
    la t0, buffer       # t0 = address of buffer
    addi t0, t0, 13     # skip the header (13 bytes)
    la t1, msg1         # t1 = address of msg1
    li t2, 31           # number of chars to process
1:
    li t3, 8            # number of bits to process
    li t4, 0            # initialize msg1 char
2:
    lbu t5, 0(t0)       # load byte from buffer
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
    lbu t5, 0(t0)       # load byte from buffer
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

    la a0, msg2_enc     # a0 = address of msg2
    jal write_str       # write msg2 encoded to stdout

    la a0, newline
    jal write_str

    # decode msg2
    la t0, msg2_enc     # t0 = address of msg2
    la t1, msg2_dec     # t1 = address of msg2_dec
    li s1, 65           # ASCII 'A'
    li s2, 90           # ASCII 'Z'
    li s3, 97           # ASCII 'a'
    li s4, 122          # ASCII 'z'
    li s5, 12           # key for Caesar cipher
    li t6, 10           # ASCII '\n'
1:
    lbu t2, 0(t0)       # load byte of msg2
    beqz t2, msg2_done  # if null terminator, done
    beq t2, t6, msg2_done # if '\n', done
    bltu t2, s1, not_alpha # if < 'A', not alpha
    bgtu t2, s4, not_alpha # if > 'z', not alpha
    bleu t2, s2, upper_case # if <= 'Z', upper case; else, lower case
lower_case:
    sub t4, t2, s3      # t4 = t2 - 'a'
    bltu t4, s5, wrap_lower # wrap around if needed
    sub t2, t2, s5      # t2 = t2 - key
    sb t2, 0(t1)        # store decoded char
    addi t0, t0, 1      # move to next byte in msg2
    addi t1, t1, 1      # move to next char in msg2_dec
    j 1b
wrap_lower:
    sub t5, s5, t4      # t5 = key - t4
    addi t5, t5, -1     # adjust for wrap around
    sub t2, s4, t5      # t2 = 'z' - t5 (decoded char)
    sb t2, 0(t1)        # store decoded char
    addi t0, t0, 1      # move to next byte in msg2
    addi t1, t1, 1      # move to next char in msg2_dec
    j 1b
upper_case:
    sub t4, t2, s1      # t4 = t2 - 'A'
    bltu t4, s5, wrap_upper # wrap around if needed
    sub t2, t2, s5      # t2 = t2 - key
    sb t2, 0(t1)        # store decoded char
    addi t0, t0, 1      # move to next byte in msg2
    addi t1, t1, 1      # move to next char in msg2_dec
    j 1b
wrap_upper:
    sub t5, s5, t4      # t5 = key - t4
    addi t5, t5, -1     # adjust for wrap around
    sub t2, s2, t5      # t2 = 'Z' - t5 (decoded char)
    sb t2, 0(t1)        # store decoded char
    addi t0, t0, 1      # move to next byte in msg2
    addi t1, t1, 1      # move to next char in msg2_dec
    j 1b
not_alpha:
    sb t2, 0(t1)        # store non-alpha char
    addi t0, t0, 1      # move to next byte in msg2 (non-alpha char is unchanged)
    addi t1, t1, 1      # move to next char in msg2_dec
    j 1b
msg2_done:
    sb zero, 0(t1)      # null terminate msg2_dec

# put msg2_dec in the last 192 bytes of buffer
    la t0, buffer       # t0 = address of buffer
    addi t0, t0, 3917   # skip to last 192 bytes of buffer (for msg2)
    la t1, msg2_dec     # t1 = address of msg2_dec
    li s0, 2            # divisor
    li s2, 24           # number of chars to process
1:
    li s1, 8            # number of bits to process in each char
    lbu t4, 0(t1)       # load byte of msg2_dec
2:
    lbu t3, 0(t0)       # load byte of buffer
    andi t3, t3, 0xFE   # clear LSB (byte and 0b11111110)
    remu t5, t4, s0     # get LSB of msg2_dec
    srli t4, t4, 1      # shift msg2_dec right by 1
    add t3, t3, t5      # add LSB of msg2_dec to buffer
    sb t3, 0(t0)        # store modified byte in buffer
    addi t0, t0, 1      # move to next byte in buffer
    addi s1, s1, -1     # decrement bit counter
    bnez s1, 2b         # if bits left, continue
    addi s2, s2, -1     # decrement char counter
    bnez s2, 1b         # if chars left, continue

# show the changed image
    li a0, 0
    li a1, 0
    li s0, 64
show_image:
    bgtu a0, s0, new_line

    mv a0, s0           # file descriptor
    li a7, 57           # syscall close
    ecall

    lw ra, 0(sp)        # load return address
    addi sp, sp, 16     # deallocate space

    ret

# write_str: Writes a string to stdout
# Input: a0 = address of string
# Output: writes the string to stdout
write_str:
    mv t0, a0           # t0 = string[0]
count_loop:
    lbu t1, 0(t0)       # gets byte from string
    beqz t1, write      # if byte == 0 ('\0'), end of string
    addi t0, t0, 1      # next position
    j count_loop
write:
    sub a2, t0, a0      # a2 = string size (t0 - a0)
    mv a1, a0           # a1 = buffer (string[0])
    li a0, 1            # a0 = file descriptor = stdout (1)
    li a7, 64           # syscall write
    ecall
    ret