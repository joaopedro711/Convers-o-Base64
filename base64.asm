;================================================================================================================================
;Programa que tem 2 funções:
; 1° - codificar: receber até 3 bytes e os codifica para a Base 64.
; 2° - Decodificar: recebe até 4 bytes na Base 64 e os decodifica para os 3 bytes iniciais.
;================================================================================================================================
 
        section .text

        global  _main_base64_encode
        global  _main_base64_decode
       
;================================================================================================================================
 ; _main_base64_encode
; Rotina que converte até 3 bytes em uma string de 4 caracteres Base 64.
;
; A passagem de parametros deve ser feita utilizando a convenção de chamada C.
; A rotina recebe apenas um parametro inteiro de 32 bits, que representa a juncao de 4 bytes: count,byte1,byte2,byte3.
;
; Esses 4 bytes, extraidos dos 32 bits, representam as seguintes informacoes:
;
; count: Quantidade de bytes a ser convertido:        está na posicao 0xFF000000 (primeiro  byte dos 32 bits)
; byte1: Primeiro byte a ser convertido: sempre fica na posicao 0x00FF0000 (segundo   byte dos 32 bits)
; byte2: Segundo  byte a ser convertido: sempre fica na posicao 0x0000FF00 (penultimo byte dos 32 bits)
; byte3: Terceiro byte a ser convertido: sempre fica na posicao 0x000000FF (ultimo    byte dos 32 bits)
;
; A funcao retorna 32 bits no eax, sendo que cada byte representa um caractere codificado em base64.

_main_base64_encode:
        push    ebp                     ; ebp deve ser preservado, Ponteiro para a base da pilha de frames
        mov     ebp,esp                 ; ebp recebe o Ponteiro para o topo da pilha
        sub     esp,4                   ; reservando 4 bytes na pilha 
        push    edi                     ; edi deve ser preservado (no windows), Ponteiro para uma string de destino
        push    esi                     ; esi deve ser preservado (no windows), Ponteiro para uma string de origem
        push    ebx                     ; ebx deve ser preservado, Ponteiro para dados

        ; inicio do codigo
        mov     ebx, 0
        mov     ebx, [ebp+8]            ; ponteiro de dados recebe base da pilha + 8 bytes acima
        shr     ebx, 24                 ; shift right, pega o valor de count
        add     ebx, 1
        mov     BYTE [ebp-4], bl        ; [ebp-4] representará, a partir de agora quantos caracteres ainda faltam ser gerados. bl = ebx(8bit)
                                        ; Inicializa ele como count + 1

        mov     ebx, 3                  ; ebx será utilizado para mutiplicar os delocamentos
        mov     eax, '===='             ; eax é a saída, inicia com os valores que suspostamente serao (pad).

loop:
        cmp     BYTE [ebp-4], 0         ; se nao faltar gerar mais nenhum byte
        je      end

        mov     esi,[ebp+8]             ; Ponteiro para uma string de origem recebe base da pilha + 8 bytes

        mov     ecx, 6                  ; contador recebe o valor 6
        imul    ecx, ebx                ; calculando deslocamento de count*6 bits
        shr     esi, cl                 ; shift right de cl=8 bits 

        and     esi,0x3F                ; Extraindo 6 bits
        call    convert_caracter             ; chama a sub rotina pra converter 6 bits em caracter Base 64

        mov     ecx, 8                  ; contador recebe o valor 8
        imul    ecx, ebx                ; calculando deslocamento de count*8 bits
        shl     esi, cl                 ; shift left de cl=8bits

        mov     edi, 0xFF               ; Ponteiro para uma string de destino recebe o valor 256
        shl     edi, cl                 ; shift left de cl=8bits
        xor     edi, 0xFFFFFFFF         ; calculando máscara de bits

        and     eax, edi                ; eax que eh o caracter "=" and a mascara de bits
        or      eax, esi                ; eax mais o caractere da Base 64

        sub     BYTE [ebp-4], 1         ; contador de bytes faltantes para conversão - 1
        sub     ebx, 1                  ; menos 1 no deslocamento de trem de bits
        jmp     loop                    ; retorna ao loop
end:
        pop ebx                         ; recuperando ebx
        pop esi                         ; recuperando esi
        pop edi                         ; recuperando edi
        leave                           ; mov esp,ebp / pop ebp 
        ret                             ; the max will be in rax

        
;================================================================
; convert_caracter:
; Rotina interna para converter número de 6 bits em caractere base64
;================================================================
convert_caracter:
        cmp     esi, 63                 ; n == 63?
        je      barra                   ; se sim, é uma /
        cmp     esi, 62                 ; n == 62?
        je      mais                    ; se sim, é um sinal de +
        cmp     esi, 51                 ; n <= 51?
        jnbe    numeros                 ; Se nao, vai pra numeros (n esta entre 52 e 61)
        cmp     esi, 25                 ; n <= 25?
        jnbe    letras_minusculas       ; Se nao, vai pra letras_minusculas (n esta entre 26 e 51)
        jmp     letras_maiusculas       ; Vai pra letras_maiusculas (n esta entre 0 e 25)
barra:
        mov     esi, '/'                ; transforma no simbolo correspondente
        ret
mais:
        mov     esi, '+'                ; transforma no simbolo correspondente
        ret
numeros:
        sub     esi, 52
        add     esi, '0'                ; transforma no simbolo
        ret

letras_maiusculas :
        add     esi, 'A'                ; transforma no simbolo correspondente
        ret

letras_minusculas:
        sub     esi, 26
        add     esi, 'a'                ; transforma no simbolo correspondente
        ret


;================================================================================================================================

;                                  ================================================================
;                                  ================================================================
;                                  ================================================================

;================================================================================================================================
; _main_base64_decode
;
; Rotina que converte 4 caracteres base64 em até 3 bytes.
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
_main_base64_decode:
        push    ebp                     ; ebp deve ser preservado
        mov     ebp,esp                 ; ebp recebe o Ponteiro para o topo da pilha
        sub     esp,4                   ; reservando 4 bytes na stack 
        push    edi                     ; edi deve ser preservado (no windows), Ponteiro para uma string de destino
        push    esi                     ; esi deve ser preservado (no windows), Ponteiro para uma string de origem
        push    ebx                     ; ebx deve ser preservado, Ponteiro para dados

        ; inicio do codigo
        mov     ebx, 3                  ; recebe o valor 3 que representa 3 bytes
        mov     eax, 0                  ; a saída recebe o valor 0, pois caso não tenha caracter é atribuido o valor 0
loop2:
        mov     esi,[ebp+8]             ; bytes

        mov     ecx, 8
        imul    ecx, ebx                ; calculando deslocamento de count*8 bits
        shr     esi, cl

        and     esi,0xFF                ; Extraindo 8 bits
        cmp     esi, '='                ; se chegamos em '=', é o final dos dados.
        je      end2

        call    i_convert_caracter

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
;================================================================
; i_convert_caracter:
; Rotina inversa ao conver_esi. Será usada no processo de decode.
;================================================================
i_convert_caracter:
        cmp     esi, '/'                ; é uma /?
        je      i_barra                 ; Se sim, vamos pra i_barra.
        cmp     esi, '+'                ; é um +?
        je      i_mais                  ; Se sim, vamos pra i_plus.
        cmp     esi, 'Z'                ; é menor ou igual ao ascii Z?
        jnbe    i_letras_minusculas            ; Se não, só pode ser minusculo.
        cmp     esi, '9'                ; é menor ou igual ao ascii '9'?
        jnbe    i_letras_maiusculas            ; Se não, só pode ser ascii maiusculo.
        jmp     i_numeros               ; Se sim, só pode ser um número ascii.

i_barra:
        mov     esi, 63
        ret   

i_mais:
        mov     esi, 62
        ret

i_numeros:
        sub     esi, '0'
        add     esi, 52
        ret

i_letras_minusculas:
        sub     esi, 'a'
        add     esi, 26
        ret

i_letras_maiusculas:
        sub     esi, 'A'
        ret