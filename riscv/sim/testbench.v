// testbench top module file
// for simulation only

// `include "/mnt/d/Coding/RISCV-CPU/riscv/src/riscv_top.v"

`timescale 1ns/1ps
module testbench;

reg clk;
reg rst;

riscv_top #(.SIM(1)) top(
    .EXCLK(clk),
    .btnC(rst),
    .Tx(),
    .Rx(),
    .led()
);

integer cnt = 0;    // calculate execution cycles
initial begin
    clk=0;
    rst=1;
    repeat(50) #1 clk=!clk;
    rst=0; 
    forever #1 begin
        clk=!clk;
        // cnt = cnt + 1;
        // if (cnt % 10000 == 0) $display("current_cycles%d", cnt);
    end
    $finish;
end

// initial begin
//     $dumpfile("test.vcd");
//     $dumpvars(0, testbench);
//     #300000000 $finish;         // 设置强制结束时间，默认为 300000000
// end

endmodule
