`include "opcodes.v" 

module mux2to1 #(parameter DATA_WIDTH = 16) (in1, in2, sel, out);
    input [DATA_WIDTH-1:0] in1, in2;
    input sel;
    output reg [DATA_WIDTH-1:0] out;
    
    always @(*) begin
        case(sel)
            1: out = in2;
            default: out = in1;
        endcase
    end
endmodule

module mux4to1 #(parameter DATA_WIDTH = 16) (in1, in2, in3, in4, sel, out);
    input [DATA_WIDTH-1:0] in1, in2, in3, in4;
    input [1:0] sel;
    output reg [DATA_WIDTH-1:0] out;
    
    always @(*) begin
        case(sel)
            1: out = in2;
            2: out = in3;
            3: out = in4;
            default: out = in1;
        endcase
    end
endmodule