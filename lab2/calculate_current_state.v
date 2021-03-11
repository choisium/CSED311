
`include "vending_machine_def.v"
	

module calculate_current_state(i_input_coin,i_select_item,item_price,coin_value,current_total,
current_total_nxt,wait_time,o_return_coin,o_available_item,o_output_item);


	
	input [`kNumCoins-1:0] i_input_coin,o_return_coin;
	input [`kNumItems-1:0]	i_select_item;			
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];	
	input [`kTotalBits-1:0] current_total;
	input [31:0] wait_time;
	output reg [`kNumItems-1:0] o_available_item,o_output_item;
	output reg  [`kTotalBits-1:0] current_total_nxt;
	integer i;	

	wire [`kTotalBits-1:0] inserted_coin, selected_item;
	assign inserted_coin = i_input_coin[0] * coin_value[0]
						+ i_input_coin[1] * coin_value[1]
						+ i_input_coin[2] * coin_value[2];
	assign selected_item = i_select_item[0] * item_price[0]
						+ i_select_item[1] * item_price[1]
						+ i_select_item[2] * item_price[2]
						+ i_select_item[3] * item_price[3];

	
	// Combinational logic for the next states
	always @(*) begin
		// when item is selected and it is available
		if (selected_item !== 0 && selected_item <= current_total) begin
			current_total_nxt = current_total - selected_item;
			o_output_item = i_select_item;
		end
		// when coin is inserted or item is selected but unavailable
		else begin
			current_total_nxt = current_total + inserted_coin;
			o_output_item = `kNumItems'b0;
		end

		// check available items using current_total_nxt
		for (i = 0; i < `kNumItems; i = i + 1) begin
			if (item_price[i] <= current_total_nxt)
				o_available_item[i] = 1;
			else
				o_available_item[i] = 0;
		end

		// print available items
		if (inserted_coin || o_output_item)
			$strobe("o_available_item = %0b", o_available_item);
	end
 
	


endmodule 