

# A True Random Number Generator ASIC

# Status: In Fabrication Stage


This TRNG peripheral can be used as a memory mapped peripheral with the [VexRiscv](https://github.com/spinalhdl/vexriscv) management core or can be used as an SPI slave device. 

There are two entropy sources available in this peripheral: the intended primary metastable state latch array (layed out in analog space), and an FPGA friendly dual-latch array. The primary entropy source had to be layed out in analog space to make the paths within the latch unbiased. This doesn't exactly translate
to an FPGA, so a different latch based entropy source was added which is suppose to be FPGA friendly where the presets and resets of two latches are intertwined. The FPGA friendly entropy source was helpful for prototyping the design as a whole.

Interrupts to the management core are supported as well as blocking and non blocking operation.

# Register Map

Base address of 0x30133700

## Control Register (Offset = `0x00`)

| Bit | Field | Access | Initial | Description |
| :--- | :--- | :--- | :--- | :--- |
| 31 - 6 | Reserved | R | 0 | |
| 5 | Reserved | RW | 0 | |
| 4 | AllowDual | RW | 0 | 1: Generated random bit is outputted over an IO pin even if Mode isn't configured for SPI mode. **Highly Unrecommended**. <br>0: Generated random bit is only outputted over an IO pin when in SPI mode |
| 3 | NotBlocking | RW | 0 | 1: Memory read of data doesn't stall even if there isn't a full word of random. <br>0: Memory bus stalls on data read until a word of random is available from FIFO. |
| 2 | StaleAllowed | RW | 0 | 1: When Enabled is set to low, the FIFO retains its state. <br>0: Random bits generated from when Enable was last high are only considered. |
| 1 | AuxEnb | RW | 0 | 1: Auxiliary entropy source is enabled and combined with with primary entropy source. <br>0: Random generated bits come primarily from the primary entropy source. |
| 0 | Mode | RW | 0 | 1: System peripheral mode where interaction of peripheral is done on chip with managment core. The FIFO is also enabled. <br>0: SPI slave mode where a new random bit is generated and outputted over an IO pin on the positive edge of master clock. Data pin should be sampled on the negative edge of master clock. |

## Request Register (Offset = `0x04`)

| Bit | Field | Access | Initial | Description |
| :--- | :--- | :--- | :--- | :--- |
| 31 | AsyncRequest | RW |  | Interrupt is triggered if BytesRequested amount of random bytes are available. Interrupt needs to be cleared via the Interrupt Clear Register for another interrupt to fire. | 
| 30 - 5 | Reserved | RW |  | |
| 4 - 0| BytesRequested | RW |  | Amount of random bytes to trigger an interrupt if AsyncRequested is high. |

## Random Bytes Ready Register (Offset = `0x08`)

| Bit | Field | Access | Initial | Description |
| :--- | :--- | :--- | :--- | :--- |
| 31 | InterruptStatus | R | 0 | High represents an active interrupt that has not yet been cleared. | 
| 30 - 5 | Reserved | R | 0 | |
| 4 - 0 | BytesReady | R | 0 | The amount of random bytes available. |

## Interrupt Clear Register (Offset = `0x0c`)

| Bit | Field | Access | Initial | Description |
| :--- | :--- | :--- | :--- | :--- |
| 31 - 1 | Reserved |  |  | | 
| 0 | InterruptClear | W |  | Clear an active interrupt. Must be done for another interrupt to trigger. |

# Primary Entropy Source Analog

It was important to have the NAND gates that make up these latches be layed out in such a way where everything is symmetrical. For a single latch unit, one NAND gate is in a flipped orientation relative to the other NAND gate. This allows us to have symmetric and equal connections between the NAND gates. A buffer is used on
the output of the SR latch and a dummy buffer (and a dummy pad on it) is used on the inverted output of the latch to keep things balanced. Because the NAND gates are in opposite orientations form each other, the power and wells don't neatly just line up. We connect multiple latch units in an alternating fashion and use a well cell to basically staple
each latch together. A NAND gate from one latch shares a well cell with the NAND gate of the neighboring latch. The buffers have half well cell runnning horizontally connecting them.

<img width="2555" height="1030" src="https://github.com/user-attachments/assets/23c748d0-a1e3-48d7-a283-b45eb277b154" />


<img width="2553" height="1385" src="https://github.com/user-attachments/assets/5370394a-1adf-40a5-8dd9-c35e5fda98a5" />


<img width="1699" height="1183" src="https://github.com/user-attachments/assets/1c15fc5d-f924-4286-bdaa-24dc355d8351" />
