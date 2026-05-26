.globl main

funcao_f:
    mv s2 a0
    li t0 0          
    addi t1 zero 5   
inicio:
    addi sp sp -4
    sw ra 0(sp) 
    beq t0 t1 endfor
    slli t3 t0 2
    add t5 s1 t3
    lw t4 0(t5)
    add t6 s2 t3      
    sw t4 0(t6)
    addi a0 zero 1
    mv a1 t4
    ecall
    addi t0 t0 1
    j inicio
endfor:
   lw ra 0(sp) 
   addi sp sp 4
   ret

main:
   li s1 0x0FFFFFE8  #base
   addi a0 zero 9    #id da syscall
   addi a1 zero 20   #bytes a serem alocados
   ecall
   jal funcao_f
