.global _start


_start:
    MOV     R0, #1        // i = 1
    MOV     R1, #0        // sum = 0

loop:
    ADD     R1, R1, R0    // sum += i
    ADD     R0, R0, #1    // i++
    CMP    R0, #4          // if i == 4
    BEQ     end              // break loop if equal
    B          loop

end:
    B       end
