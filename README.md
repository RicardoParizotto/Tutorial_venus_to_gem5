# Tutorial_venus_to_gem5

Do Venus para o Gem5

Neste tutorial, vamos pegar um código elaborado no Venus e portá-lo no gem5. O código assembly elaborado no Venus não funciona diretamente no gem5 e exige as seguintes correções de sintaxe e estrutura:

Considere o seguinte código do repositório, que recebe um vetor de char, que é geralmente configurado pelo usuário na interface do Venus. Ao migrarmos para o gem5, a história é outra 🙂


Passo 1: Arrumar a sintaxe: O Venus permite expressar instruções sem separação por vírgulas. Porém, como vamos usar as ferramentas do GCC, será necessário adicionar Vírgulas em Instruções. Insira vírgulas em todas as instruções do código.

Exemplo:
    addi a0 zero 1
    mv a1 t4
    addi a0, zero, 1
    mv a1, t4



Passo 2: Retorno de Função: Geralmente fazíamos programas que não tinham uma função “global”, ou que tinha, mas nem sempre retornava um valor. Para executar corretamente nosso código no gem5, temos que preservar e restaurar ra na main. Garanta que existe uma função main, e na função main, adicione as seguintes instruções no início:

No início da main
addi sp, sp, -4
sw ra, 0(sp) 


Por fim antes de retornar, adicione no fim da main
lw ra, 0(sp) 
addi sp, sp, 4


Passo 3: Adicionar Retorno de Função: Na função main, use a instrução ret para retornar corretamente após a execução do código.

Passo 4: Eliminação de Endereços de Memória Estática, Em gem5, usar endereços de memória fixos (como 0x0FFFFFE8 do Venus) pode gerar um Segmentation Fault por pertencerem ao espaço protegido do sistema operacional emulado.


4.1Solução: Use a diretiva de assembler .data para definir uma seção de dados estruturada. O
O montador se encarregará de posicionar as variáveis em uma região segura da memória durante a linkagem do binário.

.data
 my_vector:  .word 10, 20, 30, 40, 50



4.1 Na seção .text, use a instrução la (Load Address) para carregar o endereço da memória alocada (Ex: la s1, my_vector).

.text
.globl main
. . .

main:
. . .
la s1, my_vector 



Passo 5: Substituição das Chamadas de Sistema (Uso da Libc)
Ao invés de programar diretamente via Assembly a chamada bruta ao kernel emulado do gem5,aproveite que a toolchain do GCC fornece suporte à biblioteca C. Substitua as syscalls proprietárias do Venus por chamadas simplificadas a malloc e printf.

   # malloc(20)  5 ints de 4 bytes
    li   a0, 20
    call malloc


De maneira similar, o mesmo pode/deve ser feito para mostrar o inteiro. No venus, temos uma chamada de sistema que permite fazer isso.
No gem5, primeiro configure uma seção somente leitura para armazenar a string de formato para printf:

.section .rodata 
     fmt: .string "%d\n"


E substituir no corpo da nossa função 

Substituir:                         Por:
    addi a0 zero 1
    mv a1 t4
    ecall
    la   a0, fmt
    mv   a1, t4
    call printf



Ao fazer isso, porém, vamos criar um problema: as variaveis temporarias t0…tn não são preservadas internamente por printf e malloc. Isso vai exigir substituir elas. Por hora, vamos apenas substituí-las por variáveis do tipo S. 


Registrador Original (Temporário)
t0
t1
t3
Novo Registrador Substituto

(Salvo)
s3
s4
s5





Configurando o Ambiente e Rodando o Código RISC-V

Para rodar um código em assembly do RISC-V no gem5, siga estes passos:

Compilar o Código Assembly: Use o riscv64-linux-gnu-gcc para compilar o arquivo assembly (sum.s) em um binário RISC-V estático (sum.riscv). 
Comando:
riscv64-linux-gnu-gcc -static solucao.s -o solucao.riscv

Simular no gem5: Execute o binário compilado usando o simulador gem5.opt, especificando o modelo de simulação e o caminho para o binário
./gem5/build/RISCV/gem5.opt   models/<model_name>.py   --binary programs/solucao.riscv


