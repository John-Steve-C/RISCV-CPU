module LSB(
    input wire clk_in,
  	input wire rst_in,
  	input wire rdy_in,

    // dispatcher
    input wire [31:0] en_signal_from_dispatcher,
    input wire [5:0] inst_name_from_dispatcher,
    input wire [4:0] Q1_from_dispatcher,
    input wire [4:0] Q2_from_dispatcher,
    input wire [31:0] V1_from_dispatcher,
    input wire [31:0] V2_from_dispatcher,
    input wire [31:0] pc_from_dispatcher,
    input wire [31:0] imm_from_dispatcher,
    input wire [4:0] rob_id_from_dispatcher,

    // send to LSU
    output reg en_signal_to_lsu,
    output reg [5:0] inst_name_to_lsu,
    output reg [31:0] store_value_to_lsu,
    output reg [31:0] mem_addr_to_lsu,

    // send it to execute
    output reg [4:0] rob_id_to_exe,

    // ALU
    input wire valid_from_alu,
    input wire [31:0] result_from_alu,
    input wire [4:0] rob_id_from_alu,

    // LSU
    input wire busy_from_lsu,
    input wire valid_from_lsu,
    input wire [31:0] result_from_lsu,
    input wire [4:0] rob_id_from_lsu,

    // RoB
    input wire commit_flag_from_rob,
    input wire [4:0] rob_id_from_rob,
    input wire [4:0] head_io_rob_id_from_rob,

    // specify i/o
    output wire [4:0] io_rob_id_to_rob,

    // fetcher
    output wire full_to_fetcher
);



integer i;

localparam LSB_SIZE = 16;
`define LSBLen LSB_SIZE - 1 : 0

// LSB Node
reg busy [`LSBLen];
reg [5:0] inst_name [`LSBLen];
reg [4:0] Q1 [`LSBLen];
reg [4:0] Q2 [`LSBLen];
reg [31:0] V1 [`LSBLen];
reg [31:0] V2 [`LSBLen];
reg [31:0] pc [`LSBLen];
reg [4:0] rob_id [`LSBLen];  // inst destination

reg [31:0] imm [`LSBLen];

// query Q/V again
// alu -> lsu -> reg 
wire [4:0] real_Q1 = (valid_from_alu && Q1_from_dispatcher == rob_id_from_alu) ? 0 : ((valid_from_lsu && Q1_from_dispatcher == rob_id_from_lsu) ? 0 : Q1_from_dispatcher);
wire [4:0] real_Q2 = (valid_from_alu && Q2_from_dispatcher == rob_id_from_alu) ? 0 : ((valid_from_lsu && Q2_from_dispatcher == rob_id_from_lsu) ? 0 : Q2_from_dispatcher);
wire [31:0] real_V1 = (valid_from_alu && Q1_from_dispatcher == rob_id_from_alu) ? result_from_alu : ((valid_from_lsu && Q1_from_dispatcher == rob_id_from_lsu) ? result_from_lsu : V1_from_dispatcher);
wire [31:0] real_V2 = (valid_from_alu && Q2_from_dispatcher == rob_id_from_alu) ? result_from_alu : ((valid_from_lsu && Q2_from_dispatcher == rob_id_from_lsu) ? result_from_lsu : V2_from_dispatcher);


always @(posedge clk_in) begin
    if (rst_in) begin
        for (i = 0; i < LSB_SIZE; ++i) begin
            busy[i] <= 0;
            inst_name[i] <= 0;
            Q1[i] <= 0;
            Q2[i] <= 0;
            V1[i] <= 0;
            V2[i] <= 0;
            pc[i] <= 0;
            rob_id[i] <= 0;
            imm[i] <= 0;
        end
    end
    else if (!rdy_in) begin
    end
    else begin
        
    end
end

endmodule