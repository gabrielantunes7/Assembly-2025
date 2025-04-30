# Write a function ("busca_caractere") which verifies if one chain of characters
# (finished in zero) has a certain character
# Inputs: a0 = address of string, a1 = character to be found
# Output: a0 = address of first appearance of character or zero if not found

busca_caractere:
while:
    lbu t0, 0(a0)       # t0 = string[i]
    beq t0, zero, not_found  # if string[i] == '\0', jump to not found
    beq t0, a1, found   # if string[i] == character, jump to found

    addi a0, a0, 1      # if neither, advances with pointer a0
    j while

not_found:
    mv a0, zero

found:
    ret