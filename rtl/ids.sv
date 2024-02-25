
//---------------------------------------------------------------------------
// DUT 
//---------------------------------------------------------------------------
module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output wire dut_ready                   ,

//---------------------------------------------------------------------------
//q_state_output SRAM interface
  output wire         sram_write_enable  ,
  output wire [15:0]  sram_write_address ,
  output wire [31:0]  sram_write_data    ,
  output wire [15:0]  sram_read_address  , 
  input  wire [7:0]  sram_read_data     

);

//---------------------------------------------------------------------------
//q_state_output SRAM interface
  reg        sram_write_enable_r  ;
  reg [15:0] sram_write_address_r ;
  reg [31:0] sram_write_data_r    ;
  reg [15:0] sram_read_address_r  ; 
  reg compute_complete;

// This is test sub for the DW_fp_add, do not change any of the inputs to the
// param list for the DW_fp_add, you will only need one DW_fp_add

// synopsys translate_off
  // This is a helper val for seeing the 32bit flaot value, you can repicate 
  // this for any signal, but keep it between the translate_off and
  // translate_on 
// synopsys translate_on

  // FIXED CODE ENDS

  parameter[2:0] // synopsys enum states
   S0 = 2'b000,
   S1 = 2'b001,
   S2 = 2'b010,
   S3 = 2'b011,
   S4 = 2'b100;

   reg [2:0] current_state, next_state;
   wire [15:0] next_sram_read_address;
   reg [15:0] N;
   reg [5:0] next_address_offset, attack_code, next_attack_code;

  always @ (posedge clk) begin
    if (!reset_n) begin 
      current_state <= S0;
    end
    else begin
      if (!dut_ready) begin
        sram_read_address_r <= next_sram_read_address;
        attack_code <= next_attack_code
        if(sram_read_address_r == 0) N <= sram_read_data;
      end
      else begin
        sram_read_address_r <= 16'b0;
      end
      current_state <= next_state;
    end
  end

  parameter[7:0]
   ATTACH_REJECT  = 8'h44,
   AUTH_FAILURE   = 8'h05,
   SERVICE_REJECT = 8'h4e,
   TAU_REJECT     = 8'h4b;

  always @ (*) begin
    compute_complete = 1'b0;
    sram_write_address_r = 16'b0;
    sram_write_enable_r = 1'b0;
    sram_write_data_r = 32'b0;
    next_address_offset = 6'b1;
    next_attack_code = 6'b0;
    casex(current_state)
      S0: begin
        compute_complete = 1;
        if(dut_valid) next_state = S1;
        else next_state = S0;
      end

      S1: begin
        next_state = S2;
      end

      S2: begin
        if(sram_read_data[3:0] != 4'h7) begin
          next_state = S4;
          next_attack_code = 6'b111111;
        end
        if(sram_read_data[4] == 1'b1) begin
          next_state = S3;
          next_address_offset = 6'b100;
        end
      end

      S3: begin 
        casex(sram_read_data)
          ATTACH_REJECT: next_attack_code = 8'h01;
          AUTH_FAILURE: next_attack_code = 8'h02;
          SERVICE_REJECT: next_attack_code = 8'h03;
          TAU_REJECT: next_attack_code = 8'h04;
        endcase
      end

      S4: begin
        sram_write_enable_r = 1'b1;
        sram_write_address_r = N+1;
        sram_write_data_r = attack_code;
        next_state = S0;
      end

      default: next_state = S0;
    endcase
  end

  assign sram_write_address = sram_write_address_r;
  assign sram_write_data = sram_write_data_r;
  assign sram_read_address = sram_read_address_r;
  assign sram_write_enable = sram_write_enable_r;
  assign dut_ready = compute_complete;

  assign next_sram_read_address = sram_read_address_r + next_address_offset;
endmodule
