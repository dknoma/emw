org $83EE00


db $53, $54, $41, $52				; Needed to stop Asar from treating this like an xkas patch.
dw SGEnd-SampleGroupPtrs-$01
dw SGEnd-SampleGroupPtrs-$01^$FFFF
SampleGroupPtrs:


dw $0000, SGPointer01, SGPointer02, SGPointer03, SGPointer04, SGPointer05, SGPointer06, SGPointer07, SGPointer08, SGPointer09, SGPointer0A, SGPointer0B, SGPointer0C, SGPointer0D, SGPointer0E, SGPointer0F
dw SGPointer10, SGPointer11, SGPointer12, SGPointer13, SGPointer14, SGPointer15, SGPointer16, SGPointer17, SGPointer18, SGPointer19, SGPointer1A, SGPointer1B, SGPointer1C, SGPointer1D, SGPointer1E, SGPointer1F
dw SGPointer20, SGPointer21, SGPointer22, SGPointer23, SGPointer24, SGPointer25, SGPointer26, SGPointer27, SGPointer28, SGPointer29, SGPointer2A, SGPointer2B, SGPointer2C, SGPointer2D, SGPointer2E, SGPointer2F
dw SGPointer30, SGPointer31, SGPointer32, SGPointer33, SGPointer34, SGPointer35, SGPointer36, SGPointer37, SGPointer38, SGPointer39, SGPointer3A, SGPointer3B, SGPointer3C, SGPointer3D, SGPointer3E, SGPointer3F
dw SGPointer40, SGPointer41, SGPointer42, SGPointer43, SGPointer44, SGPointer45, SGPointer46


SGPointer01:

SGPointer02:

SGPointer03:

SGPointer04:

SGPointer05:

SGPointer06:

SGPointer07:

SGPointer08:

SGPointer09:

SGPointer0A:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer0B:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer0C:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer0D:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $000F, $0010, $0011, $0012, $0013
SGPointer0E:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer0F:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer10:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer11:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer12:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer13:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer14:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer15:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer16:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $000F, $0010, $0014, $0012, $0013
SGPointer17:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer18:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer19:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $000F, $0010, $0014, $0012, $0013
SGPointer1A:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer1B:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer1C:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $000F, $0010, $0014, $0012, $0013
SGPointer1D:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer1E:
db $14
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028
SGPointer1F:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $000F, $0010, $0011, $0012, $0013
SGPointer20:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $000F, $0010, $0011, $0012, $0013
SGPointer21:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $000F, $0010, $0011, $0012, $0013
SGPointer22:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $000F, $0010, $0014, $0012, $0013
SGPointer23:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0011, $0012, $0013
SGPointer24:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0011, $0012, $0013
SGPointer25:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer26:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $000F, $0010, $0014, $0012, $0013
SGPointer27:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer28:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $000F, $0010, $0014, $0012, $0013
SGPointer29:
db $1D
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $002A, $002F, $0030, $0031, $0032, $0033, $0034, $0035, $0036
SGPointer2A:
db $21
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0037, $002A, $0033, $0034, $0038, $002B, $0035, $0039, $003A, $003B, $003C, $0014, $003E
SGPointer2B:
db $1F
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0014, $0040, $0041, $002A, $003E, $0029, $0034, $0042, $0037, $0043, $0044
SGPointer2C:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $000F, $0010, $0014, $0012, $0013
SGPointer2D:
db $20
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0045, $0033, $003E, $0034, $0046, $002B, $0047, $002E, $002A, $0037, $0041, $0014
SGPointer2E:
db $2D
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0048, $0014, $004A, $004B, $0014, $0014, $004E, $0014, $0014, $0014, $0014, $0053, $0054, $0014, $0014, $0056, $0014, $0014, $0014, $005A, $0014, $0014, $005D, $0014, $0014
SGPointer2F:
db $1D
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0045, $0033, $003E, $0034, $002A, $0047, $0042, $0039, $002B
SGPointer30:
db $40
dw $0015, $0016, $0017, $0018, $0019, $0014, $001B, $001C, $001D, $0014, $0060, $0020, $0021, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0061, $0062, $0063, $0064, $0065, $0066, $0067, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014
SGPointer31:
db $40
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $0063, $0060, $0020, $0068, $0061, $0023, $0014, $0025, $0069, $0027, $0028, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014
SGPointer32:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $0014, $0010, $0014, $0012, $0013
SGPointer33:
db $1C
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $002A, $006A, $003D, $0029, $0034, $0046, $0014, $002F
SGPointer34:
db $14
dw $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $0014, $000E, $000F, $0010, $0014, $0012, $0013
SGPointer35:
db $1D
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0033, $0014, $0014, $002A, $006B, $0014, $006D, $0014, $0014
SGPointer36:
db $1A
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0033, $002A, $002B, $002C, $002D, $002E
SGPointer37:
db $1D
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0045, $003A, $0033, $0032, $0034, $002A, $0030, $0047, $0042
SGPointer38:
db $1D
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $002A, $0033, $003D, $0034, $0035, $002F, $0030, $0040, $006E
SGPointer39:
db $1B
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0037, $006E, $0046, $002A, $0034, $003E, $0033
SGPointer3A:
db $19
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0037, $006E, $0046, $002A, $0034
SGPointer3B:
db $1A
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $003D, $0029, $0037, $006F, $0034, $006E
SGPointer3C:
db $1E
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $003D, $0033, $006D, $0070, $0037, $006E, $0046, $002A, $0034, $0040
SGPointer3D:
db $20
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $006E, $0037, $002A, $003D, $0033, $002C, $0034, $003C, $003B, $002B, $003A, $0071
SGPointer3E:
db $1B
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0022, $0023, $0014, $0025, $0014, $0027, $0028, $002A, $0033, $003D, $0034, $002F, $0072, $0041
SGPointer3F:
db $1F
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0014, $0038, $002A, $0033, $003D, $0034, $0037, $003F, $0039, $0045, $0074
SGPointer40:
db $1E
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0036, $0047, $002A, $0033, $003E, $0034, $0043, $0037, $0075, $0045
SGPointer41:
db $1F
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0042, $0048, $0035, $0040, $0014, $0038, $002A, $006E, $003E, $0029, $0034
SGPointer42:
db $21
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0035, $006E, $0076, $0040, $0043, $0077, $003E, $0029, $0034, $006D, $002A, $0030, $003A
SGPointer43:
db $21
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0078, $0079, $0044, $006E, $0077, $0076, $002A, $0043, $003E, $0029, $0034, $0037, $0030
SGPointer44:
db $22
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $002C, $0072, $006E, $0014, $0040, $002F, $002A, $0043, $003E, $0029, $0034, $0037, $0030, $0042
SGPointer45:
db $22
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $0045, $0033, $003E, $0034, $0046, $002B, $0047, $002E, $002A, $0037, $0041, $0014, $0040, $0043
SGPointer46:
db $21
dw $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D, $001E, $001F, $0020, $0021, $0014, $0023, $0014, $0025, $0014, $0027, $0028, $007B, $0042, $0035, $007C, $004F, $002A, $0043, $003E, $0029, $0034, $0030, $003B, $002B
SGEnd: