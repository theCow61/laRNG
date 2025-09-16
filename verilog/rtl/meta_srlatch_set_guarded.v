`default_nettype none

/// sta-blackbox


//`celldefine
module meta_srlatch_set_guarded (
	`ifdef USE_POWER_PINS
		inout VPWR,
		inout VGND,
	`endif
	input i_srclk,
	output [255:0] o_ranQ
);

assign o_ranQ = 0;

endmodule
//`endcelldefine

`default_nettype wire

