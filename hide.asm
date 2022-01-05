section .data
    NULL         equ 0
    LF           equ 10             ;line feed
    
    SYS_write equ 1 ; write
    SYS_open     equ 2              ;file open
    SYS_read     equ 0              ;read
    SYS_creat    equ 85             ;file open/create
    SYS_close    equ 3              ;file close
    
    O_RDONLY     equ 000000q        ;read only
    S_IRUSR equ 00400q
    S_IWUSR equ 00200q

    emptyLine    db "", LF, NULL    ;Linha vazia
    
    BUFF_SIZE    equ 1000000
    messengeDesc     dq  0
    bmpDesc dq 0
    saveDesc dq 0
    
    len dq 4

section .bss
    messengeName resb 255           ;Nome do ficheiro
    messengeBuffer resb BUFF_SIZE   ;Conteudo do ficheiro
    
    bmpName    resb 255             ;Nome do ficheiro bmp   
    bmpBuffer resb BUFF_SIZE        ;Conteudo do ficheiro bmp
    
    bmpSize resb 24                 ;Tamanho do bmp
    bmpOffset resb 24               ;Tamanho do offset do bmp
    bmpMensSize resb 24             ;Tamanho possivel para a mensagem
    
    bmpSaveName resb 255            ;Nome do novo ficheiro bmp 
    messenge resb 64                ;Usado para guardar cada pixel (para depois ser escrito no novo bmp) 
    
    pixelAtual resb 24              ;Contador com o pixel atual do bmp
    corAtual resb 24                ;Contador com a cor atual (0 - B, 1 - G, 2 - R)
    
    caracterAtual resb 24           ;Contador com o caracter atual da mensagem
    bitAtual resb 24                ;Contador com o bit atual do caracter
    
extern exit
extern argsInvalidSize
extern errorOnLoad
extern errorOnRead
extern errorOnWrite
extern errorFileExist
extern printString
    
section .text
global _start
_start:
    ;-------- LEITURA DOS ARGUMENTOS ---------

    ;Verifica o numero de args inserido
    pop rbx                         ;numero de args
    pop rcx                         ;args
    
    cmp rbx, 4                      ;recebe 4 args
    jne argsInvalidSize             ;caso seja diferente, erro    
   
    ;Mensagem
    add rcx, 48                     ;converter args para ascii
    push rcx                        ;args na pilha
    mov rdi, qword [rsp+8]          ;Argumento 1
    mov [messengeName], rdi         ;Guardar numa variavel
    call printString                ;Imprimir o nome do ficheiro que contem a mensagem

    mov rdi, emptyLine              ;Imprimir uma linha vazia
    call printString

    ;Imagem
    add rcx, 48                     ;converter args para ascii
    push rcx                        ;args na pilha
    mov rdi, qword [rsp+24]         ;Argumento 2
    mov [bmpName], rdi              ;Guardar numa variavel
    call printString                ;Imprimir o nome do ficheiro bmp
    
    mov rdi, emptyLine
    call printString
    
    ;Nome da imagem com mensagem
    add rcx, 48                     ;converter args para ascii
    push rcx                        ;args na pilha
    mov rdi, qword [rsp+40]         ;Argumento 3
    mov [bmpSaveName], rdi          ;Guardar numa variavel
    call printString                ;Imprimir o nome do ficheiro que vai ser gerado
    
    mov rdi, emptyLine              ;Imprimir uma linha vazia
    call printString
    
    call .openOutputFile            ;Verifica se o ficheiro para output já existe
    
    ;-------- LEITURA DA MENSAGEM ---------
    
    call .openMessengeFile          ;Ler a mensagem do ficheiro txt
    
    ;-------- LEITURA DA IMAGEM ---------
    
    call .openBmpFile               ;Ler o conteudo do ficheito bmp
    
    ;Obter o tamanho (SSSS)
    mov rax, [bmpBuffer]            ;Conteudo do ficheiro para o rax
    shl rax, 8*2                    ;Tirar os dois primeiros bytes
    shr rax, 8*4                
    mov [bmpSize], rax              ;Tamanho do bmp
    
    ;Obter o offset (OOOO)
    mov rax, [bmpBuffer+8]          ;Conteudo do ficheiro para o rax
    shl rax, 8*2                    ;Tirar os dois primeiros bytes
    shr rax, 8*4
    mov [bmpOffset], rax            ;Tamanho do offset do bmp
    
    ;Tamanho da mensagem
    mov rax, [bmpSize]              ;Tamanho do ficheiro
    mov rcx, [bmpOffset]            ;Tamanho do offset
    sub rax, rcx                    ;Calcular o tamanho possivel da mensagem
    mov [bmpMensSize], rax          ;Guardar o tamanho possivel da mensagem
    
    cmp rax, 8                      ;Tem de ser superior a 8bytes para conter uma mensagem (8 é um caracter)
    jb errorOnRead                  ;Caso nao seja imprime um erro
    
    call .saveFile                  ;Gerar ficheiro bmp

.hideMessenge:
    
    mov rax, SYS_write              ;Inserir cabecalho no ficheiro
    mov rdi, qword [saveDesc]
    mov rsi, bmpBuffer
    mov rdx, qword [bmpOffset]
    syscall
    cmp rax, 0
    jl errorOnWrite
    
    mov rbx, 0                      ;Definir variaveis a 0
    mov [pixelAtual], rbx
    mov [caracterAtual], rbx
    mov [bitAtual], rbx
    mov [corAtual], rbx
    
    call .LOOP                      ;Começar o loop
    
.LOOP: 
    mov edx, [caracterAtual]        ;Index do caracter atual
    mov ebx, 0                      ;Limpar ebx
    mov bl, [messengeBuffer + edx]  ;Caracter atual
    
    cmp ebx, 0                      ;Se o caracter atual for 0, insere o ultimo caracter
    je .ultimoCaracter              ;Senao continua
    
    mov ecx, [bitAtual]             ;Bit atual do caracter atual
    mov edx, 0                      ;Limpar edx
    
    jmp .LOOPAUX                    ;Obter o bit que se pretende esconder
            
.LOOPAUX:
    cmp ecx, edx                    ;Enquanto nao for o bit que é pretendido, faz shift para a esquerda
    je .LOOPCONTINUA               
    
    shl ebx, 1 
    mov bh, 0   
    inc edx
    jmp .LOOPAUX
    
.LOOPCONTINUA:
    shr ebx, 7                      ;Ter apenas o bit do caracter pretendido
    
    mov rdx, [pixelAtual]           ;Index do pixel atual
    mov rcx, [bmpOffset]            ;Tamanho do offset
    mov eax, [bmpBuffer + rcx + rdx];Pixel atual
    
    mov rcx, [corAtual]             ;Para saber para qual cor deve ir
    cmp rcx, 0                      ;Caso 0, vai para o metodo que esconde no LSB de Blue
    je .CORBLUE
    cmp rcx, 1                      ;Caso 1, vai para o metodo que esconde no LSB de Green
    je .CORGREEN            
    cmp rcx, 2                      ;Caso 2, vai para o metodo que esconde no LSB de Red
    je .CORRED
    cmp rcx, 3                      ;Caso 3, adiciona o Alpha e escreve no ficheiro
    je .CORALPHA
   
.CORBLUE:
    shl eax, 8*3                    ;Byte de blue com o LSB a zero
    shr eax, 8*3 + 1
    shl eax, 1
    
    add eax, ebx                    ;Adiciona o bit do caracter atual
       
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov ebx, [corAtual]             ;Incrementar a cor atual, proxima cor é Green
    inc ebx
    mov [corAtual], ebx
    
    mov ebx, [bitAtual]             ;Incrementar o bit atual do caracter
    inc ebx
    mov [bitAtual], ebx
    cmp ebx, 8                      ;Caso bit atual seja 8, passa para o proximo caracter
    je .nextCaracter
    
    jmp .LOOP                       ;Senao continua o loop

.CORGREEN:
    shl eax, 8*2                    ;Byte de green com o LSB a zero
    shr eax, 8*3 + 1
    shl eax, 1
    
    add eax, ebx                    ;Adiciona o bit do caracter atual
    shl eax, 8*1                    ;Preparar eax para ser inserido em messenge
    
    mov ecx, [messenge]
    add eax, ecx                    ;Inserir cor a messenge
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov ebx, [corAtual]             ;Incrementar a cor atual, proxima cor é Red
    inc ebx
    mov [corAtual], ebx
    
    mov ebx, [bitAtual]             ;Incrementar o bit atual do caracter
    inc ebx
    mov [bitAtual], ebx
    cmp ebx, 8                      ;Caso bit atual seja 8, passa para o proximo caracter
    je .nextCaracter
    
    jmp .LOOP                       ;Senao continua o loop 
    
.CORRED:
    shl eax, 8*1                    ;Byte de red com o LSB a zero
    shr eax, 8*3 + 1
    shl eax, 1
    
    add eax, ebx                    ;Adiciona o bit do caracter atual
    shl eax, 8*2                    ;Preparar eax para ser inserido em messenge
    
    mov ecx, [messenge]
    add eax, ecx                    ;Inserir cor a messenge
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov ebx, [corAtual]             ;Incrementar a cor atual, proxima cor é Alpha
    inc ebx
    mov [corAtual], ebx

    mov ebx, [bitAtual]             ;Incrementar o bit atual do caracter
    inc ebx
    mov [bitAtual], ebx
    cmp ebx, 8                      ;Caso bit atual seja 8, passa para o proximo caracter
    je .nextCaracter
    
    jmp .LOOP                       ;Senao continua o loop  
    
.CORALPHA:  
    shr eax, 8*3                    ;Byte de alpha
    shl eax, 8*3      
    
    mov ecx, [messenge]
    add eax, ecx                    ;Inserir cor a messenge
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov ebx, [pixelAtual]           ;Incrementar o pixel atual
    add ebx, 4
    mov [pixelAtual], ebx
    
    mov ebx, 0                      ;Definir cor atual a 0, para voltar a Blue
    mov [corAtual], ebx
 
    jmp .writeToFile                ;Como o pixel já foi concluido, escreve-o no ficheiro
    
.nextCaracter:
    mov rbx, [caracterAtual]        ;Incrementa o caracter atual, para passar ao proximo
    inc rbx
    mov [caracterAtual], rbx  
    mov rdx, 0                      ;Definir o bit atual, para comecar no primeiro novamente
    mov [bitAtual], rdx  
    
    jmp .LOOP                       ;Continuar o loop
         
.ultimoCaracter:
    mov rcx, [corAtual]             ;Inserir o ultimo caracter, neste caso 8 bits a 0
    cmp rcx, 0                      ;Caso 0, vai para o metodo que esconde 0 no LSB de Blue
    je .CORBLUEUltimo
    cmp rcx, 1                      ;Caso 1, vai para o metodo que esconde 0 no LSB de Green
    je .CORGREENUltimo
    cmp rcx, 2                      ;Caso 2, vai para o metodo que esconde 0 no LSB de Red
    je .CORREDUltimo
    cmp rcx, 3                      ;Caso 3, adiciona o Alpha e escreve no ficheiro
    je .CORALPHAUltimo

.CORBLUEUltimo:
    shl eax, 8*3                    ;Byte de blue com o LSB a zero
    shr eax, 8*3 + 1
    shl eax, 1
            
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov ebx, [corAtual]             ;Incrementar a cor atual, proxima cor é Green
    inc ebx
    mov [corAtual], ebx
    
    mov ebx, [bitAtual]             ;Incrementar o bit atual do caracter
    inc ebx
    mov [bitAtual], ebx
    cmp ebx, 8                      ;Caso o bit atual seja 8, acaba o pixel atual
    je .acabarPixel
    
    jmp .ultimoCaracter             ;Senão continua o loop do ultimo caracter    

.CORGREENUltimo:
    shl eax, 8*2                    ;Byte de green com o LSB a zero
    shr eax, 8*3 + 1
    shl eax, 1
    
    shl eax, 8*1                    ;Preparar eax para ser inserido em messenge
    
    mov ecx, [messenge]
    add eax, ecx                    ;Inserir cor a messenge
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov ebx, [corAtual]             ;Incrementar a cor atual, proxima cor é Red
    inc ebx
    mov [corAtual], ebx
    
    mov ebx, [bitAtual]             ;Incrementar o bit atual do caracter
    inc ebx
    mov [bitAtual], ebx
    cmp ebx, 8                      ;Caso o bit atual seja 8, acaba o pixel atual
    je .acabarPixel
    
    jmp .ultimoCaracter             ;Senão continua o loop do ultimo caracter 
    
.CORREDUltimo:
    shl eax, 8*1                    ;Byte de red com o LSB a zero
    shr eax, 8*3 + 1
    shl eax, 1

    shl eax, 8*2                    ;Preparar eax para ser inserido em messenge
    
    mov ecx, [messenge]
    add eax, ecx                    ;Inserir cor a messenge
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov ebx, [corAtual]             ;Incrementar a cor atual, proxima cor é Alpha
    inc ebx
    mov [corAtual], ebx
    
    mov ebx, [bitAtual]             ;Incrementar o bit atual do caracter
    inc ebx
    mov [bitAtual], ebx
    cmp ebx, 8                      ;Caso o bit atual seja 8, acaba o pixel atual
    je .acabarPixel
    
    jmp .ultimoCaracter             ;Senão continua o loop do ultimo caracter 
    
.CORALPHAUltimo:  
    shr eax, 8*3                    ;Byte de alpha
    shl eax, 8*3      
    
    mov ecx, [messenge]
    add eax, ecx                    ;Inserir cor a messenge
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov ebx, [pixelAtual]           ;Incrementar o pixel atual
    add ebx, 4
    mov [pixelAtual], ebx
    
    mov ebx, 0                      ;Definir cor atual a 0, para voltar a Blue
    mov [corAtual], ebx
 
    mov rax, SYS_write              ;Como o pixel já foi concluido, escreve-o no ficheiro
    mov rdi, qword [saveDesc]
    mov rsi, messenge
    mov rdx, qword [len]
    syscall
    cmp rax, 0
    jl errorOnWrite
    
    jmp .ultimoCaracter             ;Continua o loop do ultimo caracter    

.acabarPixel:                   
    mov rcx, [corAtual]             ;Finaliza o pixel atual
    cmp rcx, 0                      ;Caso 0, imprime os restantes pixeis
    je .pixeisRestantes
    cmp rcx, 1                      ;Caso 1, finaliza o messenge atual para green
    je .acabarGREEN
    cmp rcx, 2                      ;Caso 2, finaliza o messenge atual para red
    je .acabarRED
    cmp rcx, 3                      ;Caso 3, finaliza o messenge atual para alpha
    je .acabarALPHA
    
.acabarGREEN:
    mov rdx, [pixelAtual]           ;Index do pixel atual
    mov rcx, [bmpOffset]            ;Tamanho do offset
    mov eax, [bmpBuffer + rcx + rdx];Pixel atual
    
    shr eax, 8*1                    ;Preparar eax para ser inserido em messenge
    shl eax, 8*1
    
    mov ecx, [messenge]
    add eax, ecx                    ;Inserir cores (alpha, red, green) a messenge
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov rax, SYS_write              ;Como o pixel já foi concluido, escreve-o no ficheiro
    mov rdi, qword [saveDesc]
    mov rsi, messenge
    mov rdx, qword [len]
    syscall
    cmp rax, 0
    jl errorOnWrite
    
    jmp .pixeisRestantes            ;Imprime os restantes pixeis
    
.acabarRED:
    mov rdx, [pixelAtual]           ;Index do pixel atual
    mov rcx, [bmpOffset]            ;Tamanho do offset
    mov eax, [bmpBuffer + rcx + rdx];Pixel atual
    
    shr eax, 8*2                    ;Preparar eax para ser inserido em messenge
    shl eax, 8*2
    
    mov ecx, [messenge]
    add eax, ecx                    ;Inserir cores (alpha, red) a messenge
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov rax, SYS_write              ;Como o pixel já foi concluido, escreve-o no ficheiro
    mov rdi, qword [saveDesc]
    mov rsi, messenge
    mov rdx, qword [len]
    syscall
    cmp rax, 0
    jl errorOnWrite
    
    jmp .pixeisRestantes            ;Imprime os restantes pixeis

.acabarALPHA:
    mov rdx, [pixelAtual]           ;Index do pixel atual
    mov rcx, [bmpOffset]            ;Tamanho do offset
    mov eax, [bmpBuffer + rcx + rdx];Pixel atual
    
    shr eax, 8*3                    ;Preparar eax para ser inserido em messenge
    shl eax, 8*3
    
    mov ecx, [messenge]
    add eax, ecx                    ;Inserir cor (alpha) a messenge
    mov [messenge], eax             ;Guardar progresso em messenge
    
    mov rax, SYS_write              ;Como o pixel já foi concluido, escreve-o no ficheiro
    mov rdi, qword [saveDesc]
    mov rsi, messenge
    mov rdx, qword [len]
    syscall
    cmp rax, 0
    jl errorOnWrite
    
    jmp .pixeisRestantes            ;Imprime os restantes pixeis (sem mensagem)
        
.pixeisRestantes:
    mov rbx, [pixelAtual]           ;Index do pixel atual
    mov rax, [bmpMensSize]          ;Numero de pixeis no ficheiro bmp
    cmp rbx, rax                    ;Caso o numero seja o mesmo (ou superior), fecha o ficheiro e                  
    jae .saveFileClose              ;termina o programa
                                    ;Senão continua
                                    
    mov rdx, [pixelAtual]           ;Index do pixel atual
    mov rcx, [bmpOffset]            ;Tamanho do offset
    mov eax, [bmpBuffer + rcx + rdx];Pixel atual
    
    mov [messenge], eax             ;Guardar pixel em messenge
    mov rbx, [pixelAtual]           ;Incrementar o pixel atual
    add rbx, 4
    mov [pixelAtual], rbx   
    
    mov rax, SYS_write              ;Como o pixel já foi concluido, escreve-o no ficheiro
    mov rdi, qword [saveDesc]
    mov rsi, messenge
    mov rdx, qword [len]
    syscall
    cmp rax, 0
    jl errorOnWrite
         
    jmp .pixeisRestantes            ;Continua a inserir os restantes pixeis  

;Escreve no ficheiro que vai ser gerado        
.writeToFile:
    ; -----
    ; Write to file.
    ; In this example, the characters to write are in a
    ; predefined string containing a URL.
    ; System Service - write
    ; rax = SYS_write
    ; rdi = file descriptor
    ; rsi = address of characters to write
    ; rdx = count of characters to write
    ; Returns:
    ; if error -> rax < 0
    ; if success -> rax = count of characters actually read
    mov rax, SYS_write
    mov rdi, qword [saveDesc]
    mov rsi, messenge
    mov rdx, qword [len]
    syscall
    cmp rax, 0
    jl errorOnWrite
    
    jmp .LOOP               ;Continua o loop
    
    
;------ OPEN INPUT FILE ------
;Abrir o ficheiro txt e guardar na variavel messengeDesc
.openMessengeFile:
    mov rax, SYS_open ; file open
    mov rdi, [messengeName] ; file name string
    mov rsi, O_RDONLY ; read only access
    
    syscall ; call the kernel
    cmp rax, 0 ; check for success
    jl errorOnLoad
    mov qword [messengeDesc], rax ; save descriptor
    
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
    mov rdi, qword [messengeDesc]
    mov rsi, messengeBuffer
    mov rdx, BUFF_SIZE
    syscall
    cmp rax, 0
    jl errorOnLoad


    mov rsi, messengeBuffer
    mov byte [rsi+rax], NULL
    
    ; -----
    ; Close the file.
    ; System Service - close
    ; rax = SYS_close
    ; rdi = file descriptor
    mov rax, SYS_close
    mov rdi, qword [messengeDesc]
    syscall
    ret            

;Abrir o ficheiro bmp e guardar na variavel bmpDesc
.openBmpFile:
    mov rax, SYS_open ; file open
    mov rdi, [bmpName] ; file name string
    mov rsi, O_RDONLY ; read only access
    
    syscall ; call the kernel
    cmp rax, 0 ; check for success
    jl errorOnLoad
    mov qword [bmpDesc], rax ; save descriptor
    
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
    mov rdi, qword [bmpDesc]
    mov rsi, bmpBuffer
    mov rdx, BUFF_SIZE
    syscall
    cmp rax, 0
    jl errorOnLoad


    mov rsi, bmpBuffer
    mov byte [rsi+rax], NULL
    
    ; -----
    ; Close the file.
    ; System Service - close
    ; rax = SYS_close
    ; rdi = file descriptor
    mov rax, SYS_close
    mov rdi, qword [bmpDesc]
    syscall
    ret

.openOutputFile:
    mov rax, SYS_open ; file open
    mov rdi, [bmpSaveName] ; file name string
    mov rsi, O_RDONLY ; read only access
    
    syscall ; call the kernel
    cmp rax, 0 ; check for success
    jge errorFileExist
    ret

;Cria o ficheiro que vai ser gerado
.saveFile:
    mov rax, SYS_creat ; file open/create
    mov rdi, [bmpSaveName] ; file name string
    mov rsi, S_IRUSR | S_IWUSR ; allow read/write
    syscall ; call the kernel
    cmp rax, 0 ; check for success
    jl errorOnWrite
    mov qword [saveDesc], rax ; save descriptor
        
    call .hideMessenge      ;Esconder mensagem

;Fecha o ficheiro gerado
.saveFileClose: 
    ; -----
    ; Close the file.
    ; System Service - close
    ; rax = SYS_close
    ; rdi = file descriptor
    mov rax, SYS_close            
    mov rdi, qword [saveDesc]
    syscall
    jmp exit    ;Termina o programa
    