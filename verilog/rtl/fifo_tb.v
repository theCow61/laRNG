module fifo_tb;


reg s_clock;
reg s_rst;
reg s_enb;
reg s_ranBit;
reg s_read;
wire [31:0] s_data;
wire [4:0] s_bytesReady;



fifo fifo_under_test (
	.i_clock(s_clock),
	.i_rst(s_rst),
	.i_enb(s_enb),
	.i_ranBit(s_ranBit),
	.i_read(s_read),
	.o_data(s_data),
	.o_bytesReady(s_bytesReady)
);

always #2 s_clock = ~ s_clock;

initial begin
	s_clock = 0;
	s_rst = 0;
	s_enb = 1;
	s_read = 0;
	s_ranBit = 0;
	#20 s_rst = 1;
	#20 s_rst = 0;
	

	// bytesReady should be 0
	$display("Expected: 0 Actual: %d", s_bytesReady);
	
	#(8*4) // 8*4
	$display("Expected: 1 Actual: %d", s_bytesReady);

	#(3*8*4)
	$display("Expected: 4 Actual: %d", s_bytesReady);

	s_read = 1;
	#4
	$display("Expected: 0 Actual: %d", s_bytesReady);
	s_read = 0;

	#(7*8*4)
	$display("Expected: 7 Actual: %d", s_bytesReady);
	
	s_read = 1;
	#4
	$display("Expected: 3 Actual: %d", s_bytesReady);
	
	#4
	$display("Expected: 0 Acutal: %d", s_bytesReady);
	s_read = 0;

	#(20*4*8*4)
	$display("Expected: 31 Actual: %d", s_bytesReady);
	s_read = 1;

	#4
	$display("Expected: 28 Actual: %d", s_bytesReady);
	s_read = 0;

	#(20*4*8*4)
	s_read = 1;
	#(8*4)
	s_read = 0;
	#4
	$display("Expected: 1 Actual: %d", s_bytesReady); // despite having doing destructuve reads for the past lot of cycles, we should still be increasing our fifo with new bits despite this. There should be a byte of bits accumulated at this point even though we were
	// "clearing" large amounts of data
	
	// track data
	s_read = 1; // wipe word
	s_ranBit = 1; // but should also take in a new bit at same time
	#4
	$display("Expected: 0 Actual: %d", s_bytesReady);
	$display("Expected: 0x1 Actual: %h", s_data);
	s_ranBit = 0;
	s_read = 0;

	#4
	$display("Expected: 0 Actual: %d", s_bytesReady);
	$display("Expected: 0x2 Actual: %h", s_data);
	s_read = 1;
	#4
	$display("Expected: 0x0 Actual: %h", s_data);
	s_read = 0;
	
	#(20*4*8*4)
	s_ranBit = 1;
	s_read = 1;
	#4
	s_ranBit = 1;
	#4
	s_ranBit = 0;
	#(5*4)
	$display("Expected: 0x1 Actual: %h", s_data);
	#4
	s_read = 0;
	$display("Expected: 0x40 Actual: %h", s_data);
	#4
	$display("Expected: 1 Actual: %d", s_bytesReady);
	$display("Expected: 0x80 Actual: %h", s_data);

	s_read = 1;
	#16
	s_read = 0;
	#(4*4*8*4)
	s_read = 1;
	s_ranBit = 1;
	#(4*4)
	s_read = 0;
	$display("Expected: 0 Acutal: %d", s_bytesReady);
	$display("Expected: 0xf Actual: %h", s_data);
	#4

	s_rst = 1;
end

endmodule
