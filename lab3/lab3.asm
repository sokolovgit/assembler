STSEG SEGMENT PARA STACK "STACK"
    DB 64 DUP ("STACK")
STSEG ENDS

DSEG SEGMENT PARA PUBLIC "DATA"
    result DW 0
    tempResult DW 0
    inputValue DW 0
    remainder DW 0
    printValue DW 0

    inputMsg DB 0DH, 0AH, 'Provide X for equation', 0Dh, 0Ah, ' / x + 3, x<=0', 0Dh, 0Ah, '| 4x^2 / (x + 1), 0<x<2', 0Dh, 0Ah, '| (x^2 - 1) / (2x + 5), 2<=x<=4', 0Dh, 0Ah, '\ (x^3 - 1) / (x^2 + 1), x>4', 0Dh, 0Ah, 'x: $'
    input DB 7, ?, 7 DUP (0)
    outputMsg DB 0DH, 0AH, "Result: $"
    outputMsgRemainder DB 0DH, 0AH, "Remainder: $"
    continueMsg DB 0DH, 0AH, "Exit? ( + / - ): $"
    
    errorEmptyMsg DB 0DH, 0AH, "!Error, empty input!$"
    nonNumErrorMsg DB 0DH, 0AH, "!Error, non-numeric characters!$"
    overflowMsg DB 0DH, 0AH, "!Error, reached overflow while reading value!$"
    calcOverflowMsg DB 0DH, 0AH, "!Error, reached overflow while calculating result!$"
    
    isValueNegative DB 0
    validInput DB 0
    errorFlag DB 0
DSEG ENDS

CSEG SEGMENT PARA PUBLIC "CODE"
MAIN PROC FAR
    ASSUME CS: CSEG, DS: DSEG, SS: STSEG
    PUSH DS
    XOR AX, AX
    PUSH AX
    MOV AX, DSEG
    MOV DS, AX

inputLoop:
    CALL inputProcedure

    CMP errorFlag, 1
    JE skipOperation

    LEA DX, outputMsg
    MOV AH, 9
    INT 21h

    MOV AX, result
    MOV printValue, AX
    CALL outputProcedure

    CMP remainder, 0
    JE skipOperation

    LEA DX, outputMsgRemainder
    MOV AH, 9
    INT 21h

    MOV AX, remainder
    MOV printValue, AX
    CALL outputProcedure

skipOperation:
    MOV errorFlag, 0

askLoop:
    LEA DX, continueMsg
    MOV AH, 9
    INT 21h

    MOV AH, 1
    INT 21h

    CMP AL, '-'
    JE inputLoop
    CMP AL, '+'
    JE exitProgram
    JMP askLoop

exitProgram:
    MOV AH, 4Ch
    INT 21h

MAIN ENDP

inputProcedure PROC
    LEA DX, inputMsg
    MOV AH, 9
    INT 21h

    LEA DX, input
    MOV AH, 10
    INT 21h

    LEA SI, input + 2
    XOR BX, BX
    MOV BL, [SI]

    CMP BL, '-'
    JE readNegative
    CMP BL, '+'
    JE readPositive

    MOV isValueNegative, 0
    JMP readInteger

readPositive:
    MOV isValueNegative, 0
    INC SI
    MOV BL, [SI]
    JMP readInteger

readNegative:
    MOV isValueNegative, 1
    INC SI
    MOV BL, [SI]
    JMP readInteger

readInteger:
    MOV validInput, 0
    MOV CX, 10
    XOR AX, AX

loopRead:
    CMP BL, 0Dh
    JE endOfLineReached

    CMP BL, '0'
    JB charError
    CMP BL, '9'
    JA charError

    MOV validInput, 1
    XOR BH, BH
    IMUL CX
    JO overflowError
    SUB BL, '0'
    ADD AX, BX
    JO overflowError

    INC SI
    MOV BL, [SI]
    JMP loopRead

endOfLineReached:
    CMP validInput, 0
    JE emptyInputError
    JMP calculateResult

charError:
    LEA DX, nonNumErrorMsg
    MOV AH, 9
    INT 21h
    MOV errorFlag, 1
    JMP endProcedure

emptyInputError:
    LEA DX, errorEmptyMsg
    MOV AH, 9
    INT 21h
    MOV errorFlag, 1
    JMP endProcedure

overflowError:
    LEA DX, overflowMsg
    MOV AH, 9
    INT 21h
    MOV errorFlag, 1
    JMP endProcedure

calculateResult:
    MOV inputValue, AX
    XOR DX, DX

    CMP isValueNegative, 1
    JE firstCaseNegative
    CMP AX, 0
    JE firstCaseZero
    CMP AX, 2
    JL secondCase
    CMP AX, 4
    JLE thirdCase
    JMP fourthCase

firstCaseNegative:
    SUB AX, 3
    JO calcOverflowError
    NEG AX
    JMP saveResult

firstCaseZero:
    ADD AX, 3
    JO calcOverflowError
    JMP saveResult

secondCase:
    MOV tempResult, AX
    ADD tempResult, 1
    MOV CX, AX
    MUL CX
    MOV CX, 4
    MUL CX
    MOV CX, tempResult
    DIV CX
    JMP saveResult

thirdCase:
    MOV CX, 2
    MUL CX
    ADD AX, 5
    MOV tempResult, AX
    MOV AX, inputValue
    MOV CX, AX
    MUL CX
    SUB AX, 1
    MOV CX, tempResult
    DIV CX
    JMP saveResult

fourthCase:
    MOV CX, AX
    MUL CX
    ADD AX, 1
    MOV tempResult, AX
    MOV AX, inputValue
    MOV CX, AX
    MUL CX
    MUL CX
    SUB AX, 1
    MOV CX, tempResult
    DIV CX
    JMP saveResult

calcOverflowError:
    LEA DX, calcOverflowMsg
    MOV AH, 9
    INT 21h
    MOV errorFlag, 1
    JMP endProcedure

saveResult:
    MOV remainder, DX
    MOV result, AX

endProcedure:
    XOR AX, AX
    XOR DX, DX
    RET
inputProcedure ENDP

outputProcedure PROC
    MOV BX, printValue
    OR BX, BX
    JNS positive2
    MOV al, '-'
    INT 29h
    NEG bx

positive2:
    MOV AX, BX
    XOR CX, CX
    MOV BX, 10

toString:
    XOR DX, DX
    DIV BX
    ADD DL, '0'
    PUSH DX
    INC CX
    TEST AX, AX
    JNZ toString

outputPrint:
    POP AX
    INT 29h
    LOOP outputPrint
    RET
outputProcedure ENDP

CSEG ENDS
END MAIN
