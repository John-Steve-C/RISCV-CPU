# RISCV CPU

利用 verilog 仿真，实现一个支持 RISCV 指令集的CPU

需要使用乱序执行的 tomasulo

## 具体实现

1. verilog 仿真，设计好总体的架构
2. 实现Instruction Fecth功能
3. 通过仿真测试点
4. 用vivado生成`.bit` 文件，将其烧录到FPGA板上

## 大致架构

除了助教提供的 `ram.v`,common 等模块，首先是 tomasulo 的基本组成

- [ ] Instruction Fetcher

  只完成了与部分模块的交互
- [x] predictor
  
  二位饱和预测
- [ ] Memory Controller
- [ ] Instruction Decoder
- [ ] Execute

  - [ ] Re-Order Buffer
  - [ ] Reservation Station

- [ ] Register File

- uart(异步收发传输器) 将要传输的资料在串行通信与并行通信之间加以转换。
