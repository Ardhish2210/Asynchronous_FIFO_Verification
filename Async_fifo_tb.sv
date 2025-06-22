`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.06.2025 14:09:46
// Design Name: 
// Module Name: Async_fifo_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//Transaction class
class transaction;

  localparam data_width = 8;
  localparam fifo_depth = 8;
  localparam address_size = 4;
  
  rand bit wr;
  rand bit rd;
  randc bit [data_width-1:0] wdata;
  
  bit [data_width-1:0] rdata;
  bit empty;
  bit valid;
  bit full;
  bit overflow;
  bit underflow;
  
  // Constraint to control write/read operations
  constraint wr_rd_c {
    wr dist {1:=70, 0:=30};
    rd dist {1:=70, 0:=30};
  }
  
  // Add test scenarios
  static int test_phase = 0; // 0=mixed, 1=fill_fifo, 2=empty_fifo
  
  function void display();
    $display("wr=%0d rd=%0d wdata=%0d rdata=%0d full=%0d empty=%0d valid=%0d overflow=%0d underflow=%0d", wr, rd, wdata, rdata, full, empty, valid, overflow, underflow);
  endfunction
  
  function transaction copy();
    copy = new();
    copy.wr = this.wr;
    copy.rd = this.rd;
    copy.wdata = this.wdata;
    copy.rdata = this.rdata;
    copy.empty = this.empty;
    copy.full = this.full;
    copy.valid = this.valid;
    copy.underflow = this.underflow;
    copy.overflow = this.overflow;
  endfunction
  
endclass

//Generator class
class generator;
  
  transaction trans;
  mailbox #(transaction) gen2drv;
  event gen_done;
  int test_count = 20;
  
  function new(mailbox #(transaction) gen2drv);
    this.gen2drv = gen2drv;
    trans = new();
  endfunction 
  
  task run();
    $display("[GEN]: Starting generation of %0d transactions", test_count);
    
    // Phase 1: Fill FIFO to test full condition
    transaction::test_phase = 1;
    for(int i = 0; i < 10; i++) begin
      trans.randomize() with {wr == 1; rd == 0;};
      gen2drv.put(trans.copy());
      $display("[GEN]: FILL Phase - Transaction %0d generated", i+1);
      trans.display();
      #10;
    end
    
    // Phase 2: Empty FIFO to test empty condition  
    transaction::test_phase = 2;
    for(int i = 0; i < 12; i++) begin
      trans.randomize() with {wr == 0; rd == 1;};
      gen2drv.put(trans.copy());
      $display("[GEN]: EMPTY Phase - Transaction %0d generated", i+1);
      trans.display();
      #10;
    end
    
    // Phase 3: Mixed operations
    transaction::test_phase = 0;
    for(int i = 0; i < test_count-22; i++) begin
      trans.randomize();
      gen2drv.put(trans.copy());
      $display("[GEN]: MIXED Phase - Transaction %0d generated", i+1);
      trans.display();
      #10;
    end
    
    $display("[GEN]: All transactions generated");
    -> gen_done;
  endtask
endclass

//Interface
interface async_fifo_if;
  parameter data_width = 8;
  parameter fifo_depth = 8;
  parameter address_size = 4;
  
  logic wr_clk;
  logic rd_clk;
  logic rst_n;  
  logic wr;
  logic rd;
  logic [data_width-1:0] wdata;
  
  logic [data_width-1:0] rdata;
  logic empty;
  logic valid;
  logic full;
  logic overflow;
  logic underflow;
  
endinterface

//Driver class
class driver;
  
  virtual async_fifo_if vif;
  transaction data;
  mailbox #(transaction) gen2drv;
  event gen_done;
  int test_count = 20;
  
  function new(mailbox #(transaction) gen2drv);
    this.gen2drv = gen2drv;
  endfunction
  
  task run();
    $display("[DRV]: Driver started");
    
    wait(vif.rst_n);
    
    for(int i = 0; i < test_count; i++) begin
      gen2drv.get(data);
      
      // Drive write operation (check for full condition)
      if(data.wr) begin
        @(posedge vif.wr_clk);
        if(!vif.full) begin
          vif.wr <= data.wr;
          vif.wdata <= data.wdata;
          @(posedge vif.wr_clk);
          vif.wr <= 0;
          $display("[DRV]: Write operation - Data: %0d", data.wdata);
        end else begin
          $display("[DRV]: Write blocked - FIFO is full");
        end
      end
      
      if(data.rd) begin
        @(posedge vif.rd_clk);
        if(!vif.empty) begin
          vif.rd <= data.rd;
          @(posedge vif.rd_clk);
          vif.rd <= 0;
          $display("[DRV]: Read operation initiated");
        end else begin
          $display("[DRV]: Read blocked - FIFO is empty");
        end
      end
      
      #5; 
    end
    $display("[DRV]: All transactions driven");
  endtask
endclass

//Monitor class
class monitor;
  
  virtual async_fifo_if vif;
  mailbox #(transaction) mon2sco;
  transaction data;
  event gen_done;
  int test_count = 20;
  
  function new(mailbox #(transaction) mon2sco);
    this.mon2sco = mon2sco;
  endfunction
  
  task run();
    $display("[MON]: Monitor started");
    data = new();
    
    wait(vif.rst_n);
    
    fork
      forever begin
        @(posedge vif.wr_clk);
        if(vif.wr && vif.rst_n) begin
          data = new();
          data.wr = vif.wr;
          data.wdata = vif.wdata;
          data.full = vif.full;
          data.overflow = vif.overflow;
          $display("[MON]: Write monitored - Data: %0d, Full: %0d, Overflow: %0d", 
                   data.wdata, data.full, data.overflow);
          mon2sco.put(data.copy());
        end
      end
      
      // Monitor read operations
      forever begin
        @(posedge vif.rd_clk);
        if(vif.rd && vif.rst_n) begin
          @(posedge vif.rd_clk); // Wait for data to be available
          data = new();
          data.rd = vif.rd;
          data.rdata = vif.rdata;
          data.empty = vif.empty;
          data.valid = vif.valid;
          data.underflow = vif.underflow;
          $display("[MON]: Read monitored - Data: %0d, Valid: %0d, Empty: %0d, Underflow: %0d", data.rdata, data.valid, data.empty, data.underflow);
          mon2sco.put(data.copy());
        end
      end
      
      wait(gen_done.triggered);
      #1000;      
    join_any
    
    $display("[MON]: Monitoring completed");
  endtask
  
endclass

//Scoreboard class
class scoreboard;
  
  mailbox #(transaction) mon2sco;
  transaction data;  
  event gen_done;
  int transactions_received = 0;
  
  function new(mailbox #(transaction) mon2sco);
    this.mon2sco = mon2sco;
  endfunction
  
  task run();
    $display("[SCO]: Scoreboard started");
    
    fork
      forever begin
        mon2sco.get(data);
        transactions_received++;
        $display("[SCO]: Transaction %0d received", transactions_received);
        data.display();
        
        // Enhanced checking logic
        if(data.wr && data.full) begin
          if(data.overflow) 
            $display("[SCO]: PASS - Overflow correctly detected when writing to full FIFO");
          else
            $display("[SCO]: FAIL - Overflow should be asserted when writing to full FIFO");
        end
        
        if(data.rd && data.empty) begin
          if(data.underflow)
            $display("[SCO]: PASS - Underflow correctly detected when reading from empty FIFO");
          else
            $display("[SCO]: FAIL - Underflow should be asserted when reading from empty FIFO");
        end
        
        // Check data integrity for valid reads
        if(data.rd && data.valid && !data.empty) begin
          $display("[SCO]: PASS - Valid data read: %0d", data.rdata);
        end
      end
      
      wait(gen_done.triggered);
      #2000;
      
    join_any
    
    $display("[SCO]: Scoreboard completed. Total transactions: %0d", transactions_received);
  endtask
  
endclass

//Environment class
class environment;
  
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  mailbox #(transaction) gen2drv;
  mailbox #(transaction) mon2sco;
  
  virtual async_fifo_if vif;
  event gen_done;
  
  function new(virtual async_fifo_if vif);
    this.vif = vif;
    
    gen2drv = new();
    mon2sco = new();
    
    gen = new(gen2drv);
    drv = new(gen2drv);
    mon = new(mon2sco);
    sco = new(mon2sco);
    
    drv.vif = vif;
    mon.vif = vif;
    
    gen.gen_done = gen_done;
    drv.gen_done = gen_done;
    mon.gen_done = gen_done;
    sco.gen_done = gen_done;
  endfunction
  
  task run();
    $display("[ENV]: Environment started");
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
    $display("[ENV]: Environment completed");
  endtask
  
endclass

//Testbench module
module async_fifo_tb;
  
  parameter DATA_WIDTH = 8;
  parameter FIFO_DEPTH = 8;
  parameter ADDRESS_SIZE = 4;
  
  async_fifo_if vif();
  
  // DUT instance
  Async_fifo #(
    .data_width(DATA_WIDTH),
    .fifo_depth(FIFO_DEPTH),
    .address_size(ADDRESS_SIZE)
  ) dut (
    .wr_clk(vif.wr_clk), 
    .rd_clk(vif.rd_clk), 
    .rst_n(vif.rst_n),
    .wr(vif.wr), 
    .rd(vif.rd), 
    .wdata(vif.wdata), 
    .rdata(vif.rdata),
    .empty(vif.empty), 
    .valid(vif.valid), 
    .full(vif.full),
    .overflow(vif.overflow), 
    .underflow(vif.underflow)
  );
  
  environment env;
  
  // Clock generation
  initial vif.wr_clk = 0;
  always #5 vif.wr_clk = ~vif.wr_clk;    // 10ns period
  
  initial vif.rd_clk = 0;
  always #7 vif.rd_clk = ~vif.rd_clk;    // 14ns period (different from write clock)
  
  initial begin
    $dumpfile("Async_fifo_tb.vcd");
    $dumpvars(0, async_fifo_tb);
    
    $display("Starting Async FIFO Verification");
    
    vif.rst_n = 1;
    vif.wr = 0;
    vif.rd = 0;
    vif.wdata = 0;
    
    $display("Applying reset");
    #10 vif.rst_n = 0;  
    #50 vif.rst_n = 1;  
    #20;
    
    $display("Reset released. Starting verification");
    
    env = new(vif);
    env.run();
    
    #5000;
    
    $display("=== Async FIFO Verification Completed ===");
    $finish;
  end
  
  always @(posedge vif.wr_clk) begin
    if (vif.wr && vif.rst_n && !vif.full) begin
      $display("TIME: %0t WRITE: Data = %0d", $time, vif.wdata);
    end
    if (vif.wr && vif.rst_n && vif.full) begin
      $display("TIME: %0t WRITE BLOCKED: FIFO is full", $time);
    end
  end
  
  always @(posedge vif.rd_clk) begin
    if (vif.valid && vif.rst_n) begin
      $display("TIME: %0t READ: Data = %0d", $time, vif.rdata);
    end
    if (vif.rd && vif.rst_n && vif.empty) begin
      $display("TIME: %0t READ BLOCKED: FIFO is empty", $time);
    end
  end
  
endmodule