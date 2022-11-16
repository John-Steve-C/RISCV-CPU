module fetcher (
  	input wire clk_in,
  	input wire rst_in,
  	input wire rdy_in,

	input wire [31:0] target_pc,

	// memctrl
	output reg [31:0] pc_send_to_mem,
	input wire [31:0] inst_from_mem,
	input wire en_signal,

	// decoder
	output reg [31:0] inst_to_decoder,

	// predictor
	output wire [31:0] query_pc_in_predictor,
	input wire [31:0] predict_pc
);

reg [31:0] pc, mem_pc;

// branch predict must go ahead of mem, so it should be a wire
assign query_pc_in_predictor = pc;

always @(posedge clk_in) begin
    if (rst_in) begin
        pc <= 0;
		mem_pc <= 0;
		pc_send_to_mem <= 0;
		inst_to_decoder <= 0;
    end
    else if (!rdy_in) begin
    end
    else begin
		if (en_signal) begin
			pc <= predict_pc;
			mem_pc <= (mem_pc == pc) ? mem_pc + 4 : pc;
			
			// 时序问题？
			pc_send_to_mem <= mem_pc;
			inst_to_decoder <= inst_from_mem;	
		end	
    end
end

endmodule