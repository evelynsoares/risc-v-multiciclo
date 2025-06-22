.data
valor:   .word 5

.text
LOOP:
    addi t0, zero, 2
    addi t1, zero, 5
    add t0, t1, t0
    sub t0, t1, t0
    and t0, t1, t0
    or t0, t1, t0

    la t1, valor 	# carrega endereco
    lw t2, 0(t1)
    sw t2, 4(t1)

    beq t0, t1, FIM 	# nao deve pular pra FIM
    jal ra, FUNCAO	# pula e salva pc+4 em ra

VOLTA:
    jal zero, FIM 

FUNCAO:
    addi t0, zero, 3
    jalr zero, 0(ra)	# pula pra volta 

FIM:
    jal zero, FIM
