
module laRNG #(
	parameter DUALLATCH_SET_SIZE = 16,
	parameter FIFO_WORDS = 8
)(
	`ifdef USE_POWER_PINS
		inout vccd1,
		inout vssd1,
	`endif
	input i_sysClock,
	input i_gpioSPIClock,
	input wb_rst_i,
	input wbs_stb_i,
	input wbs_cyc_i,
	input wbs_we_i,
	input [31:0] wbs_adr_i,
	input [31:0] wbs_dat_i,
	output [31:0] wbs_dat_o,
	output reg wbs_ack_o,
	output o_genned,
	output [127:0] la_out,
	output o_irq
);

wire s_muxedClock;
/*always @* begin
	case (control_mode)
		'b0 : s_muxedClock = i_gpioSPIClock;
		'b1 : s_muxedClock = i_sysClock;
	endcase
end*/

wire control_mode;
wire control_specialLatchesEnb;
wire control_allowDual;

assign s_muxedClock = control_mode ? i_sysClock : i_gpioSPIClock;

wire[DUALLATCH_SET_SIZE-1:0] dualLatchBlockOuts;

auxRanSet #(.N_BLOCKS(DUALLATCH_SET_SIZE)) ranSet1 (
	.i_enb(control_auxEnb),
	.o_block_Qs(dualLatchBlockOuts)
);


wire [255:0] specialLatchesOut;
meta_srlatch_set_guarded meta_srlatch_array_stack (
	`ifdef USE_POWER_PINS
		.VPWR(vccd1),
		.VGND(vssd1),
	`endif
	.i_srclk(s_muxedClock & control_specialLatchesEnb),
	.o_ranQ(specialLatchesOut)
);

wire specialLatches_xoredResult;
assign specialLatches_xoredResult = ^specialLatchesOut;

wire auxLatches_xoredResult;
assign auxLatches_xoredResult = ^dualLatchBlockOuts;

wire xored_result = specialLatches_xoredResult ^ auxLatches_xoredResult;

assign o_genned = control_allowDual ? s_ranBit : (~(s_ranBit | control_mode));
reg s_ranBit;



// DFF for storing fresh ran bit. 
always @(posedge s_muxedClock) begin
	s_ranBit <= xored_result;
end


assign la_out[12] = specialLatchesOut[191];
assign la_out[11] = specialLatchesOut[221];
assign la_out[10] = specialLatchesOut[63];
assign la_out[9] = specialLatchesOut[255];
assign la_out[8] = specialLatchesOut[0];
assign la_out[7] = specialLatches_xoredResult;
assign la_out[6] = auxLatches_xoredResult;
assign la_out[5] = s_ranBit;
assign la_out[4:0] = s_bytesReady;

wire [($clog2(FIFO_WORDS)+2)-1:0] s_bytesReady;

fifo #(.N_WORDS(FIFO_WORDS)) aFifo (
	.i_clock(i_sysClock),
	.i_rst(wbs_rst_i),
	.i_enb(control_mode),
	.i_ranBit(s_ranBit),
	.i_read(s_doRead),
	.i_staleAllowed(control_staleAllowed),
	.o_data(s_fifoOut),
	.o_bytesReady(s_bytesReady)
);

wire [31:0] s_fifoOut;
reg s_doRead;


reg [5:0] control_register;
assign control_specialLatchesEnb = control_register[5];
assign control_allowDual = control_register[4];
assign control_nBlocking = control_register[3];
assign control_staleAllowed = control_register[2];
assign control_auxEnb = control_register[1];
assign control_mode = control_register[0];


wire [31:0] bytesReadyIntStatus_register;
reg interrupt_status;
assign o_irq = interrupt_status;
assign bytesReadyIntStatus_register[$clog2(FIFO_WORDS)+2-1:0] = s_bytesReady;
assign bytesReadyIntStatus_register[30:$clog2(FIFO_WORDS)+2] = 0;
assign bytesReadyIntStatus_register[31] = interrupt_status;

always @(posedge i_sysClock) begin
	if (wb_rst_i) interrupt_status <= 0;
	else begin
		if (wbs_stb_i && wbs_cyc_i && wbs_we_i && wbs_adr_i[7:0] == 'h0c)
			interrupt_status <= ~wbs_dat_i[0] & interrupt_status;
		else if (async_requested && s_bytesReady >= bytes_requested && !interrupt_status)
			interrupt_status <= 1; // also make interrupt go high
	end
end


reg [31:0] request_register;
assign async_requested = request_register[31];
assign bytes_requested = request_register[$clog2(FIFO_WORDS)+2-1:0];

/*
* 0: control register (RW): mode | aux enable | stale allowed | not blocking
* | allow dual (bits go out spi in sys mode) | special latches enable
*
* 4: request register (RW): async request | reserved | bytes request
*
* 8: status	(R) : bytes ready | reserved | interrupt status
*
* c: interrupt clear (W) : reserved | clear interrupt
*/

always @(posedge i_sysClock) begin
	if (wb_rst_i) control_register <= 0;
	else begin
		if (wbs_stb_i && wbs_cyc_i && wbs_we_i && wbs_adr_i[7:4] == 'h0) begin
			case (wbs_adr_i[3:0])
				'h0 : control_register <= wbs_dat_i[5:0];
				'h4 : request_register <= wbs_dat_i;
				//'hc : interrupt_status <= ~wbs_dat_i[0] & interrupt_status;
				default : control_register <= control_register;
			endcase
		end
	end
end

reg [31:0] wbs_dat_s;
assign wbs_dat_o = wbs_dat_s;

always @(posedge i_sysClock) begin
	wbs_dat_s <= 0;
	wbs_ack_o <= 0;
	if (!wb_rst_i) begin
		wbs_ack_o <= (wbs_cyc_i && wbs_stb_i && !wbs_ack_o && (s_doRead || wbs_we_i || wbs_adr_i[7:4] == 'h0)) ? 1 : 0;

		if (wbs_stb_i && wbs_cyc_i && !wbs_we_i && !wbs_ack_o && wbs_adr_i[7:4] == 'h0) begin
			case (wbs_adr_i[3:0])
				'h0 : begin
					wbs_dat_s[31:6] <= {26 {1'b0}};
					wbs_dat_s[5:0] <= control_register;
				end
				'h4 : wbs_dat_s <= request_register;
				'h8 : wbs_dat_s <= bytesReadyIntStatus_register;
				default : wbs_dat_s <= 0;
			endcase
		end
		if (s_doRead) wbs_dat_s <= s_fifoOut;
	end
end

always @* s_doRead = (wbs_stb_i && wbs_cyc_i && !wbs_we_i && !wbs_ack_o && wbs_adr_i[7:4] != 'h0 && (control_nBlocking || s_bytesReady[($clog2(FIFO_WORDS)+2)-1:2] != 'b000)) ? 1 : 0;

endmodule
