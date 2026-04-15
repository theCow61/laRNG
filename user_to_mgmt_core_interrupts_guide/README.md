

CSR registers to be aware of: `mtvec`,  `mie`, `mstatus`, and `0xbc0` (specific to the External Interrupt Array Plugin. this one was the smoking gun).

Look at how these were configured in the modified `crt0_vex.S` in the firmware folder. The
stack saving before calling `irq_handler` in `crt0_vex.S` may not actually be necessary though.

I assume this doesn't have to be setup in the `crt0_vex.S` and can be done later and in a more comfortable place (not inside the firmware folder)

`irq_handler` in `irqs.c` in the firmware folder
is marked with the weak interrupt, so
you can redefine the irq_handler somewhere else. You could also just redefine the user handlers (which are also week) and take advantage of the
existing `irq_handler` (which calls the user handlers).


user management area memory mapped registers have to
be dealt with as well.
Look at `laRNG_into.c`.

Look at `reg_mprj_irq`, `reg_user_irq_ena_out``, `reg_user_irq_0_ev_enable`, and `reg_user_irq_0_ev_pending`.


