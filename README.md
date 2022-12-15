# RISCV CPU

利用 verilog 仿真，实现一个支持 RISCV 指令集的CPU

需要使用乱序执行的 tomasulo

## 具体实现

1. verilog 仿真，设计好总体的架构
2. 实现Instruction Fecth功能
3. 通过仿真测试点
4. 用vivado生成`.bit` 文件，将其烧录到FPGA板上

Tomasulo 分为三部分：Issue -> EXE -> Write Back

## 大致架构

除了助教提供的 `ram.v`,common 等模块，首先是 tomasulo 的基本组成

- Issue
  - Fetcher : 从 memCtrl 中取数据
  - predictor : 二位饱和预测（BHT）
  - Decoder
  - Dispatcher : 分发数据，综合部分连线
    - Instruction cache
- Execute
  - Re-Order Buffer
  - Reservation Station
    - ALU (EXE part) : 组合逻辑实现
  - Load/Store Buffer (a queue like RoB)
    - Load/Store Unit (EXE part)

- Memory Controller

- Register File

## 工作进程

- [x] 实现大致架构
- [x] 完成CPU连线
- [ ] 通过 simulation 测试
- [ ] 通过 FPGA 测试

## 其他信息

uart(异步收发传输器) 将要传输的资料在串行通信与并行通信之间加以转换。

> Q : the inst id in ROB/RS/LSB
> 
> V : the value of data
