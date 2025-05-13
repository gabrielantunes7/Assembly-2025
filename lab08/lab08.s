.data
input_file: .asciz "image.pgm"
buffer: .space 56

.text
.globl _start

_start:
    jal main
    li a0, 0
    li a7, 93           # exit
    ecall

main:
    addi sp, sp, -4     # allocate space for return address
    sw ra, 0(sp)        # save return address

    la a0, buffer       # load address of buffer
    li a1, 55           # number of bytes to read (440 bits)
    la a2, input_file   # load address of input file
    jal ra, read_file   # read file (440 bits) into buffer

    

    lw ra, 0(sp)        # load return address
    addi sp, sp, 4      # deallocate space

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

# read_file: Reads a string from a given file
# Inputs: a0 = address of buffer, a1 = bytes to read, a2 = address of input file
# No output, stores the string read in buffer
read_file:
    addi sp, sp, -4     # allocate space for return address
    sw ra, 0(sp)        # save return address

    mv t0, a0            # t0 = buffer address
    mv t1, a1            # t1 = bytes to read

    # load the file descriptor for input_file in a0
    mv a0, a2           # load address of input file
    li a1, 0            # flag for read only
    li a2, 0            # mode
    li a7, 1024         # syscall open
    ecall
    mv t0, a0           # t0 = file descriptor

    # read from the file
    mv a0, t0           # a0 = file descriptor
    mv a1, t0           # a1 = buffer address
    mv a2, t1           # a2 = bytes to read
    li a7, 63           # syscall read
    ecall

    # close the file
    mv a0, t0          # a0 = file descriptor
    li a7, 57          # syscall close
    ecall

    lw ra, 0(sp)        # load return address
    addi sp, sp, 4      # deallocate space

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

# exponentiate: Calculates the value of x^n
# Input: a0 = base (x), a1 = exponent (n)
# Output: a2 = result (x^n)
exponentiate:
    li a2, 1            # a2 = result (x^n)
    beqz a1, exp_done   # if n == 0, return 1
    beqz a0, exp_done_zero  # if x == 0, return 0
    beq a0, a2, exp_done  # if x == 1, return 1
exp_loop:
    mul a2, a2, a0      # result *= x
    addi a1, a1, -1     # n--
    bnez a1, exp_loop   # if n != 0, continue loop
    j exp_done          # done
exp_done_zero:
    li a2, 0            # result = 0 (x^0 = 0)
exp_done:
    ret