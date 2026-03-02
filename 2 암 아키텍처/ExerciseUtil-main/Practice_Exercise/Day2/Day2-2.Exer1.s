.global _start

_start:
    MOV R0, #6
    PUSH {R0}
    BL factorial
    ADD SP, SP, #4
    MOV R1, R0
hang:
    B hang

factorial:
    PUSH {LR}
    LDR R0, [SP, #4]
    CMP R0, #1
    BLE base_case

    SUB R0, R0, #1    
    PUSH {R0}
    BL factorial
    ADD SP, SP, #4

    LDR R1, [SP, #4]
    MOV R3, R0
    MUL R0, R3, R1
    B end_fact

base_case:
    MOV R0, #1

end_fact:
    POP {LR}
    BX LR

