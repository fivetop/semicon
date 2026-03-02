.global _start

_start:
    MOV R0, #5      // R0 = 5
    MOV R1, #7      // R1 = 7

    PUSH {R0, R1}   // push R0 and R1 onto stack

    MOV R0, #0      // R0 = 0
    MOV R1, #0      // R1 = 0

    POP {R0, R1}    // pop back R0 and R1

hang:
    B hang
