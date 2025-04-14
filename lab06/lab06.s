.globl _start

_start:
    jal main
    li a0, 0
    li a7, 93 # exit
    ecall

main:
    jal read             # call read function for the first triangle
    la a0, input_address # a0 points to input start

    jal atoi             # convert string to integer
    mv s0, a1            # s0 = CA1

    jal skip_non_digits  # skip non-digit characters
    jal atoi             # convert string to integer
    mv s1, a1            # s1 = CO1

    jal skip_non_digits  # skip non-digit characters
    jal atoi             # convert string to integer
    mv s2, a1            # s2 = CO2

    # CA2 = (CA1 * CO2) / CO1
    mul t1, s0, s2       # t1 = CA1 * CO2
    divu s3, t1, s1      # s3 = (CA1 * CO2) / CO1 = CA2

    # convert the result (s3) to string
    mv a0, s3            # move result to a0
    la a1, result        # a1 points to result buffer
    jal ra, itoa         # convert integer to string

    jal write
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

# skip_non_digits: Skip non-digit characters in the input string
skip_non_digits:
    lbu t2, 0(a0)        # load byte from string
    li t3, 48            # ASCII '0'
    li t4, 57            # ASCII '9'
    blt t2, t3, skip_advance # if less than '0', advance
    bgt t2, t4, skip_advance # if greater than '9', advance
    ret

skip_advance:
    addi a0, a0, 1       # move to next character
    j skip_non_digits

read:
    li a0, 0             # file descriptor = 0 (stdin)
    la a1, input_address # buffer
    li a2, 24            # size - Reads 24 bytes.
    li a7, 63            # syscall read (63)
    ecall
    ret

write:
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, result       # buffer
    li a2, 4            # size - Writes 4 bytes.
    li a7, 64           # syscall write (64)
    ecall
    ret

.bss

input_address: .skip 0x18  # buffer

result: .skip 0x4