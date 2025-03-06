STACKSEGMENT SEGMENT PARA STACK "STACK"
                 DB 64 DUP(?)
STACKSEGMENT ENDS

DATASEGMENT SEGMENT PARA PUBLIC "DATA"
    GREETING_MSG    DB 'This program subtracts 96 from your number. $'
    RULES_MSG       DB 13, 10, 'Enter a number in range [-10922, 10922] $'
    INPUT_MSG       DB 13, 10, 'Your number: $'
    RESULT_MSG      DB 13, 10, 'Result: $'
    ERR_EMPTY_MSG   DB 13, 10, 'Error: No input provided! $'
    ERR_RANGE_MSG   DB 13, 10, 'Error: Number out of range! $'
    ERR_INVALID_MSG DB 13, 10, 'Error: Invalid input! $'
    EXIT_MSG        DB 13, 10, 'Do you want to exit? (y/*ANY*): $'

    IS_VALID        DB 0
    IS_NEGATIVE     DB 0
    USER_INPUT      DB 7, ?, 7 DUP(?)
    INT_NUM         DW 0
DATASEGMENT ENDS

CODESEGMENT SEGMENT PARA "CODE"
MAIN PROC FAR
                      ASSUME CS:CODESEGMENT, DS:DATASEGMENT, SS:STACKSEGMENT

                      PUSH   DS
                      MOV    AX, DATASEGMENT
                      MOV    DS, AX

                      CALL   PrintGreeting

program_loop:    
                      CALL   ResetState
                      CALL   AskForInput
                      CALL   ReadUserNumber
                      CALL   ValidateUserInput
                      CMP    BYTE PTR [IS_VALID], 1
                      JE     program_loop
                      CALL   SubtractNumber
                      CALL   PrintResult

                      CALL   AskForExit
                      CMP    BYTE PTR [USER_INPUT], 'y'
                      JE     ExitProgram
                      JMP    program_loop

ExitProgram:
                      MOV    AX, 4C00h
                      INT    21h
MAIN ENDP

ResetState PROC NEAR
                      MOV    BYTE PTR [IS_VALID], 0
                      MOV    BYTE PTR [IS_NEGATIVE], 0
                      MOV    WORD PTR [INT_NUM], 0
                      MOV    BYTE PTR [USER_INPUT], 7
                      MOV    BYTE PTR [USER_INPUT + 1], 0
                      RET
ResetState ENDP

PrintGreeting PROC NEAR
                      MOV    DX, OFFSET GREETING_MSG
                      MOV    AH, 09h
                      INT    21h
                      MOV    DX, OFFSET RULES_MSG
                      MOV    AH, 09h
                      INT    21h
                      RET
PrintGreeting ENDP

AskForInput PROC NEAR
                      MOV    DX, OFFSET INPUT_MSG
                      MOV    AH, 09h
                      INT    21h
                      RET
AskForInput ENDP

ReadUserNumber PROC NEAR
                      MOV    DX, OFFSET USER_INPUT
                      MOV    AH, 0Ah
                      INT    21h
                      RET
ReadUserNumber ENDP

ValidateUserInput PROC NEAR
                      XOR    AX, AX
                      XOR    DX, DX
                      MOV    SI, OFFSET USER_INPUT + 2
                      MOV    CL, [USER_INPUT + 1]
                      OR     CL, CL
                      JZ     error_empty

                      MOV    BL, [SI]
                      CMP    BL, 'q'
                      JE     ExitProgram
                      CMP    BL, '-'
                      JNE    check_digit
                      MOV    DL, 1
                      MOV    [IS_NEGATIVE], DL
                      INC    SI
                      DEC    CL

    check_digit:      
                      CMP    CL, 0
                      JZ     error_invalid
                      MOV    BL, [SI]
                      CMP    BL, '0'
                      JNE    convert_loop
                      CMP    CL, 1
                      JE     convert_loop
                      JMP    error_invalid

    convert_loop:     
                      MOV    BL, [SI]
                      CMP    BL, '0'
                      JL     error_invalid
                      CMP    BL, '9'
                      JG     error_invalid

                      SUB    BL, '0'
                      MOV    BH, 0

                      PUSH   CX
                      MOV    CX, 10
                      IMUL   CX
                      JO     overflow
                      ADD    AX, BX
                      JC     overflow
                      POP    CX

                      INC    SI
                      LOOP   convert_loop

                      CMP    AX, 10922
                      JG     error_out_of_range
                    
                      MOV    [INT_NUM], AX

                      MOV    DL, [IS_NEGATIVE]
                      OR     DL, DL
                      JZ     end_proc
                      NEG    AX
                      MOV    [INT_NUM], AX

    end_proc:         
                      RET

    error_invalid:    
                      MOV    DX, OFFSET ERR_INVALID_MSG
                      JMP    print_error

    overflow:         
                      POP    CX
                      JMP    error_out_of_range
    error_out_of_range:  
                      MOV    DX, OFFSET ERR_RANGE_MSG
                      JMP    print_error

    error_empty:      
                      MOV    DX, OFFSET ERR_EMPTY_MSG
                      JMP    print_error

    print_error:      
                      MOV    BL, 1
                      MOV    [IS_VALID], BL
                      MOV    AH, 09h
                      INT    21h
                      RET

ValidateUserInput ENDP

SubtractNumber PROC NEAR
                      MOV    AX, [INT_NUM]
                      SUB    AX, 96
                      MOV    [INT_NUM], AX
                      RET
SubtractNumber ENDP

PrintResult PROC NEAR
                      MOV    DX, OFFSET RESULT_MSG
                      MOV    AH, 09h
                      INT    21h

                      MOV    BX, [INT_NUM]
                      OR     BX, BX
                      JNS    print_number

                      MOV    DL, '-'
                      MOV    AH, 02h
                      INT    21h
                      NEG    BX

    print_number:     
                      MOV    AX, BX
                      XOR    CX, CX
                      MOV    BX, 10

    push_digits:      
                      XOR    DX, DX
                      DIV    BX
                      ADD    DL, '0'
                      PUSH   DX
                      INC    CX
                      TEST   AX, AX
                      JNZ    push_digits

    pop_and_print:    
                      POP    DX
                      MOV    AH, 02h
                      INT    21h
                      LOOP   pop_and_print

                      RET
PrintResult ENDP

AskForExit PROC NEAR
                      MOV    DX, OFFSET EXIT_MSG
                      MOV    AH, 09h
                      INT    21h

                      MOV    AH, 01h      
                      INT    21h
                      MOV    [USER_INPUT], AL 
                      RET
AskForExit ENDP

CODESEGMENT ENDS
END MAIN
