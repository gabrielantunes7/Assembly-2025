# the target's X coordinate is roughly 40

.rodata
.set BASE_ADDR, 0xFFFF0100              # base address for the MMIO, used to start GPS use (0 for off, 1 for on)
.set X_COORD_ADDR, BASE_ADDR + 0x10     # address for x coordinate
.set STEERING_ADDR, BASE_ADDR + 0x20    # address for steering control (negative for left, positive for right)
.set ENGINE_ADDR, BASE_ADDR + 0x21      # address for engine control (0 for off, 1 for forward, -1 for reverse)
.set HANDBRAKE_ADDR, BASE_ADDR + 0x22   # address for handbrake control (0 for off, 1 for on)


.text
.globl _start

_start:
    jal main
    jal exit

main:
    addi sp, sp, -16    # allocate stack space
    sw ra, 12(sp)       # save return address

    li a0, STEERING_ADDR    # load steering address
    li t0, 1            # used to set car functions on (GPS, engine, brakes)
    li t1, 19           # used to set steering wheel position (got this information from testing)
    li t2, 0            # used to set car functions off
    sb t1, (a0)         # set steering value to 19 (positive for right turn)
    li a0, HANDBRAKE_ADDR   # load handbrake address
    sb t2, (a0)         # set handbrake off
    li a0, ENGINE_ADDR  # load engine address
    sb t0, (a0)         # set engine to forward
1:
    li a1, BASE_ADDR    # load base address for GPS
    sb t0, (a1)         # turn GPS on
    lb t5, (a1)         # read GPS status
    bnez t5, 1b         # wait until GPS reads the coordinates (when it goes to zero, it menas the reading is done)

    li a0, X_COORD_ADDR  # load x coordinate address
    lw t3, (a0)         # read x coordinate value
    li t6, 40
    bgt t3, t6, 1b      # while x coordinate > 40, continue

    # stop the car
    li a0, ENGINE_ADDR  # load engine address
    sb t2, (a0)         # set engine to off
    li a0, HANDBRAKE_ADDR   # load handbrake address
    sb t0, (a0)         # set handbrake on

    lw ra, 12(sp)       # restore return address
    addi sp, sp, 16     # deallocate stack space
    ret

exit:
    li a0, 0            # exit code 0
    li a7, 10           # syscall for exit
    ecall               # make the syscall