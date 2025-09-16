module cLDPE (
	input D,
	input GE,
	input G,
	input PRE,
	output Q
);
reg s_Q;
assign Q = s_Q;
always @* begin
	if (PRE) begin
		s_Q = 'b1;
	end
	else if (GE && G) begin
		s_Q = D;
	end
end
endmodule
