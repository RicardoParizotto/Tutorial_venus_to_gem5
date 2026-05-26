# Tutorial: Portando Código Assembly do Venus para o gem5

## Introdução

Este tutorial guia você no processo de portação de código assembly RISC-V desenvolvido no **Venus** para o simulador **gem5**.

 **Nota**: Código assembly desenvolvido no Venus não funciona diretamente no gem5. É necessário fazer correções de sintaxe e estrutura.

---

## Pré-requisitos

- Código assembly funcionando no Venus
- gem5 instalado e compilado
- Toolchain RISC-V: `riscv64-linux-gnu-gcc`

---

## Passos de Migração

### Passo 1: Corrigir Sintaxe - Adicionar Vírgulas

O Venus permite instruções sem separação por vírgulas. No gem5 (com ferramentas GCC), é necessário adicionar vírgulas entre operandos.

**Antes (Venus):**
```assembly
addi a0 zero 1
mv a1 t4
```

**Depois (gem5):**
```assembly
addi a0, zero, 1
mv a1, t4
```

---

### Passo 2: Configurar Preservação do Endereço de Retorno

Geralmente programas no Venus não tinham uma função global ou não retornavam valores. No gem5, é necessário preservar o endereço de retorno.

**No início da `main`:**
```assembly
addi sp, sp, -4
sw ra, 0(sp)
```

**No final da `main` (antes de retornar):**
```assembly
lw ra, 0(sp)
addi sp, sp, 4
```

---

### Passo 3: Adicionar Instrução de Retorno

Use a instrução `ret` para retornar corretamente após a execução do código.

```assembly
main:
    # seu código aqui
    ret
```

---

### Passo 4: Eliminar Endereços de Memória Estática

Em gem5, usar endereços de memória fixos (como `0x0FFFFFE8` do Venus) pode gerar **Segmentation Fault** por pertencerem a espaços protegidos.

#### 4.1 Solução: Use a Diretiva `.data`

Use a diretiva de assembler `.data` para definir uma seção de dados estruturada. O montador se encarregará de posicionar as variáveis em uma região segura da memória durante a linkagem.

```assembly
.data
    my_vector: .word 10, 20, 30, 40, 50
```

#### 4.2 Carregar Endereço com `la` (Load Address)

Na seção `.text`, use a instrução `la` para carregar o endereço da memória alocada.

```assembly
.text
.globl main

main:
    la s1, my_vector
    # seu código aqui
```

---

### Passo 5: Substituir Chamadas de Sistema pela Libc

Ao invés de programar diretamente via Assembly as syscalls do kernel emulado do gem5, aproveite que a toolchain do GCC fornece suporte à biblioteca C.

#### 5.1 Exemplo: `malloc`

Substitua chamadas de sistema proprietárias por funções da libc:

```assembly
# malloc(20) para 5 ints de 4 bytes
li   a0, 20
call malloc
```

#### 5.2 Exemplo: `printf`

Configure uma seção somente leitura para armazenar a string de formato:

```assembly
.section .rodata
    fmt: .string "%d\n"
```

Substitua syscalls por chamadas a `printf`:

| Antes (Venus) | Depois (gem5) |
|:---|:---|
| `addi a0 zero 1` | `la a0, fmt` |
| `mv a1 t4` | `mv a1, t4` |
| `ecall` | `call printf` |

#### 5.3 Aviso: Preservação de Registradores

As funções `printf` e `malloc` **não preservam** registradores temporários (`t0`...`tn`). Substitua registradores temporários por registradores salvos:

| Registrador Temporário | Registrador Salvo |
|:---|:---|
| `t0` | `s3` |
| `t1` | `s4` |
| `t3` | `s5` |

---

## Configuração do Ambiente e Execução

### Compilar o Código Assembly

Use o compilador RISC-V GCC para compilar o arquivo assembly em um binário estático:

```bash
riscv64-linux-gnu-gcc -static solucao.s -o solucao.riscv
```

**Parâmetros:**
- `-static`: Cria um binário estático (sem dependências de bibliotecas compartilhadas)
- `solucao.s`: Arquivo assembly de entrada
- `-o solucao.riscv`: Nome do binário de saída

---

### Simular no gem5

Execute o binário compilado usando o simulador gem5:

```bash
./gem5/build/RISCV/gem5.opt models/<model_name>.py --binary programs/solucao.riscv
```

**Parâmetros:**
- `gem5.opt`: Simulador gem5 compilado
- `models/<model_name>.py`: Arquivo de configuração do modelo de simulação
- `--binary`: Caminho para o binário RISC-V compilado

---
