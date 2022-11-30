module memCtrl (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire uart_full_from_ram,  //
    input wire [7:0] data_from_ram,
    output reg [7:0] data_to_ram,
    output reg rw_flag_to_ram,
    output reg [31:0] addr_to_ram,

    input wire [31:0] pc_from_fetcher,
    input wire en_from_fetcher,          //chip enable signal
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

// like ram, 0-write; 1-read
localparam READ = 1, WRITE = 0;
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

// the enable signal will shadow previous statuses, and then get magic ones
reg en_shadow_status, en_shadow_fetch_valid, en_shadow_ls_valid;
wire [1:0] status_magic = en_shadow_status ? IDLE : status;
wire buffer_fetch_valid_magic = en_shadow_fetch_valid ? 0 : buffer_fetch_valid;
wire buffer_ls_valid_magic = en_shadow_ls_valid ? 0 : buffer_ls_valid;

// modify chip_enable_signals
always @(*) begin
    en_shadow_status = 0;
    en_shadow_ls_valid = 0;
    en_shadow_fetch_valid = 0;

    if (drop_flag_from_fetcher) begin
        if (status == FETCH || status == LOAD) begin
            en_shadow_status = 1;
        end
        en_shadow_fetch_valid = 1;
        if (buffer_ls_valid && buffer_rw_flag == READ) begin
            en_shadow_ls_valid = 1;
        end    
    end
end

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
        

    end
    else if (!rdy_in) begin
    end
    else begin
        ok_flag_to_fetcher <= 0;
        ok_flag_to_lsu <= 0;

        addr_to_ram <= 0;
        rw_flag_to_ram <= READ;    

        if (en_shadow_status) status <= IDLE;   //status_magic?
        if (en_shadow_ls_valid) buffer_ls_valid <= 0;
        if (en_shadow_fetch_valid) buffer_fetch_valid <= 0;

        // busy mem, put query into buffer
        if (status_magic != IDLE || (en_from_fetcher && en_from_lsu)) begin
            if (!en_from_fetcher && en_from_lsu) begin
                buffer_ls_valid <= 1;
                buffer_rw_flag <= rw_flag_from_lsu;
                buffer_addr <= addr_from_lsu;
                buffer_write_data <= write_data_from_lsu;
                buffer_size <= size_from_lsu;
            end
            else if (en_from_fetcher) begin
                buffer_fetch_valid <= 1;
                buffer_pc <= pc_from_fetcher;
            end
        end

        if (status_magic == IDLE) begin
            ok_flag_to_fetcher <= 0;
            ok_flag_to_lsu <= 0;
            inst_to_fetcher <= 0;
            load_data_to_lsu <= 0;

            if (en_from_lsu) begin
                if (rw_flag_from_lsu == WRITE) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= size_from_lsu;
                    writing_data <= write_data_from_lsu;
                    addr_to_ram <= 0;
                    ram_access_pc <= addr_from_lsu;
                    rw_flag_to_ram <= WRITE;


                    status <= STORE;
                end
                else if (rw_flag_from_lsu == READ) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= size_from_lsu;
                    addr_to_ram <= addr_from_lsu;
                    rw_flag_to_ram <= READ;
                    status <= LOAD;
                end
            end

            // there are buffered requests
            else if (buffer_ls_valid_magic) begin
                if (buffer_rw_flag == WRITE) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= buffer_size;
                    writing_data <= buffer_write_data;
                    addr_to_ram <= 0;
                    ram_access_pc <= buffer_addr;
                    rw_flag_to_ram <= WRITE;
                    status <= STORE;                
                end
                else if (buffer_rw_flag == READ) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= buffer_size;
                    addr_to_ram <= buffer_addr;
                    ram_access_pc <= buffer_addr + 1;
                    rw_flag_to_ram <= READ;
                    status <= LOAD;
                end
            end

            else if (en_from_fetcher) begin
                ram_access_counter <= 0;
                ram_access_stop <= 4;
                addr_to_ram <= pc_from_fetcher + 1;
                rw_flag_to_ram <= READ;
                status <= FETCH;
            end

            else if (buffer_ls_valid_magic) begin
                ram_access_counter <= 0;
                ram_access_stop <= 4;
                addr_to_ram <= buffer_pc;
                ram_access_pc <= buffer_pc + 1;
                rw_flag_to_ram <= READ;
                status <= FETCH;
                buffer_fetch_valid <= 0;
            end
        
        end
        // busy
        else if (!uart_full_from_ram || status_magic != STORE) begin

        end        
    end
end

endmodule