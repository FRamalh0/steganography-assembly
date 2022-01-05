section .data
    NULL         equ 0
    LF           equ 10         ;line feed
    
    SYS_exit     equ 60         ;terminate
    EXIT_SUCCESS equ 0          ;success code
    
    errArgs      db "Invalid args input", LF, NULL
    errFileLoad  db "Cannot load the file...", LF, NULL
    errMensRead  db "Cannot read any messenge", LF, NULL
    errMensWrite  db "Cannot write any messenge", LF, NULL
    errFileExist  db "Output file already exist. Please try another name or delete that file.", LF, NULL

section .text    
;------ EXIT ------
global exit
exit:
    mov rax, SYS_exit           ;Termina o programa
    mov rdi, EXIT_SUCCESS
    syscall
    ret
    
;------ ERROS ------
global argsInvalidSize
argsInvalidSize:
    mov rdi, errArgs            ;Imprime a mensagem de erro
    call printString
    call exit                   ;Termina o programa

global errorOnLoad
errorOnLoad:
    mov rdi, errFileLoad        ;Imprime a mensagem de erro
    call printString
    call exit                   ;Termina o programa

global errorOnRead
errorOnRead:
    mov rdi, errMensRead        ;Imprime a mensagem de erro
    call printString
    call exit                   ;Termina o programa

global errorOnWrite:   
errorOnWrite:
    mov rdi, errMensWrite       ;Imprime a mensagem de erro
    call printString
    call exit                   ;Termina o programa

global errorFileExist:
errorFileExist:
    mov rdi, errFileExist       ;Imprime a mensagem de erro
    call printString
    call exit                   ;Termina o programa

;------ PRINT DE STRINGS ------
global printString
printString:
    push rbp
    mov rbp, rsp
    push rbx
    ; -----
    ; Count characters in string.
    mov rbx, rdi
    mov rdx, 0
    
strCountLoop:
    cmp byte [rbx], NULL
    je strCountDone
    inc rdx
    inc rbx
    jmp strCountLoop
    
strCountDone:
    cmp rdx, 0
    je prtDone
    ; -----
    ; Call OS to output string.
    mov rax, 1 ; code for write()
    mov rsi, rdi ; addr of characters
    mov edi, 1 ; file descriptor
    ; count set above
    syscall ; system call
    
; -----
; String printed, return to calling routine.
prtDone:
    pop rbx
    pop rbp
    ret
