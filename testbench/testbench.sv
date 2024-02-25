

module tb_top();


  parameter CLK_PHASE=5;
  // parameter ADDR_464=12'h000;
  // parameter MAX_ROUNDS=200;
  
  // Evaluation variables
  // time computeCycle;
  // event computeStart;
  // event computeEnd;
  // event checkFinish;
  // time startTime;
  // time endTime;

  // Testbench control variables
  // event simulationStart;
  // event testStart;
  // integer totalNumOfCases=0;
  // integer totalNumOfPasses=0;
  // real epsilon_mult=1.0;          // Overridden by Makefile
  // shortreal result;
  // integer info_level=0;
  
  // Testbench configuration variables 
  string input_dir;               // Overridden by Makefile
  string output_dir;              // Overridden by Makefile
  // integer rounds=1;
  integer timeout=100000;      // Overridden by Makefile 
  // integer num_of_testcases = 1;   // Overridden by Makefile

  bit  [31:0 ]     mem     [int] ;

  // integer num_results=72;
  // int correctResult[MAX_ROUNDS];
  // reg [15:0] result_array[int];
  // reg [15:0] golden_result_array[int];
  int i;
  int j;
  int k;
  int q;
  int p;
  //---------------------------------------------------------------------------
  // General
  //
  reg                                   clk            ;
  reg                                   reset_n        ;
  reg                                   dut_valid        ;
  wire                                  dut_ready       ;
  
  //--------------------------------------------------------------------------
  //---------------------- sram ---------------------------------------------
  wire                                 sram_write_enable  ;
  wire [15:0] sram_write_address ;
  wire [31:0]    sram_write_data    ;
  wire [15:0] sram_read_address  ; 
  wire [31:0]    sram_read_data     ;
  
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  //SRAM
  //sram for q_state_inputs
  sram  #(.ADDR_WIDTH   (16 ),
          .DATA_WIDTH   (8     ))
          sram_inst  (
          .write_enable ( sram_write_enable         ),
          .write_address( sram_write_address        ),
          .write_data   ( sram_write_data           ), 
          .read_address ( sram_read_address         ),
          .read_data    ( sram_read_data            ),
          .clk          ( clk                                     )
         );

		 
//---------------------------------------------------------------------------
// DUT 
//---------------------------------------------------------------------------
  MyDesign dut(
//---------------------------------------------------------------------------
//System signals
          .reset_n                    (reset_n                      ),  
          .clk                        (clk                          ),

//---------------------------------------------------------------------------
//Control signals
          .dut_valid                  (dut_valid                    ), 
          .dut_ready                  (dut_ready                    ),

//---------------------------------------------------------------------------
// SRAM interface
          .sram_write_enable       (sram_write_enable     ),
          .sram_write_address      (sram_write_address    ),
          .sram_write_data         (sram_write_data       ),
          .sram_read_address       (sram_read_address     ),
          .sram_read_data          (sram_read_data        )
         );

       
  //---------------------------------------------------------------------------
  //  clk
  initial 
    begin
        clk                     = 1'b0;
        forever # CLK_PHASE clk = ~clk;
    end

  //---------------------------------------------------------------------------
  // get runtime args 
  initial
  begin
    #1;
    if($value$plusargs("TIMEOUT=%d",timeout));
    if($value$plusargs("input_dir=%s",input_dir));
    // if($value$plusargs("num_of_testcases=%d",num_of_testcases));
    // if($value$plusargs("info_level=%d",info_level));
    // $display("INFO: number of testcases: %d",num_of_testcases);
    // if($value$plusargs("epsilon_mult=%f",epsilon_mult));

    repeat (5) @(posedge clk);
    ->simulationStart;
    @testStart
    wait_n_clks(timeout);
    $display("###################################");
    $display("             TIMEOUT               ");
    $display("###################################");
    $finish();
  end
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  // Stimulus

  task wait_n_clks;
    input integer i;
  begin
    repeat(i)
    begin
      wait(clk);
      wait(!clk);
    end
  end
  endtask

  task handshack;
  begin
    wait(!clk);
    dut_valid = 1;
    wait(clk);
    wait(!dut_ready);
    wait(!clk);
    dut_valid = 0;
    wait(clk);
    wait(dut_ready);
    wait(!clk);
    wait(clk);
  end
  endtask

 // User-defined function
//  import "DPI-C" function shortreal sum_fp(shortreal A, shortreal B);

//   function void check_output(integer testNum);
//     integer passes;
//     integer idx;
//     //real e;
//     //real check;
//     //real diff;
//     shortreal e;
//     shortreal check;
//     shortreal diff;
//     shortreal sum;
//     shortreal temp;
//     //e = $bitstoreal(64'h3CB0_0000_0000_0000);
//     e = $bitstoshortreal(64'h3CB0_0000);
//     sum=0;
//     for(int i=0;i<sram_inst.mem[0];i++)
//     begin
//       temp = sum;
//       sum = sum_fp(temp, $bitstoshortreal(sram_inst.mem[i+1]));
//       if(info_level>=1)
//         $display("INFO:LVL1: sum: %0x =  %0x +  %0x",$shortrealtobits(sum), $shortrealtobits(temp), sram_inst.mem[i+1]);
//     end
//     check = $bitstoshortreal(sram_inst.mem[sram_inst.mem.size()-1]&32'h7fff_ffff);
//     sum = $bitstoshortreal(($shortrealtobits(sum)&32'h7fff_ffff));
//     if(sum >= check)
//       diff = sum - check; 
//     else 
//       diff =check - sum ; 
//     if(diff <= (e*epsilon_mult))
//     begin
//       totalNumOfPasses+=1; 
//       $display("INFO:LVL0: Test: Passed");
//     end else begin
//       $display("INFO:LVL0: Test: Faild");
//       $display("INFO:LVL0: sum: %7.20f, check: %7.20f",sum,check);
//     end
//     totalNumOfCases+=1;
//   endfunction


  parameter[7:0]
   ATTACH_REJECT  = 8'h01,
   AUTH_FAILURE   = 8'h02,
   SERVICE_REJECT = 8'h03,
   TAU_REJECT     = 8'h04;

  function void disp_attack();
  reg check;
  check = sram_inst.mem[sram_inst.mem.size()-1]&8'hff;
  casex(check)
    ATTACH_REJECT: $display("Detected attack: Attach Reject");
    AUTH_FAILURE: $display("Detected attack: Authentication Failure");
    SERVICE_REJECT: $display("Detected attack: Service Reject");
    TAU_REJECT: $display("Detected attack: TAU Reject");
    default: $display("Detected attack: Unknown");
  endcase
  endfunction

  task test;
    input integer testNum;
  begin
    
    $display("INFO:LVL0: ######## Running Test: %0d ########",testNum);
    wait_n_clks(10);
    sram_inst.loadMem($sformatf("%s/test%0d.dat",input_dir,testNum));
    wait_n_clks(10);
    handshack();
    wait_n_clks(10);
    //check_output(testNum);
    disp_attack();
    wait_n_clks(10);
  end
  endtask



  initial
  begin
    wait(simulationStart);
    reset_n = 1;
    wait_n_clks(10);
    reset_n = 0;
    wait_n_clks(20);
    dut_valid = 0;
    wait_n_clks(20);
    reset_n = 1;
    wait_n_clks(20);
    $display("INFO: DONE WITH RESETING DUT");
    ->testStart;
    startTime=$time();
    for(int i=1;i<num_of_testcases+1;i++)
    begin
      test(i);
    end
    //endTime=$time();
    // if(totalNumOfCases != 0)
    // begin
    //   $display("INFO: Total number of cases  : %0d",totalNumOfCases);
    //   $display("INFO: Total number of passes : %0d",totalNumOfPasses);
    //   $display("INFO: Final Results          : %6.2f",(totalNumOfPasses * 100)/totalNumOfCases);
    //   $display("INFO: Final Time Result      : %0t ns",endTime-startTime);
    //   $display("INFO: Final Cycle Result     : %0d cycles\n",((endTime-startTime)/CLK_PHASE));
    // end
    $finish();
  end
endmodule
