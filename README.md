# RISCV CPU

利用 verilog 仿真，实现一个支持 RISCV 指令集的CPU

需要使用乱序执行的 tomasulo

## 具体实现

1. verilog 仿真，设计好总体的架构
2. 实现Instruction Fecth等功能
3. 通过仿真测试点
4. 用vivado生成`.bit` 文件，将其烧录到FPGA板上

Tomasulo 分为三部分：Issue -> EXE -> Write Back

实际操作上，可以把指令的执行分成  `issue -> execute -> read_access_memory -> write_CDB -> commit` 的五个阶段

- execute 指计算立即数，对于 load/store 来说就是计算出要访问的具体内存地址
- read_access_memory 是 load 专有的时间
- write_CDB 就是把 ALU/LSU 的计算结果广播到 CPU 中，包括 RS/ROB/..，主要由 dispatcher 实现
- commit 会正式修改 内存（store）/寄存器

## 大致架构

除了助教提供的 `ram.v`,common 等模块，首先是 tomasulo 的基本组成。大部分模块使用 **时序逻辑** 实现

- Issue
  - Fetcher

    从 memCtrl 中取数据
      
    包含一个 direct-mapping 的 Instruction cache，大小为 256
  - predictor
  
    二位饱和预测（BHT），大小为 256
  - Decoder（组合逻辑）
  - Dispatcher
  
    分发数据，综合部分连线，实现 data-forwarding
- Execute
  - Re-Order Buffer

    接收指令，按照 issue 的顺序提交
  - Reservation Station

    实现乱序执行，每次挑选可以执行
    - ALU (EXE part) : 组合逻辑实现
  - Load/Store Buffer (a queue like RoB)
    - Load/Store Unit (EXE part)

- Memory Controller

  处理程序与内存之间的交互

- Register File

- cpu.v

  result_alu, result_lsu 等充当 “总线”，将计算出的结果广播到 RS/LSB/ROB 上

  完成各模块之间的连线

## 工作进程

- [x] 实现大致架构
- [x] 完成CPU连线
- [x] 通过 simulation 测试
- [x] 通过 FPGA 测试

## 评测方式

配置好 riscv-toolchain，将 .c 编译为 riscv 格式的 .data 文件，同时还有 .dump 等文件，最后 `vvp test.out` 生产 .vcd 的波形图，在 gtkwave 中查看

### simulation

直接利用 src 下的 Makefile

> `make test_sim name=007_hanoi`

### FPGA

安装 vivado，将代码编译为 bitStream，烧录到 FPGA 板上运行。

实测运行速度远快于 simulation

script中 `run_test_fpga.sh`

> `./run_test_fpga.sh fpga/uartboom`

## 其他信息

uart(异步收发传输器) 将要传输的资料在串行通信与并行通信之间加以转换。同时会向 cpu 中传入 `io_buffer_full` 的信号

对于 RS：

- V1: value of rs1, V2: rs2
- Q1，Q2 表示数据 V1/V2 将由RoB中的 Q1/Q2 条指令计算出来，用来捕捉数据
- A(imm + data): 计算出的立即数/LoadStore地址
- rob_id(simple Q): 指令在 ROB 中存储的位置


> Q = rob_id = the inst id in ROB + 1
> 
> Q = 0 表示当前指令已经执行完毕(ready)，可以 commit
> 
> V : the value of data
