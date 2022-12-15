`include "/mnt/d/Coding/RISCV-CPU/riscv/src/defines.v"

module memCtrl (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire uart_full_from_ram,  //
    input wire [7:0] data_from_ram, // input
    output reg [7:0] data_to_ram,   // output
    output reg rw_flag_to_ram,
    output reg [31:0] addr_to_ram,

    input wire [31:0] pc_from_fetcher,
    input wire en_signal_from_fetcher,          //chip enable signal
    input wire drop_flag_from_fetcher,   //
    output reg ok_flag_to_fetcher,     //
    output reg [31:0] inst_to_fetcher,

    input wire [31:0] addr_from_lsu,
    input wire [31:0] write_data_from_lsu,
    input wire en_from_lsu,
    input wire rw_flag_from_lsu,
    input wire [2:0] size_from_lsu,
    output reg ok_flag_to_lsu,
    output reg [31:0] load_data_to_lsu
);

// mem status
localparam IDLE = 0, FETCH = 1, LOAD = 2, STORE = 3;
reg [1:0] status;
reg [31:0] ram_access_counter, ram_access_stop, ram_access_pc, writing_data;

// read/write buffer
// If receive a request while Mem is working, the request will be put into buffer
reg [31:0] buffer_pc;
reg buffer_fetch_valid, buffer_ls_valid, buffer_rw_flag;  
reg [2:0] buffer_size;
reg [31:0] buffer_addr, buffer_write_data;

// the enable signal will shadow previous status, and then get magic ones
// reg en_shadow_status, en_shadow_fetch_valid, en_shadow_ls_valid;
// wire [1:0] status_magic = en_shadow_status ? IDLE : status;
// wire buffer_fetch_valid_magic = en_shadow_fetch_valid ? 0 : buffer_fetch_valid;
// wire buffer_ls_valid_magic = en_shadow_ls_valid ? 0 : buffer_ls_valid;

// prevent write data to hci when io is full
reg uart_write_is_io, uart_write_lock;

// modify chip_enable_signals
// always @(*) begin
//     en_shadow_status = 0;
//     en_shadow_ls_valid = 0;
//     en_shadow_fetch_valid = 0;

//     if (drop_flag_from_fetcher) begin
//         if (status == FETCH || status == LOAD) begin
//             en_shadow_status = 1;
//         end
//         en_shadow_fetch_valid = 1;
//         if (buffer_ls_valid && buffer_rw_flag == `READ_FLAG) begin
//             en_shadow_ls_valid = 1;
//         end    
//     end
// end

always @(posedge clk_in) begin
    if (rst_in) begin
        status <= IDLE;
        ram_access_counter <= 0;
        ram_access_stop <= 0;
        ram_access_pc <= 0;
        buffer_fetch_valid <= 0;
        buffer_ls_valid <= 0;
        inst_to_fetcher <= 0;
        load_data_to_lsu <= 0;
        
        uart_write_is_io <= 0;
        uart_write_lock <= 0;
    end
    else if (!rdy_in) begin
    end
    else begin
        ok_flag_to_fetcher <= 0;
        ok_flag_to_lsu <= 0;

        addr_to_ram <= 0;
        rw_flag_to_ram <= `READ_FLAG;    

        // if (en_shadow_status) status <= IDLE;
        // if (en_shadow_ls_valid) buffer_ls_valid <= 0;
        // if (en_shadow_fetch_valid) buffer_fetch_valid <= 0;

        // busy mem, put query into buffer
        if (status != IDLE || (en_signal_from_fetcher && en_from_lsu)) begin
            if (!en_signal_from_fetcher && en_from_lsu) begin
                buffer_ls_valid <= 1;
                buffer_rw_flag <= rw_flag_from_lsu;
                buffer_addr <= addr_from_lsu;
                buffer_write_data <= write_data_from_lsu;
                buffer_size <= size_from_lsu;
            end
            else if (en_signal_from_fetcher) begin
                buffer_fetch_valid <= 1;
                buffer_pc <= pc_from_fetcher;
            end
        end

        // IDLE
        if (status == IDLE) begin
            ok_flag_to_fetcher <= 0;
            ok_flag_to_lsu <= 0;
            inst_to_fetcher <= 0;
            load_data_to_lsu <= 0;

            if (en_from_lsu) begin
                if (rw_flag_from_lsu == `WRITE_FLAG) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= size_from_lsu;
                    writing_data <= write_data_from_lsu;
                    addr_to_ram <= 0;
                    ram_access_pc <= addr_from_lsu;
                    rw_flag_to_ram <= `WRITE_FLAG;

                    uart_write_is_io <= (addr_from_lsu == `RAM_IO_PORT);
                    uart_write_lock <= 0;

                    status <= STORE;
                end
                else if (rw_flag_from_lsu == `READ_FLAG) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= size_from_lsu;
                    addr_to_ram <= addr_from_lsu;
                    rw_flag_to_ram <= `READ_FLAG;
                    status <= LOAD;
                end
            end

            // there are buffered requests
            else if (buffer_ls_valid) begin
                if (buffer_rw_flag == `WRITE_FLAG) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= buffer_size;
                    writing_data <= buffer_write_data;
                    addr_to_ram <= 0;
                    ram_access_pc <= buffer_addr;
                    rw_flag_to_ram <= `WRITE_FLAG;
                    status <= STORE;                
                end
                else if (buffer_rw_flag == `READ_FLAG) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= buffer_size;
                    addr_to_ram <= buffer_addr;
                    ram_access_pc <= buffer_addr + 1;
                    rw_flag_to_ram <= `READ_FLAG;
                    status <= LOAD;
                end
            end

            else if (en_signal_from_fetcher) begin
                ram_access_counter <= 0;
                ram_access_stop <= 4;
                addr_to_ram <= pc_from_fetcher + 1;
                rw_flag_to_ram <= `READ_FLAG;
                status <= FETCH;
            end

            else if (buffer_fetch_valid) begin
                ram_access_counter <= 0;
                ram_access_stop <= 4;
                addr_to_ram <= buffer_pc;
                ram_access_pc <= buffer_pc + 1;
                rw_flag_to_ram <= `READ_FLAG;
                status <= FETCH;
                buffer_fetch_valid <= 0;
            end
        end

        // busy
        else if (!uart_full_from_ram || status == STORE) begin
            // work fetch
            if (status == FETCH) begin
                addr_to_ram <= ram_access_pc;
                rw_flag_to_ram <= `READ_FLAG;
                case (ram_access_counter)
                    1: inst_to_fetcher[7:0] <= data_from_ram;
                    2: inst_to_fetcher[15:8] <= data_from_ram;
                    3: inst_to_fetcher[23:16] <= data_from_ram;
                    4: inst_to_fetcher[31:24] <= data_from_ram;
                endcase

                // get new pc
                ram_access_pc <= (ram_access_counter >= ram_access_stop - 1) ? 0 : ram_access_pc + 1;
                if (ram_access_counter == ram_access_stop) begin
                    // stop
                    ok_flag_to_fetcher <= ~drop_flag_from_fetcher;
                    status <= IDLE;
                    ram_access_pc <= 0;
                    ram_access_counter <= 0;
                end
                else begin
                    ram_access_counter <= ram_access_counter + 1;
                end
            end

            // load
            else if (status == LOAD) begin
                addr_to_ram <= ram_access_pc;
                rw_flag_to_ram <= `READ_FLAG;
                case (ram_access_counter)
                    1: load_data_to_lsu[7:0] <= data_from_ram;
                    2: load_data_to_lsu[15:8] <= data_from_ram;
                    3: load_data_to_lsu[23:16] <= data_from_ram;
                    4: load_data_to_lsu[31:24] <= data_from_ram;
                endcase

                ram_access_pc <= (ram_access_counter >= ram_access_stop - 1) ? 0 : ram_access_pc + 1;
                if (ram_access_counter == ram_access_stop) begin
                    ok_flag_to_lsu <= ~drop_flag_from_fetcher;
                    status <= IDLE;
                    ram_access_pc <= 0;
                    ram_access_counter <= 0;
                end
                else begin
                    ram_access_counter <= ram_access_counter + 1;
                end
            end
            
            // store
            else if (status == STORE) begin
                if (!uart_write_is_io || ~uart_write_lock) begin
                    // uart is full, lock 1 cycle
                    uart_write_lock <= 1;
                    
                    addr_to_ram <= ram_access_pc;
                    rw_flag_to_ram <= `WRITE_FLAG;
                    case (ram_access_counter) 
                        0: data_to_ram <= writing_data[7:0];
                        1: data_to_ram <= writing_data[15:8];
                        2: data_to_ram <= writing_data[23:16];
                        3: data_to_ram <= writing_data[31:24];
                    endcase

                    ram_access_pc <= (ram_access_counter >= ram_access_stop - 1) ? 0 : ram_access_pc + 1;
                    if (ram_access_counter == ram_access_stop) begin
                        ok_flag_to_lsu <= 1;
                        status <= IDLE;
                        ram_access_pc <= 0;
                        ram_access_counter <= 0;
                        addr_to_ram <= 0;
                        rw_flag_to_ram <= `READ_FLAG;
                    end
                    else begin
                        ram_access_counter <= ram_access_counter + 1;
                    end
                end
                else begin
                    // unlock uart
                    uart_write_lock <= 0;
                end
            end
        end        
    end
end

endmodule