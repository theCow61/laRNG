module shiftCache #(
	parameter BITS = 256
) (
	input i_clock,
	input i_firstBitClock, // differntiation because first bit may be used for GPIO while the rest of the cache should only be relevent when directly used within the context of the core.
	input i_enb,
	input i_rst,
	input i_ranBit,
	input [BITS-1:1] i_bitDestroy,
	output [BITS-1:0] o_data
);

reg [BITS-1:0] s_data;
assign o_data = s_data;

always @(posedge i_firstBitClock) begin
	s_data[0] <= i_ranBit;
end

genvar i;
generate
	for (i = 1; i < BITS; i = i + 1) begin: cacheGen
		always @(posedge i_clock) begin
			if (i_rst || (i_bitDestroy[i] == 1'b1)) begin
				s_data[i] <= 'b0;
			end
			else if (i_enb) begin
				s_data[i] <= s_data[i - 1];
			end
		end
	end
endgenerate
endmodule
