#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

extern "C" uint32_t main_base64_encode(uint32_t join);
extern "C" uint32_t main_base64_decode(uint32_t join);

static uint32_t print_count = 0;

/**
 * passa a codificacao para o arquivo (de 4 em 4 bits)
 */
void print_chars(uint32_t chars, FILE *fp)
{
    for (int i = 0; i < 4; i++)
    {
        char c = (char)((chars >> ((3 - i) * 8)) & 0xFF);
        fputc(c, fp);
        print_count++;
        if (print_count % 76 == 0)
        {
            fputc('\n', fp);
        }
    }
}

/**
 *  faz a operacao inversa (passa para o arquivo binario de 3 em 3 bits)
 */
int print_bytes(uint32_t join, FILE *fp)
{
    uint8_t count = join >> 24;
    uint8_t byte;
    for (uint8_t i = 2; count; i--, count--)
    {
        byte = (join >> (8 * i)) & 0xFF;
        fwrite(&byte, 1, 1, fp);
    }
    print_count += (join >> 24);
    return (join >> 24);
}

uint32_t copy_bytes(uint8_t count, uint8_t *bytes)
{
    uint32_t chars = count << 24; // shifta pra esquerda ate os caracteres atingirem 32 bits
    for (int i = 0; i < count; i++)
    {
        chars |= (bytes[i] << ((2 - i) * 8)); // faz uma operacao "or" para copiar os bits necessarios
    }
    return chars;
}

void print_error()
{
    printf("\r\n");
    printf("Erro na leitura dos arquivos \r\n");
}

void encode(char *i_fname, char *o_fname)
{
    FILE *f_in;
    FILE *f_out;

    f_in = fopen(i_fname, "rb");

    if (!f_in)
    {
        printf("Erro ao abrir arquivo %s.\r\n", i_fname);
        fclose(f_in);
        return;
    }

    f_out = fopen(o_fname, "w");

    if (!f_out)
    {
        printf("Erro ao criar arquivo %s.\r\n", i_fname);
        fclose(f_in);
        fclose(f_out);
        return;
    }

    fseek(f_in, 0L, SEEK_END);            // Reposiciona o indicador de posição do fluxo em função do deslocamento.
    uint32_t bytes_to_read = ftell(f_in); // o valor atual do indicador de posição do fluxo (quantos bytes possui o arquivo a ser lido).
    fseek(f_in, 0L, SEEK_SET);            // indica a posicao atual dentro do arquivo
    printf("O arquivo possui %d bytes para a leitura.\r\n", bytes_to_read);

    uint8_t buffer[1024];

    for (uint32_t i = 0, bytes_left, bytes_to_process; i < bytes_to_read; i += 3)
    {
        bytes_left = bytes_to_read - i;
        bytes_to_process = bytes_left > 3 ? 3 : bytes_left;

        for (uint8_t j = 0; j < bytes_to_process; j++)
        {
            fread(buffer + j, 1, 1, f_in);
        }

        uint32_t join = copy_bytes(bytes_to_process, buffer);
        uint32_t chars = main_base64_encode(join); // codificar com base no alfabeto definido dentro do assembly
        print_chars(chars, f_out);
    }

    printf("Caracteres escritos: %d\r\n", print_count);
    fclose(f_in);
    fclose(f_out);
}

void decode(char *i_fname, char *o_fname)
{
    FILE *f_in;
    FILE *f_out;

    f_in = fopen(i_fname, "r");

    if (!f_in)
    {
        printf("Erro ao abrir arquivo %s.\r\n", i_fname);
        fclose(f_in);
        return;
    }

    f_out = fopen(o_fname, "wb");

    if (!f_out)
    {
        printf("Erro ao criar arquivo %s.\r\n", i_fname);
        fclose(f_in);
        fclose(f_out);
        return;
    }

    uint32_t buffer;
    uint32_t read_count = 0;

    do
    {
        buffer = 0;

        for (int i = 0; i < 4; i++)
        {
            int r = fgetc(f_in);
            if (r == '\r' || r == '\n')
            {
                i--;
            }
            else if (r == EOF)
            {
                if (i != 0)
                    printf("ERRO: EOF\r\n");
                goto end;
            }
            else
            {
                read_count++;
                buffer |= ((uint32_t)(r & 0xFF) << (3 - i) * 8); // operacao para filtrar os bits necessarios e depois copiar de acordo com o buffer
            }
        }

        buffer = main_base64_decode(buffer); // decodificar com base no alfabeto binario definido dentro do assembly
    } while (print_bytes(buffer, f_out) == 3);

end:

    printf("Caracteres lidos: %d\r\n", read_count);
    printf("Bytes escritos: %d\r\n", print_count);
    fclose(f_in);
    fclose(f_out);
}

int main(int argc, char *argv[])
{

    char bytes[] = "";

    if (argc < 2)
    {
        print_error();
        return 0;
    }

    char *input_file_name = 0;
    char *output_file_name = 0;
    int operation = 0; // 1: encode, 2: decode.

    for (int i = 1; i < argc; i++)
    {
        if (argv[i][0] == '-')
        {
            if (argv[i][1] == 'o')
            {
                if (i + 1 == argc)
                {
                    print_error();
                    return 0;
                }
                output_file_name = argv[i + 1];
                i++;
            }
            if (argv[i][1] == 'i')
            {
                if (i + 1 == argc)
                {
                    print_error();
                    return 0;
                }
                input_file_name = argv[i + 1];
                i++;
            }
            if (argv[i][1] == '-')
            {
                if (argv[i][2] == 'e')
                {
                    operation = 1;
                }
                if (argv[i][2] == 'd')
                {
                    operation = 2;
                }
            }
        }
    }

    if (!input_file_name || !output_file_name || !operation)
    {
        print_error();
        return 0;
    }

    printf("Operacao %s\r\n", operation == 1 ? "codificando arquivo..." : "decodificando arquivo...");

    if (operation == 1)
        encode(input_file_name, output_file_name);

    else if (operation == 2)
        decode(input_file_name, output_file_name);

    return 0;
}