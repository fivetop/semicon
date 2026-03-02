.global _start

_start:
    MOV R0, #42
    BL add_3
    B end

add_3:
    ADD R0, R0, #3
    BX LR

end:
    B end