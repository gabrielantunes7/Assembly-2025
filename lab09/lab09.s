.rodata
newline: .asciz "\n"

.text
.globl atoi
.globl itoa
.globl gets
.globl puts
.globl exit
.globl linked_list_search

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
# No output, the string is stored in the buffer
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

# linked_list_search: Searches for a node that contains a value (sum of two values) in a linked list
# Input: a0 = head of linked list, a1 = value to search for
# Output: a0 = index of the node if found, otherwise -1
linked_list_search:
    addi sp, sp, -16    # allocate stack space
    sw ra, 0(sp)        # save return address

    li t0, 0            # index = 0
    mv t1, a0           # t1 = head of linked list
search_loop:
    lw t2, 0(t1)        # load current node val1
    lw t3, 4(t1)        # load current node val2
    add t4, t2, t3      # sum = val1 + val2
    beq t4, a1, found   # if sum == value to search for, found
    addi t1, t1, 8      # move to next node address (8 bytes for each node)
    lw t1, 0(t1)        # load next node address
    beqz t1, not_found  # if end of list, not found
    addi t0, t0, 1      # increment index
    j search_loop       # continue searching
found:
    mv a0, t0           # return index
    j return
not_found:
    li a0, -1           # default return value (not found)
return:
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