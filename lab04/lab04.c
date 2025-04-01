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

// Função para transformar uma string de número decimal em valor inteiro
long int str_para_dec(char str[6]){
    long int decimal = 0;
    for (int i = 1; i < 5; i++)
        decimal = decimal * 10 + (str[i] - '0');

    if (str[0] == '-')
        decimal = -decimal;
    
    return decimal;
}
    
// Função para transformar um número decimal em hexadecimal e imprimi-lo
void dec_para_hex(int val){
    char hex[11];
    unsigned int uval = (unsigned int) val, aux;

    hex[0] = '0';
    hex[1] = 'x';
    hex[10] = '\n';

    for (int i = 9; i > 1; i--){
        aux = uval % 16;
        if (aux >= 10)
            hex[i] = aux - 10 + 'A';
        else
            hex[i] = aux + '0';
        uval = uval / 16;
    }

    write(STDOUT_FD, hex, 11);
}

void inicializa_com_zero(char str[], int tam){
    for (int i = 0; i < tam; i++)
        str[i] = 0;
}

int main(){
    char dec1[6], dec2[6], dec3[6], dec4[6],
         dec5[6], dec6[6], dec7[6], dec8[6];
    char entrada[49];

    inicializa_com_zero(dec1, 6);
    inicializa_com_zero(dec2, 6);
    inicializa_com_zero(dec3, 6);
    inicializa_com_zero(dec4, 6);
    inicializa_com_zero(dec5, 6);
    inicializa_com_zero(dec6, 6);
    inicializa_com_zero(dec7, 6);
    inicializa_com_zero(dec8, 6);
    inicializa_com_zero(entrada, 49);

    int n = read(STDIN_FD, entrada, 48); // lê toda a linha de entrada
    for (int i = 0; i < 5; i++){
        dec1[i] = entrada[i];
        dec2[i] = entrada[i + 6];
        dec3[i] = entrada[i + 12];
        dec4[i] = entrada[i + 18];
        dec5[i] = entrada[i + 24];
        dec6[i] = entrada[i + 30];
        dec7[i] = entrada[i + 36];
        dec8[i] = entrada[i + 42];
    }

    long int dec1_int = str_para_dec(dec1);
    long int dec2_int = str_para_dec(dec2);
    long int dec3_int = str_para_dec(dec3);
    long int dec4_int = str_para_dec(dec4);
    long int dec5_int = str_para_dec(dec5);
    long int dec6_int = str_para_dec(dec6);
    long int dec7_int = str_para_dec(dec7);
    long int dec8_int = str_para_dec(dec8);

    long int N1 = dec1_int & dec2_int;
    long int N2 = dec3_int | dec4_int;
    long int N3 = dec5_int ^ dec6_int;
    long int N4 = ~(dec7_int & dec8_int);

    // "processado" = isolar somente os bits que interessam, zero no resto
    // isso é feito a partir de um "and" com uma máscara e um deslocamento, se necessário
    long int N1_processado = N1 & 255; // 255 pq oito bits menos significativos = 1
    long int N2_processado = (N2 & 255) << 8; // shift para a esquerda para posicionar os bits corretamente
    long int N3_processado = N3 & 4278190080; // 4278190080 pq oito bits mais significativos = 1
    long int N4_processado = (N4 & 4278190080) >> 8; // shift para a direita para posicionar os bits corretamente


    long int N_final = N1_processado + N2_processado + N3_processado + N4_processado;
    
    char hex[11];
    inicializa_com_zero(hex, 11);
    dec_para_hex(N_final);

    return 0;
}