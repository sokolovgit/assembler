; STACK SEGMENT DESCRIPTION
STACK_SEG SEGMENT PARA STACK "STACK"
    DB 64 DUP ("STACK")
STACK_SEG ENDS

; DATA SEGMENT DESCRIPTION
DATA_SEG SEGMENT PARA PUBLIC "DATA"
    result dw 0
    temp_result dw 0
    user_input dw 0
    division_remainder dw 0
    display_value dw 0
    
    prompt_msg DB 0DH, 0AH, 'Enter value for X in equation:', 0Dh, 0Ah, '/ x+3, x<=0', 0Dh, 0Ah, '| 4x^2/(x+1), 0<x<2', 0Dh, 0Ah, '| (x^2-1)/(2x+5), 2<=x<=4', 0Dh, 0Ah, '\ (x^3-1)/(x^2+1), x>4', 0Dh, 0Ah, 'X: $'
    input_buffer DB 7, ?, 7 dup (0)
    result_msg DB 0DH, 0AH, "Output: $"
    remainder_msg DB 0DH, 0AH, "Division remainder: $"
    exit_prompt DB 0DH, 0AH, "Quit? (y/n): $"
    
    error_empty_msg DB 0DH, 0AH, "!Error: Input is empty!$"
    error_non_numeric_msg DB 0DH, 0AH, "!Error: Invalid characters detected!$"
    error_overflow_msg DB 0DH, 0AH, "!Error: Input value too large!$"
    error_calc_overflow_msg DB 0DH, 0AH, "!Error: Calculation overflow occurred!$"
    is_negative DB 0
    valid_input DB 0
    error_state DB 0

DATA_SEG ENDS

; CODE SEGMENT DESCRIPTION
CODE_SEG SEGMENT PARA PUBLIC "CODE"
PROGRAM_START PROC FAR
    ASSUME CS:CODE_SEG, DS:DATA_SEG, SS:STACK_SEG
    PUSH DS
    XOR AX, AX
    PUSH AX
    MOV AX, DATA_SEG
    MOV DS, AX

main_loop:
    CALL execute_calculation
    
    CMP error_state, 1
    JE bypass_output
    
    LEA DX, result_msg
    MOV AH, 9
    INT 21h
    
    MOV AX, result
    MOV display_value, AX
    CALL display_output
    
    CMP division_remainder, 0
    JE bypass_output
    
    LEA DX, remainder_msg
    MOV AH, 9
    INT 21h
    
    MOV AX, division_remainder
    MOV display_value, AX
    CALL display_output
    
bypass_output:
    MOV error_state, 0

prompt_exit:
    LEA DX, exit_prompt
    MOV AH, 9
    INT 21h
    
    MOV AH, 1
    INT 21h
    
    CMP AL, 'n'
    JE main_loop
    CMP AL, 'y'
    JE terminate
    JMP prompt_exit

terminate:
    MOV AH, 4Ch
    INT 21h

PROGRAM_START ENDP

execute_calculation PROC
    LEA DX, prompt_msg
    MOV AH, 9
    INT 21h
    
    LEA DX, input_buffer
    MOV AH, 10
    INT 21h

    LEA SI, input_buffer + 2
    XOR BX, BX
    MOV BL, byte ptr [SI]
    
    CMP BL, '-'
    JE parse_negative
    CMP BL, '+'
    JE parse_positive
    
    MOV is_negative, 0
    JMP parse_number
    
parse_positive:
    MOV is_negative, 0
    INC SI
    MOV BL, byte ptr [SI]
    JMP parse_number
    
parse_negative:
    MOV is_negative, 1
    INC SI
    MOV BL, byte ptr [SI]
    JMP parse_number

parse_number:
    MOV valid_input, 0
    MOV CX, 10
    XOR AX, AX
    
number_loop:
    CMP BL, 0Dh
    JE input_complete
    
    CMP BL, 30h
    JB invalid_char
    CMP BL, 39h
    JA invalid_char
    
    MOV valid_input, 1
    
    XOR BH, BH
    IMUL CX
    JO input_overflow
    SUB BL, '0'
    ADD AX, BX
    JO input_overflow
    
    INC SI
    MOV BL, byte ptr [SI]
    JMP number_loop

input_complete:
    CMP valid_input, 0
    JE empty_input
    JMP evaluate_expression

invalid_char:
    LEA DX, error_non_numeric_msg
    MOV AH, 9
    INT 21h
    MOV error_state, 1
    JMP calc_end
    
empty_input:
    LEA DX, error_empty_msg
    MOV AH, 9
    INT 21h
    MOV error_state, 1
    JMP calc_end

input_overflow:
    LEA DX, error_overflow_msg
    MOV AH, 9
    INT 21h
    MOV error_state, 1
    JMP calc_end

evaluate_expression:
    MOV user_input, AX
    XOR DX, DX
    CMP is_negative, 1
    JE case_negative
    CMP AX, 0
    JE case_zero
    CMP AX, 2
    JL case_second
    CMP AX, 4
    JLE case_third
    JMP case_fourth
    
case_negative:
    SUB AX, 3
    JO calc_overflow
    NEG AX
    JMP store_result
    
case_zero:
    ADD AX, 3
    JO calc_overflow
    JMP store_result
    
case_second:
    MOV temp_result, AX
    ADD temp_result, 1
    
    MOV CX, AX
    MUL CX
    MOV CX, 4
    MUL CX
    
    MOV CX, temp_result
    DIV CX
    
    JMP store_result
    
case_third:
    MOV CX, 2
    MUL CX
    JO calc_overflow
    ADD AX, 5
    JO calc_overflow
    MOV temp_result, AX
    
    MOV AX, user_input
    MOV CX, AX
    MUL CX
    JO calc_overflow
    SUB AX, 1
    JO calc_overflow
    
    MOV CX, temp_result
    DIV CX
    
    JMP store_result
    
case_fourth:
    MOV CX, AX
    MUL CX
    JO calc_overflow
    ADD AX, 1
    JO calc_overflow
    MOV temp_result, AX
    
    MOV AX, user_input
    MOV CX, AX
    MUL CX
    JO calc_overflow
    MUL CX
    JO calc_overflow
    SUB AX, 1
    JO calc_overflow
    
    MOV CX, temp_result
    DIV CX
    JO calc_overflow
    
    JMP store_result
    
calc_overflow:
    LEA DX, error_calc_overflow_msg
    MOV AH, 9
    INT 21h
    MOV error_state, 1
    JMP calc_end
    
store_result:
    MOV division_remainder, DX
    MOV result, AX
    
calc_end:
    XOR AX, AX
    XOR DX, DX
    RET
execute_calculation ENDP

display_output PROC
    MOV BX, display_value
    OR BX, BX
    JNS positive_num
    MOV AL, '-'
    INT 29h
    NEG BX

positive_num:
    MOV AX, BX
    XOR CX, CX
    MOV BX, 10

convert_to_string:
    XOR DX, DX
    DIV BX
    ADD DL, '0'
    PUSH DX
    INC CX
    TEST AX, AX
    JNZ convert_to_string
    
print_loop:
    POP AX
    INT 29h
    LOOP print_loop
    RET
display_output ENDP

CODE_SEG ENDS
END PROGRAM_START