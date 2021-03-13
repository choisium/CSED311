
`include "vending_machine_def.v"
	
module d_flip_flop(
        clk, 
        reset_n,
        i_input_coin,
        o_available_item_async,
        o_output_item_async,
        o_return_coin_async,
        o_available_item,
        o_output_item,
        o_return_coin);

        input clk;
        input reset_n;
        input [`kNumCoins-1:0] i_input_coin;
        input [`kNumItems-1:0] o_available_item_async;
        input [`kNumItems-1:0] o_output_item_async;
        input [`kNumCoins-1:0] o_return_coin_async;

        output reg [`kNumItems-1:0] o_available_item;
        output reg [`kNumItems-1:0] o_output_item;
        output reg [`kNumCoins-1:0] o_return_coin;

        // d flip flop to make output synchronous 
        always @(posedge clk) begin 
            if (!reset_n) begin
                o_available_item <= `kNumItems'b0;
                o_output_item <= `kNumItems'b0;
                o_return_coin <= `kNumCoins'b0;
            end
            else begin
                o_available_item <= o_available_item_async;
                o_output_item <= o_output_item_async;
                o_return_coin <= o_return_coin_async;
            end
                // print available items
                if (i_input_coin || o_output_item)
                    $strobe("o_available_item = %0b", o_available_item);
        end   
endmodule

