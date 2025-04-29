# Simple calculator that performs addition, subtraction, multiplication, and division of two unsigned integers up to two digits.
# The calculator reads two numbers and the operador from the user ("n1 op n2\n"), performs the specified operation, and prints the result.
# Operator can be '+', '-', '*', or '/'.
# The result is printed as a string followed by a newline character.

.data
buffer: .space 8         # maximum 7 digits + '\n'
num1: .space 3           # maximum 2 digits + '\0'
num2: .space 3           # maximum 2 digits + '\0' 
operator: .space 2       # maximum 1 digit + '\0'
result: .space 6         # maximum 4 digits + '\n' + '\0'

.text

.globl _start

_start:
    jal main
    li a0, 0
    li a7, 93            # exit
    ecall

main:
    addi sp, sp, -4      # allocate space for 4 bytes (for ra)
    sw ra, 0(sp)         # save ra on stack
    la a0, buffer        # a0 points to input start
    li a1, 8             # a1 = maximum size of buffer
    jal ra, read_line    # call read function
    la s0, buffer        # s0 points to buffer start (used to move the pointer without losing buffer addres)
    la t0, num1          # t0 points to num1
    lb t1, 0(s0)         # t1 = buffer[0]
    sb t1, 0(t0)         # store num1[0]
    addi s0, s0, 1       # moves to next position (buffer[1])
    addi t0, t0, 1       # moves to next position (num1[1])
    lb t2, 0(s0)         # t2 = buffer[1]
    li t3, 32            # ASCII ' '
    bne t2, t3, 1f       # if buffer[1] != ' ', jump to next 1
    j 2f

1:
    sb t2, 0(t0)         # store num1[1]
    addi t0, t0, 1       # moves to next position (num1[2])
    addi s0, s0, 1       # moves to next position (buffer[2])

2:
    sb zero, 0(t0)       # store '\0' in num1
    addi s0, s0, 1       # moves to next position (buffer[2 or 3], which is the operator)
    
    la t0, operator      # t0 points to operator
    lb t1, 0(s0)         # t1 = buffer[2 or 3], operator
    sb t1, 0(t0)         # store operator
    addi s0, s0, 2       # moves to next valid position (buffer[4 or 5], first digit of num2)
    addi t0, t0, 1       # moves to next position (operator[1])
    sb zero, 0(t0)       # store '\0' in operator

    la t0, num2          # t0 points to num2
    lb t1, 0(s0)         # t1 = buffer[4 or 5], num2[0]
    sb t1, 0(t0)         # store num2[0]
    addi s0, s0, 1       # moves to next position (buffer[5 or 6])
    addi t0, t0, 1       # moves to next position (num2[1])
    lb t2, 0(s0)         # t2 = buffer[5 or 6]
    li t3, 10            # ASCII '\n'
    bne t2, t3, 1f       # if buffer[5 or 6] != '\n', jump to next 1
    j 2f

1:
    sb t2, 0(t0)         # store num2[1]
    addi t0, t0, 1       # moves to next position (num2[2])
    addi s0, s0, 1       # moves to next position (buffer[6 or 7])

2:
    sb zero, 0(t0)       # store '\0' in num2

    la a0, num1          # a0 points to num1 start
    jal ra, atoi         # convert string to integer
    mv s1, a1            # s1 = num1

    la a0, num2          # a0 points to num2 start
    jal ra, atoi         # convert string to integer
    mv s2, a1            # s2 = num2

    la t0, operator      # t0 points to operator
    lb s3, 0(t0)         # load operator

    li t0, 43            # ASCII '+'
    li t1, 45            # ASCII '-'
    li t2, 42            # ASCII '*'
    li t3, 47            # ASCII '/'

    beq s3, t0, sum      # if operator == '+', jump to sum
    beq s3, t1, subtraction  # if operator == '-', jump to subtraction
    beq s3, t2, multiplication  # if operator == '*', jump to multiplication
    beq s3, t3, division # if operator == '/', jump to division

sum:
    add a0, s1, s2       # a0 = num1 + num2
    j print_result

subtraction:
    sub a0, s1, s2       # a0 = num1 - num2
    j print_result

multiplication:
    mul a0, s1, s2       # a0 = num1 * num2
    j print_result

division:
    divu a0, s1, s2      # a0 = num1 / num2
    j print_result

print_result:
    la a1, result        # a1 points to result buffer
    jal ra, itoa         # convert integer to string
    la a0, result        # a0 points to result start
    jal ra, write_str    # write result to stdout

    lw ra, 0(sp)         # recover ra
    addi sp, sp, 4       # free stack space
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
    addi sp, sp, -20    # 16 bytes for the number + 4 bytes for ra
    sw ra, 16(sp)       # save ra on top of stack
    mv t0, a0           # copy integer to t0
    mv t1, sp           # t1 points to start of stack (temporary pointer)
    li t2, 10           # divisor 10

itoa_loop:
    beqz t0, itoa_done_loop
    remu t3, t0, t2     # t3 = t0 % 10
    addi t3, t3, 48     # convert to ASCII
    sb t3, 0(t1)        # save on stack
    addi t1, t1, 1
    divu t0, t0, t2     # t0 = t0 / 10
    j itoa_loop

itoa_done_loop:
    beqz a0, itoa_case_zero
    addi t1, t1, -1    # adjust pointer

itoa_copy:
    lbu t3, 0(t1)
    sb t3, 0(a1)
    addi a1, a1, 1
    addi t1, t1, -1
    bgeu t1, sp, itoa_copy
    j itoa_end

itoa_case_zero:
    li t3, 48
    sb t3, 0(a1)
    addi a1, a1, 1

itoa_end:
    li t3, 10
    sb t3, 0(a1)
    addi a1, a1, 1

    lw ra, 16(sp)       # recover ra
    addi sp, sp, 20     # free stack space
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