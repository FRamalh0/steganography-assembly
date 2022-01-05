section .data
    NULL         equ 0
    LF           equ 10         ;line feed
    
    SYS_open     equ 2          ;file open
    SYS_read     equ 0          ;read
    SYS_close    equ 3          ;file close
    
    O_RDONLY     equ 000000q    ;read only

    emptyLine    db "", LF, NULL;Linha vazia
    
    BUFF_SIZE    equ 1000000
    fileDesc     dq  0      

section .bss
    fileName resb 255           ;Nome do ficheiro
    readBuffer resb BUFF_SIZE   ;Conteudo do ficheiro
    
    fileMensagem resb 1024      ;Mensagem
    
    bmpSize resb 24             ;Tamanho do bmp
    bmpOffset resb 24           ;Tamanho do offset do bmp
    bmpMensSize resb 24         ;Tamanho possivel para a mensagem
    
    contador resb 4             ;Contador com a cor atual (0 - B, 1 - G, 2 - R)
    
extern exit
extern argsInvalidSize
extern errorOnLoad
extern errorOnRead
extern printString
            
section .text
global _start
_start:
    ;-------- LEITURA DOS ARGUMENTOS ---------

    ;Verifica o numero de args inserido
    pop rbx                     ;numero de args
    pop rcx                     ;args
    
    cmp rbx, 2                  ;recebe 2 args
    jne argsInvalidSize         ;caso seja diferente, erro    
   
    ;Argumento inserido
    add rcx, 48                 ;converter args para ascii
    push rcx                    ;args na pilha
    mov rdi, qword [rsp+8]      ;Argumento 1
    mov [fileName], rdi         ;Guardar numa variavel
    
    ;-------- LEITURA DO FICHEIRO ------------
        
    ;Carregar o ficheiro
    call .openInputFile         ;Carrega o file e guarda o conteudo em readBuffer
        
    ;------- RECUPERAR MENSAGEM ---------

    ;Obter o tamanho (SSSS)
    mov rax, [readBuffer]       ;Conteudo do ficheiro para o rax
    shl rax, 8*2                ;Tirar os dois primeiros bytes
    shr rax, 8*4                
    mov [bmpSize], rax          ;Tamanho do bmp
    
    ;Obter o offset (OOOO)
    mov rax, [readBuffer+8]     ;Conteudo do ficheiro para o rax
    shl rax, 8*2                ;Tirar os dois primeiros bytes
    shr rax, 8*4
    mov [bmpOffset], rax        ;Tamanho do offset do bmp
    
    ;Tamanho da mensagem
    mov rax, [bmpSize]          ;Tamanho do ficheiro
    mov rcx, [bmpOffset]        ;Tamanho do offset
    sub rax, rcx                ;Calcular o tamanho possivel da mensagem
    mov [bmpMensSize], rax      ;Guardar o tamanho possivel da mensagem
    
    cmp rax, 8                  ;Tem de ser superior a 8bytes para conter uma mensagem (8 é um caracter)
    jb errorOnRead              ;Caso nao seja imprime um erro
      
    ;Obter cor BGRA
    mov rdi, 0                  ;Limpar rdi
    mov [contador], rdi         ;Contador a 0
    mov rdx, 0                  ;Limpar rdx
    mov rbx, 0                  ;Limpar rbx
             
    jmp .BGRALOOP               ;Metodo que obtem o LSB de Blue
    
.BGRALOOP:
    ;Metodo que obtem o LSB de Blue
    
    mov rax, 0                  ;Limpar rax
    mov rcx, [bmpOffset]        ;Tamanho do offset
    mov eax, [readBuffer + rcx + rdx]   ;readBuffer + offset + pixel atual
        
    shl eax, 8*3 + 7            ;LSB de Blue em eax
    shr eax, 8*3 + 7

    add rbx, rax                ;adicionar LSB a rbx (contem os bits do caracter atual)
    inc rdi                     ;Numero de caracteres incrementa
    
    mov rax, [contador]         ;Incrementar o contador
    inc rax                     ;(para saber em que cor do pixel se encontra)
    mov [contador], rax

    cmp rdi, 8                  ;Caso já tenha 8 bits, adiciona o caracter
    je .addCaracter
      
    shl rbx, 1                  ;Caso nao tenha, prepara rbx para o proximo LSB

    jmp .BGRALOOPA              ;Metodo que obtem o LSB de Green
    
    
.BGRALOOPA:        
    ;Metodo que obtem o LSB de Green
    
    mov rax, 0                  ;Limpar rax
    mov rcx, [bmpOffset]        ;Tamanho do offset
    mov eax, [readBuffer + rcx + rdx]   ;readBuffer + offset + pixel atual
        
    shl eax, 8*2 + 7            ;LSB de Green em eax
    shr eax, 8*3 + 7

    add rbx, rax                ;adicionar LSB a rbx (contem os bits do caracter atual)
    inc rdi                     ;Numero de caracteres incrementa
    
    mov rax, [contador]         ;Incrementar o contador
    inc rax                     ;(para saber em que cor do pixel se encontra)
    mov [contador], rax 
    
    cmp rdi, 8                  ;Caso já tenha 8 bits, adiciona o caracter
    je .addCaracter
     
    shl rbx, 1                  ;Caso nao tenha, prepara rbx para o proximo LSB
   
    jmp .BGRALOOPB              ;Metodo que obtem o LSB de Red
     
.BGRALOOPB:
    ;Metodo que obtem o LSB de Red
    
    mov rax, 0                  ;Limpar rax                 
    mov rcx, [bmpOffset]        ;Tamanho do offset
    mov eax, [readBuffer + rcx + rdx]   ;readBuffer + offset + pixel atual
        
    shl eax, 8*1 + 7            ;LSB de Red em eax
    shr eax, 8*3 + 7

    add rbx, rax                ;adicionar LSB a rbx (contem os bits do caracter atual)
    inc rdi                     ;Numero de caracteres incrementa
    
    mov rax, 0                  ;Faz reset ao contador           
    mov [contador], rax         ;(para saber em que cor do pixel se encontra)
    
    add rdx, 4                  ;Incrementa 4 vezes o rdx (proximo pixel)
    cmp rdx, [bmpMensSize]      ;Se nao tiver mais pixeis, termina o programa
    jae exit
    
    cmp rdi, 8                  ;Caso já tenha 8 bits, adiciona o caracter
    je .addCaracter
        
    shl rbx, 1                  ;Caso nao tenha, prepara rbx para o proximo LSB
        
    jmp .BGRALOOP               ;Metodo que obtem o LSB de Blue

.addCaracter:
    cmp rbx, 0                  ;Caso nao exista mensagem, termina o programa
    je exit
    
    mov [fileMensagem], rbx     ;Guardar caracter em fileMensagem
    
    mov rbx, rdx                ;Guardar pixel atual em rbx
    
    mov rdi, fileMensagem       ;Mensagem recuperada
    call printString            ;Imprimir mensagem
    
    mov rdx, rbx                ;Recuparar o pixel atual
    mov rbx, 0                  ;Limpar rbx
    mov rdi, 0                  ;Limpar rdi
    
    mov rax, [contador]         ;Para saber para qual cor deve ir
    cmp rax, 0                  ;Caso 0, vai para o metodo que obtem o LSB de Blue
    je .BGRALOOP
    cmp rax, 1                  ;Caso 1, vai para o metodo que obtem o LSB de Green
    je .BGRALOOPA
    cmp rax, 2                  ;Caso 2, vai para o metodo que obtem o LSB de Red
    je .BGRALOOPB

;------ OPEN INPUT FILE ------
.openInputFile:
    mov rax, SYS_open ; file open
    mov rdi, [fileName] ; file name string
    mov rsi, O_RDONLY ; read only access
    
    syscall ; call the kernel
    cmp rax, 0 ; check for success
    jl errorOnLoad
    mov qword [fileDesc], rax ; save descriptor
    
    ; -----
    ; Read from file.
    ; For this example, we know that the file has only 1 line.
    ; System Service - Read
    ; rax = SYS_read
    ; rdi = file descriptor
    ; rsi = address of where to place data
    ; rdx = count of characters to read
    ; Returns:
    ; if error -> rax < 0
    ; if success -> rax = count of characters actually read
    mov rax, SYS_read
    mov rdi, qword [fileDesc]
    mov rsi, readBuffer
    mov rdx, BUFF_SIZE
    syscall
    cmp rax, 0
    jl errorOnLoad


    mov rsi, readBuffer
    mov byte [rsi+rax], NULL
    
    ; -----
    ; Close the file.
    ; System Service - close
    ; rax = SYS_close
    ; rdi = file descriptor
    mov rax, SYS_close
    mov rdi, qword [fileDesc]
    syscall
    ret