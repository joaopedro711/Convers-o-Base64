#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

extern "C" uint32_t main_base64_encode(uint32_t join);
extern "C" uint32_t main_base64_decode(uint32_t join);

static uint32_t print_count = 0;

/**
 * Função que imprime no arquivo os 4 caracteres codificados dentro dos 32 bits.
 */
void print_chars(uint32_t chars, FILE * fp) {
    for (int i = 0; i < 4; i++) {
        char c = (char)((chars >> ((3-i)*8)) & 0xFF);
        fputc(c, fp);
        print_count++;
        if (print_count%76 == 0){
            fputc('\n', fp);
        }
    }
}

/**
 *  Função que imprime no arquivo até 3 bytes, codificados dentro dos 32 bits.
 */
int print_bytes(uint32_t join, FILE * fp) {
    uint8_t count = join >> 24;
    uint8_t byte;
    for (uint8_t i=2; count; i--, count--) {
        byte = (join >> (8 * i)) & 0xFF;
        fwrite(&byte,1,1,fp);
    }
    print_count+=(join >> 24);
    return (join >> 24);
}

/**
 * Função que prepara o argumento de 32 bits a ser passado para rotina de encode base64.
 * O primeiro byte (mais significativo) dos 32 bits será preenchido com a quantidade de bytes (1 a 3).
 * Os bytes seguintes dos 32 bits serão preenchidos com até 3 bytes do char* informado.
 */
uint32_t join_count_and_bytes(uint8_t count, uint8_t* bytes) {
    uint32_t chars = count << 24;
    for (int i = 0; i < count; i++) {
        chars |= (bytes[i] << ((2-i)*8));
    }
    return chars;
}

void print_usage() {
    printf("\r\n");
    printf("Por favor, insira as seguintes opcoes: \r\n");
    printf("-o arquivo_de_saida \r\n");
    printf("-i arquivo_de_entrada \r\n");
    printf("--encode entra bytes e sai base64.\r\n");
    printf("--decode entra base64 e sai bytes.\r\n");
    printf("\r\n");
    printf("Exemplo: saida.exe --encode -i imagem.jpg -o byte.txt\r\n");
    printf("Exemplo: saida.exe --decode -i byte.txt -o imagem_2.jpg\r\n");
    printf("\r\n");
}

void run_encode(char* i_fname, char* o_fname) {
    FILE * f_in;
    FILE * f_out;

    f_in = fopen (i_fname, "rb");

    if (!f_in) {
        printf("Erro ao abrir arquivo %s.\r\n", i_fname);
        fclose(f_in);
        return;
    }

    f_out = fopen (o_fname, "w");

    if (!f_out) {
        printf("Erro ao criar arquivo %s.\r\n", i_fname);
        fclose(f_in);
        fclose(f_out);
        return;
    }

    fseek(f_in, 0L, SEEK_END);
    uint32_t bytes_to_read = ftell(f_in);
    fseek(f_in, 0L, SEEK_SET);
    printf("Bytes a serem lidos: %d\r\n", bytes_to_read);

    uint8_t buffer[1024];

    for (uint32_t i = 0, bytes_left, bytes_to_process; i < bytes_to_read; i+=3){
        bytes_left = bytes_to_read - i;
        bytes_to_process = bytes_left > 3 ? 3 : bytes_left;

        for (uint8_t j = 0; j < bytes_to_process; j++) {
            fread(buffer+j,1,1,f_in);
        }

        uint32_t join = join_count_and_bytes(bytes_to_process, buffer);
        uint32_t chars = main_base64_encode(join); // Aqui é a chamada do assembly.
        print_chars(chars, f_out);
    }

    printf("Caracteres escritos: %d\r\n", print_count);
    fclose(f_in);
    fclose(f_out);
}


void run_decode(char* i_fname, char* o_fname) {
    FILE * f_in;
    FILE * f_out;

    f_in = fopen (i_fname, "r");

    if (!f_in) {
        printf("Erro ao abrir arquivo %s.\r\n", i_fname);
        fclose(f_in);
        return;
    }

    f_out = fopen (o_fname, "wb");

    if (!f_out) {
        printf("Erro ao criar arquivo %s.\r\n", i_fname);
        fclose(f_in);
        fclose(f_out);
        return;
    }

    uint32_t buffer;
    uint32_t read_count = 0;

    do {
        buffer = 0;

        for (int i = 0; i < 4; i++) {
            int r = fgetc(f_in);
            if (r == '\r' || r == '\n') {
                i--;
            } else if (r == EOF) {
                if (i != 0)
                    printf("ERRO: Fim de arquivo nao esperado! abortando...\r\n");
                goto end;
            } else {
                read_count++;
                buffer |= ((uint32_t)(r&0xFF) << (3-i)*8);
            }
        }

        buffer = main_base64_decode(buffer); // Aqui é a chamada do assembly.
    } while (print_bytes(buffer, f_out) == 3);
    
    end:

    printf("Caracteres lidos: %d\r\n", read_count);
    printf("Bytes escritos: %d\r\n", print_count);
    fclose(f_in);
    fclose(f_out);
}

int main(int argc, char *argv[]) {

    char bytes[] = "";

    if (argc < 2) {
        print_usage();
        return 0;
    }

    char*  input_file_name = 0;
    char* output_file_name = 0;
    int          operation = 0; // 1: encode, 2: decode.

    for (int i = 1; i < argc; i++) {
        if (argv[i][0] == '-') {
            if (argv[i][1] == 'o') {
                if (i+1 == argc) {
                    print_usage();
                    return 0;
                }
                output_file_name = argv[i+1];
                i++;
            }
            if (argv[i][1] == 'i') {
                if (i+1 == argc) {
                    print_usage();
                    return 0;
                }
                input_file_name = argv[i+1];
                i++;
            }
            if (argv[i][1] == '-') {
                if (argv[i][2] == 'e') {
                    operation = 1;
                }
                if (argv[i][2] == 'd') {
                    operation = 2;
                }
            }
        }
    }

    if (!input_file_name || !output_file_name || !operation) {
        print_usage();
        return 0;
    }

    printf("Lendo arquivo %s\r\n", input_file_name);
    printf("Escrevendo arquivo %s\r\n", output_file_name);
    printf("Operacao %s\r\n", operation == 1 ? "encode" : "decode");

    if (operation == 1) {
        run_encode(input_file_name, output_file_name);
    } else if (operation == 2) {
        run_decode(input_file_name, output_file_name);
    }

    return 0;
}