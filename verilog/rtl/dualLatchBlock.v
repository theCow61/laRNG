module dualLatchBlock (
	input i_enb,
	output o_Q
);

wire bLatchQ;
wire tLatchQ;
wire xnoredQ;
assign xnoredQ = ~(bLatchQ ^ tLatchQ);

cLDPE tLatch (
	.Q(tLatchQ),
	.PRE(xnoredQ),
	.D(bLatchQ),
	/*.G(1'b1),
	.GE(1'b1)*/
	.G(i_enb),
	.GE(i_enb)
);

cLDCE bLatch (
	.Q(bLatchQ),
	.CLR(xnoredQ),
	.D(tLatchQ),
	/*.G(1'b1),
	.GE(1'b1)*/
	.G(i_enb),
	.GE(i_enb)
);

assign o_Q = tLatchQ;

endmodule
