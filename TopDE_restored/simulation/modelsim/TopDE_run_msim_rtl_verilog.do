transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored {C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored/Parametros.v}
vlog -sv -work work +incdir+C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored {C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored/ramU.v}
vlog -sv -work work +incdir+C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored {C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored/ALUControl.v}
vlog -sv -work work +incdir+C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored {C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored/TopDE.v}
vlog -sv -work work +incdir+C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored {C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored/ALU.v}
vlog -sv -work work +incdir+C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored {C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored/Registers.v}
vlog -sv -work work +incdir+C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored {C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored/ImmGen.v}
vlog -sv -work work +incdir+C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored {C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored/ControlMulticiclo.v}
vlog -sv -work work +incdir+C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored {C:/Users/Evelyn/Downloads/GrupoD4_Lab2/GrupoD4_Lab2/TopDE_restored/Multiciclo2.v}

