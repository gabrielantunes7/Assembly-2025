.data
buffer: .space 6        # max 5 characters + '\0'
sgn1: .space 2          # 1 character + '\0'
sgn2: .space 2          # 1 character + '\0'
sgn3: .space 2          # 1 character + '\0'
exp1: .space 4          # max 3 digits + '\0'
exp2: .space 4          # max 3 digits + '\0'
exp3: .space 4          # max 3 digits + '\0'
lower: .space 4         # max 3 digits + '\0'
upper: .space 4         # max 3 digits + '\0'
result: .space 32       # max 30 digits + '\n' + '\0' (estimating)
newline: .byte 10, 0

.text
.globl _start

_start:
    jal main
    li a0, 0
    li a7, 93           # exit
    ecall

main:
    # first: read 3 lines and store each of the signals and exponents
    # then read the line containing the integration limits
    addi sp, sp, -4     # allocate space for return address
    sw ra, 0(sp)        # save return address

    la a0, buffer       # a0 points to input start
    li a1, 6            # a1 = maximum size of buffer
    jal ra, read_line
    la a2, sgn1         # a2 points to signal buffer
    la a3, exp1         # a3 points to exponent buffer
    jal ra, read_polynomial # read first polynomial

    la a0, sgn1
    jal ra, write_str

    la a0, exp1
    jal ra, write_str

    la a0, buffer       # a0 points to input start
    li a1, 6            # a1 = maximum size of buffer
    jal ra, read_line
    la a2, sgn2         # a2 points to signal buffer
    la a3, exp2         # a3 points to exponent buffer
    jal ra, read_polynomial # read second polynomial

    la a0, sgn2
    jal ra, write_str

    la a0, exp2
    jal ra, write_str

    la a0, buffer       # a0 points to input start
    li a1, 6            # a1 = maximum size of buffer
    jal ra, read_line
    la a2, sgn3         # a2 points to signal buffer
    la a3, exp3         # a3 points to exponent buffer
    jal ra, read_polynomial # read third polynomial

    la a0, sgn3
    jal ra, write_str

    la a0, exp3
    jal ra, write_str

    la a0, buffer       # a0 points to input start
    li a1, 6            # a1 = maximum size of buffer
    jal ra, read_line
    la a2, lower        # a2 points to lower limit buffer
    la a3, upper        # a3 points to upper limit buffer
    jal ra, read_limits # read integration limits

    la a0, lower
    jal ra, write_str

    la a0, upper
    jal ra, write_str

    la a0, newline
    jal ra, write_str

    # now: convert exponents to integers and store them in s0, s1, s2
    # also convert integration limits to integers and store them in s4 and s5

    la a0, exp1         # a0 points to first exponent buffer
    jal ra, atoi        # convert first exponent to integer
    mv s0, a1           # s0 = first exponent (integer)

    la a0, exp2         # a0 points to second exponent buffer
    jal ra, atoi        # convert second exponent to integer
    mv s1, a1           # s1 = second exponent (integer)

    la a0, exp3         # a0 points to third exponent buffer
    jal ra, atoi        # convert third exponent to integer
    mv s2, a1           # s2 = third exponent (integer)

    la a0, lower        # a0 points to lower limit buffer
    jal ra, atoi        # convert lower limit to integer
    mv s4, a1           # s4 = lower limit (integer)

    la a0, upper        # a0 points to upper limit buffer
    jal ra, atoi        # convert upper limit to integer
    mv s5, a1           # s5 = upper limit (integer)

    # calculate the result of the integration for each polynomial

    mv a0, s5
    addi s0, s0, 1      # exp1 + 1
    mv a1, s0
    jal ra, exponentiate # calculate upper^s0
    divu t0, a2, a1     # t0 = (upper limit ^ (exp1 + 1)) / (exp1 + 1)
    mv a0, s4
    jal ra, exponentiate # calculate lower^s0
    divu t1, a2, a1     # t1 = (lower limit ^ (exp1 + 1)) / (exp1 + 1)
    sub t0, t0, t1      # t0 = (upper limit ^ (exp1 + 1)) / (exp1 + 1) - (lower limit ^ (exp1 + 1)) / (exp1 + 1)
    li s6, -1
    la a0, sgn1
    lbu t2, 0(a0)       # load first signal character
    li s8, 43           # ASCII '+'
    beq t2, s8, 1f      # if t0 >= 0, jump to next 1
    mul t0, t0, s6      # t0 = -t0
1:
    mv a0, s5
    addi s1, s1, 1      # exp2 + 1
    mv a1, s1
    jal ra, exponentiate # calculate upper^s1
    divu t1, a2, a1     # t1 = (upper limit ^ (exp2 + 1)) / (exp2 + 1)
    mv a0, s4
    jal ra, exponentiate # calculate lower^s1
    divu t2, a2, a1     # t2 = (lower limit ^ (exp2 + 1)) / (exp2 + 1)
    sub t1, t1, t2      # t1 = (upper limit ^ (exp2 + 1)) / (exp2 + 1) - (lower limit ^ (exp2 + 1)) / (exp2 + 1)
    la a0, sgn2
    lbu t3, 0(a0)       # load second signal character
    beq t3, s8, 1f      # if t1 >= 0, jump to next 1
    mul t1, t1, s6      # t1 = -t1
1:
    mv a0, s5
    addi s2, s2, 1      # exp3 + 1
    mv a1, s2
    jal ra, exponentiate # calculate upper^s2
    divu t2, a2, a1     # t2 = (upper limit ^ (exp3 + 1)) / (exp3 + 1)
    mv a0, s4
    jal ra, exponentiate # calculate lower^s2
    divu t3, a2, a1     # t3 = (lower limit ^ (exp3 + 1)) / (exp3 + 1)
    sub t2, t2, t3      # t2 = (upper limit ^ (exp3 + 1)) / (exp3 + 1) - (lower limit ^ (exp3 + 1)) / (exp3 + 1)
    la a0, sgn3
    lbu t4, 0(a0)       # load third signal character
    beq t4, s8, 1f      # if t2 >= 0, jump to next 1
    mul t2, t2, s6      # t2 = -t2
1:
    # now: sum all of the results and store them in a0, convert to string and print
    add a0, t0, t1      # a0 = t0 + t1
    add a0, a0, t2      # a0 = t0 + t1 + t2
    la a1, result       # a1 points to result buffer
    jal ra, itoa        # convert integer to string
    la a0, result       # a0 points to result buffer
    jal ra, write_str   # write result to stdout

    lw ra, 0(sp)        # load return address
    addi sp, sp, 4      # deallocate stack space
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
    li t3, 0             # ASCII '\0' (null terminator)
    sb t3, 0(a1)         # store '\0' in buffer
    addi sp, sp, 16      # deallocate stack space
    ret

# read_line: Reads a string (line) from stdin
# Inputs: a0 = address of buffer, a1 = maximum size of buffer
# Output: a0 = address of buffer, a1 = number of bytes read
read_line:
    mv t0, a0           # t0 = buffer address
    mv t5, a0           # t5 = buffer address (for writing)
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
    mv a0, t5                # returns buffer address
    mv a1, t2                # returns bytes read
    ret

# read_polynomial: Reads a polynomial from stdin
# Input: a0 = address of buffer, a1 = maximum size of buffer,
# a2 = address of signal buffer, a3 = address of exponent buffer
# No output
# The polynomial is "signal exponent"; example: "- 2" = -x^2
read_polynomial:
    mv t6, a0               # t6 = buffer address
    lbu t0, 0(t6)           # t0 = first character of buffer
    sb t0, 0(a2)            # store first character (signal) in signal buffer
    addi a2, a2, 1          # move to next character (signal buffer)
    sb zero, 0(a2)          # null terminate signal string
    addi t6, t6, 2          # move to next valid character (buffer[1] = ' ')
    li s1, 10               # ASCII '\n'
read_exponent:
    lbu t0, 0(t6)           # t0 = first character of the exponent
    beq t0, s1, read_done_exponent # if '\n', done
    beqz t0, read_done_exponent # if null terminator, done
    sb t0, 0(a3)            # store exponent in exponent buffer
    addi t6, t6, 1          # move to next character
    addi a3, a3, 1          # move to next position in exponent buffer
    j read_exponent
read_done_exponent:
    sb zero, 0(a3)          # null terminate exponent string
    ret

# read_limits: Reads the integration limits from stdin
# Input: a0 = address of buffer, a1 = maximum size of buffer,
# a2 = address of lower limit buffer, a3 = address of upper limit buffer
# No output
# The limits are "lower upper"; example: "0 1" = [0, 1]
read_limits:
    lbu t0, 0(a0)           # t0 = first character of buffer
    sb t0, 0(a2)            # store first character (lower limit) in lower limit buffer
    addi a0, a0, 1          # move to next character in buffer
    addi a2, a2, 1          # move to next position in lower limit buffer
    li s1, 10               # ASCII '\n'
    li s2, 32               # ASCII ' '
read_lower_limit:
    lbu t0, 0(a0)           # t0 = character of lower limit
    beq t0, s2, read_done_lower_limit # if space, done
    beq t0, s1, read_done_lower_limit # if '\n', done
    beqz t0, read_done_lower_limit # if null terminator, done
    sb t0, 0(a2)            # store lower limit in lower limit buffer
    addi a0, a0, 1          # move to next character in buffer
    addi a2, a2, 1          # move to next position in lower limit buffer
    j read_lower_limit
read_done_lower_limit:
    sb zero, 0(a2)          # null terminate lower limit string
    addi a0, a0, 1          # move to next character in buffer
    lbu t0, 0(a0)           # t0 = first character of buffer
    sb t0, 0(a3)            # store first character (upper limit) in upper limit buffer
    addi a0, a0, 1          # move to next character in buffer
    addi a3, a3, 1          # move to next position in upper limit buffer
read_upper_limit:
    lbu t0, 0(a0)           # t0 = character of upper limit
    beq t0, s1, read_done_upper_limit # if '\n', done
    beqz t0, read_done_upper_limit # if null terminator, done
    sb t0, 0(a3)            # store upper limit in upper limit buffer
    addi a0, a0, 1          # move to next character in buffer
    addi a3, a3, 1          # move to next position in upper limit buffer
    j read_upper_limit
read_done_upper_limit:
    sb zero, 0(a3)          # null terminate upper limit string
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
    beqz a0, exp_done   # if x == 0, return 0
exp_loop:
    mul a2, a2, a0      # result *= x
    addi a1, a1, -1     # n--
    bnez a1, exp_loop   # if n != 0, continue loop
exp_done:
    ret