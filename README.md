# Apple III Custom ROM Project (B9 ROM)
This project builds custom ROMs for the Apple ///: for the main system ROM ("**B9 ROM**").

Currently, ROMs with the following functionality are available:

  * A custom ROM supporting bootstrapping volumes directly from the [DAN II Controller](https://github.com/ThorstenBr/Apple2Card) card. No more floppy disks required.

  * A custom ROM adding a disassembler to the Apple /// monitor. The Apple /// ROM inherited many routines from the Apple II, however, the disassemler had to be stripped, since Apple only installed a tiny 4KB ROM in the Apple ///. The machine does support 8KB ROMs though. So, if by installing a larger ROM, we have the necessary space to add the missing disassembler.

## Custom ROM Adapter
The Apple /// mainboard expects a ROM with the pinout of the "2532" ROM. However, using an adapter is possible to plug the more common 27c32/27c64 4KB/8KB EPROMs. The Apple /// chassis leaves extremely little clearance, however, so general purpose ROM adapters will not fit.

Here's my Apple ///-specific ROM adapter: [https://github.com/ThorstenBr/Apple_III_ROM_Adapter](https://github.com/ThorstenBr/Apple_III_ROM_Adapter). This PCB was designed to exactly fit into the restricted space inside the Apple ///. It works well with any standard 27c64 EPROMs, or 28c64 EEPROMs.

# Available ROMs
The [/bin](bin) folder contains the following ROM variants for the Apple ///:

* [A3ROM_ORIGINAL_4KB.bin](bin/A3ROM_ORIGINAL_4KB.bin): Original 4KB ROM for the Apple ///. In case you just want to replace a defective ROM with an original.

* [A3ROM_ORIGINAL_DISASS_8KB.bin](bin/A3ROM_ORIGINAL_EXTMONITOR_8KB.bin): 8KB ROM which contains the original (unmodified) Apple /// ROM in the default ROM bank (bank 1). The alternate ROM bank 0 contains an adapted ROM variant with improved "debug monitor" (currently adds a disassembler).

* [A3ROM_DANII_4KB.bin](bin/A3ROM_DANII_4KB.bin): Custom 4KB Apple /// ROM variant. Adapted to support direct bootstrapping of volumes from the [DAN II Controller](https://github.com/ThorstenBr/Apple2Card) card.

* [A3ROM_DANII_DISASS_8KB.bin](bin/A3ROM_DANII_EXTMONITOR_8KB.bin): Custom 8KB Apple /// ROM variant. Default ROM bank 1 contains the adapted ROM to support direct bootstrapping of volumes from the [DAN II Controller](https://github.com/ThorstenBr/Apple2Card) card. The alternate ROM bank 0 contains an adapted ROM variant with improved "debug monitor" (currently adds a disassembler).

# Using the Custom ROM Bank
The Apple /// has two ROM banks, each is 4KB. Apple /// were orignally only shipped with a 4KB ROM, which is mapped to ROM bank 1.
ROM bank 0 could be activated, but was empty (would show random data).

The ROM banks are switched through the Apple ///'s "system environment register" at $FFDF, bit 1 (value of 0x2). When you installed one of the 8KB ROM variants, you can activate the alternate ROM bank when using the monitor:

* **Press "OpenApple-Ctrl-RESET"** to enter the debug monitor (then release RESET, but keep the OpenApple-key pressed for a moment).

* Enter "FFDF:75" to enable ROM bank 0 (clears bit 1 = value 0x02).

    ![A3ROM Switch to bank 0](Images/A3ROM_bank0.jpg)

* Now the alternate ROM is active. If you programmed a ROM variant with extended debug monitor, you can use "L" for a debug **l**isting:

    ![A3ROM Disassembler](Images/A3ROM_disassembler.jpg)

* Enter "FFDF:77" to switch to default ROM bank 1 again (stock ROM, no extended debug monitor).