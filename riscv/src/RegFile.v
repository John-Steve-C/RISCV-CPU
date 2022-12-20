module RegFile (
    inout wire clk_in,
  	input wire rst_in,
  	input wire rdy_in,

    // dispatcher get register
	input wire en_signal_from_dispatcher,	// means register can be modified
    input wire [4:0] rd_from_dispatcher,
    input wire [4:0] Q_from_dispatcher,		// new id

	// query value in register
    input wire [4:0] rs1_from_dispatcher,
    input wire [4:0] rs2_from_dispatcher,
    output wire [31:0] V1_to_dispatcher,
    output wire [31:0] V2_to_dispatcher,
    output wire [4:0] Q1_to_dispatcher,
    output wire [4:0] Q2_to_dispatcher,

    // commit from rob
    input wire commit_flag_from_rob,
    input wire rollback_flag_from_rob,
    input wire [4:0] rd_from_rob,
    input wire [4:0] Q_from_rob,
    input wire [31:0] V_from_rob
);

integer i;

localparam REG_SIZE = 32;

// reg Node
reg [4:0] Q [REG_SIZE - 1 : 0];
reg [31:0] V [REG_SIZE - 1 : 0];

assign Q1_to_dispatcher = Q[rs1_from_dispatcher];
assign Q2_to_dispatcher = Q[rs2_from_dispatcher];
assign V1_to_dispatcher = V[rs1_from_dispatcher];
assign V2_to_dispatcher = V[rs2_from_dispatcher];

// need to modify register at once，组合逻辑实现
always @(*) begin
    if (rst_in) begin
		for (i = 0;i < REG_SIZE; i = i + 1) begin
			Q[i] = 0;
			V[i] = 0;
		end
    end
    else if (!rdy_in) begin
    end
    else begin
		// only need to clear the address -> Q
		if (rollback_flag_from_rob) begin
			for (i = 0;i < REG_SIZE; i = i + 1)
				Q[i] = 0;
		end
		else if (en_signal_from_dispatcher) begin
			if (rd_from_dispatcher != 0) Q[rd_from_dispatcher] = Q_from_dispatcher;
		end
		
		// update when commit
		if (commit_flag_from_rob) begin
			// rd != 0 means that it's not ready
			// otherwise, no need to modify it
			if (rd_from_rob != 0) begin
				V[rd_from_rob] = V_from_rob;
				if (Q[rd_from_rob] == Q_from_rob) Q[rd_from_rob] = 0;	// ready now
			end
		end
    end
end


endmodule