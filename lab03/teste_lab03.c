#include <stdio.h>
#include <stdlib.h>

#define STDIN_FD  0
#define STDOUT_FD 1

// Função para transformar o número binário de 32 bits (complemento de dois) em decimal
int bin_para_dec(char str[33]){
    int negativo = (str[0] == '1');
    int decimal = 0;

    // não precisa inverter bits
    if (!negativo)
        // transforma em decimal
        for (int i = 0; i < 32; i++)
            decimal = (decimal << 1) | (str[i] - '0');
    
    else{
        int complemento = 0;
        
        // inverte os bits e transforma em decimal
        for (int i = 0; i < 32; i++)
            complemento = (complemento << 1) | (str[i] == '0' ? 1 : 0);
        
        complemento += 1;
        decimal = -complemento;
    }

    return decimal;
}

char* inverte_endian_bin(char str[33]){
    char byte1[9];
    char byte2[9];
    char byte3[9];
    char byte4[9];
    char *invertido = (char*) malloc(33 * sizeof(char));

    for (int i = 0; i < 8; i++){
        byte1[i] = str[i];
        byte2[i] = str[i + 8];
        byte3[i] = str[i + 16];
        byte4[i] = str[i + 24];
    }

    byte1[8] = byte2[8] = byte3[8] = byte4[8] = '\0';

    for (int i = 0; i < 8; i++)
        invertido[i] = byte4[i];
    for (int i = 8; i < 16; i++)
        invertido[i] = byte3[i - 8];
    for (int i = 16; i < 24; i++)
        invertido[i] = byte2[i - 16];
    for (int i = 24; i < 32; i++)
        invertido[i] = byte1[i - 24];

    invertido[32] = '\0';

    return invertido;
}

// Função para transformar o número binário de 32 bits (unsigned e little-endian) em decimal
int bin_para_dec_endian_invertido(char str[33]){
    int decimal = 0;
    char *invertido = inverte_endian_bin(str);

    // com os bytes invertidos, converte de binário para decimal
    for (int i = 0; i < 32; i++)
        decimal = (decimal << 1) | (invertido[i] - '0');

    free(invertido);

    return decimal;
}

// Função para imprimir um número decimal
// void imprime_dec(int valor){
//     char buffer[12]; // maior número decimal é -2147483648
//     char *ptr = buffer + 11; // ponteiro no LSB do número
//     *ptr = '\0';
//     ptr--;
//     // o ponteiro é usado para indicar qual a primeira posição válida do número na string

//     int negativo = (valor < 0);
//     if (negativo)
//         valor = -valor;

//     do {
//         *ptr = valor % 10 + '0';
//         valor /= 10;
//         ptr--;
//     } while (valor > 0);

//     if (negativo){
//         *ptr = '-'; // coloca o sinal de menos no MSB
//         ptr--;
//     }

//     ptr++;

//     write(STDOUT_FD, ptr, buffer + 12 - ptr);
// }

// Função para transformar a string do número binário numa string de número hexadecimal
char* bin_para_hex(char str[33]){
    char *hex = (char*) malloc(11 * sizeof(char)); // tamanho máximo do número é 8 bits, mais "0x" e '\0'
    hex[0] = '0';
    hex[1] = 'x';
    hex[10] = '\0';

    int negativo = (str[0] == '1'); // bit de sinal
    char hex_chars[] = "0123456789abcdef";
    char str_processado[33]; // se for negativo, precisa processar primeiro

    if (negativo){
        int carry = 1;

        for (int i = 31; i >= 0; i--){
            if (str[i] == '1')
                str_processado[i] = (carry) ? '0' : '1';
            else{
                str_processado[i] = (carry) ? '1' : '0';
                carry = 0;
            }
        }
        str_processado[32] = '\0';
    }    
    else
        for (int i = 0; i < 33; i++)
            str_processado[i] = str[i];

    for (int i = 0; i < 8; i++){
        int valor = 0;
        for (int j = 0; j < 4; j++)
            valor = (valor << 1) | (str_processado[i * 4 + j] - '0');
        
        hex[i + 2] = hex_chars[valor];
    }

    return hex;
}

// Função para transformar a string do número binário numa string de número octal
char* bin_para_oct(char str[33]){
    char *oct = (char*) malloc(15 * sizeof(char)); // "0o" + 11 dígitos + '\0'
    oct[0] = '0';
    oct[1] = 'o';
    oct[14] = '\0';

    int negativo = (str[0] == '1');
    char str_processado[33];

    if (negativo){
        int carry = 1;
        for (int i = 31; i >= 0; i--){
            if (str[i] == '1')
                str_processado[i] = (carry) ? '0' : '1';
            else{
                str_processado[i] = (carry) ? '1' : '0';
                carry = 0;
            }
        }
        str_processado[32] = '\0';
    }    
    else
        for (int i = 0; i < 33; i++)
            str_processado[i] = str[i];
    

    for (int i = 0; i < 11; i++){
        int valor = 0;
        for (int j = 0; j < 3; j++)
            valor = (valor << 1) | (str_processado[i * 3 + j] - '0');

        oct[i + 2] = '0' + valor;
    }

    return oct;
}

void imprime_invertido(char str[33]){
    char *invertido = inverte_endian_bin(str);
    char invertido_completo[35]; // binário invertido com "0b" na frente
    invertido_completo[0] = '0';
    invertido_completo[1] = 'b';
    invertido_completo[34] = '\0';

    // como um strcpy()
    for (int i = 0; i < 33; i++)
        invertido_completo[i + 2] = invertido[i];

    printf("%s\n", invertido_completo);
}

int bin_para_dec_invertido_comp_dois(char str[33]){
    char *invertido = inverte_endian_bin(str);
    int decimal = bin_para_dec(invertido);
    free(invertido);

    return decimal;
}

char* hex_endian_invertido(char str[33]){
    char *invertido = inverte_endian_bin(str);
    char *hex = bin_para_hex(invertido);
    free(invertido);

    return hex;
}

char* oct_endian_invertido(char str[33]){
    char *invertido = inverte_endian_bin(str);
    char *oct = bin_para_oct(invertido);
    free(invertido);

    return oct;
}

int main(){
    char str[33];
    scanf(" %s", str);
    
    int dec = bin_para_dec(str);
    printf("%d\n", dec);

    int dec_endian = bin_para_dec_endian_invertido(str);
    printf("%d\n", dec_endian);

    char *hex = bin_para_hex(str);
    printf("%s\n", hex);
    free(hex);

    char *oct = bin_para_oct(str);
    printf("%s\n", oct);
    free(oct);

    imprime_invertido(str);

    int dec_endian_comp_dois = bin_para_dec_invertido_comp_dois(str);
    printf("%d\n", dec_endian_comp_dois);

    char *hex_invertido = hex_endian_invertido(str);
    printf("%s\n", hex_invertido);
    free(hex_invertido);

    char *oct_invertido = oct_endian_invertido(str);
    printf("%s\n", oct_invertido);
    free(oct_invertido);

    return 0;
}