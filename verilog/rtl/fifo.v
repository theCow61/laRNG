module fifo #(
	parameter N_WORDS = 8
) (
	input i_clock,
	input i_rst,
	input i_enb,
	input i_ranBit,
	input i_read, // destructive read
	input i_staleAllowed,
	output [31:0] o_data,
	output [($clog2(N_WORDS)+2)-1:0] o_bytesReady
);

reg [$clog2(N_WORDS)-1:0] s_currentWordAddr;

reg [4:0] s_currentWordProgressCounter;
always @(posedge i_clock) begin
	if (i_rst || (!i_enb && !i_staleAllowed)) begin
		s_currentWordProgressCounter <= 0;
	end
	else if (!i_enb && i_staleAllowed) begin
		s_currentWordProgressCounter <= s_currentWordProgressCounter;
	end
	else if (i_enb) begin
		if (!i_read && s_currentWordAddr == {$clog2(N_WORDS) {1'b1}} && s_currentWordProgressCounter == {5 {1'b1}}) begin // If it's not a read and we are maxed out, then keep it looking like it's maxxed out
			s_currentWordProgressCounter <= {5 {1'b1}}; // Keep same
		end
		else if (i_read && s_currentWordAddr == 0) begin
			s_currentWordProgressCounter <= 1; // new bit should come in
		end
		else begin
			s_currentWordProgressCounter <= s_currentWordProgressCounter + 1;
		end
	end
end


// Assuming values reffed here that are set in above always block are using
// the previous cycles values
always @(posedge i_clock) begin
	if (i_rst || (!i_enb && !i_staleAllowed)) begin // we want address to be fixed at 0 when starting or when not using fifo. For spi mode, we should expect the ran bit to be the 0th bit in the bottom fifo despite fifo being off.
		s_currentWordAddr <= 0;
	end
	else if (!i_enb && i_staleAllowed) begin
		s_currentWordAddr <= s_currentWordAddr;
	end
	else begin
		if (i_read && s_currentWordProgressCounter == {5 {1'b1}}) begin // almost full so increment but reading so decrement, so cancel out and leave at same value
			s_currentWordAddr <= s_currentWordAddr;
		end
		else if (i_read && s_currentWordAddr != {$clog2(N_WORDS) {1'b0}}) begin // reading but current word isn't 0th word and not almost full. Lets support this because maybe less than a word of random is requested via the async feuture
			s_currentWordAddr <= s_currentWordAddr - 1;
		end
		else if ((s_currentWordAddr != {$clog2(N_WORDS) {1'b1}}) && s_currentWordProgressCounter == {5 {1'b1}}) begin // almost full but our addr isn't at the top yet. (If it is we wouldn't want it to increment/wrap around to 0).
			s_currentWordAddr <= s_currentWordAddr + 1;
		end
		else begin
			s_currentWordAddr <= s_currentWordAddr;
		end
	end
end


assign o_bytesReady[($clog2(N_WORDS)+2)-1:2] = s_currentWordAddr;
assign o_bytesReady[1:0] = s_currentWordProgressCounter[4:3];


// first bit in lowest level of fifo should have no reset or care for enb.
// This bit should be used when doing in spi mode regardless of fifo being
// off. Because this bit is also being used for the fifo, decoding addresses
// is needed, though this isn't needed in spi mode and may just lower our spi
// mode throughput. One thing could be to add a bit before and external to the
// fifo, though that would then require 1 clock cycle of initialization.
// Actually, this shouldn't matter because the default startup mode is spi
// mode anyways so having initialization slowed by 1 cycle shouldn't
// matter because you would anyways need to change out of spi mode for
// utilizing the fifo.

reg [31:0] s_datas[N_WORDS-1:0];
assign o_data = s_datas[0];

// data loading down diagnoly in the case of not finished with the word. Loading from opposite direction may have unconsistant outputs when non word aligned amounts of bytes are requested. (you want 3 bytes but say sometimes the 3 random bytes are organized le and sometimes organized be).
genvar i;
generate
	for (i = 0; i < N_WORDS-1; i = i + 1) begin
		always @(posedge i_clock) begin
			if (i_rst) begin
				s_datas[i] <= 0;
			end
			else if (i_enb) begin
				if (i_read) begin
					if (s_currentWordAddr == i+1 || (i == 0 && s_currentWordAddr == 0/*special case for bottom register generate*/)) begin
						s_datas[i][31:1] <= s_datas[i+1][30:0]; // shift when loading down to give space for the new ran bit.
						s_datas[i][0] <= i_ranBit;
					end
					else begin
						s_datas[i] <= s_datas[i+1];
					end
				end
				else if (s_currentWordAddr == i) begin
					s_datas[i][31:1] <= s_datas[i][30:0];
					s_datas[i][0] <= i_ranBit;
				end
			end
		end
	end

	// for the last register. Not doing ring as of now.
	always @(posedge i_clock) begin
		if (i_rst) begin
			s_datas[N_WORDS-1] <= 0;
		end
		else if (i_enb) begin
			if (i_read) begin
				s_datas[N_WORDS-1] <= 0; // if we were maxed out then we loose a bit of rand because
				// when maxed out, row under takes a full row of random from this row but then also
				// gets a new random bit as well
			end
			else if (s_currentWordAddr == N_WORDS-1) begin
				s_datas[N_WORDS-1][31:1] <= s_datas[N_WORDS-1][30:0];
				s_datas[N_WORDS-1][0] <= i_ranBit;
			end
		end
	end

endgenerate

endmodule
