module ALUControl (
    input  [1:0] ALUOp,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output logic [4:0] ALUControlOut
);

always_comb begin
    case (ALUOp)
        2'b00: ALUControlOut = OPADD;  // lw, sw
        2'b01: ALUControlOut = OPSUB;  // beq
        2'b10: begin                   // Tipo R
            case (funct3)
                FUNCT3_ADD: ALUControlOut = (funct7 == FUNCT7_SUB) ? OPSUB : OPADD;
                FUNCT3_AND: ALUControlOut = OPAND;
                FUNCT3_OR:  ALUControlOut = OPOR;
                FUNCT3_SLT: ALUControlOut = OPSLT;
                default:    ALUControlOut = OPNULL;
            endcase
        end
        2'b11: begin                   // Tipo I (addi)
            case (funct3)
                FUNCT3_ADD: ALUControlOut = OPADD;  // addi
                default:    ALUControlOut = OPNULL;
            endcase
        end
        default: ALUControlOut = OPNULL;
    endcase
end

endmodule
