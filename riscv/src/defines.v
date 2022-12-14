// instruction name
`define NOP     6'd0

`define LUI     6'd1
`define AUIPC   6'd2

`define JAL     6'd3
`define JALR    6'd4

`define BEQ     6'd5
`define BNE     6'd6
`define BLT     6'd7 
`define BGE     6'd8
`define BLTU    6'd9 
`define BGEU    6'd10 

`define LB      6'd11 
`define LH      6'd12 
`define LW      6'd13 
`define LBU     6'd14 
`define LHU     6'd15 
`define SB      6'd16 
`define SH      6'd17 
`define SW      6'd18 

`define ADD     6'd19 
`define SUB     6'd20 
`define SLL     6'd21 
`define SLT     6'd22 
`define SLTU    6'd23 
`define XOR     6'd24 
`define SRL     6'd25 
`define SRA     6'd26
`define OR      6'd27 
`define AND     6'd28

`define ADDI    6'd29
`define SLTI    6'd30
`define SLTIU   6'd31
`define XORI    6'd32
`define ORI     6'd33
`define ANDI    6'd34
`define SLLI    6'd35
`define SRLI    6'd36
`define SRAI    6'd37

//----------------------------------------------------------------
`define RAM_IO_PORT 32'h30000

// r/w flag for memory
`define READ_FLAG   1'b0
`define WRITE_FLAG  1'b1

`define FULL_WARNING 3'd6