`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/08/08 11:22:22
// Design Name: 
// Module Name: bramwrapper
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


module bramwrapper #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,
    parameter READ_LATENCY =3
    )(
    input clk,
    input rst,
    input wea,
    input [ADDR_WIDTH - 1 : 0] addra,
    input [DATA_WIDTH - 1 : 0] dina,
    input ena,
    output valid,
    output [DATA_WIDTH - 1 : 0] extDataOut
    );
    
    localparam IDLE  = 2'b00,
                WAIT = 2'b01,
                READ = 2'b10;
                
    reg [1:0] cState, nState; // cState : Current State, nState : next State
    reg enToBlkmem;
    reg validToExt;
    reg [1:0] waitCounter;
    wire trCondition0;
    wire trCondition1;
    wire [DATA_WIDTH - 1 : 0]douta;

   blk_mem_gen_0 A01 (
  .clka(clk),    // input wire clka
  .ena(enToBlkmem),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [7 : 0] addra
  .dina(dina),    // input wire [31 : 0] dina
  .douta(douta)  // output wire [31 : 0] douta
  );    
    assign trCondition0 = (ena == 1'b1 && wea == 1'b0)? 1: 0;
    assign trCondition1 = (waitCounter == (READ_LATENCY-1))? 1: 0;
    assign extDataOut = (validToExt)? douta: 0;
    assign valid = validToExt;
    
    always @(posedge clk, negedge rst) begin
        if(!rst)
            cState <= IDLE;
        else
            cState <= nState;
    end
    
    always @(*) begin
        nState = cState;
        case(cState)
            IDLE : begin
                if(trCondition0) begin
                    if(READ_LATENCY == 1) 
                        nState = READ;
                    else
                        nState = WAIT;
                end
            end    
            WAIT : begin
                if (trCondition1)
                    nState = READ;
            end
            READ : begin
                nState = IDLE;
            end
         endcase                
    end

    //Output signals
    always @(*) begin
        nState = cState;
        case(cState)
            IDLE : begin
                enToBlkmem = ena;
                validToExt = 0;                
            end
            WAIT : begin
                enToBlkmem = 1;
                validToExt = 0;
            end
            READ : begin
                enToBlkmem = 0;
                validToExt = 1;
            end
        endcase    
     end
     
     //Clock count for WAIT state
     always @(posedge clk, negedge rst)begin
        if(!rst)
            waitCounter <= 0;
        else
            if(cState == WAIT)begin
                if(waitCounter == READ_LATENCY)
                    waitCounter <= 0;
                else 
                    waitCounter <= waitCounter + 1'b1;
            end
            else waitCounter <= 0;
     end
                 
endmodule
