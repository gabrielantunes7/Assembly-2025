int read(int __fd, const void *__buf, int __n){
    int ret_val;
__asm__ __volatile__(
    "mv a0, %1           # file descriptor\n"
    "mv a1, %2           # buffer \n"
    "mv a2, %3           # size \n"
    "li a7, 63           # syscall write code (63) \n"
    "ecall               # invoke syscall \n"
    "mv %0, a0           # move return value to ret_val\n"
    : "=r"(ret_val)  // Output list
    : "r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
);
return ret_val;
}

void write(int __fd, const void *__buf, int __n)
{
__asm__ __volatile__(
    "mv a0, %0           # file descriptor\n"
    "mv a1, %1           # buffer \n"
    "mv a2, %2           # size \n"
    "li a7, 64           # syscall write (64) \n"
    "ecall"
    :   // Output list
    :"r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
);
}

void exit(int code)
{
__asm__ __volatile__(
    "mv a0, %0           # return code\n"
    "li a7, 93           # syscall exit (64) \n"
    "ecall"
    :   // Output list
    :"r"(code)    // Input list
    : "a0", "a7"
);
}

void _start()
{
int ret_code = main();
exit(ret_code);
}

#define STDIN_FD  0
#define STDOUT_FD 1

// Inicializa uma string totalmente zerada, para evitar problemas de memória
void inicializa_com_zero(char str[], int n){
    for (int i = 0; i < n; i++)
        str[i] = '\0';
}

// Função para transformar o número binário de 32 bits (complemento de dois) em decimal sem assinatura
unsigned long int bin_para_dec_unsigned(char str[33]){
    unsigned long int decimal = 0;

    // transforma em decimal
    for (int i = 0; i < 32; i++)
        decimal = (decimal * 2) + (str[i] - '0');

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

    invertido[32] = '\0';
}

// Função para transformar o número binário de 32 bits (unsigned e little-endian) em decimal
unsigned long int bin_para_dec_endian_invertido(char str[33]){
    unsigned long int decimal = 0;
    char invertido[33];
    inicializa_com_zero(invertido, 33);

    inverte_endian_bin(str, invertido);

    decimal = bin_para_dec_unsigned(invertido);

    return decimal;
}

// Função para imprimir um número decimal
void imprime_dec(long int valor){
    char decimal[13]; // maior número decimal é -2147483648 + '\n'
    inicializa_com_zero(decimal, 13);

    char aux[12]; // guarda o valor do decimal ao contrário
    inicializa_com_zero(aux, 12);
    
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
    decimal[i + 1] = '\0';

    write(STDOUT_FD, decimal, i + 1);
}

// Função para imprimir um número decimal
void imprime_dec_unsigned(unsigned long int valor){
    char decimal[13]; // maior número decimal é -2147483648 + '\n'
    inicializa_com_zero(decimal, 13);

    char aux[12]; // guarda o valor do decimal ao contrário
    inicializa_com_zero(aux, 12);
    
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
    decimal[i + 1] = '\0';

    write(STDOUT_FD, decimal, i + 1);
}

// Função para transformar a string do número binário numa string de número hexadecimal
// Retorna o tamanho da string
// hex tem 12 bits, porque o tamanho máximo do número é 8 bits, mais "0x" e '\0'
int bin_para_hex(char str[33], char hex[12]){
    hex[0] = '0';
    hex[1] = 'x';

    unsigned long int decimal = bin_para_dec_unsigned(str);

    // guarda o valor do número em hexa ao contrário
    char aux[9];
    inicializa_com_zero(aux, 9);

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
    hex[i + 3] = '\0';

    return i + 3;
}

// Função para transformar a string do número binário numa string de número octal
// Retorna o tamanho da string
// oct tem 16 bits, "0o" + 11 dígitos + '\n + '\0'
int bin_para_oct(char str[33], char oct[16]){
    oct[0] = '0';
    oct[1] = 'o';

    unsigned long int decimal = bin_para_dec_unsigned(str);

    char aux[13];
    inicializa_com_zero(aux, 13);

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
    oct[i + 3] = '\0';

    return i + 3;
}

void imprime_invertido(char str[33]){
    char invertido[33];
    inicializa_com_zero(invertido, 33);

    inverte_endian_bin(str, invertido);

    if (str[0] != '1'){
        char invertido_sem_sinal[32]; // tira o bit de sinal
        inicializa_com_zero(invertido_sem_sinal, 32);
        for (int i = 0; i < 32; i++)
            invertido_sem_sinal[i] = invertido[i + 1];

        write(STDOUT_FD, "0b", 2);
        write(STDOUT_FD, invertido_sem_sinal, 31);
        write(STDOUT_FD, "\n", 1);
    }
    // se for negativo, precisa incluir todos os bits
    else{
        write(STDOUT_FD, "0b", 2);
        write(STDOUT_FD, invertido, 32);
        write(STDOUT_FD, "\n", 1);
    }
}

// Função para transformar o binário (comp. de dois e little-endian) em decimal
long int bin_para_dec_invertido_comp_dois(char str[33]){
    char invertido[33];
    inicializa_com_zero(invertido, 33);

    inverte_endian_bin(str, invertido);
    long int decimal = bin_para_dec(invertido);

    return decimal;
}

// Função para tranformar o binário little-endian em hexadecimal
// Retorna o tamanho da string
int hex_endian_invertido(char str[33], char hex[12]){
    char invertido[33];
    inicializa_com_zero(invertido, 33);

    inverte_endian_bin(str, invertido);

    return bin_para_hex(invertido, hex);
}

// Função para tranformar o binário little-endian em octal
// Retorna o tamanho da string
int oct_endian_invertido(char str[33], char oct[16]){
    char invertido[33];
    inicializa_com_zero(invertido, 33);

    inverte_endian_bin(str, invertido);

    return bin_para_oct(invertido, oct);
}

int main(){
    char str[33];
    inicializa_com_zero(str, 33);
    int n = read(STDIN_FD, str, 33);
    
    long int dec = bin_para_dec(str);
    imprime_dec(dec);

    unsigned long int dec_endian = bin_para_dec_endian_invertido(str);
    imprime_dec_unsigned(dec_endian);

    char hex[12];
    inicializa_com_zero(hex, 12);
    int tam_hex = bin_para_hex(str, hex);
    write(STDOUT_FD, hex, tam_hex);

    char oct[16];
    inicializa_com_zero(oct, 16);
    int tam_oct = bin_para_oct(str, oct);
    write(STDOUT_FD, oct, tam_oct);

    imprime_invertido(str);

    long int dec_endian_comp_dois = bin_para_dec_invertido_comp_dois(str);
    imprime_dec(dec_endian_comp_dois);

    char hex_invertido[12];
    inicializa_com_zero(hex_invertido, 12); 
    int tam_hex_invertido = hex_endian_invertido(str, hex_invertido);
    write(STDOUT_FD, hex_invertido, tam_hex_invertido);

    char oct_invertido[16];
    inicializa_com_zero(oct_invertido, 16);
    int tam_oct_invertido = oct_endian_invertido(str, oct_invertido);
    write(STDOUT_FD, oct_invertido, tam_oct_invertido);

    return 0;
}