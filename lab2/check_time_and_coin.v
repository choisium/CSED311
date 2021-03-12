`include "vending_machine_def.v"

	

module check_time_and_coin(i_input_coin,i_select_item,o_output_item,clk,reset_n,wait_time,o_return_coin,coin_value,current_total,i_trigger_return);
	input clk;
	input reset_n;
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0]	i_select_item;
	input [`kNumItems-1:0]	o_output_item;
	input [`kTotalBits-1:0] current_total;
	input [31:0] coin_value [`kNumCoins-1:0];
	input i_trigger_return;	
	output reg  [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;

	// signal to return coin start / done
	reg return_coin_signal;
	reg return_done;
	reg [`kTotalBits-1:0] temp_current;
	integer i;

	// initiate values
	initial begin
		o_return_coin <= `kNumCoins'b0;
		wait_time <= 'd100;
		return_coin_signal <= 0;
		return_done <= 0;
	end


	// update coin return time when insert money, item dispensed
	always @(i_input_coin, o_output_item) begin
		wait_time <= 'd100;
	end

	// when return_signal == 1, start to return available coin 
	always @(*) begin
		if(return_coin_signal) begin

			//return available coin
			temp_current = current_total;
			for (i = 0; i < `kNumCoins; i = i + 1) begin
				if (coin_value[i] <= temp_current) begin
					o_return_coin[i] = 1;
					temp_current = temp_current - coin_value[i];
				end
				else
					o_return_coin[i] = 0;
			end

			// when return is done, reset
			if (current_total <= 0) begin
				return_done = 1;
			end
		end
		else 
			o_return_coin = `kNumCoins'b0;
		
	end

	always @(posedge clk ) begin
		if (!(reset_n) | return_done) begin
			// reset all states.
			o_return_coin <= `kNumCoins'b0;
			wait_time <= 'd100;
			return_coin_signal <= 0;
			return_done <= 0;
		end
		else begin
			// update wait time. else statement to avoid underflow
			if (wait_time > 0)
				wait_time <= wait_time - 1;
			else
				wait_time <= 0;

			//$strobe("wait_time = %0d", wait_time);
			
			// return coin when wait_time over or trigger_return
			if ((wait_time <= 0) || i_trigger_return)
				return_coin_signal <= 1;
		end
	end
endmodule 