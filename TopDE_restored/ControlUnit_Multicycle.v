// Parametros.v precisará definir os estados
// F_FETCH = 0, F_DECODE = 1, F_EXECUTE = 2, F_MEMORY = 3, F_WRITEBACK = 4, etc.
// E os estados de espera se aplicável (Instruction_Wait, Data_Wait)


//estados DO GEMINI

`ifndef PARAM
	`include "Parametros.v"
`endif

module ControlUnit_Multicycle (
    input logic clock, reset,
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    input logic zero, // Saída da ULA para branches

    // Sinais de controle de saída
    output logic PCWrite, PCWriteCond, IorD, MemRead, MemWrite, IRWrite, RegWrite, MemtoReg,
    output logic ALUSrcA, ALUSrcB, PCSource, RegDst,
    output logic [1:0] ALUOp,
    // ... outros sinais de controle
    output logic [3:0] current_state_out // Para depuração, mostrar o estado atual
);

// Estados da máquina de estados
typedef enum logic [3:0] { // Use um número de bits apropriado para a quantidade de estados
    STATE_FETCH_INSTR,
    STATE_DECODE,
    STATE_EXECUTE_R_TYPE,
    STATE_EXECUTE_LOAD_STORE,
    STATE_MEMORY_ACCESS_LOAD,
    STATE_MEMORY_ACCESS_STORE,
    STATE_WRITE_BACK_LOAD,
    STATE_BRANCH_EXECUTE,
    STATE_JUMP_EXECUTE,
    STATE_JALR_EXECUTE,
    // Adicionar estados de espera para memória de 2 ciclos
    STATE_FETCH_WAIT1,
    STATE_FETCH_WAIT2,
    STATE_LOAD_WAIT1,
    STATE_LOAD_WAIT2
} State_t;

State_t current_state, next_state;

// Registrador de estado
always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        current_state <= STATE_FETCH_INSTR;
    end else begin
        current_state <= next_state;
    end
end

// Lógica para determinar next_state e sinais de controle
always_comb begin
    // Valores padrão para evitar latches ou X's
    PCWrite = 0; PCWriteCond = 0; IorD = 0; MemRead = 0; MemWrite = 0; IRWrite = 0; RegWrite = 0; MemtoReg = 0;
    ALUSrcA = 0; ALUSrcB = 0; PCSource = 0; RegDst = 0;
    ALUOp = 2'b00; // Default ALUOp (e.g., add para endereço)
    current_state_out = current_state; // Para depuração

    case (current_state)
        STATE_FETCH_INSTR: begin
            // Ações: PC é o endereço, MemRead, IRWrite
            // IorD = 0 (seleciona PC para memória)
            MemRead = 1;
            IRWrite = 1; // Escreve a instrução no Instruction Register
            // PC = PC + 4
            // Proximo estado: Depende da latência da memória.
            next_state = STATE_FETCH_WAIT1; // Vai para o estado de espera
        end

        STATE_FETCH_WAIT1: begin
            // Ações: Nenhuma, apenas espera
            next_state = STATE_FETCH_WAIT2;
        end

        STATE_FETCH_WAIT2: begin
            // Ações: Instrução está disponível. Decodificar
            next_state = STATE_DECODE;
        end

        STATE_DECODE: begin
            // Ações: Lê registradores, gera imediato
            // Proximo estado depende do opcode
            case (opcode)
                OPC_RTYPE: next_state = STATE_EXECUTE_R_TYPE;
                OPC_OPIMM: next_state = STATE_EXECUTE_LOAD_STORE; // addi usa caminho similar
                OPC_LOAD:  next_state = STATE_EXECUTE_LOAD_STORE; // calcula endereço
                OPC_STORE: next_state = STATE_EXECUTE_LOAD_STORE; // calcula endereço
                OPC_BRANCH: next_state = STATE_BRANCH_EXECUTE;
                OPC_JAL: next_state = STATE_JUMP_EXECUTE;
                OPC_JALR: next_state = STATE_JALR_EXECUTE;
                default: next_state = STATE_FETCH_INSTR; // erro ou instrução inválida
            endcase
        end

        STATE_EXECUTE_R_TYPE: begin
            // Ações: ULA opera (com base em funct3/7), RegWrite
            ALUOp = 2'b10; // R-type ALUOp
            ALUSrcA = 0; // rs1
            ALUSrcB = 0; // rs2
            RegWrite = 1;
            RegDst = 1; // write to rd
            PCWrite = 1; // PC = PC + 4 para a proxima instrução
            PCSource = 0; // seleciona PC+4
            next_state = STATE_FETCH_INSTR; // Volta para buscar proxima instrução
        end

        STATE_EXECUTE_LOAD_STORE: begin
            // Ações: ULA calcula endereço (Rs1 + Imediato)
            ALUOp = 2'b00; // ADD para endereço
            ALUSrcA = 0; // rs1
            ALUSrcB = 1; // imediato
            PCWrite = 1; // PC = PC + 4
            PCSource = 0; // seleciona PC+4
            // Proximo estado depende da instrução (load ou store)
            case (opcode)
                OPC_LOAD: next_state = STATE_MEMORY_ACCESS_LOAD;
                OPC_STORE: next_state = STATE_MEMORY_ACCESS_STORE;
                OPC_OPIMM: begin // addi
                    RegWrite = 1;
                    RegDst = 0; // write to rd
                    next_state = STATE_FETCH_INSTR;
                end
                default: next_state = STATE_FETCH_INSTR;
            endcase
        end

        STATE_MEMORY_ACCESS_LOAD: begin
            // Ações: Leitura da memória de dados
            IorD = 1; // Seleciona endereço da ULA para memória
            MemRead = 1;
            next_state = STATE_LOAD_WAIT1; // Espera por dados da memória
        end

        STATE_LOAD_WAIT1: begin
            // Ações: Nenhuma, espera
            next_state = STATE_LOAD_WAIT2;
        end

        STATE_LOAD_WAIT2: begin
            // Ações: Dados disponíveis.
            next_state = STATE_WRITE_BACK_LOAD;
        end

        STATE_WRITE_BACK_LOAD: begin
            // Ações: Escreve no registrador
            MemtoReg = 1;
            RegWrite = 1;
            RegDst = 0; // write to rd
            next_state = STATE_FETCH_INSTR; // Volta para buscar
        end

        STATE_MEMORY_ACCESS_STORE: begin
            // Ações: Escrita na memória de dados
            IorD = 1; // Seleciona endereço da ULA para memória
            MemWrite = 1;
            next_state = STATE_FETCH_INSTR; // Store é completo aqui para simplificação, mas poderia ter estados de espera
        end

        STATE_BRANCH_EXECUTE: begin
            // Ações: ULA compara (SUB), PCWriteCond, PCSource (Branch target)
            ALUOp = 2'b01; // SUB para beq
            ALUSrcA = 0; // rs1
            ALUSrcB = 0; // rs2
            PCWriteCond = 1; // Escreve PC condicionalmente
            PCSource = 1; // Seleciona endereço do branch
            next_state = STATE_FETCH_INSTR;
        end

        STATE_JUMP_EXECUTE: begin
            // Ações: JAL
            RegWrite = 1; // Escreve PC+4 no rd
            RegDst = 1; // rd
            MemtoReg = 0; // PC+4
            PCWrite = 1; // Escreve PC
            PCSource = 2; // Endereço de JAL
            next_state = STATE_FETCH_INSTR;
        end

        STATE_JALR_EXECUTE: begin
            // Ações: JALR
            RegWrite = 1; // Escreve PC+4 no rd
            RegDst = 1; // rd
            MemtoReg = 0; // PC+4
            PCWrite = 1; // Escreve PC
            PCSource = 3; // Endereço de JALR (ULA)
            ALUOp = 2'b00; // Add para ULA (rs1 + imediato)
            ALUSrcA = 0; // rs1
            ALUSrcB = 1; // imediato
            next_state = STATE_FETCH_INSTR;
        end

        default: next_state = STATE_FETCH_INSTR; // Estado desconhecido, volta para o início
    endcase
end

endmodule