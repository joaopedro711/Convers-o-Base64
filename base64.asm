
        global  _base64_encode
        global  _base64_decode
        section .text

;================================================================
; convert_esi:
; Rotina interna para converter número de 6 bits em caractere base64
;================================================================
convert_esi:
        cmp     esi, 63                 ; n == 63?
        je      barra                   ; se sim, é uma /
        cmp     esi, 62                 ; n == 62?
        je      plus                    ; se sim, é um +
        cmp     esi, 51                 ; n <= 51?
        jnbe    numeros                 ; Se nao, vai pra numeros (n esta entre 52 e 61)
        cmp     esi, 25                 ; n <= 25?
        jnbe    minusculos              ; Se nao, vai pra minusculos (n esta entre 26 e 51)
        jmp     maiusculos              ; Vamos pra maiusculos (n esta entre 0 e 25)
maiusculos:
        add     esi, 'A'
        ret
minusculos:
        sub     esi, 26
        add     esi, 'a'
        ret
numeros:
        sub     esi, 52
        add     esi, '0'
        ret
plus:
        mov     esi, '+'
        ret
barra:
        mov     esi, '/'
        ret

;================================================================
; _base64_encode
; Rotina 'C' que converte até 3 bytes em uma string de 4 caracteres base64.
;
; A passagem de parametros deve ser feita utilizando a convenção de chamada C.
; A rotina recebe apenas um parametro inteiro de 32 bits, que representa a juncao de 4 bytes: count,byte1,byte2,byte3.
;
; Esses 4 bytes, extraidos dos 32 bits, representam as seguintes informacoes:
;
; count: Quantidade de bytes a ser convertido:        está na posicao 0xFF000000 (primeiro  byte dos 32 bits)
; byte1: Primeiro byte a ser convertido: deve sempre estar na posicao 0x00FF0000 (segundo   byte dos 32 bits)
; byte2: Segundo  byte a ser convertido: deve sempre estar na posicao 0x0000FF00 (penultimo byte dos 32 bits)
; byte3: Terceiro byte a ser convertido: deve sempre estar na posicao 0x000000FF (ultimo    byte dos 32 bits)
;
; A funcao retorna 32 bits no eax, sendo que cada byte representa um caractere codificado em base64.
;================================================================
_base64_encode:
        push    ebp                     ; ebp deve ser preservado
        mov     ebp,esp 
        sub     esp,4                   ; reservando 4 bytes na stack 
        push    edi                     ; edi deve ser preservado (no windows)
        push    esi                     ; esi deve ser preservado (no windows)
        push    ebx                     ; ebx deve ser preservado

        ; inicio do codigo
        mov     ebx, 0
        mov     ebx, [ebp+8]
        shr     ebx, 24
        add     ebx, 1
        mov     BYTE [ebp-4], bl        ; [ebp-4] representará, a partir de agora quantos caracteres ainda faltam ser gerados.
                                        ; Inicializamos ele como count + 1

        mov     ebx, 3                  ; ebx será utilizado para mutiplicar os delocamentos
        mov     eax, '===='             ; eax é a saída, iniciamos com placeholder de saida com paddings.

loop:
        cmp     BYTE [ebp-4], 0
        je      end

        mov     esi,[ebp+8]             ; bytes

        mov     ecx, 6
        imul    ecx, ebx                ; calculando deslocamento de count*6 bits
        shr     esi, cl

        and     esi,0x3F                ; Extraindo 6 bits
        call    convert_esi

        mov     ecx, 8
        imul    ecx, ebx                ; calculando deslocamento de count*8 bits
        shl     esi, cl

        mov     edi, 0xFF
        shl     edi, cl
        xor     edi, 0xFFFFFFFF         ; calculando máscara de bits

        and     eax, edi
        or      eax, esi

        sub     BYTE [ebp-4], 1
        sub     ebx, 1
        jmp     loop
end:
        pop ebx                         ; recuperando ebx
        pop esi                         ; recuperando esi
        pop edi                         ; recuperando edi
        leave                           ; mov esp,ebp / pop ebp 
        ret                             ; the max will be in rax

        
;================================================================
; i_convert_esi:
; Rotina inversa ao conver_esi. Será usada no processo de decode.
;================================================================
i_convert_esi:
        cmp     esi, '/'                ; é uma /?
        je      i_barra                 ; Se sim, vamos pra i_barra.
        cmp     esi, '+'                ; é um +?
        je      i_plus                  ; Se sim, vamos pra i_plus.
        cmp     esi, 'Z'                ; é menor ou igual ao ascii Z?
        jnbe    i_minusculos            ; Se não, só pode ser minusculo.
        cmp     esi, '9'                ; é menor ou igual ao ascii '9'?
        jnbe    i_maiusculos            ; Se não, só pode ser ascii maiusculo.
        jmp     i_numeros               ; Se sim, só pode ser um número ascii.
i_maiusculos:
        sub     esi, 'A'
        ret
i_minusculos:
        sub     esi, 'a'
        add     esi, 26
        ret
i_numeros:
        sub     esi, '0'
        add     esi, 52
        ret
i_plus:
        mov     esi, 62
        ret
i_barra:
        mov     esi, 63
        ret    

;================================================================
; _base64_decode
;
; Rotina 'C' que converte 4 caracteres base64 em até 3 bytes.
;
; A passagem de parametros deve ser feita utilizando a convenção de chamada C.
; A rotina recebe apenas um parametro inteiro de 32 bits, que representa a juncao de 4 caracteres: char1,char2,char3,char4.
; A rotina não faz verificações se os caracteres são válidos dentro do alfabeto base64, simplesmente assume que são.
;
; Retorna um inteiro de 32 bits, em eax, codificado da seguinte maneira:
; count:  Quantidade de bytes convertidos: está na posicao 0xFF000000 (primeiro  byte dos 32 bits)
; byte1: Primeiro byte que foi convertido: está na posicao 0x00FF0000 (segundo   byte dos 32 bits)
; byte2: Segundo  byte que foi convertido: está na posicao 0x0000FF00 (penultimo byte dos 32 bits)
; byte3: Terceiro byte que foi convertido: está na posicao 0x000000FF (ultimo    byte dos 32 bits)
;
;================================================================
_base64_decode:
        push    ebp                     ; ebp deve ser preservado
        mov     ebp,esp 
        sub     esp,4                   ; reservando 4 bytes na stack 
        push    edi                     ; edi deve ser preservado (no windows)
        push    esi                     ; esi deve ser preservado (no windows)
        push    ebx                     ; ebx deve ser preservado

        ; inicio do codigo
        mov     ebx, 3
        mov     eax, 0
loop2:
        mov     esi,[ebp+8]             ; bytes

        mov     ecx, 8
        imul    ecx, ebx                ; calculando deslocamento de count*8 bits
        shr     esi, cl

        and     esi,0xFF                ; Extraindo 8 bits
        cmp     esi, '='                ; se chegamos em '=', é o final dos dados.
        je      end2

        call    i_convert_esi

        mov     ecx, 6
        imul    ecx, ebx                ; calculando deslocamento de count*6 bits
        shl     esi, cl

        mov     edi, 0x3F
        shl     edi, cl
        xor     edi, 0xFFFFFFFF         ; calculando máscara de bits

        and     eax, edi
        or      eax, esi
        add     eax, 0x01000000

        cmp     ebx, 0
        je      end2
        sub     ebx, 1
        jmp     loop2
end2:
        sub     eax, 0x01000000
        pop ebx                         ; recuperando ebx
        pop esi                         ; recuperando esi
        pop edi                         ; recuperando edi
        leave                           ; mov esp,ebp / pop ebp 
        ret                             ; the max will be in rax