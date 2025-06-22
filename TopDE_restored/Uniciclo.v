`ifndef PARAM
	`include "Parametros.v"
`endif

module Uniciclo (
	input logic clockCPU, clockMem,
	input logic reset,
	output reg [31:0] PC,
	output logic [31:0] Instr,
	input  logic [4:0] regin,
	output logic [31:0] regout
);

	// Inicialização
	initial begin
		PC <= TEXT_ADDRESS;
		Instr <= 32'b0;
		regout <= 32'b0;
	end

	// ******************** Sinais internos ********************
	logic [31:0] Leitura1, Leitura2, Imediato, entradaB, ValorEscrito, SaidaULA, MemData;
	logic Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite, Jump, Jalr;
	logic [1:0] ALUOp;
	logic [4:0] ControleULA;

	// ******************** Controladores ********************
	ControlUnit ctrl (
		.opcode(Instr[6:0]),
		.Branch(Branch),
		.MemRead(MemRead),
		.MemtoReg(MemtoReg),
		.ALUOp(ALUOp),
		.MemWrite(MemWrite),
		.ALUSrc(ALUSrc),
		.RegWrite(RegWrite),
		.Jump(Jump),
		.Jalr(Jalr)
	);

	ALUControl aluCtrl (
		.ALUOp(ALUOp),
		.funct3(Instr[14:12]),
		.funct7(Instr[31:25]),
		.ALUControlOut(ControleULA)
	);

	ImmGen gerador (
		.iInstrucao(Instr),
		.oImm(Imediato)
	);

	Registers banco (
		.iCLK(clockCPU),
		.iRST(reset),
		.iRegWrite(RegWrite),
		.iReadRegister1(Instr[19:15]),
		.iReadRegister2(Instr[24:20]),
		.iWriteRegister(Instr[11:7]),
		.iWriteData(ValorEscrito),
		.oReadData1(Leitura1),
		.oReadData2(Leitura2),
		.iRegDispSelect(regin),
		.oRegDisp(regout)
	);

	ALU alu (
		.iControl(ControleULA),
		.iA(Leitura1),
		.iB(entradaB),
		.oResult(SaidaULA)
	);

	// Seleção da entrada B da ULA
	assign entradaB = (ALUSrc) ? Imediato : Leitura2;

	// Valor a ser escrito no banco de registradores
	assign ValorEscrito = (Jump || Jalr) ? PC + 32'd4 : (MemtoReg ? MemData : SaidaULA);

	// ******************** Controle de PC ********************
	always @(posedge clockCPU or posedge reset)
		if (reset)
			PC <= TEXT_ADDRESS;
		else if (Jalr)
			PC <= (Leitura1 + Imediato) & ~32'd1; // jalr
		else if (Jump)
			PC <= PC + Imediato;                 // jal
		else if (Branch && (SaidaULA == 32'd0))
			PC <= PC + Imediato;                 // beq
		else
			PC <= PC + 32'd4;

	// ******************** Conexões de memória ********************

	assign EscreveMem = MemWrite;
	assign LeMem      = MemRead;

	// Instanciação das memórias
	ramI MemC (
		.address(PC[11:2]),
		.clock(clockMem),
		.data(),
		.wren(1'b0),
		.rden(1'b1),
		.q(Instr)
	);

	ramD MemD (
		.address(SaidaULA[11:2]),
		.clock(clockMem),
		.data(Leitura2),
		.wren(EscreveMem),
		.rden(LeMem),
		.q(MemData)
	);

endmodule
