.data
buffer: .space 6 # maximum 5 digits + '\n'
side1: .space 3 # maximum 2 digits + '\0'
side2: .space 3 # maximum 2 digits + '\0'
side3: .space 3 # maximum 2 digits + '\0'
result: .space 5 # maximum 3 digits + '\n' + '\0'

.text

.globl _start

_start:
    jal main
    li a0, 0
    li a7, 93            # exit
    ecall

main:
    # buffer is going to be "side1 side2\n", side1 and side2 can be 1 or 2 bytes (digits)
    la a0, buffer        # a0 points to input start
    li a1, 6             # a1 = maximum size of buffer
    jal ra, read_line    # call read function for the first triangle
    la s4, buffer        # s4 points to buffer start

    la t1, side1         # t1 points to side1
    lb t2, 0(s4)         # side1[0] = buffer[0]
    sb t2, 0(t1)         # store side1[0]
    addi s4, s4, 1       # moves to next position (buffer[1])
    addi t1, t1, 1       # moves to next position (side1[1])
    lb t3, 0(s4)         # t3 = buffer[1]
    li t5, 32            # ASCII ' '
    bne t3, t5, else     # if buffer[1] == ' ', jump to cont
    j cont

else:
    sb t3, 0(t1)         # store side1[1]
    addi s4, s4, 1       # moves to next position (buffer)
    addi t1, t1, 1       # moves to next position (side1)

cont:
    addi s4, s4, 1       # moves to next position (buffer)
    li t3, 0             # t3 = '\0'
    sb t3, 0(t1)         # store '\0' in side1

    la a0, side1         # a0 points to side1 start

    jal atoi             # convert string to integer
    mv s0, a1            # s0 = CA1

    la t1, side2         # t1 points to side2
    lb t2, 0(s4)         # side2[0] = next valid buffer position
    sb t2, 0(t1)         # store side2[0]
    addi s4, s4, 1       # moves to next position (buffer)
    addi t1, t1, 1       # moves to next position (side2[1])
    lb t3, 0(s4)         # t3 = next buffer position
    li t5, 10            # ASCII '\n'
    bne t3, t5, else2    # if t3 == '\n', jump to cont2
    j cont2

else2:
    sb t3, 0(t1)         # store side2[1]
    addi t1, t1, 1       # move to next position (side2)

cont2:
    li t3, 0             # t3 = '\0'
    sb t3, 0(t1)         # store '\0' in side2

    la a0, side2         # a0 points to side2 start

    jal atoi             # convert string to integer
    mv s1, a1            # s1 = CO1

    la a0, buffer        # a0 points to buffer start
    li a1, 6             # a1 = maximum size of buffer
    jal ra, read_line    # call read function for the second triangle
    la s4, buffer        # s4 points to buffer start

    la t1, side3         # t1 points to side3
    lb t2, 0(s4)         # side3[0] = buffer[0]
    sb t2, 0(t1)         # store side3[0]
    addi s4, s4, 1       # moves to next position (buffer[1])
    addi t1, t1, 1       # moves to next position (side3[1])
    lb t3, 0(s4)         # t3 = buffer[1]
    bne t3, t5, else3    # if buffer[1] == '\n', jump to cont3
    j cont3

else3:
    sb t3, 0(t1)         # store side3[1]
    addi t1, t1, 1       # move to next position (side3)

cont3:
    addi s4, s4, 1       # moves to next position (buffer)
    li t3, 0             # t3 = '\0'
    sb t3, 0(t1)         # store '\0' in side3

    la a0, side3         # a0 points to side3 start

    jal atoi             # convert string to integer
    mv s2, a1            # s2 = CO2

    mul t1, s0, s2      # t1 = CA1 * CO2
    divu s3, t1, s1     # s3 = (CA1 * CO2) / CO1 = CA2

    mv a0, s3           # a0 = CA2
    la a1, result
    jal itoa

    la a0, result       # a0 = pointer for result string
    jal ra, write_str   # write result to stdout
    ret

# atoi: Converts a string to an integer
# Input: a0 = address of string
# Output: a1 = integer value
atoi:
    li a1, 0             # initialize result to 0

atoi_loop:
    lbu t0, 0(a0)        # load byte from string
    beqz t0, atoi_done   # if null terminator, done
    li t2, 48            # ASCII '0'
    sub t0, t0, t2       # convert ASCII to integer
    li t6, 10
    mul a1, a1, t6       # result = result * 10
    add a1, a1, t0       # result += digit
    addi a0, a0, 1       # move to next character
    j atoi_loop

atoi_done:
    ret

# itoa: Converts an integer to a string
# Input: a0 = integer value, a1 = address of buffer
# Output: a1 = string ended in '\n'
itoa:
    mv t0, a0            # copy integer to t0
    addi sp, sp, -16     # allocate stack space
    mv t1, sp            # t1 points to stack (temporary pointer)
    li t2, 10            # divisor for base 10

itoa_loop:
    beqz t0, itoa_done_loop
    remu t3, t0, t2      # remainder (digit)
    addi t3, t3, 48      # convert to ASCII
    sb t3, 0(t1)         # store digit in buffer
    addi t1, t1, 1
    divu t0, t0, t2      # divide by 10
    j itoa_loop

itoa_done_loop:
    beqz a0, itoa_case_zero
    addi t1, t1, -1      # adjust pointer to first position in stack
    itoa_copy:
        lbu t3, 0(t1)    # load byte from stack
        sb t3, 0(a1)     # store in buffer
        addi a1, a1, 1   # move to next position in buffer
        addi t1, t1, -1  # move to next position in stack
        bgeu t1, sp, itoa_copy # continue until stack pointer (number has ended)
    j itoa_end

itoa_case_zero:
    li t3, 48            # ASCII '0'
    sb t3, 0(a1)         # store '0' in buffer
    addi a1, a1, 1       # move to next position in buffer

itoa_end:
    li t3, 10            # ASCII '\n'
    sb t3, 0(a1)         # store '\n' in buffer
    addi a1, a1, 1       # move to next position in buffer
    addi sp, sp, 16      # deallocate stack space
    ret

# read_line: Reads a string (line) from stdin
# Inputs: a0 = address of buffer, a1 = maximum size of buffer
# Output: a1 = number of bytes read, saves the line read in buffer
read_line:
    mv t0, a0           # t0 = buffer address
    mv t1, a1           # t1 = bytes remaining
    li t2, 0            # t2 = bytes read

read_loop:
    beqz t1, read_done  # if no space left, done

    # syscall read: a0 = stdin, a1 = buffer, a2 = 1
    li a0, 0            # stdin
    mv a1, t0           # current buffer address
    li a2, 1            # reads 1 byte
    li a7, 63
    ecall

    beq a0, zero, read_done  # EOF
    lb t3, 0(t0)             # byte read
    addi t2, t2, 1           # total += 1
    addi t0, t0, 1           # buffer++
    addi t1, t1, -1          # space remaining--

    li t4, 10                # ASCII '\n'
    beq t3, t4, read_done    # if '\n', finish

    j read_loop

read_done:
    mv a1, t2                # returns bytes read
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
    li a1, 1         # file descriptor = 1 (stdout)
    mv a1, a0        # a1 = buffer (string[0])
    li a0, 1         # a0 = stdout
    li a7, 64        # syscall write
    ecall
    ret