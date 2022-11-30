module RoB(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // dispatcher
    input wire [4:0] Q1_from_dispatcher,
    input wire [4:0] Q2_from_dispatcher,
    output wire Q1_ready_to_dispatcher,
    output wire Q2_ready_to_dispatcher,
    output wire [31:0] data1_to_dispatcher,
    output wire [31:0] data2_to_dispatcher,

    input wire en_signal_from_dispatcher,
    input wire jump_from_dispatcher,
    input wire is_store_from_dispatcher,
    input wire [4:0] rd_from_dispatcher,
    input wire predicted_jump_from_dispatcher,
    input wire [31:0] pc_from_dispatcher,
    input wire [31:0] rollback_pc_from_dispatcher,

    output reg commit_flag, 

    // fetcher
    output reg rollback_flag,
    output reg [31:0] target_pc_to_fetcher,
    output wire full_to_fetcher,

    // predictor
    output reg en_signal_to_predictor,
    output reg hit_to_predictor,
    output reg [31:0] pc_to_predictor,

    // alu
    input wire valid_from_alu,
    input wire jump_from_alu,
    input wire [4:0] rob_id_from_alu,
    input wire [31:0] result_from_alu,
    input wire [31:0] target_pc_from_alu,

    // lsu
    input wire valid_from_lsu,
    input wire [4:0] rob_id_from_lsu,
    input wire [31:0] result_from_lsu,

    // lsb
    output reg [4:0] rob_id_to_lsb,

    // regFile
    output reg [4:0] rd_to_reg,
    output reg [4:0] Q_to_reg,
    output reg [31:0] V_to_reg

);

// ReOrder Buffer 
// 实际上是一个循环队列 size = 16
localparam ROB_SIZE = 16;
`define ROBLen ROB_SIZE - 1 : 0

// 注意区分
reg [3:0] head, tail, element_cnt;
wire [3:0] next_head = (head == ROB_SIZE - 1) ? 0 : head + 1, next_tail = (tail == ROB_SIZE - 1) ? 0 : tail + 1;

reg [31:0] pc [`ROBLen];
reg [4:0] rd [`ROBLen];
reg [31:0] data [`ROBLen];
reg [31:0] target_pc [`ROBLen];
reg [31:0] rollback_pc [`ROBLen];

reg busy [`ROBLen];  // 当前位置是否被占用
reg ready [`ROBLen];
reg [3:0] state [`ROBLen];
reg is_jump [`ROBLen];
reg is_store [`ROBLen];
reg is_io [`ROBLen];
reg predicted_jump[`ROBLen];

// use to update the element_cnt of RoB
wire [31:0] insert_cnt = en_signal_from_dispatcher ? 1 : 0;
wire [31:0] commit_cnt = (busy[head] && (ready[head] || is_store[head])) ? -1 : 0;

integer i;

always @(posedge clk_in) begin
    if (rst_in || rollback_flag) begin
        element_cnt <= 0;
        head <= 0;
        tail <= 0;
        for (i = 0;i < 16; ++i) begin
            pc[i] <= 0;
            rd[i] <= 0;
            data[i] <= 0;
            target_pc[i] <= 0;
            rollback_pc[i] <= 0;
            busy[i] <= 0;
            ready[i] <= 0;
            state[i] <= 0;
            is_jump[i] <= 0;
            is_store[i] <= 0;
        end
        commit_flag <= 0;
        rollback_flag <= 0;
        en_signal_to_predictor <= 0;
    end
    else if (!rdy_in) begin
    end
    else begin
        // commit (pop from queue)
        commit_flag <= 0;
        rollback_flag <= 0;
        en_signal_to_predictor <= 0;
        element_cnt <= element_cnt + insert_cnt + commit_cnt;
        
        if (busy[head] && (ready[head] || is_store[head])) begin
            commit_flag <= 1;   
            rd_to_reg <= rd[head];
            Q_to_reg <= head + 1;   // head
            V_to_reg <= data[head];

            if (is_jump[head]) begin
                en_signal_to_predictor <= 1;
                pc_to_predictor <= pc[head];
                // hit_to_predictor <= is_jump[head];
            end

            busy[head] <= 0;
            ready[head] <= 0;
            is_store[head] <= 0;
            is_jump[head] <= 0;
            predicted_jump[head] <= 0;

            head <= next_head;
        end

        // update
        if (busy[rob_id_from_alu - 1] && valid_from_alu) begin
            ready[rob_id_from_alu - 1] <= 1;
            data[rob_id_from_alu - 1] <= result_from_alu;
            target_pc[rob_id_from_alu - 1] <= target_pc_from_alu;

        end
        if (busy[rob_id_from_lsu - 1] && valid_from_lsu) begin
            ready[rob_id_from_lsu - 1] <= 1;
            data[rob_id_from_lsu - 1] <= result_from_lsu;
        end

        //
        // if (io)

        // insert
        if (en_signal_from_dispatcher) begin
            busy[tail] <= 1;
            is_io[tail] <= 0;
            predicted_jump[tail] <= predicted_jump_from_dispatcher;
            pc[tail] <=  pc_from_dispatcher;
            rd[tail] <= rd_from_dispatcher;

            data[tail] <= 0;
            target_pc[tail] <= 0;
            rollback_pc[tail] <= rollback_pc_from_dispatcher;
            is_jump[tail] <= jump_from_dispatcher;
            is_store[tail] <= is_store_from_dispatcher;

            ready[tail] <= 0;

            tail <= next_tail;
        end
    end
end

endmodule