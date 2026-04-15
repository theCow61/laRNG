#include "csr.h"
#include "irq_vex.h"
#include "stub.h"
#include "defs.h"

__attribute__((weak)) void default_handler() {}

__attribute__((weak, alias("default_handler"))) void exception_handler();
// __attribute__((weak, alias("default_handler"))) void software_handler();
// __attribute__((weak, alias("default_handler"))) void timer_handler();
__attribute__((weak, alias("default_handler"))) void timer0_handler();
__attribute__((weak, alias("default_handler"))) void uart_handler();
__attribute__((weak, alias("default_handler"))) void user0_handler();
__attribute__((weak, alias("default_handler"))) void user1_handler();
__attribute__((weak, alias("default_handler"))) void user2_handler();
__attribute__((weak, alias("default_handler"))) void user3_handler();
__attribute__((weak, alias("default_handler"))) void user4_handler();
__attribute__((weak, alias("default_handler"))) void user5_handler();


#define INTERRUPT 0x80000000


__attribute__((weak, interrupt))
void irq_handler() {
  // This VexRiscv core does not support vectored interrupts, so 
  // this vectors the interrupts in software
  uint32_t cause = csrr(mcause);


  // Internal exception
  if (!(cause & INTERRUPT)) {
    exception_handler();
    while (1) continue;
  }

  // Supervisor mode is not supported in this VexRiscv core
  // if (cause == (INTERRUPT|3)) return software_handler();

  // mtime and mtimecmp are not supported in this VexRiscv core
  // if (cause == (INTERRUPT|7)) return timer_handler();

  // External Interrupts
  if (cause == (INTERRUPT|11)) {
    uint32_t pending = irq_pending();
    if (pending & 0x01) return timer0_handler();
    if (pending & 0x02) return uart_handler();
    if (pending & 0x04) return user0_handler();
    if (pending & 0x08) return user1_handler();
    if (pending & 0x10) return user2_handler();
    if (pending & 0x20) return user3_handler();
    if (pending & 0x40) return user4_handler();
    if (pending & 0x80) return user5_handler();
  }
}
