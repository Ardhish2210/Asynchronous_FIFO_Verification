`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.06.2025 14:07:36
// Design Name: 
// Module Name: Async_fifo_design
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

//ASYNC FIFO DESIGN
module Async_fifo (
  wr_clk,
  rd_clk,
  rst_n,
  wr,
  rd, 
  wdata,
  rdata,
  empty,
  valid,
  full,
  overflow,
  underflow
);
  
  parameter data_width = 8;
  parameter fifo_depth = 8;
  parameter address_size = 4;
  
  input wr_clk;
  input rd_clk;
  input rst_n;  
  input wr;
  input rd;
  input [data_width-1:0] wdata;
  
  output reg [data_width-1:0] rdata;
  output empty;
  output reg valid;
  output full;
  output reg overflow;
  output reg underflow;
  
  reg [address_size-1:0] wr_pointer, wr_pointer_gray_S1, wr_pointer_gray_S2;
  reg [address_size-1:0] rd_pointer, rd_pointer_gray_S1, rd_pointer_gray_S2;
  wire [address_size-1:0] wr_pointer_gray;
  wire [address_size-1:0] rd_pointer_gray;
  
  // FIFO memory
  reg [data_width-1:0] mem [fifo_depth-1:0];
  
  // Binary to Gray conversion
  assign wr_pointer_gray = wr_pointer ^ (wr_pointer >> 1);
  assign rd_pointer_gray = rd_pointer ^ (rd_pointer >> 1);
  
  // Writing data into FIFO
  always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
      wr_pointer <= 0;
    end else if (!full && wr) begin      
      mem[wr_pointer[2:0]] <= wdata;  
      wr_pointer <= wr_pointer + 1;
    end
  end
    
  // Reading data from FIFO
  always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
      rd_pointer <= 0;
    end else if (!empty && rd) begin
      rdata <= mem[rd_pointer[2:0]];  
      rd_pointer <= rd_pointer + 1;
    end
  end
  
  // 2-stage synchronizer for wr_pointer to rd_clk domain
  always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
      wr_pointer_gray_S1 <= 0;
      wr_pointer_gray_S2 <= 0;
    end else begin 
      wr_pointer_gray_S1 <= wr_pointer_gray;
      wr_pointer_gray_S2 <= wr_pointer_gray_S1;
    end  	
  end
  
  // 2-stage synchronizer for rd_pointer to wr_clk domain
  always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
      rd_pointer_gray_S1 <= 0;
      rd_pointer_gray_S2 <= 0;
    end else begin 
      rd_pointer_gray_S1 <= rd_pointer_gray;
      rd_pointer_gray_S2 <= rd_pointer_gray_S1;
    end  	
  end  
  
  // Empty condition
  assign empty = (rd_pointer_gray == wr_pointer_gray_S2);
  
  // Full condition
  assign full = (wr_pointer_gray == {~rd_pointer_gray_S2[address_size-1:address_size-2], rd_pointer_gray_S2[address_size-3:0]});
  
  // Overflow and underflow detection
  always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
      overflow <= 1'b0;
    end else begin
      overflow <= (full && wr);
    end
  end
  
  always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
      underflow <= 1'b0;
      valid <= 1'b0;
    end else begin
      underflow <= (empty && rd);
      valid <= (rd && !empty);
    end
  end
    
endmodule