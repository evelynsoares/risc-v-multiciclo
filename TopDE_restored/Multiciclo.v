`ifndef PARAM
	`include "Parametros.v"
`endif

module Multiciclo (
	input logic clockCPU, clockMem,
	input logic reset,
	output logic [31:0] PC,
	output logic [31:0] Instr,
	input logic [4:0] regin,
	output logic [31:0] regout,
	output logic [3:0] estado
);
	// Sinais de controle
	wire MemRead, MemWrite, RegWrite;
	wire ALUSrcA, ALUSrcB, MemtoReg, Branch, Jump, Jalr;
	wire PCWrite, PCWriteCond, IRWrite, IorD_MemAddrSelect, RegDst;
	wire [1:0] ALUOp_Ctrl;
	wire [1:0] PCSource_Ctrl;

	wire [6:0] opcode = Instr[6:0];
	wire [2:0] funct3 = Instr[14:12];
	wire [6:0] funct7 = Instr[31:25];

	
	wire[31:0] oReadData1_wire;
	wire[31:0] oReadData2_wire;
	wire[31:0] oImm_wire;
	wire [31:0] oResult_ULA_wire;

	logic zero_flag_ULA;
	logic [4:0] aluControlOut;

	// Instância do controlador
	ControlMulticiclo ctrl (
		.clock(clockCPU),
		.reset(reset),
		.opcode(opcode),
		.funct3(funct3),
		.funct7(funct7),
		.zero_flag(zero_flag_ULA),
		.estadoAtual(estado),
		.proximoEstado(),
		.MemRead(MemRead),
		.MemWrite(MemWrite),
		.RegWrite(RegWrite),
		.ALUSrcA(ALUSrcA),
		.ALUSrcB(ALUSrcB),
		.MemtoReg(MemtoReg),
		.Branch(Branch),
		.Jump(Jump),
		.Jalr(Jalr),
		.PCWrite(PCWrite),
		.PCWriteCond(PCWriteCond),
		.PCSource(PCSource_Ctrl),
		.RegDst(RegDst),
		.IRWrite(IRWrite),
		.IorD_MemAddrSelect(IorD_MemAddrSelect),
		.ALUOp(ALUOp_Ctrl)
	);

	// Registradores e sinais auxiliares
	logic [31:0] ReadData1_Reg, ReadData2_Reg;
	logic [31:0] SignExtendedImmediate_Reg;
	logic [31:0] ALUResult_Reg;
	logic [31:0] MemReadData_Reg;
	logic [31:0] MemAddress, MemDataIn, MemDataOut_from_RAM;

	ramU MemU (
		.clock(clockMem),
		.data(MemDataIn),
		.address(MemAddress[10:0]),
		.rden(MemRead),
		.wren(MemWrite),
		.q(MemDataOut_from_RAM)
	);

	assign MemAddress = IorD_MemAddrSelect ? ALUResult_Reg : PC;
	assign MemDataIn = ReadData2_Reg;

	ImmGen gerador (
		.iInstrucao(Instr),
		.oImm(oImm_wire)
	);

	Registers banco (
		.iCLK(clockCPU),
		.iRST(reset),
		.iRegWrite(RegWrite),
		.iReadRegister1(Instr[19:15]),
		.iReadRegister2(Instr[24:20]),
		.iWriteRegister(RegDst ? Instr[11:7] : Instr[24:20]),
		.iWriteData(MemtoReg ? MemReadData_Reg : ALUResult_Reg),
		.oReadData1(oReadData1_wire),
		.oReadData2(oReadData2_wire),
		.iRegDispSelect(regin),
		.oRegDisp(regout)
	);

	ALUControl aluCtrl (
		.ALUOp(ALUOp_Ctrl),
		.funct3(funct3),
		.funct7(funct7),
		.ALUControlOut(aluControlOut)
	);

	ALU alu (
		.iControl(aluControlOut),
		.iA(ALUSrcA ? PC : ReadData1_Reg),
		.iB(ALUSrcB ? SignExtendedImmediate_Reg : ReadData2_Reg),
		.oResult(oResult_ULA_wire),
		.zero(zero_flag_ULA)
	);

	always_ff @(posedge clockCPU or posedge reset) begin
		if (reset) Instr <= 32'b0;
		else if (IRWrite) Instr <= MemDataOut_from_RAM;
	end

	always_ff @(posedge clockCPU or posedge reset) begin
		if (reset) PC <= TEXT_ADDRESS;
		else begin
			if (PCWrite) begin
				case (PCSource_Ctrl)
					2'b00: PC <= PC + 32'd4;
					default: PC <= ALUResult_Reg;
				endcase
			end else if (PCWriteCond && Branch && zero_flag_ULA)
				PC <= ALUResult_Reg;
		end
	end

	always_ff @(posedge clockCPU or posedge reset) begin
		if (reset) MemReadData_Reg <= 32'b0;
		else MemReadData_Reg <= MemDataOut_from_RAM;
	end

	always_ff @(posedge clockCPU or posedge reset) begin
		if (reset) begin
			ReadData1_Reg <= 32'b0;
			ReadData2_Reg <= 32'b0;
			SignExtendedImmediate_Reg <= 32'b0;
		end else begin
			ReadData1_Reg <= oReadData1_wire;
			ReadData2_Reg <= oReadData2_wire;
			SignExtendedImmediate_Reg <= oImm_wire;
		end
	end

	always_ff @(posedge clockCPU or posedge reset) begin
		if (reset) ALUResult_Reg <= 32'b0;
		else ALUResult_Reg <= oResult_ULA_wire;
	end

endmodule
