.MODEL SMALL
.STACK 100H
.DATA
.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX          ; Initialize data segment

    ; Push parameters onto the stack (simulating function call)
    MOV AX, 1111H       ; First parameter
    PUSH AX
    MOV AX, 2222H       ; Second parameter
    PUSH AX

    CALL MyFunction     ; Call the function

    ADD SP, 4           ; Remove parameters from stack after the call

    MOV AX, 4C00H       ; End program
    INT 21H
MAIN ENDP

MyFunction PROC
    PUSH BP             ; Save previous BP
    MOV BP, SP          ; BP now points to the current top of the stack

    MOV AX, [BP+4]      ; Get the first parameter (1111H)
    MOV BX, [BP+6]      ; Get the second parameter (2222H)

    POP BP              ; Restore BP
    RET
MyFunction ENDP

END MAIN
