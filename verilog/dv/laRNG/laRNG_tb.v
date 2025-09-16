// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

`ifdef GL
`include "../../gl/user_project_wrapper.v"
`else
`include "user_project_wrapper.v"
`include "vs/glbl.v"
`include "vs/LDPE.v"
`include "vs/LDCE.v"
`endif

module laRNG_tb;
	reg clock;
    reg RSTB;
	reg CSB;

	reg power1, power2;

	wire gpio;
	wire [37:0] mprj_io;

	assign uart_tx = mprj_io[6];

	always #12.5 clock <= (clock === 1'b0);

	always @(posedge gpio) $display("%t: GPIO ON", $realtime);
	always @(negedge gpio) $display("%t: GPIO OFF", $realtime);

	initial begin
		clock = 0;
	end


	// assign mprj_io[3] = 1'b1;

	initial begin
		$dumpfile("laRNGwInt.vcd");
		$dumpvars(0, laRNG_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (250) begin
			repeat (1000) @(posedge clock);
			$display("+1000 cycles");
		end
		$finish;
	end

	wire [3:0] status;

	assign status = mprj_io[35:32];

	/*initial begin
		wait (status == 4'h5);
		$display("Monitor: Test started");
		wait (status == 4'h7);
		$display("Monitor: Test ended");
		#1000 $finish;
	end*/

   initial begin
	   wait (gpio === 'b0 || gpio === 'b1);
	   if (gpio == 'b0) $display("Test failed");
	   else $display("Test success");
	   #100
   		$finish;
   end


	initial begin
		RSTB <= 1'b0;
		CSB <= 1'b1;
		#2000;
		RSTB <= 1'b1;	    	// Release reset
		#170000;
		CSB = 1'b0;
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD1V8;
	wire VDD3V3;
	wire VSS;
    
	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vddio_2  (VDD3V3),
		.vssio	  (VSS),
		.vssio_2  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda1_2  (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa1_2  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock    (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("laRNG.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

	tbuart tbuart (
		.ser_rx(uart_tx)
	);

endmodule
`default_nettype wire
