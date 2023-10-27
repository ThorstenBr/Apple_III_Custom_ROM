# Apple III Custom ROM Project (B9 ROM)
This project builds custom ROMs for the Apple ///: for the main system ROM ("**B9 ROM**").

Currently, ROMs with the following functionality are available:

  * A custom ROM supporting bootstrapping volumes directly from the [DAN II Controller](https://github.com/ThorstenBr/Apple2Card) card. No more floppy disks required.

  * A custom ROM adding a disassembler to the Apple /// monitor. The Apple /// ROM inherited many routines from the Apple II, however, the disassemler had to be stripped, since Apple only installed a tiny 4KB ROM in the Apple ///. The machine does support 8KB ROMs though. So, if by installing a larger ROM, we have the necessary space to add the missing disassembler.

## Custom ROM Adapter
The Apple /// mainboard expects a ROM with the pinout of the "2532" ROM. However, using an adapter is possible to plug the more common 27c32/27c64 4KB/8KB EPROMs. The Apple /// chassis leaves extremely little clearance, however, so general purpose ROM adapters will not fit.

Here's my Apple ///-specific ROM adapter: [https://github.com/ThorstenBr/Apple_III_ROM_Adapter](https://github.com/ThorstenBr/Apple_III_ROM_Adapter). This PCB was designed to exactly fit into the restricted space inside the Apple ///. It works well with any standard 27c64 EPROMs, or 28c64 EEPROMs.

