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

void write(int __fd, const void *__buf, int __n){
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

void exit(int code){
    __asm__ __volatile__(
        "mv a0, %0           # return code\n"
        "li a7, 93           # syscall exit (64) \n"
        "ecall"
        :   // Output list
        :"r"(code)    // Input list
        : "a0", "a7"
    );
}

void _start(){
    int ret_code = main();
    exit(ret_code);
}

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

// Função para transformar o número binário de 32 bits (unsigned e little-endian) em decimal
int bin_para_dec_endian_invertido(char str[33]){
    int decimal = 0;
    char byte1[9];
    char byte2[9];
    char byte3[9];
    char byte4[9];

    for (int i = 0; i < 8; i++){
        byte1[i] = str[i];
        byte2[i] = str[i + 8];
        byte3[i] = str[i + 16];
        byte4[i] = str[i + 24];
    }

    byte1[8] = byte2[8] = byte3[8] = byte4[8] = '\0';

    for (int i = 0; i < 8; i++)
        str[i] = byte1[i];
    for (int i = 8; i < 16; i++)
        str[i] = byte2[i];
    for (int i = 16; i < 24; i++)
        str[i] = byte3[i];
    for (int i = 24; i < 32; i++)
        str[i] = byte4[i];

    // com os bytes invertidos, converte de binário para decimal
    for (int i = 0; i < 32; i++)
        decimal = (decimal << 1) | (str[i] - '0');

    return decimal;
}

// Função para imprimir um número decimal
void imprime_dec(int valor){
    char buffer[12]; // maior número decimal é -2147483648
    char *ptr = buffer + 11; // ponteiro no LSB do número
    *ptr = '\n';
    ptr--;
    // o ponteiro é usado para indicar qual a primeira posição válida do número na string

    int negativo = (valor < 0);
    if (negativo)
        valor = -valor;

    do {
        *ptr = valor % 10 + '0';
        valor /= 10;
        ptr--;
    } while (valor > 0);

    if (negativo){
        *ptr = '-'; // coloca o sinal de menos no MSB
        ptr--;
    }

    ptr++;

    write(1, ptr, buffer + 12 - ptr);
}

int main(){
    char str[33];
    int n = read(STDIN_FD, str, 33);
    
    int dec = bin_para_dec(str);
    imprime_dec(dec);

    int dec_endian = bin_para_dec_endian_invertido(str);
    imprime_dec(dec_endian);

    write(STDOUT_FD, str, n);
    return 0;
}