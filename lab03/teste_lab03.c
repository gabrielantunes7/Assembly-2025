#include <stdio.h>
#include <stdlib.h>

#define STDIN_FD  0
#define STDOUT_FD 1

// Função para transformar o número binário de 32 bits (complemento de dois) em decimal
long int bin_para_dec(char str[33]){
    int negativo = (str[0] == '1');
    long int decimal = 0;

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

// Função para inverter o endianness de uma string de um número binário
void inverte_endian_bin(char str[33], char invertido[33]){
    for (int i = 0; i < 8; i++){
        invertido[i] = str[i + 24];
        invertido[i + 8] = str[i + 16];
        invertido[i + 16] = str[i + 8];
        invertido[i + 24] = str[i];
    }

    invertido[32] = '\0';
}

// Função para transformar o número binário de 32 bits (unsigned e little-endian) em decimal
long int bin_para_dec_endian_invertido(char str[33]){
    long int decimal = 0;
    char invertido[33];
    inverte_endian_bin(str, invertido);

    // com os bytes invertidos, converte de binário para decimal
    for (int i = 0; i < 32; i++)
        decimal = (decimal << 1) | (invertido[i] - '0');

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
// hex tem 11 bits, porque o tamanho máximo do número é 8 bits, mais "0x" e '\0'
int bin_para_hex(char str[33], char hex[11]){
    hex[0] = '0';
    hex[1] = 'x';

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

    int pos = 2;
    int zero_a_esquerda = 1;
    for (int i = 0; i < 8; i++){
        int valor = 0;
        for (int j = 0; j < 4; j++)
            valor = (valor << 1) | (str_processado[i * 4 + j] - '0');

        // para que não tenha zeros à esquerda da representação do número em hexadecimal
        if (valor != 0 || !zero_a_esquerda || i == 7){
            zero_a_esquerda = 0;
            hex[pos++] = hex_chars[valor]; // atualiza a posição na string para que saiba onde colocar o '\0' ao final
        }
        
        hex[pos] = '\0';
    }

    return pos + 1;
}

// Função para transformar a string do número binário numa string de número octal
// oct tem 15 bits, "0o" + 11 dígitos + '\0'
int bin_para_oct(char str[33], char oct[15]){
    oct[0] = '0';
    oct[1] = 'o';

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

    int decimal = bin_para_dec(str_processado);

    int i = 2;
    if (decimal == 0)
        oct[i] = '0';
    else{
        int i = 2;
        while (decimal > 0){
            int valor = decimal % 8;
            oct[i] = '0' + valor;
            decimal /= 8;
            i++;
        }
    }

    oct[i] = '\0';

    return i + 1;
}

void imprime_invertido(char str[33]){
    char invertido[33];
    inverte_endian_bin(str, invertido);
    char invertido_completo[34]; // binário invertido com "0b" na frente sem o bit de sinal
    invertido_completo[0] = '0';
    invertido_completo[1] = 'b';
    invertido_completo[33] = '\0';

    // como um strcpy()
    for (int i = 1; i < 33; i++)
        invertido_completo[i + 1] = invertido[i];

    printf("%s\n", invertido_completo);
}

int bin_para_dec_invertido_comp_dois(char str[33]){
    char invertido[33];
    inverte_endian_bin(str, invertido);
    int decimal = bin_para_dec(invertido);

    return decimal;
}

void hex_endian_invertido(char str[33], char hex[11]){
    char invertido[33];
    inverte_endian_bin(str, invertido);
    bin_para_hex(invertido, hex);
}

void oct_endian_invertido(char str[33], char oct[15]){
    char invertido[33];
    inverte_endian_bin(str, invertido);
    bin_para_oct(invertido, oct);
}

int main(){
    char str[33];
    scanf(" %s", str);
    
    long int dec = bin_para_dec(str);
    printf("%li\n", dec);

    long int dec_endian = bin_para_dec_endian_invertido(str);
    printf("%li\n", dec_endian);

    char hex[11];
    bin_para_hex(str, hex);
    printf("%s\n", hex);

    char oct[15];
    bin_para_oct(str, oct);
    printf("%s\n", oct);

    imprime_invertido(str);

    int dec_endian_comp_dois = bin_para_dec_invertido_comp_dois(str);
    printf("%d\n", dec_endian_comp_dois);

    char hex_invertido[11]; 
    hex_endian_invertido(str, hex_invertido);
    printf("%s\n", hex_invertido);

    char oct_invertido[15];
    oct_endian_invertido(str, oct_invertido);
    printf("%s\n", oct_invertido);

    return 0;
}