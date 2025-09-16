module auxRanSet #(
	parameter N_BLOCKS = 12
) (
	input i_enb,
	output [N_BLOCKS-1:0] o_block_Qs
);
/*
wire s_Qlatch;
wire s_nQlatch;

assign s_Qlatch = ~(i_clock & s_nQlatch);
assign s_nQlatch = ~(i_clock & s_Qlatch);


restDFF bufDFF1(
	.clock(i_clock),
	.D(s_Qlatch),
	.Q(o_Q)
);
wire s_nQbuf;
restDFF bufDFF2(
	.clock(i_clock),
	.D(s_nQlatch),
	.Q(s_nQbuf)
);
*/

genvar i;
generate
	for (i = 0; i < N_BLOCKS; i = i + 1)
	begin
		dualLatchBlock dualLatchComp(
			.i_enb(i_enb),
			.o_Q(o_block_Qs[i])
		);
	end
endgenerate
endmodule

