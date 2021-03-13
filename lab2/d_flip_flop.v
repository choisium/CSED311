
`include "vending_machine_def.v"
	
module d_flip_flop(
        clk, 
        reset_n,
        o_available_item_async,
        i_input_coin,
        o_output_item,
        o_available_item);

        input clk;
        input reset_n;
        input [`kNumItems-1:0] o_available_item_async;
        input [`kNumCoins-1:0] i_input_coin;
        input [`kNumItems-1:0] o_output_item;
        output reg [`kNumItems-1:0] o_available_item;

        // d flip flop to make mealy machine synchronous 
        always @(posedge clk) begin 
            if (!reset_n)
                o_available_item <= `kNumItems'b0;
            else
                o_available_item <= o_available_item_async;
                // print available items
                if (i_input_coin || o_output_item)
                    $strobe("o_available_item = %0b", o_available_item);
        end   
endmodule

