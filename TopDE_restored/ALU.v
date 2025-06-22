/*
 * ALU Simplificada – OAC Lab 2
 */

`ifndef PARAM
	`include "Parametros.v"
`endif

module ALU (
	input        [4:0]  iControl,
	input  signed [31:0] iA, 
	input  signed [31:0] iB,
	output logic [31:0] oResult,
	output logic zero
);

//	wire [4:0] iControl=OPDIV;		// Usado para as analises

always @(*)
begin
    case (iControl)
		OPAND:
			oResult <= iA & iB;
		OPOR:
			oResult <= iA | iB;
		OPADD:
			oResult <= iA + iB;
		OPSUB:
			oResult <= iA - iB;
		OPSLT:
			oResult <= iA < iB;
		OPNULL:
			oResult <= ZERO;
		default:
			oResult <= ZERO;
    endcase
	 zero = (oResult == 32'b0);
end

endmodule
