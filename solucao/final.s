.section .rodata 
     fmt: .string "%d\n"


.data
 my_vector:  .word 10, 20, 30, 40, 50

.text
.globl main

funcao_f:

    addi sp, sp, -4
    sw ra, 0(sp) 

    mv s2, a0
    li s3, 0          
    addi s4, zero, 5   
inicio:
    beq s3, s4, endfor
    slli s5, s3, 2
    add t5, s1, s5
    lw t4, 0(t5)
    add t6, s2, s5      
    sw t4, 0(t6)
    la   a0, fmt
    mv   a1, t4
    call printf

    addi s3, s3, 1
    j inicio
endfor:
   lw ra, 0(sp) 
   addi sp, sp, 4
   ret

main:

    addi sp, sp, -4
    sw ra, 0(sp) 
   
   
   la s1, my_vector 


    li   a0, 20
    call malloc

   jal funcao_f
  
    
   lw ra, 0(sp) 
   addi sp, sp, 4
 
   ret
