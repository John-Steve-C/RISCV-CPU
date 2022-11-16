module decoder(
    input wire [31:0] inst,

    output reg jump,
    output reg [4:0] rd,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [31:0] imm
);

localparam OPCODE_LUI = 7'b0110111, OPCODE_AUIPC = 7'b0010111, OPCODE_JAL =  7'b1101111, OPCODE_JALR = 7'b1100111, OPCODE_BR = 7'b1100011, 
        OPCODE_L = 7'b0000011, OPCODE_S = 7'b0100011, OPCODE_ARITHI = 7'b0010011, OPCODE_ARITH = 7'b0110011;

always @(*) begin
    rd = inst[11:7];
    rs1 = inst[19:15];
    rs2 = inst[24:20];
    imm = 0;
    jump = 0;

    case (inst[6:0])
        OPCODE_LUI, OPCODE_AUIPC: begin  
            imm = {inst[31:12], 12'b0};
        end

        OPCODE_JAL: begin
            imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            jump = 1;
        end

        OPCODE_JALR, OPCODE_L, OPCODE_ARITHI: begin
        end

        OPCODE_BR: begin
        end

        OPCODE_S: begin
        end

        OPCODE_ARITH: begin
        end
    endcase

end

endmodule