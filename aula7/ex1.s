# Translate the following C code to assembly RISC-V:

; /* Global array */ 
; int numbers[10]; 

; /* Returns the largest value from array numbers. */ 
; int get_largest_number() { 
;    int largest = numbers[0]; 
;    for (int i=1; i<10; i++) { 
;       if (numbers[i] > largest) 
;          largest = numbers[i]; 
;       } 
;    return largest; 
; }

.data
numbers: .skip 40     # 10 integers (4 bytes each)

.text
get_largest_number:
    la t0, numbers
    lw a0, 0(t0)      # a0 = largest = numbers[0]
    li t1, 1          # i = 1
    li t2, 10         # size of array
    li t3, 4          # used to iterate with i (since it's an integer array, each position occupies 4 bytes) 

for:
    bge t1, t2, cont  # if i >= 10, jump to cont (end of for loop)
    mul t4, t1, t3    # t4 = i * 4
    add t3, t0, t4    # t3 = &(numbers[i]) = &(numbers[0]) + i * 4
    lw t3, (t3)       # t3 = numbers[i]
    ble t3, a0, end_if  # if numbers[i] <= largest, jump to end_if
    mv a0, t3

end_if:
    addi t1, t1, 1    # i++
    j for

cont:
    ret