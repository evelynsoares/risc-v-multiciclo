`ifndef PARAM
	`include "Parametros.v"
`endif

module TopDE (
	input logic CLOCK, Reset,
	input logic [4:0] Regin,
	output logic ClockDIV,
	output logic [31:0] PC,Instr,Regout,
	output logic [3:0] Estado
	);
	
	 logic [1:0] clk_div;  // contador de 2 bits

    initial begin
        clk_div <= 2'b00;
        ClockDIV <= 1'b0;
    end

    always @(posedge CLOCK) begin
        clk_div <= clk_div + 2'b01;
        ClockDIV <= clk_div[1];  // divide por 4
    end
	

	
/*	Uniciclo UNI1 (.clockCPU(ClockDIV), .clockMem(CLOCK), .reset(Reset), 
						.PC(PC), .Instr(Instr), .regin(Regin), .regout(Regout)); */

					
	Multiciclo MULT1 (.clockCPU(ClockDIV), .clockMem(CLOCK), .reset(Reset), 
						.PC(PC), .Instr(Instr), .regin(Regin), .regout(Regout), .estado(Estado));	
						
/* Pipeline PIP1 (.clockCPU(ClockDIV), .clockMem(CLOCK), .reset(Reset), 
						.PC(PC), .Instr(Instr), .regin(Regin), .regout(Regout)); */
		
	
endmodule
