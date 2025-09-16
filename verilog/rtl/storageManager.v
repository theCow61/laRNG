module storageManager #(
	parameter BITS = 256
) (
	input i_storageClock,
	input i_ranBitClock, // the 2 clocks should be the same when used in direct core context.
	input i_storageEnb,
	input i_rst,
	input i_ranBit,
	input i_read16, // wipe last 16 valid
	input i_read32, // wipe last 32 valid. Do a mask with pointer and somethin with sbitsDestroy
	output [31:0] o_read
);

wire [BITS-1:1] s_bitsDestroy;

wire [BITS-1:0] s_cacheData;

shiftCache #(.BITS(BITS)) storage (
	.i_clock(i_storageClock),
	.i_firstBitClock(i_ranBitClock),
	.i_enb(i_storageEnb),
	.i_rst(i_rst),
	.i_ranBit(i_ranBit),
	.i_bitDestroy(s_bitsDestroy),
	.o_data(s_cacheData)
);

//reg [($clog2(BITS))-1:0] s_upToValidPointer;
reg [7:0] s_upToValidPointer;

assign s_bitsDestroy = i_read32 ? (s_upToValidPointer & 8'b11100000) : (); // figure out

always @(posedge i_storageClock) begin
	if (i_rst || !i_storageEnb) begin
		s_upToValidPointer <= 0;
	end
	else begin
		if (s_upToValidPointer == (BITS-1)) begin
			s_upToValidPointer <= BITS-1;
		end
		else if (i_read16) begin
			s_upToValidPointer <= (s_upToValidPointer & 8'b11110000);
		end
		else if (i_read32) begin
			s_upToValidPointer <= (s_upToValidPointer & 8'b11100000);
		end
		else begin
			s_upToValidPointer <= s_upToValidPointer + 1;
		end
	end
end

always @(s_upToValidPointer[7:4], s_cacheData) begin
	case (s_upToValidPointer[7:4]) begin
		4'b0000		: o_read = s_cacheData[15:0];
		4'b0001		: o_read = s_cacheData[31:16];
		4'b0010		: o_read = s_cacheData[47:32];
		4'b0011		: o_read = s_cacheData[63:48];
		4'b0100		: o_read = s_cacheData[79:64];
		4'b0101		: o_read = s_cacheData[95:80];
		4'b0110		: o_read = s_cacheData[111:96];
		4'b0111		: o_read = s_cacheData[127:112];
		4'b1000		: o_read = s_cacheData[143:128];
		4'b1001		: o_read = s_cacheData[159:144];
		4'b1010		: o_read = s_cacheData[175:160];
		4'b1011		: o_read = s_cacheData[191:176];
		4'b1100		: o_read = s_cacheData[207:192];
		4'b1101		: o_read = s_cacheData[223:208];
		4'b1110		: o_read = s_cacheData[239:224];
		4'b1111		: o_read = s_cacheData[255:240];
	endcase
end


endmodule
