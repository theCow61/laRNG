module cLDCE (
	input D,
	input GE,
	input G,
	input CLR,
	output Q
);
reg s_Q;
assign Q = s_Q;
always @* begin
	if (CLR) begin
		s_Q = 'b0;
	end
	else if (GE && G) begin
		s_Q = D;
	end
end
endmodule
