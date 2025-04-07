.globl _start

_start:
    jal main
    li a0, 0
    li a7, 93 # exit
    ecall

main:
    jal read             # call read function
    la t0, input_address # t0 points to input start

    li t3, 10            # used in multiplications ahead

    # Processing point A

    # A.x: characters in 1 and 2
    lb t1, 1(t0)         # t1 = tens
    lb t2, 2(t0)         # t2 = units
    addi t1, t1, -48     # convert ASCII to int
    addi t2, t2, -48
    # A.x = t1 * 10 + t2
    mul t1, t1, t3       # t1 = tens * 10
    add s0, t1, t2       # s0 = A.x

    # A.y: characters in 4 and 5
    lb t1, 4(t0)         # t1 = tens
    lb t2, 5(t0)         # t2 = units
    addi t1, t1, -48     # convert ASCII to int
    addi t2, t2, -48
    # A.y = t1 * 10 + t2
    mul t1, t1, t3       # t1 = tens * 10
    add s1, t1, t2       # s1 = A.y

    # Processing point B

    # B.x: characters in 9 and 10
    lb t1, 9(t0)         # t1 = tens
    lb t2, 10(t0)        # t2 = units
    addi t1, t1, -48     # convert ASCII to int
    addi t2, t2, -48
    # B.x = t1 * 10 + t2
    mul t1, t1, t3       # t1 = tens * 10
    add s2, t1, t2       # s2 = B.x

    # B.y: characters in 12 and 13
    lb t1, 12(t0)        # t1 = tens
    lb t2, 13(t0)        # t2 = units
    addi t1, t1, -48     # convert ASCII to int
    addi t2, t2, -48
    # B.y = t1 * 10 + t2
    mul t1, t1, t3       # t1 = tens * 10
    add s3, t1, t2       # s3 = B.y

    # Processing point C

    # C.x: characters in 17 and 18
    lb t1, 17(t0)        # t1 = tens
    lb t2, 18(t0)        # t2 = units
    addi t1, t1, -48     # convert ASCII to int
    addi t2, t2, -48
    # C.x = t1 * 10 + t2
    mul t1, t1, t3       # t1 = tens * 10
    add s4, t1, t2       # s4 = C.x

    # C.y: characters in 20 and 21
    lb t1, 20(t0)        # t1 = tens
    lb t2, 21(t0)        # t2 = units
    addi t1, t1, -48     # convert ASCII to int
    addi t2, t2, -48
    # C.y = t1 * 10 + t2
    mul t1, t1, t3       # t1 = tens * 10
    add s5, t1, t2       # s5 = C.y

    # Calculating the sides

    # Horizontal: B.x - A.x -> s6
    sub s6, s2, s0       # s6 = B.x - A.x

    # Vertical: C.y - A.y -> s7
    sub s7, s5, s1       # s7 = C.y - A.y

    # Sum of the squares: s6² + s7² = s8
    mul t3, s6, s6       # t3 = s6² (s6 * s6)
    mul t4, s7, s7       # t4 = s7² (s7 * s7)
    add s8, t3, t4       # s8 = s6² + s7²

    # Aproximating the square root of s8 -> s9

    # if s8 = 0, sqrt = 0
    beq s8, zero, sqrt_done

    # initial aproximation: s9 = s8 / 2
    li t5, 2
    div s9, s8, t5       # s9 = s8 / 2
    li s10, 10           # number of iterations (10)

sqrt_loop:
    div t6, s8, s9
    add t6, s9, t6       # t7 = s9 + (s8 / s9)
    li t5, 2             
    div s9, t6, t5       # s9 = (k + y/k) / 2
    addi s10, s10, -1    # decrement the number of iterations
    bnez s10, sqrt_loop

sqrt_done:
    # s9 = aproximation of sqrt(s8)
    # Convert integer in s9 to 3 digit string
    la t0, result        # t0 points to the result buffer

    # hundreds: s9 / 100
    li t5, 100
    div t6, s9, t5       # t6 = hundreds digit
    rem t4, s9, t5       # t4 = remainder (s9 % 100)

    # tens: t4 / 10
    li t5, 10
    div t1, t4, t5       # t1 = tens digit
    rem t2, t4, t5       # t2 = remainder (t4 % 10) and units digit

    li t3, 48            # ASCII '0'
    add t6, t6, t3       # hundreds digit to ASCII
    sb t6, 0(t0)         # store hundreds digit in result buffer
    addi t0, t0, 1       # t0 points to second position of result buffer

    add t1, t1, t3       # tens digit to ASCII
    sb t1, 0(t0)         # store tens digit in result buffer
    addi t0, t0, 1       # t0 points to third position of result buffer

    add t2, t2, t3       # units digit to ASCII
    sb t2, 0(t0)         # store units digit in result buffer
    addi t0, t0, 1       # t0 points to fourth position of result buffer

    li t4, 10            # ASCII '\n'
    sb t4, 0(t0)         # store '\n' in result buffer

    jal write

    jr ra

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