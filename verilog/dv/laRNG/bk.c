#include <defs.h>
#include <stub.h>

void configure_io() {
	
  reg_mprj_io_0 = GPIO_MODE_MGMT_STD_ANALOG;

  // Changing configuration for IO[1-4] will interfere with programming flash. if you change them,
  // You may need to hold reset while powering up the board and initiating flash to keep the process
  // configuring these IO from their default values.

  reg_mprj_io_1 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_2 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;
  reg_mprj_io_3 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;
  reg_mprj_io_4 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;

  // -------------------------------------------

  reg_mprj_io_5  = GPIO_MODE_MGMT_STD_INPUT_NOPULL; // UART Rx
  reg_mprj_io_6  = GPIO_MODE_MGMT_STD_OUTPUT;       // UART Tx
  reg_mprj_io_7  = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_8  = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_9  = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_10 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_11 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_12 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_13 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_14 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_15 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;

  reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_32 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_33 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_34 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_35 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_36 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_37 = GPIO_MODE_MGMT_STD_OUTPUT;

  // Initiate the serial transfer to configure IO
  reg_mprj_xfer = 1;
  while (reg_mprj_xfer == 1);
}

void main() {

	reg_wb_enable = 1;

	unsigned long cycs;
	asm volatile ("csrrs %0, cycle, x0" : "=r" (cycs));
	//uint32_t cycsH;
	unsigned long cycsH;
	asm volatile ("csrrs %0, mcycleh, x0" : "=r" (cycsH));
	// user clock and do det sequence sampling and see if diff
	configure_io();

	reg_gpio_mode1 = 1;
	reg_gpio_mode0 = 0;
	reg_gpio_ien = 1;
	reg_gpio_oe = 1;

	reg_uart_enable = 1;

	//reg_la0_oenb = reg_la0_iena = 0x00000000; // pin 1: enb, pin 0: result
	set_la_dir(0, false); // result
	set_la_dir(1, false); // check
	set_la_dir(2, true); // enb

	bool trngEnb = false;
	set_la_data(2, trngEnb);



	char sample[256];
	for (int i = 0; i < sizeof(sample); i++) {
		sample[i] = reg_la0_data_in & 0x1;
	}

	//unsigned long again;
	//asm volatile ("csrr %0, mstatus" : "=r" (again));
	//again = (again >> 11) & 3;

	unsigned long time;
	asm volatile ("csrr %0, time" : "=r" (time));

	char* pSample = sample;
	
	while(1) {
		while (reg_uart_rxempty) {}
		char entered = reg_uart_rxtx;
		if (entered == 'c') {
			//reg_la0_data ^= 0x1; // toggle clock
			reg_uart_rxtx = '0' + (reg_la0_data_in & 0x2);
		} else if (entered == 'y') {
			reg_gpio_out = 1;
		} else if (entered == 'n') {
			reg_gpio_out = 0;
		} else if (entered == 'r') {
			reg_uart_rxtx = '0' + (reg_la0_data_in & 0x1);
		} else if (entered == 's') {
			reg_uart_rxtx = '0' + *(pSample++);
		} else if (entered == 't') {
			//reg_uart_rxtx = '0' + ((cycs & 0xf0) >> 4);
			print_hex(time, 8);
			//reg_uart_rxtx = '0' + again;
		} else if (entered == 'o') {
			trngEnb ^= 1;
			set_la_data(2, trngEnb);
		} else if (entered == 'g') {
			while(1) {
				putchar('0' + (reg_la0_data_in & 0x1));
			}
		} else if (entered == 'w') {
			uint32_t bone_data = *((uint32_t *) 0x30000000);
			print_hex(bone_data, 8);
		} else {
			reg_uart_rxtx = entered;
		}
		reg_uart_ev_pending = 2;
	}



}
