module ControlUnit (
    input  [6:0] opcode,
    output logic Branch,
    output logic MemRead,
    output logic MemtoReg,
    output logic [1:0] ALUOp,
    output logic MemWrite,
    output logic ALUSrc,
    output logic RegWrite,
    output logic Jump,
    output logic Jalr
);

always_comb begin
    // valores padrão (default)
    Branch     = 0;
    MemRead    = 0;
    MemtoReg   = 0;
    ALUOp      = 2'b00;
    MemWrite   = 0;
    ALUSrc     = 0;
    RegWrite   = 0;
    Jump       = 0;
    Jalr       = 0;

    case (opcode)
        OPC_RTYPE: begin
            RegWrite   = 1;
            ALUOp      = 2'b10;
        end
        OPC_OPIMM: begin
            RegWrite   = 1;
            ALUSrc     = 1;
            ALUOp      = 2'b11;  // Tipo I
        end
        OPC_LOAD: begin
            MemRead    = 1;
            MemtoReg   = 1;
            ALUSrc     = 1;
            RegWrite   = 1;
            ALUOp      = 2'b00;
        end
        OPC_STORE: begin
            MemWrite   = 1;
            ALUSrc     = 1;
            ALUOp      = 2'b00;
        end
        OPC_BRANCH: begin
            Branch     = 1;
            ALUOp      = 2'b01;
        end
        OPC_JAL: begin
            Jump       = 1;
            RegWrite   = 1;
        end
        OPC_JALR: begin
            Jalr       = 1;
            RegWrite   = 1;
            ALUSrc     = 1;
        end
    endcase
end

endmodule
