# Write a piece of code that determines the highest value in an array of 32 bit
# unsigned integers which starting address is given in a2
# At the start, a3 contains the number of values present in the array (a3 > 0);
# At the end, a0 must contain the highest value and a1 must contain the address
# for the position of the highest value

maximum_unsigned_int:
    lw a0, 0(a2)            # a0 = highest = array[0]
    addi a3, a3, -1         # a3-- (already counted the first number)
    addi a2, a2, 4          # go to next position in array

while:
    beqz a3, cont           # if a3 == 0, done (no more numbers left)
    addi a2, a2, 4
    lw t0, 0(a2)            
    bleu t0, a0, end_if     # if t0 <= a0, nothing to do, go to next position
    mv a0, t0               # if t0 > a0, a0 = highest = current value
    mv a1, a2               # if t0 > a0, a1 = &highest = address of current position

end_if:
    addi a3, a3, -1
    j while

cont:
    ret