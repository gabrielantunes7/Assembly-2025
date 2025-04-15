.data 
buffer: .space 1      # read function uses it
result: .space 1      # write function uses it

.text

.globl _start

_start:
    jal main
    li a0, 0
    li a7, 93           # exit
    ecall

main:
    jal read_number
    mv s0, a0           # s0 = CA1

    jal read_number
    mv s1, a0           # s1 = CO1

    jal read_number
    mv s2, a0           # s2 = CO2

    mul t1, s0, s2      # t1 = CA1 * CO2
    divu s3, t1, s1     # s3 = (CA1 * CO2) / CO1 = CA2

    mv a0, s3           # a0 = CA2
    jal itoa

    jal write

    jr ra
    
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

read:
    li a0, 0             # file descriptor = 0 (stdin)
    la a1, buffer        # buffer
    li a2, 1             # size - reads 1 byte.
    li a7, 63            # syscall read (63)
    ecall
    ret

# Reads an entire integer number (1 or 2 digits)
read_number:
    mv s4, ra
    li t0, 0             # final number (accumulator)
    li t1, 10            # base 10

read_loop:
    jal read
    lb t2, 0(a1)

    li t3, 48            # ASCII '0'
    li t4, 57            # ASCII '9'

    # if t2 < '0' or t2 > '9', finish reading
    blt t2, t3, read_done
    bgt t2, t4, read_done

    sub t2, t2, t3       # converts character to integer

    mul t0, t0, t1       # number = number * 10
    add t0, t0, t2       # number = number + new digit (t2)

    j read_loop

read_done:
    mv a0, t0            # returns in a0
    mv ra, s4
    ret

write:
    li a0, 1             # file descriptor = 1 (stdout)
    la a1, result        # buffer
    li a2, 1             # size - writes 1 byte.
    li a7, 64            # syscall write (64)
    ecall
    ret

write_result:
    mv t0, a0
    la t3, result        # t0 = result address

write_loop:
    lb t1, 0(t0)         # digit from result buffer
    li t2, 10            # ASCII '\n'
    sb t1, 0(t3)

    jal write

    beq t1, t2, write_done # if t1 == '\n', finish writing

    addi t0, t0, 1       # next character

    j write_loop

write_done:
    ret