module predictor(
    input wire clk_in,
  	input wire rst_in,
  	input wire rdy_in,

    // query
    input wire [31:0] current_pc,
    output wire [31:0] predict_pc,
    output wire jump,

    //update
    input wire [31:0] bus_pc
);

localparam STRONG_NOT = 0, WEAK_NOT = 1, WEAK_JUMP = 2, STRONG_JUMP = 3;

reg [11:0] now_pc;
reg [4095:0] two_counter;   // 1 << 12

// predict new pc
assign jump = two_counter[now_pc] > 1;
assign predict_pc = jump ? bus_pc : current_pc + 4;

always @(posedge clk_in) begin
    now_pc = current_pc [11:0];

    // update the predictor, 二位饱和预测
    if (two_counter[now_pc] == STRONG_NOT) begin
        two_counter[now_pc] = jump ? WEAK_NOT : STRONG_NOT;
    end
    else if (two_counter[now_pc] == WEAK_NOT) begin
        two_counter[now_pc] = jump ? WEAK_JUMP : STRONG_NOT;
    end
    else if (two_counter[now_pc] == WEAK_JUMP) begin
        two_counter[now_pc] = jump ? STRONG_JUMP : WEAK_NOT;
    end
    else begin
        two_counter[now_pc] = jump ? STRONG_JUMP : WEAK_JUMP;
    end   
end

endmodule