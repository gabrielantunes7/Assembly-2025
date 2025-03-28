#include <stdio.h>
#include <stdlib.h>

#define STDIN_FD  0
#define STDOUT_FD 1

// Função para transformar o número binário de 32 bits (complemento de dois) em decimal sem assinatura
long int bin_para_dec_unsigned(char str[33]){
    long int decimal = 0;

    // transforma em decimal
    for (int i = 0; i < 32; i++)
        decimal = (decimal << 1) | (str[i] - '0');

    return decimal;
}

// Função para transformar o número binário de 32 bits (complemento de dois) em decimal
long int bin_para_dec(char str[33]){
    int negativo = (str[0] == '1');
    long int decimal = 0;

    // não precisa inverter bits
    if (!negativo)
        decimal = bin_para_dec_unsigned(str);
    
    else{
        long int complemento = 0;
        
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

    invertido[32] = '\n';
}

// Função para transformar o número binário de 32 bits (unsigned e little-endian) em decimal
long int bin_para_dec_endian_invertido(char str[33]){
    long int decimal = 0;
    char invertido[33];
    inverte_endian_bin(str, invertido);

    decimal = bin_para_dec_unsigned(invertido);

    return decimal;
}

// Função para imprimir um número decimal
void imprime_dec(long int valor){
    char decimal[12]; // maior número decimal é -2147483648
    char aux[12]; // guarda o valor do decimal ao contrário
    
    int i = 0;

    // se for negativo, primeiro caractere é '-' e transforma em positivo
    if (valor < 0){
        decimal[0] = '-';
        valor = -valor;
        i = 1;
    }

    while (valor > 0){
        aux[i] = '0' + valor % 10;
        valor /= 10;
        i++;
    }

    aux[i] = '\0';

    if (decimal[0] == '-')
        for (int j = 1; j < i + 1; j++)
            decimal[j] = aux[i - j];
    else
        for (int j = 0; j < i; j++)
            decimal[j] = aux[i - j - 1];
        

    decimal[i] = '\n';

    printf("%s", decimal);
}

// Função para transformar a string do número binário numa string de número hexadecimal
// Retorna o tamanho da string
// hex tem 11 bits, porque o tamanho máximo do número é 8 bits, mais "0x" e '\0'
int bin_para_hex(char str[33], char hex[11]){
    hex[0] = '0';
    hex[1] = 'x';

    long int decimal = bin_para_dec_unsigned(str);

    // guarda o valor do número em hexa ao contrário
    char aux[9];
    int i = 0;
    if (decimal == 0)
        hex[i + 2] = '0';
    else{
        // converte para hexa (divisões sucessivas)
        while (decimal > 0){
            int valor = decimal % 16;
            if (valor < 10)
                aux[i] = '0' + valor;
            else
                aux[i] = 'a' + valor - 10;
            decimal /= 16;
            i++;
        }
        aux[i] = '\0';

        for (int j = 0; j < i; j++)
            hex[j + 2] = aux[i - 1 - j];
    }

    hex[i + 2] = '\n';

    return i + 1;
}

// Função para transformar a string do número binário numa string de número octal
// Retorna o tamanho da string
// oct tem 15 bits, "0o" + 11 dígitos + '\0'
int bin_para_oct(char str[33], char oct[15]){
    oct[0] = '0';
    oct[1] = 'o';

    long int decimal = bin_para_dec_unsigned(str);

    char aux[13];
    int i = 0;
    if (decimal == 0)
        oct[i + 2] = '0';
    else{
        while (decimal > 0){
            int valor = decimal % 8;
            aux[i] = '0' + valor;
            decimal /= 8;
            i++;
        }
        aux[i] = '\0';

        for (int j = 0; j < i; j++)
            oct[j + 2] = aux[i - 1 - j];
    }

    oct[i + 2] = '\n';

    return i + 1;
}

void imprime_invertido(char str[33]){
    char invertido[33];
    inverte_endian_bin(str, invertido);

    if (str[0] != '1'){
        char invertido_completo[34]; // binário invertido com "0b" na frente sem o bit de sinal
        invertido_completo[0] = '0';
        invertido_completo[1] = 'b';
        invertido_completo[33] = '\n';

        // como um strcpy()
        for (int i = 1; i < 33; i++)
            invertido_completo[i + 1] = invertido[i];
        
        printf("%s", invertido_completo);
    }
    // se for negativo, precisa incluir todos os bits
    else{
        char invertido_completo[35]; // binário invertido com "0b" na frente com o bit de sinal
        invertido_completo[0] = '0';
        invertido_completo[1] = 'b';
        invertido_completo[34] = '\n';

        // como um strcpy()
        for (int i = 1; i < 33; i++)
            invertido_completo[i + 2] = invertido[i];
        
        printf("%s", invertido_completo);
    }
}

// Função para transformar o binário (comp. de dois e little-endian) em decimal
long int bin_para_dec_invertido_comp_dois(char str[33]){
    char invertido[33];
    inverte_endian_bin(str, invertido);
    long int decimal = bin_para_dec(invertido);

    return decimal;
}

// Função para tranformar o binário little-endian em hexadecimal
// Retorna o tamanho da string
int hex_endian_invertido(char str[33], char hex[11]){
    char invertido[33];
    inverte_endian_bin(str, invertido);

    return bin_para_hex(invertido, hex);
}

// Função para tranformar o binário little-endian em octal
// Retorna o tamanho da string
int oct_endian_invertido(char str[33], char oct[15]){
    char invertido[33];
    inverte_endian_bin(str, invertido);

    return bin_para_oct(invertido, oct);
}

int main(){
    char str[33];
    scanf(" %s", str);
    
    long int dec = bin_para_dec(str);
    imprime_dec(dec);

    long int dec_endian = bin_para_dec_endian_invertido(str);
    imprime_dec(dec_endian);

    char hex[11];
    bin_para_hex(str, hex);
    printf("%s\n", hex);

    char oct[15];
    bin_para_oct(str, oct);
    printf("%s\n", oct);

    imprime_invertido(str);

    int dec_endian_comp_dois = bin_para_dec_invertido_comp_dois(str);
    imprime_dec(dec_endian_comp_dois);

    char hex_invertido[11]; 
    hex_endian_invertido(str, hex_invertido);
    printf("%s\n", hex_invertido);

    char oct_invertido[15];
    oct_endian_invertido(str, oct_invertido);
    printf("%s\n", oct_invertido);

    return 0;
}