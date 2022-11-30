`include "/mnt/d/Coding/RISCV-CPU/riscv/src/defines.v"

module LSU(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire enable_signal,
    input wire [31:0] inst_name,
    input wire [31:0] mem_addr,
    input wire [31:0] store_value,
    output reg valid,
    output reg [31:0] result,

    // mem
    output reg en_signal_to_mem,
    output reg [31:0] addr_to_mem,
    output reg [31:0] data_to_mem,

    // LSB
    output wire busy_to_lsb

);
// the EXE of LSB

localparam IDLE = 0, LB = 1, LH = 2, LW = 3, LBU = 4, LHU = 5, STORE = 6;
reg [2:0] status;
assign busy_to_lsb = (status != IDLE || en_signal_to_mem);

always @(posedge clk_in) begin
    if (rst_in) begin
        en_signal_to_mem <= 0;
        valid <= 0;
        status <= IDLE;
    end
    else if (!rdy_in) begin
    end
    else begin
        if (status != IDLE) begin
            en_signal_to_mem <= 0;

        end
        else begin
            valid <= 0;
        end
    end
end

endmodule