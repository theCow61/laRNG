#include <defs.h>
#include <stub.h>
#include <irq_vex.h>
//#include <irqs.c>

//volatile const uint32_t* ran_ran = (volatile uint32_t*) 0x33001000;
//volatile uint32_t* const ran_conf = (volatile uint32_t*) 0x33000100;
volatile const uint32_t* ran_ran = (volatile uint32_t*) 0x30133710;
volatile uint32_t* const ran_conf = (volatile uint32_t*) 0x30133700;
volatile uint32_t* const ran_request = (volatile uint32_t*) 0x30133704;
volatile const uint32_t* const ran_status  = (volatile uint32_t*) 0x30133708;
volatile uint32_t* const ran_int_clear  = (volatile uint32_t*) 0x3013370c;

/*volatile int donezy = 0;
void user0_handler() {
	donezy = 1;
}

void irq_handler() {
	donezy = 1;
}*/

static volatile int inter = 0;

//void user0_handler() {
void irq_handler() {
	*ran_int_clear = 1;
	reg_user_irq_0_ev_pending = 1;
	inter = 1;
}


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
  /**/
  reg_mprj_io_30 = GPIO_MODE_USER_STD_OUTPUT;
  reg_mprj_io_31 = GPIO_MODE_USER_STD_INPUT_NOPULL;
  /**/
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

	configure_io();

	inter = 0;

	/*uint32_t* bottomRam = (uint32_t*) 0;
	__asm__("li t4, 0x10000eb7\n\t");
	__asm__("sw t4, 16(zero)\n\t");
	__asm__("li t4, 0x80e70e91\n\t");
	__asm__("sw t4, 20(zero)\n\t");
	__asm__("li t4, 0xe\n\t");
	__asm__("sw t4, 24(zero)\n\t");*/


	reg_gpio_mode1 = 1;
	reg_gpio_mode0 = 0;
	reg_gpio_ien = 1;
	reg_gpio_oe = 1;

	reg_uart_enable = 1;

	reg_la0_oenb = reg_la0_iena = 0;
	reg_la1_oenb = reg_la1_iena = 0;
	reg_la2_oenb = reg_la2_iena = 0;
	reg_la3_oenb = reg_la3_iena = 0;
	//set_la_dir(0, false); // result
	//set_la_dir(1, false); // check */

	reg_mprj_irq = 1;
	reg_user_irq_ena_out = 1;
	reg_user_irq_0_ev_enable = 1;

	//asm volatile ("csrw mtvec, %0" :: "r"(0x10000004));
	//asm volatile ("csrr %0, mtvec" : "=r"(mtvec));

	reg_mprj_datah = 0x5;
	reg_mprj_datal = 0;

	bool trngEnb = false;

	//irq_setie(1);



	uint32_t trash[10] = { 0 };

	char sysMode = 0b1;
	char auxEnb = 0b10;
	char staleAllowed = 0b100;
	char notBlocking = 0b1000;
	*ran_conf = 0;
	*ran_int_clear = 1;
	*ran_conf = sysMode | auxEnb;
//	*ran_request = (1 << 31) | 0x1f;
	trash[0] = *ran_status;
	trash[1] = *ran_request;
	trash[2] = *ran_status;
	trash[3] = *ran_status;
	trash[4] = *ran_status;
	trash[5] = *ran_status;
	*ran_request = 0;
	//*ran_int_clear = 1;
	trash[6] = *ran_status;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[7] = *ran_ran;
	trash[8] = *ran_status;
	trash[9] = *ran_status;

	

	//reg_mprj_datah = 0x7;

	//test_fail();
//

	//*ran_conf = auxEnb;


	while (1) {
		while (reg_uart_rxempty) {}
		char entered = reg_uart_rxtx;
		if (entered == 'r') {
			for (int i = 0; i < 10; i++) {
				print_hex(trash[i], 8); }
			print_hex(inter, 8);
		}
		reg_uart_ev_pending = 2;
	}

	return;

}
