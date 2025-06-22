// ControlMulticiclo.v
`ifndef PARAM
	`include "Parametros.v"
`endif

module ControlMulticiclo (
	input logic clock,
	input logic reset,
	input logic [6:0] opcode,
	input logic [2:0] funct3,
	input logic [6:0] funct7,
	input logic zero_flag,
	output logic [3:0] estadoAtual,
	output logic [3:0] proximoEstado,
	output logic MemRead,
	output logic MemWrite,
	output logic RegWrite,
	output logic ALUSrcA,
	output logic ALUSrcB,
	output logic MemtoReg,
	output logic Branch,
	output logic Jump,
	output logic Jalr,
	output logic PCWrite,
	output logic PCWriteCond,
	output logic [1:0] PCSource,
	output logic RegDst,
	output logic IRWrite,
	output logic IorD_MemAddrSelect,
	output logic [1:0] ALUOp
);

	typedef enum logic [3:0] {
		IFETCH			= 4'd0,
		WAIT_IF			= 4'd1,
		ID				= 4'd2,
		EX_R			= 4'd3,
		EX_I			= 4'd4,
		EX_MEM_ADDR		= 4'd5,
		WAIT_MEM1		= 4'd6,
		WAIT_MEM2		= 4'd7,
		MEM_READ_WB		= 4'd8,
		MEM_WRITE_FINISH	= 4'd9,
		WB				= 4'd10,
		BRANCH_EX		= 4'd11,
		JUMP_EX			= 4'd12,
		JALR_EX			= 4'd13
	} state_t;

	state_t estadoReg, proxReg;
	assign estadoAtual = estadoReg;
	assign proximoEstado = proxReg;

	always_ff @(posedge clock or posedge reset) begin
		if (reset)
			estadoReg <= IFETCH;
		else
			estadoReg <= proxReg;
	end

	always_comb begin
		proxReg = IFETCH;
		case (estadoReg)
			IFETCH: proxReg = WAIT_IF;
			WAIT_IF: proxReg = ID;
			ID: begin
				case (opcode)
					OPC_RTYPE: proxReg = EX_R;
					OPC_OPIMM: proxReg = EX_I;
					OPC_LOAD: proxReg = EX_MEM_ADDR;
					OPC_STORE: proxReg = EX_MEM_ADDR;
					OPC_BRANCH: proxReg = BRANCH_EX;
					OPC_JAL: proxReg = JUMP_EX;
					OPC_JALR: proxReg = JALR_EX;
					default: proxReg = IFETCH;
				endcase
			end
			EX_R: proxReg = WB;
			EX_I: proxReg = WB;
			EX_MEM_ADDR: proxReg = WAIT_MEM1;
			WAIT_MEM1: proxReg = WAIT_MEM2;
			WAIT_MEM2: proxReg = (opcode == OPC_LOAD) ? MEM_READ_WB : MEM_WRITE_FINISH;
			MEM_READ_WB: proxReg = WB;
			MEM_WRITE_FINISH: proxReg = IFETCH;
			WB: proxReg = IFETCH;
			BRANCH_EX: proxReg = IFETCH;
			JUMP_EX: proxReg = IFETCH;
			JALR_EX: proxReg = IFETCH;
			default: proxReg = IFETCH;
		endcase
	end

	always_comb begin
		MemRead = 0;
		MemWrite = 0;
		RegWrite = 0;
		ALUSrcA = 0;
		ALUSrcB = 0;
		MemtoReg = 0;
		Branch = 0;
		Jump = 0;
		Jalr = 0;
		ALUOp = 2'b00;
		PCWrite = 0;
		PCWriteCond = 0;
		PCSource = 2'b00;
		RegDst = 0;
		IRWrite = 0;
		IorD_MemAddrSelect = 0;

		case (estadoReg)
			IFETCH: begin
				MemRead = 1;
				IRWrite = 1;
				IorD_MemAddrSelect = 0;
				PCWrite = 1;
				PCSource = 2'b00;
			end
			WAIT_IF: ;
			ID: ;
			EX_R: begin
				ALUOp = 2'b10;
				ALUSrcA = 0;
				ALUSrcB = 0;
				RegDst = 1;
			end
			EX_I: begin
				ALUSrcA = 0;
				ALUSrcB = 1;
				ALUOp = 2'b11;
				RegDst = 0;
			end
			EX_MEM_ADDR: begin
				ALUSrcA = 0;
				ALUSrcB = 1;
				ALUOp = 2'b00;
				IorD_MemAddrSelect = 1;
			end
			WAIT_MEM1: ;
			WAIT_MEM2: begin
				if (opcode == OPC_LOAD) MemRead = 1;
				else if (opcode == OPC_STORE) MemWrite = 1;
			end
			MEM_READ_WB: MemtoReg = 1;
			MEM_WRITE_FINISH: MemWrite = 1;
			WB: begin
				RegWrite = 1;
				if (opcode == OPC_LOAD) MemtoReg = 1;
				RegDst = (opcode == OPC_RTYPE || opcode == OPC_OPIMM || opcode == OPC_LOAD) ? 1 : 0;
			end
			BRANCH_EX: begin
				ALUSrcA = 0;
				ALUSrcB = 0;
				ALUOp = 2'b01;
				PCWriteCond = 1;
				PCSource = 2'b01;
			end
			JUMP_EX: begin
				Jump = 1;
				RegWrite = 1;
				RegDst = 1;
				MemtoReg = 0;
				PCWrite = 1;
				PCSource = 2'b10;
			end
			JALR_EX: begin
				Jalr = 1;
				RegWrite = 1;
				RegDst = 1;
				MemtoReg = 0;
				ALUSrcA = 0;
				ALUSrcB = 1;
				ALUOp = 2'b00;
				PCWrite = 1;
				PCSource = 2'b11;
			end
		endcase
	end

endmodule
