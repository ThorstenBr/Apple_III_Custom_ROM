# Calculate and patch checksum for Apple /// ROMs.
# Copyright 2023, Thorsten Brehm.
#
# Apple II(I) forever!
#
# The Apple III ROM calculates a simple XOR checksum over the entire ROM address range, expecting the result to be 0.
# It does exclude the address range FFC0-FFEF, however, since system registers (6522) are mapped to this range.

import sys

def readFile(FileName):
	with open(FileName, "rb") as f:
		Data = f.read()
	return Data

def writeFile(FileName, Data):
	with open(FileName, "wb") as f:
		f.write(bytes(Data))
	return Data

def calculateChecksum(Data):
	if len(Data) != 4096:
		raise RuntimeError("Invalid ROM size! Size must be 4K.")
	CkSum = 0x00
	for i in range(4096):
		if (i>=0xFC0)and(i<=0xFEF):
			# (F)FC0-(F)FEF is excluded from the checksum (ROM not visible in this area, since it's mapped to the 6522's registers)
			continue
		CkSum ^= Data[i]
	return CkSum

def patchROM(Data, Offset):
	CkSum = calculateChecksum(Data)
	Offset &= (4096-1)
	Data[Offset] = Data[Offset]^CkSum
	print("Patching ROM checksum at",hex(Offset),":", hex(Data[Offset]))
	return Data

def help():
	print("Utility to patch Apple /// ROMs.")
	print("Usage:")
	print("A)  python3 a3rompatch.py --patch <ROMFILE> <OFFSET>")
	print("     <ROMFILE>  - The binary image file with the Apple /// ROM binary.")
	print("     <OFFSET>   - Address within the ROM where to patch the checksum.")
	print("                  (An absolute address instead of an offset may be given.")
	print("                  Addressed are automatically masked and mapped into the")
	print("                  ROM area.)")
	print("")
	print("B)  python3 a3rompatch.py --4to8k <ROMFILE4K> <ROMFILE8K>")
	print("     <ROMFILE4K> - The 4KB input Apple /// ROM image.")
	print("     <ROMFILE8K> - The 8KB output Apple /// ROM image.")
	print("                  (The 8KB ROM is padded with 0xFF in the lower 4KB,")
	print("                  so this area remains unused. Only the upper 4KB are")
	print("                  normally used by the Apple ///.)")
	print("")
	print("Example:")
	print("  python3 a3rompatch.py --patch A3ROM.bin 0xF6E5")
	print("    (to patch A3ROM.bin with a checksum at offset 0x(F)6E5")

def main():
	if len(sys.argv)!=4:
		help()
	elif sys.argv[1] == "--patch":
		FileName = sys.argv[2]
		Offset   = int(sys.argv[3],16)
		Data     = bytearray(readFile(FileName))
		Data     = patchROM(Data, Offset)
		writeFile(FileName, Data)
	elif sys.argv[1] == "--4to8k":
		FileName4K = sys.argv[2]
		FileName8K = sys.argv[3]
		Data     = bytearray(readFile(FileName4K))
		FillBytes = b"\xff" * 4096
		print("Converting",FileName4K,"-->",FileName8K)
		writeFile(FileName8K, FillBytes+Data)
	else:
		help()
main()
