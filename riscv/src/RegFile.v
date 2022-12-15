module RegFile (
    inout wire clk_in,
  	input wire rst_in,
  	input wire rdy_in,

	  // call-back
    // dispatcher
	  input wire en_signal_from_dispatcher,
    input wire [4:0] rd_from_dispatcher,
    input wire [4:0] Q_from_dispatcher,
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


assign Q1_to_dispatcher = en_signal_from_dispatcher ? Q[rs1_from_dispatcher] : 0;
assign Q2_to_dispatcher = en_signal_from_dispatcher ? Q[rs2_from_dispatcher] : 0;
assign V1_to_dispatcher = en_signal_from_dispatcher ? V[rs1_from_dispatcher] : 0;
assign V2_to_dispatcher = en_signal_from_dispatcher ? V[rs2_from_dispatcher] : 0;


always @(posedge clk_in) begin
    if (rst_in) begin
		for (i = 0;i < REG_SIZE; i = i + 1) begin
			Q[i] <= 0;
			V[i] <= 0;
		end
    end
    else if (!rdy_in) begin
    end
    else begin
		if (rollback_flag_from_rob) begin
			for (i = 0;i < REG_SIZE; i = i + 1)
				Q[i] <= 0;
		end
		else begin
			if (commit_flag_from_rob) begin
				Q[rd_from_rob] <= Q_from_rob;
				V[rd_from_rob] <= V_from_rob;
			end
		end
    end
end


endmodule