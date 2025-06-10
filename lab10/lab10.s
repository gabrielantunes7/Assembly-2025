.rodata
newline: .asciz "\n"

.bss
disk_buffer: .space 2 # buffer for disk number (1 byte for disk number, 1 byte for null terminator)

.text
.globl atoi
.globl itoa
.globl gets
.globl puts
.globl exit
.globl fibonacci_recursive
.globl fatorial_recursive
.globl torre_de_hanoi

# atoi: Converts a string to an integer
# Input: a0 = address of string
# Output: a0 = integer value
atoi:
    addi sp, sp, -16    # allocate stack space
    sw s0, 0(sp)        # save s0 (used in function)
    sw ra, 4(sp)        # save return address

    li s0, 1            # s0 = sign flag (1 for positive, -1 for negative)
    li t4, 0            # initialize result to 0
    mv t1, a0           # t1 = string address
    li t5, 43           # ASCII '+'
    li t6, 45           # ASCII '-'
    lbu t0, 0(t1)       # load first byte
    bne t0, t5, 1f
    addi t1, t1, 1      # skip '+'
    j atoi_loop
1:
    bne t0, t6, atoi_loop  # if not '-', continue
    addi t1, t1, 1      # skip '-'
    li s0, -1           # set negative flag
atoi_loop:
    lbu t0, 0(t1)       # load byte from string
    beqz t0, atoi_done  # if null terminator, done
    li t2, 48           # ASCII '0'
    sub t0, t0, t2      # convert ASCII to integer
    li t3, 10
    mul t4, t4, t3      # result = result * 10
    add t4, t4, t0      # result += digit
    addi t1, t1, 1      # move to next character
    j atoi_loop
atoi_done:
    mv a0, t4           # return the result
    bgt s0, zero, 1f
    mul a0, a0, s0      # if negative, negate the result
1:
    lw ra, 4(sp)        # restore return address
    lw s0, 0(sp)        # restore s0
    addi sp, sp, 16     # deallocate stack space
    ret

# itoa: Converts an integer to a string
# Input: a0 = integer value, a1 = address of buffer, a2 = base
# Output: a0 = address of buffer
itoa:
    addi sp, sp, -80    # allocate space for return address and temporary buffer in stack
    sw ra, 0(sp)        # save return address

    li t6, 1            # t6 = sign flag (1 for positive, -1 for negative)
    mv t0, a0           # t0 = integer value
    bgt t0, zero, 1f
    li t6, -1           # if value is negative, set negative flag
    mul t0, t0, t6      # also get the absolute value
1:
    mv t1, a1           # t1 = buffer address
    mv a0, a1           # a0 = buffer address (for return)
    li t2, 0            # t2 = digit counter
    mv t4, sp           
    addi t4, t4, 4      # t4 = temporary buffer address
    beqz t0, itoa_zero  # if t0 == 0, handle zero case
itoa_loop:
    rem t3, t0, a2      # t3 = t0 % a2
    divu t0, t0, a2     # t0 = t0 / a2 (remaining number)
    li t5, 10
    blt t3, t5, 1f      # if t3 < 10, convert to ASCII directly
    addi t3, t3, 87     # convert to ASCII (for base > 10)
    j 2f
1:    
    addi t3, t3, 48     # convert digit to ASCII
2:
    sb t3, 0(t4)        # store digit in temporary buffer
    addi t4, t4, 1      # move to next position in temporary buffer
    addi t2, t2, 1      # increment digit counter
    bnez t0, itoa_loop  # if t0 != 0, continue loop
itoa_done:
    mv t4, sp           # t4 = temporary buffer address
    addi t4, t4, 4      # move to start of temporary buffer
    addi t5, t2, -1     # t5 = digit counter - 1 (last valid position)
    add t4, t4, t5      # move to last valid position in temporary buffer
    bgt t6, zero, itoa_reverse  # if positive, skip negation
    li t3, 45           # ASCII '-'
    sb t3, 0(t1)        # store '-' in result buffer
    addi t1, t1, 1      # move to next position in result buffer
itoa_reverse:
    lb t3, 0(t4)        # load byte from temporary buffer
    sb t3, 0(t1)        # store byte in result buffer
    addi t2, t2, -1     # decrement digit counter
    addi t4, t4, -1     # move to next byte in temporary buffer
    addi t1, t1, 1      # move to next byte in result buffer
    bnez t2, itoa_reverse  # if digit counter != 0, continue loop
    sb zero, 0(t1)      # null terminate the string

    lw ra, 0(sp)        # restore return address
    addi sp, sp, 80     # deallocate stack space
    ret
itoa_zero:
    li t3, 48           # ASCII '0'
    sb t3, 0(t1)        # store '0' in result buffer
    addi t1, t1, 1      # move to next byte in result buffer
    sb zero, 0(t1)      # null terminate the string

    lw ra, 0(sp)        # restore return address
    addi sp, sp, 80     # deallocate stack space
    ret

# gets: Reads a string (until '\n') from stdin
# Inputs: a0 = address of buffer
# Output: a0 = address of buffer
gets:
    addi sp, sp, -16    # allocate stack space
    sw ra, 0(sp)        # save return address

    mv t0, a0           # t0 = buffer address
    mv t5, a0           # t5 = buffer address (for return)
read_loop:
    # syscall read: a0 = stdin, a1 = buffer, a2 = 1
    li a0, 0            # stdin
    mv a1, t0           # current buffer address
    li a2, 1            # reads 1 byte
    li a7, 63
    ecall

    lbu t3, 0(t0)            # byte read
    li t4, 10                # ASCII '\n'
    beq t3, t4, read_done    # if '\n', finish
    addi t0, t0, 1           # buffer++
    j read_loop
read_done:
    sb zero, 0(t0)      # null terminate the string
    mv a0, t5           # returns buffer address

    lw ra, 0(sp)        # restore return address
    addi sp, sp, 16     # deallocate stack space
    ret

# puts: Writes a string to stdout
# Input: a0 = address of string
# Output: writes the string to stdout
puts:
    addi sp, sp, -16    # allocate stack space
    sw ra, 0(sp)        # save return address

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

    # put newline
    li a0, 1            # file descriptor = stdout
    la a1, newline      # load address of newline
    li a2, 1            # write 1 byte
    li a7, 64           # syscall write
    ecall

    lw ra, 0(sp)        # restore return address
    addi sp, sp, 16     # deallocate stack space
    ret

# exit: Exits the program
# No input, no output
# This function is used to exit the program with return code 0
exit:
    li a0, 0            # return value
    li a7, 93           # syscall exit
    ecall

# fibonacci_recursive: Computes the nth Fibonacci number recursively
# Input: a0 = n (index of Fibonacci number)
# Output: a0 = Fibonacci number at index n
fibonacci_recursive:
    addi sp, sp, -16    # allocate stack space
    sw ra, 12(sp)       # save return address
    sw s1, 8(sp)        # save s1 (used for Fibonacci n - 1)
    sw s0, 4(sp)        # save s0 (used for Fibonacci n - 2)

    li t0, 1
    ble a0, zero, base_case_0   # if n <= 0, return 0
    beq a0, t0, base_case_1     # if n == 1, return 1

    mv s0, a0           # s0 = n (original value)
    addi a0, a0, -1     # a0 = n - 1
    jal fibonacci_recursive # recursive call for n - 1
    mv s1, a0           # t3 = fibonacci(n - 1)

    addi a0, s0, -2     # a0 = n - 2
    jal fibonacci_recursive # recursive call for n - 2

    add a0, a0, s1      # a0 = fibonacci(n - 1) + fibonacci(n - 2)
    j fibonacci_done
base_case_0:
    mv a0, zero         # base case: fibonacci(0) = 0
    j fibonacci_done
base_case_1:
    li a0, 1            # base case: fibonacci(1) = 1
    j fibonacci_done
fibonacci_done:
    lw ra, 12(sp)       # restore return address
    lw s1, 8(sp)        # restore s1
    lw s0, 4(sp)        # restore s0
    addi sp, sp, 16     # deallocate stack space

    ret

# fatorial_recursive: Computes the factorial of n recursively
# Input: a0 = n (number to compute factorial)
# Output: a0 = factorial of n
fatorial_recursive:
    addi sp, sp, -16    # allocate stack space
    sw ra, 12(sp)       # save return address

    li t0, 1
    beq a0, t0, fat_base_case

    sw a0, 8(sp)        # save original n
    addi a0, a0, -1     # n = n - 1
    jal fatorial_recursive  # recursive call

    lw t1, 8(sp)        # load original n
    mul a0, a0, t1      # a0 = n * fatorial(n - 1)

    j fatorial_done
fat_base_case:
    li a0, 1            # base case: fatorial(1) = 1
    j fatorial_done
fatorial_done:
    lw ra, 12(sp)       # restore return address
    addi sp, sp, 16     # deallocate stack space

    ret

# torre_de_hanoi: Solves the Tower of Hanoi problem recursively
# Input: a0 = number of disks, a1 = source peg, a2 = auxiliary peg, a3 = target peg, a4 = buffer address
# No output
torre_de_hanoi:
    addi sp, sp, -32    # allocate stack space
    sw ra, 28(sp)       # save return address
    sw a4, 24(sp)       # save buffer address
    sb a3, 20(sp)       # save target peg
    sb a2, 16(sp)       # save auxiliary peg
    sb a1, 12(sp)       # save source peg
    sw a0, 8(sp)        # save number of disks

    li t0, 1
    beq a0, t0, hanoi_base_case # if n == 1, move disk directly

    addi a0, a0, -1     # n = n - 1
    sw a0, 4(sp)        # save n - 1
    mv t1, a2           # t1 = auxiliary peg
    mv a2, a3           # a2 = target peg
    mv a3, t1           # a3 = auxiliary peg
    lw a4, 24(sp)       # a4 = buffer address
    jal torre_de_hanoi  # recursive call to move n - 1 disks from source to auxiliary peg, using target as auxiliary

    lw a0, 8(sp)        # restore number of disks
    la a1, disk_buffer  # a1 = disk buffer address
    li a2, 10           # a2 = base 10 for conversion
    jal itoa

    lbu t0, (a0)        # load disk number (converted to char) from buffer
    lbu t1, 12(sp)      # t1 = source peg
    lbu t2, 20(sp)      # t2 = target peg
    lw a0, 24(sp)       # a0 = buffer address

    sb t0, 12(a0)       # store disk number in buffer
    sb t1, 23(a0)       # store source peg in buffer
    sb t2, 38(a0)       # store target peg in buffer
    jal puts            # print the buffer ("Mover disco <disk> da torre <source> para a torre <target>")

    lw a0, 4(sp)        # restore n - 1
    lbu a1, 16(sp)      # a1 = aux (becomes source)
    lbu a2, 12(sp)      # a2 = source (becomes auxiliary)
    lbu a3, 20(sp)      # a3 = target
    lw a4, 24(sp)       # a4 = buffer address
    jal torre_de_hanoi  # recursive call to move n - 1 disks from auxiliary to target peg, using source as auxiliary

    j torre_de_hanoi_done   # jump to end
hanoi_base_case:
    lw t4, 24(sp)       # load buffer address
    
    li t0, 49           # ASCII '1'
    sb t0, 12(t4)       # store '1' in buffer (disk number)

    lbu t1, 12(sp)      # load source peg
    lbu t3, 20(sp)      # load target peg

    sb t1, 23(t4)       # store source peg in buffer
    sb t3, 38(t4)       # store target peg in buffer

    mv a0, t4           # a0 = buffer address
    jal puts            # print the buffer ("Mover disco 1 da torre <source> para a torre <target>")

    j torre_de_hanoi_done
torre_de_hanoi_done:
    lw ra, 28(sp)       # restore return address
    lw a4, 24(sp)       # restore buffer address
    lb a3, 20(sp)       # restore target peg
    lb a2, 16(sp)       # restore auxiliary peg
    lb a1, 12(sp)       # restore source peg
    lw a0, 8(sp)        # restore number of disks
    addi sp, sp, 32     # deallocate stack space

    ret