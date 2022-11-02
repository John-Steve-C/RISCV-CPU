module IF (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
        
    
    output wire [31:0] instr
);

reg [31:0] pc;
reg stall;
wire [31:0] icache_instr;

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        pc <= 0;
        stall <= 0;
        
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
        
      end
  end

endmodule