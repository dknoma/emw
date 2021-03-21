header
sa1rom

; done:
; - make DAMN sure no score sprites can write anything anywhere
; - reprogram engines to subtract their offset value
; - look at all the reads and make sure number comparisons are correct
; - reprogram bounce sprites a bit to fit 2 extra tables, and to add their offset (gotta hijack to do that)
; - lots and lots of bug testing

incsrc "../Defines.asm"

; list:
;	00 -- EMPTY --
;	01 coin
;
;	02 -- about to clear --
;	03 brick piece
;	04 small star (glitter?)
;	05 egg piece
;	06 fire particle
;	07 small blue sparkle (invincibility sparkle)
;	08 Z
;	09 water splash
;	0A -- UNUSED --
;	0B -- UNUSED --
;	0C boo stream tile
;	0D -- UNUSED --
;
;	0E -- about to clear --
;	0F puff of smoke
;	10 reznor fireball
;	11 tiny flame
;	12 hammer
;	13 mario fireball
;	14 bone
;	15 lava splash
;	16 torpedo ted arm
;	17 malleable extended sprite
;	18 coin from coin cloud
;	19 piranha fireball
;	1A volcano lotus fire
;	1B baseball
;	1C wiggler flower
;	1D trail of smoke
;	1E spin jump stars
;	1F yoshi fireball
;	20 water bubble
;
;	21 -- about to clear --
;	22 puff of smoke
;	23 contact
;	24 turn smoke
;	25 -- UNUSED --
;	26 glitter
;
;	27 -- about to clear --
;	28 still turn block
;	29 note block
;	2A question block
;	2B side bounce block
;	2C another bounce sprite
;	2D another bounce sprite
;	2E another bounce sprite
;
;	2F -- about to clear --
;	30 block hitbox
;	31 yellow yoshi landing hitbox
;
;	32 -- about to clear --
;	33 bullet bill shooter
;	34 torpedo ted launcher
;
;	35 -- about to clear --
;	36+ custom


	org $028B05		;\ remove minor extended call
	NOP #3			;/
	org $029040		;\ remove bounce call
	NOP #3			;/
	org $029043		;\ remove quake call
	NOP #3			;/
	org $029046		;\ remove smoke call
	NOP #3			;/
	org $028B11		;\ remove coin call
	NOP #3			;/
	org $028B14		;\ remove shooter call
	NOP #3			;/
	org $029B0A		;\
	JSL HandleEx		; | expand extended to include all types
	RTS			;/


	; kill score sprites
	org $00F388
		RTL		; prevent score sprite spawn
		NOP
		RTL		; RTL second entry point as well
	BubbleOffsetY:		; use this extra space to map extra bubble coordinates
		db $10,$16,$13,$1C
		db $10,$16,$13,$1C
	BubbleOffsetX:
		db $00,$04,$0A,$07
		db $08,$03,$02,$02
	org $00FE26+1
		dw BubbleOffsetY
	org $00FE35+1
		dw BubbleOffsetX

	org $028B0B
		BRA $01 : NOP	; prevent score sprite call
	org $029AA8
		BRA $2A		;\ prevent coin from becoming a score sprite
		NOP #$2A	;/
	org $02A43D
		RTS		;\ don't spawn score sprite
		NOP #3		;/
	org $02ACE5		;\ don't spawn score sprite
		RTL		;/ (main call)
	org $02ACEF
		RTL		; don't spawn score sprite
	org $02AD34
		RTL		; don't search score sprite table
	org $02ADA4
		RTS		; remove score sprite engine
	org $02FF6C
		RTS		; don't spawn score sprite





	org $148000
	HandleEx:

		LDX #!Ex_Amount-1		; full index
		LDA $64 : PHA			; preserve this

	.Loop	STX $75E9			; store index
		STX $7698			; store index
		PHX				; just in case

		LDA !DizzyEffect : BEQ +
		REP #$20
		LDA !CameraBackupY : STA $1C
		SEP #$20
		LDA !Ex_XHi,x : XBA
		LDA !Ex_XLo,x
		REP #$20
		SEC : SBC $1A
		AND #$00FF
		LSR #3
		ASL A
		PHX
		TAX
		LDA $40A040,x
		AND #$01FF
		CMP #$0100
		BCC $03 : ORA #$FE00
		STA $1C
		PLX
		SEP #$20
		+

		LDA !Ex_Num,x
		AND #$7F : BEQ .Clear

		PHA
		TAX
		LDA.l .PalsetIndex,x : BMI .PalsetDone	; if index is negative, keep the current one
		STA $0F
		LDA.l !LoadPalset : STA $00
		LDA.l !LoadPalset+1 : STA $01
		LDA.l !LoadPalset+2 : STA $02
		LDA $0F
		PHK : PEA.w .PalsetReturn-1
		JML [$3000]
		.PalsetReturn
		LDX $0F
		LDA !GFX_status+$180,x
		ASL A
		LDX $75E9
	; this will sometimes store 0xFF!
		STA !Ex_Palset,x

		.PalsetDone
		LDX $75E9
		LDA $64
		AND #$F0
		ORA !Ex_Palset,x
		STA $64

		PLA
		CMP #!MinorOffset : BEQ .Clear
		CMP #!ExtendedOffset : BEQ .Clear
		CMP #!SmokeOffset : BEQ .Clear
		CMP #!BounceOffset : BEQ .Clear
		CMP #!QuakeOffset : BEQ .Clear
		CMP #!ShooterOffset : BEQ .Clear
		CMP #!CustomOffset : BNE .GetNum

	.Clear
		STZ !Ex_Num,x
		STZ !Ex_Data1,x
		STZ !Ex_Data2,x
		STZ !Ex_Data3,x
		STZ !Ex_XLo,x
		STZ !Ex_XHi,x
		STZ !Ex_YLo,x
		STZ !Ex_YHi,x
		STZ !Ex_XSpeed,x
		STZ !Ex_YSpeed,x
		STZ !Ex_XFraction,x
		STZ !Ex_YFraction,x
		LDA #$FF : STA !Ex_Palset,x

	.Return
		PLX				; restore X
		DEX : BMI $03 : JMP .Loop

		PHP
		REP #$20
		LDA !DizzyEffect
		AND #$00FF : BEQ +
		LDA !CameraBackupY : STA $1C
	+	PLP
		PLA : STA $64			; restore this
		RTL

	.GetNum
		CMP #$01 : BEQ .Coin
		CMP #$0C+!MinorOffset : BCC .MinorExtended
		CMP #$13+!ExtendedOffset : BCC .Extended
		CMP #$06+!SmokeOffset : BCC .Smoke
		CMP #$08+!BounceOffset : BCC .Bounce
		CMP #$03+!QuakeOffset : BCC .Quake
		CMP #$02+!ShooterOffset : BCC .Shooter
		CMP.b #((.CustomPtr_End-.CustomPtr)/2)+!CustomOffset+1 : BCC .Custom
		BRA .Clear			; invalid numbers should be cleared

	.Coin
		PHK : PEA .Return-1		; RTL address = .Return
		PEA $8B66-1			; RTS address = $8B66 (points to an RTL)
		JML $0299F1			; process coin

	.MinorExtended
		SEC : SBC #!MinorOffset		; subtract offset
		PHK : PEA .Return-1		; RTL address = .Return
		PEA $8B66-1			; RTS address = $8B66 (points to an RTL)
		JML $028B94			; execute minor extended pointer

	.Extended
		SEC : SBC #!ExtendedOffset	; subtract offset
		PHK : PEA .Return-1		; RTL address = .Return
		PEA $8B66-1			; RTS address = $8B66 (points to an RTL)
		JML $029B1B			; execute extended pointer

	.Smoke
		SEC : SBC #!SmokeOffset		; subtract offset
		PHK : PEA .Return-1		; RTL address = .Return
		PEA $8B66-1			; RTS address = $8B66 (points to an RTL)
		JML $0296C7			; execute smoke pointer

	.Bounce
		SEC : SBC #!BounceOffset	; subtract offset
		PHK : PEA .Return-1		; RTL address = .Return
		PEA $8B66-1			; RTS address = $8B66 (points to an RTL)
		JML $029052			; execute bounce pointer

	.Quake
		PHK : PEA .Return-1		; RTL address = .Return
		PEA $8B66-1			; RTS address = $8B66 (points to an RTL)
		JML $02939D			; process quake

	.Shooter
		LDY !Ex_Data1,x : BEQ +		;\
		PHA				; |
		LDA $13				; | decrement shooter timer every other frame
		LSR A : BCC ++			; |
		DEC !Ex_Data1,x			; |
	++	PLA				;/
	+	SEC : SBC #!ShooterOffset	; subtract offset
		PHK : PEA .Return-1		; RTL address = .Return
		PEA $8B66-1			; RTS address = $8B66 (points to an RTL)
		JML $02B3AB			; process shooter

	.Custom
		SEC : SBC #!CustomOffset+1
		PEA .Return-1
		ASL A
		TAX
		JMP (.CustomPtr,x)

		.CustomPtr
		dw DizzyStar
		dw LuigiFireball
		dw BigFireball
		..End


	.PalsetIndex
		db $FF	; 00 - empty
		db $0A	; 01 - coin, yellow

		db $FF	; 02 - empty
		db $0A	; 03 - brick piece, yellow
		db $0B	; 04 - small star, blue
		db $FF	; 05 - unused
		db $0C	; 06 - fire particle, red
		db $0B	; 07 - blue sparkle, blue
		db $0B	; 08 - Z, blue
		db $0B	; 09 - water splash, blue
		db $FF	; 0A - unused
		db $FF	; 0B - unused
		db $0F	; 0C - boo stream, ghost
		db $FF	; 0D - unused

		db $FF	; 0E - empty
		db $0A	; 0F - smoke puff, yellow
		db $0A	; 10 - enemy fireball, yellow (for big/reznor version, use custom 35)
		db $0A	; 11 - tiny flame, yellow
		db $0B	; 12 - hammer, blue
		db $0A	; 13 - mario fireball, yellow
		db $0E	; 14 - bone, grey
		db $0C	; 15 - lava splash, red
		db $0E	; 16 - torpedo ted arm, grey
		db $FF	; 17 - malleable extended sprite, should be set at spawn!
		db $0A	; 18 - coin from coin cloud, yellow
		db $0A	; 19 - piranha fireball, yellow
		db $0C	; 1A - volcano lotus fire
		db $0C	; 1B - baseball, red
		db $0D	; 1C - wiggler's flower, green
		db $0A	; 1D - puff of smoke, yellow
		db $0A	; 1E - spin jump star, yellow
		db $0C	; 1F - yoshi fireball, red
		db $0B	; 20 - water bubble, blue

		db $FF	; 21 - empty
		db $0A	; 22 - puff of smoke, yellow
		db $0A	; 23 - contact, yellow
		db $0A	; 24 - turn smoke, yellow
		db $FF	; 25 - unused
		db $0A	; 26 - glitter, yellow

		db $FF	; 27 - empty
		db $0A	; 28 - still turn block, yellow
		db $0A	; 29 - note block, yellow
		db $0A	; 2A - question block, yellow
		db $0A	; 2B - side bounce block, yellow
		db $0A	; 2C - unknown bounce sprite, yellow
		db $0A	; 2D - unknown bounce sprite, yellow
		db $0A	; 2E - unknown bounce sprite, yellow

		db $FF	; 2F - empty
		db $FF	; 30 - block hitbox
		db $FF	; 31 - yellow yoshi landing hitbox

		db $FF	; 32 - empty
		db $FF	; 33 - bullet bill shooter
		db $FF	; 34 - torpedo ted launcher

		db $FF	; 35 - empty
		db $0A	; 36 - dizzy star, yellow
		db $01	; 37 - luigi fireball, luigi palset
		db $0A	; 38 - big fireball, yellow
		..End


	BounceNumCalc:
		CLC : ADC #!BounceOffset+1	; we're overwriting an INC A, so we need to add +1 here
		STA !Ex_Num,y
		RTL

	BounceSetInit:
		ORA #$80 : STA !Ex_Num,x	; set init flag
		PEA $9085-1			; RTS address: $9085
		JML $0291B8			; execute invisible solid block routine

	BounceSetInit2:
		BMI .Main

		.Init
		ORA #$80 : STA !Ex_Num,x	; set init flag
		JML $0290ED			; return

		.Main
		JML $02910B			; return

	BounceRemapTile:
		AND #$7F
		TAX
		LDA $91F0-!BounceOffset,x
		RTL

	BounceCheck07:
		LDA !Ex_Num,x
		AND #$7F
		CMP #$07+!BounceOffset
		RTL

	BounceCheck06:
		PHA
		LDA !Ex_Num,x
		AND #$7F
		TAY
		PLA
		CPY #$06+!BounceOffset
		RTL


	FixSparkleOffset:
	.Init	REP #$20
		AND #$00FF
		CMP #$0080
		BCC $03 : ORA #$00FF
		CLC : ADC $96
		STA $00
		LDA $748E
		AND #$000F
		SEC : SBC #$0002
		CLC : ADC $94
		STA $02
		SEP #$20
		RTL

	.Main	STA !Ex_Data1,y
		LDA $01 : STA !Ex_YHi,y
		LDA $03 : STA !Ex_XHi,y
		RTL

	GlitterSparkleFix:
	.Init	LDA !Ex_XHi,x : STA $01
		LDA !Ex_YLo,x : STA $02
		LDA !Ex_YHi,x : STA $03
		RTL

	.Main	REP #$20
		LDA $98C2,x
		AND #$00FF
		CMP #$0080
		BCC $03 : ORA #$FF00
		CLC : ADC $00
		SEP #$20
		STA !Ex_XLo,y
		XBA : STA !Ex_XHi,y
		REP #$20
		LDA $98C6,x
		AND #$00FF
		CMP #$0080
		BCC $03 : ORA #$FF00
		CLC : ADC $02
		SEP #$20
		STA !Ex_YLo,y
		XBA : STA !Ex_YHi,y
		RTL

	ZSpawnFix:
		STA !Ex_YLo,y
		LDA $3240,x : STA !Ex_YHi,y
		LDA $3250,x
		ADC #$00				; hi bit still in carry so this is fine
		STA !Ex_XHi,y
		RTL

	SmokeSpawn:
		.SpritePlus0001
		PEI ($0E)
		STA !Ex_Num,y
		LDA $3220,x : STA $0E
		LDA $3250,x : STA $0F
		REP #$20
		LDA $00
		AND #$00FF
		CMP #$0080
		BCC $03 : ORA #$FF00
		CLC : ADC $0E
		SEP #$20
		STA !Ex_XLo,y
		XBA : STA !Ex_XHi,y
		LDA $3210,x : STA $0E
		LDA $3240,x : STA $0F
		REP #$20
		LDA $01
		AND #$00FF
		CMP #$0080
		BCC $03 : ORA #$FF00
		CLC : ADC $0E
		SEP #$20
		STA !Ex_YLo,y
		XBA : STA !Ex_YHi,y
		REP #$20
		PLA : STA $0E
		SEP #$20
		JMP .Finish

		.Block
		STA !Ex_Num,y
		LDA $7933 : BNE ..layer2
		..layer1
		LDA $9A
		AND #$F0
		STA !Ex_XLo,y
		LDA $9B : STA !Ex_XHi,y
		LDA $98
		AND #$F0
		STA !Ex_YLo,y
		LDA $99 : STA !Ex_YHi,y
		JMP .Finish
		..layer2
		REP #$20
		LDA $9A
		SEC : SBC $26
		SEP #$20
		STA !Ex_XLo,y
		XBA : STA !Ex_XHi,y
		REP #$20
		LDA $98
		SEC : SBC $28
		SEP #$20
		STA !Ex_YLo,y
		XBA : STA !Ex_YHi,y
		JMP .Finish

		.Sprite
		STA !Ex_Num,y
		LDA $3220,x : STA !Ex_XLo,y
		LDA $3250,x : STA !Ex_XHi,y
		LDA $3210,x : STA !Ex_YLo,y
		LDA $3240,x : STA !Ex_YHi,y
		BRA .Finish

		.Mario8
		STA !Ex_Num,y
		REP #$20
		LDA $94
		CLC : ADC #$0004
		SEP #$20
		STA !Ex_XLo,y
		XBA : STA !Ex_XHi,y
		REP #$20
		LDA $96
		CLC : ADC #$001A
		SEP #$20
		STA !Ex_YLo,y
		XBA : STA !Ex_YHi,y
		BRA .Finish

		.Mario16
		STA !Ex_Num,y
		LDA $94 : STA !Ex_XLo,y
		LDA $95 : STA !Ex_XHi,y
		REP #$20
		LDA $96
		CLC : ADC #$0014
		SEP #$20
		STA !Ex_YLo,y
		XBA : STA !Ex_YHi,y
		BRA .Finish

		.MarioSpecial
		STA !Ex_Num,y
		LDA $94 : STA !Ex_XLo,y
		LDA $95 : STA !Ex_XHi,y
		REP #$20
		LDA $96
		CLC : ADC #$0008
		SEP #$20
		STA !Ex_YLo,y
		XBA : STA !Ex_YHi,y

		.Finish
		LDA !Ex_Num,y
		AND #$7F
		SEC : SBC.b #!SmokeOffset
		PHX
		TAX
		LDA.l .Timer,x : STA !Ex_Data1,y
		PLX
		RTL

		.Timer
		;   00  01  02  03  04  05
		db $00,$1B,$08,$13,$00,$10

		.SpriteX
		PHX
		PHY
		PHX
		PHY
		PLX
		PLY
		JSL .Sprite
		PLY
		PLX
		RTL


	TransformCoordinates:
		LDA !Ex_XLo,x
		SBC $26					; small optimization, carry already set
		STA !Ex_XLo,x
		LDA !Ex_XHi,x
		SBC $27
		STA !Ex_XHi,x
		LDA !Ex_YLo,x
		SEC : SBC $28
		STA !Ex_YLo,x
		LDA !Ex_YHi,x
		SBC $29
		STA !Ex_YHi,x
		RTL


	; data 1: --ppssss
	; pp	= which player to attach to
	; ssss	= which sprite to attach to if pp = 0
	;
	; data 2: timer
	; data 3: y offset to attachment

	DizzyStar:
		LDX $75E9
		LDA !Ex_Data2,x : BNE .Go
	.Kill	STZ !Ex_Num,x
		RTS

	.Go	LDA $14
		AND #$03 : BNE +
		DEC !Ex_Data2,x
		+

		LDA !Ex_Data1,x
		CMP #$10 : BCC .Sprite
		CMP #$30 : BCS .Sprite

	.Player
		ASL #2
		AND #$80
		TAY
		LDA !P2Status-$80,y : BNE .Kill
		LDA !P2XPosLo-$80,y : STA !Ex_XLo,x
		LDA !P2XPosHi-$80,y : STA !Ex_XHi,x
		STZ $00
		LDA !Ex_Data3,x
		BPL $02 : DEC $00
		CLC : ADC !P2YPosLo-$80,y
		STA !Ex_YLo,x
		LDA $00
		ADC !P2YPosHi-$80,y
		STA !Ex_YHi,x
		BRA .Graphics

	.Sprite
		AND #$0F
		TAY
		LDA $3230,y : BEQ .Kill
		LDA $3220,y : STA !Ex_XLo,x
		LDA $3250,y : STA !Ex_XHi,x
		STZ $00
		LDA !Ex_Data3,x
		BPL $02 : DEC $00
		CLC : ADC $3210,y
		STA !Ex_YLo,x
		LDA $00
		ADC $3240,y
		STA !Ex_YHi,x

	.Graphics
		REP #$20
		STZ $0C
		JSR .Draw
		LDA #$0155 : STA $0C
		JSR .Draw
		LDA #$02AA : STA $0C
		JSR .Draw
		SEP #$30
		RTS


		.Draw
		LDA !Ex_XLo,x : STA $00
		LDA !Ex_XHi,x : STA $01
		LDA !Ex_YLo,x : STA $02
		LDA !Ex_YHi,x : STA $03
		REP #$20
		STZ $0E
		LDA $14
		LDY !Ex_Data2,x
		CPY #$40 : BCC +
		ASL A
	+	CPY #$20 : BCC +
		ASL A
	+	AND #$00FF
		ASL #2
		CLC : ADC $0C
		AND #$03FF
		STA $04				; angle
		CMP #$0200
		BCC $02 : DEC $0E
		AND #$01FE
		REP #$10
		TAX
		LDA.l !TrigTable,x
		EOR $0E
		BPL $01 : INC A
		CLC : ADC #$0100
		LSR #4
		CLC : ADC $00
		SEC : SBC #$000C
		SEC : SBC $1A
		STA $00
		CMP #$FFF8 : BCS .GoodX
		CMP #$0100 : BCC .GoodX
	.BadCoord
		SEP #$10
		REP #$20
		LDX $75E9
		RTS

	.GoodX	LDA $02
		SEC : SBC $1C
		CMP #$FFF8 : BCS .GoodY
		CMP #$00E0 : BCS .BadCoord

	.GoodY	SEP #$10
		LDY $05
		CPY #$01 : BEQ .HiPrio
		CPY #$02 : BEQ .HiPrio

	.LoPrio
		STA $02
		LDY #$FC
	-	LDA !OAM+$101,y
		AND #$00FF
		CMP #$00F0 : BEQ +
		DEY #4
		CPY #$FC : BCC -
		LDX $75E9
		RTS

	+	LDA $02 : STA !OAM+$101,y
		LDA #$3448 : STA !OAM+$102,y
		SEP #$30
		LDA $00 : STA !OAM+$100,y
		LDX $75E9
		TYA
		LSR #2
		TAY
		LDA $01
		AND #$01
		STA !OAMhi+$40,y
		REP #$20
		RTS

	.HiPrio
		LDY !OAMindex
		STA !OAM+$001,y
		LDA #$3448 : STA !OAM+$002,y
		SEP #$20
		LDA $00 : STA !OAM+$000,y
		LDX $75E9
		PHY
		TYA
		LSR #2
		TAY
		LDA $01
		AND #$01
		STA !OAMhi+$00,y
		PLA
		CLC : ADC #$04
		STA !OAMindex
		REP #$20
		RTS


	LuigiFireball:
		LDX $75E9

		LDA !Ex_YLo,x : PHA
		LDA !Ex_YHi,x : PHA
		STZ !Ex_YSpeed,x

		PHK : PEA.w .Return-1
		PEA $8B66-1			; point to RTL
		JML $029FAF

		.Return
		PLA : STA !Ex_YHi,x
		PLA : STA !Ex_YLo,x
		RTS

	BigFireball:
		LDX $75E9
		PHK : PEA.w .Return-1
		PEA $8B66-1
		JML $02A16B			; enemy fireball code
		.Return
		RTS


;
; input:
;	JSL followed by table, returns to first byte after table
; table format:
;	header (number of per-tile bytes to read, highest bit is p (0 = use $64, 1 = use PP bits))
;	GFX status index
;	for each tile:
;		Xdisp
;		Ydisp
;		tile
;		YXPP--s-
;	YX bits are written directly
;	PP bits are written directly if p is set, otherwise $64 is used
;	s is used as size bit
;
; $00 - 16-bit	Xpos
; $02 - 16-bit	Ypos
; $04 - 24-bit	pointer
; $07 - 8-bit	----
; $08 - 8-bit	p flag
; $0A -	16-bit	index to stop reading at
; $0C - 8-bit	tile offset from GFX status
; $0D - 8-bit	hi bit of tile number from GFX status
; $0E - 16-bit	working Xpos

	DisplayGFX:
		REP #$20				;\
		LDA $01,s				; |
		INC A					; | pointer to first byte after JSL instruction
		STA $04					; |
		SEP #$20				; |
		LDA $03,s : STA $06			;/
		REP #$20				;\
		LDA [$04]				; |
		AND #$007F				; |
		STA $0A					; > save header in RAM
		INC #2					; |
		CLC : ADC $01,s				; > update return address
		STA $01,s				;/
		LDA [$04]				;\
		AND #$0080				; | p flag
		STA $08					;/
		INC $04					;\
		LDA [$04]				; |
		INC $04					; | read GFX status index and increment past header bytes
		SEP #$20				; | (now ready to read per-tile data)
		STA $0F					;/

		PHX					; > push X
		LDA !Ex_XLo,x : STA $00			;\
		LDA !Ex_XHi,x : STA $01			; | base coordinates
		LDA !Ex_YLo,x : STA $02			; |
		LDA !Ex_YHi,x : STA $03			;/
		LDA !Ex_Palset,x			;\
		AND #$0E				; | CCC bits
		STA $0D					;/
		BIT $08 : BMI .Skip64			; p bit
	.Set64	LDA $64					;\
		AND #$30				; | add PP bits from $64
		TSB $0D					;/
	.Skip64	LDX $0F					;\
		CPX #$FF : BNE +			; | (0xFF means offset 0)
		STZ $0C					; |
		BRA ++					; |
	+	LDA !GFX_status,x : STA $0F		; |
		AND #$70				; |
		ASL A					; |
		STA $0C					; | unpack GFX offset
		LDA $0F					; |
		AND #$0F				; |
		TSB $0C					; |
		LDA $0F					; |
		BPL $02 : INC $0D			; |
		++					;/


		REP #$30
		LDA.l !OAMindex_p3 : TAX		; X = OAM index
		LDY #$0000				; Y = per-tile data
		LDA $00
		SEC : SBC $1A
		STA $00
		CMP #$0110 : BCC +
		CMP #$FFE0 : BCC .Despawn
	+	LDA $02
		SEC : SBC $1C
		STA $02
		CMP #$00F0 : BCC .Loop
		CMP #$FFE0 : BCS .Loop

	.Despawn
		SEP #$30
		PLX
		STZ !Ex_Num,x
		STZ $00
		RTL

	.BadX	INY					;\
	.BadY	INY #3					; | off-screen: go to next tile
		SEP #$20				; |
		JMP .Next				;/

	.Loop	REP #$20				; A 16-bit
		LDA [$04],y				;\
		AND #$00FF				; |
		CMP #$0080				; |
		BCC $03 : ORA #$FF00			; | check X
		CLC : ADC $00				; |
		CMP #$0100 : BCC .GoodX			; |
		CMP #$FFF0 : BCC .BadX			;/

	.GoodX	AND #$01FF				;\ store 9-bit X in scratch RAM
		STA $0E					;/
		INY					;\
		LDA [$04],y				; |
		AND #$00FF				; |
		CMP #$0080				; | check Y
		BCC $03 : ORA #$FF00			; |
		CLC : ADC $02				; |
		CMP #$00E0 : BCC .GoodY			; |
		CMP #$FFF0 : BCC .BadY			;/
	.GoodY	STA.l !OAM_p3+$001,x			; store Y
		SEP #$20				; A 8-bit
		LDA $0E : STA.l !OAM_p3+$000,x		; store X lo
		INY					;\
		LDA [$04],y				; | store tile number
		CLC : ADC $0C				; |
		STA.l !OAM_p3+$002,x			;/
		INY					;\
		LDA [$04],y				; |
		BIT $08 : BPL .64			; |
	.PP	AND #$F0 : BRA .Prop			; | store YXPPCCCT
	.64	AND #$C0				; |
		ORA $64					; |
	.Prop	ORA $0D					; |
		STA.l !OAM_p3+$003,x			;/
		PHX					;\
		REP #$20				; |
		TXA					; |
		LSR #2					; |
		TAX					; |
		SEP #$20				; | store hi byte
		LDA [$04],y				; |
		AND #$02				; |
		ORA $0F					; |
		STA.l !OAMhi_p3+$00,x			; |
		PLX					; |
		INY					;/
		INX #4					; increment OAM index
	.Next	CPY $0A : BCS $03 : JMP .Loop		; loop

		REP #$20
		STZ $00					;\
		TXA					; |
		SEC : SBC.l !OAMindex_p3		; | return $00 = number of tiles written
		LSR #2					; |
		STA $00					;/
		TXA : STA.l !OAMindex_p3		; update OAM index
		SEP #$30
		PLX					; pull X
		RTL					; return


	HammerSpinJump:
		JSL !CheckContact
		BCS .Contact
		JML $02A468				; > return with no contact
.Contact	LDA !Ex_Num,x
		CMP #$04+!ExtendedOffset : BNE .NoHammer
		LDA !Ex_Data3,x
		LSR A : BCS .Return
		LDA !MarioSpinJump : BNE .SpinHammer
		BRA .NoHammer

.SpinHammer	JSL !BouncePlayer
		JSL !ContactGFX
		LDA #$02 : STA !SPC1
		LDA #$40 : STA !Ex_YSpeed,x
		STZ !Ex_XSpeed,x
		LDA !Ex_Data3,x				; mark hammer as owned by player
		ORA #$01
		STA !Ex_Data3,x
.Return		JML $02A468				; > return
.NoHammer	JML $02A40E				; > non-hammer code


	; GenerateHammer starts at $02DAC3.

	HammerSpawn:
		LDA #$04+!ExtendedOffset : STA !Ex_Num,y
		LDA #$00 : STA !Ex_Data3,y
		JML $02DAC8

	HammerWaterCheck:
		PHX
		LDA !Ex_XLo,x : STA $00
		LDA !Ex_XHi,x : STA $01
		LDA !Ex_YLo,x : STA $02
		LDA !Ex_YHi,x : STA $03
		REP #$10
		LDA !IceLevel : BNE .No3D
		LDA !3DWater : BEQ .No3D
		LDY $02 : BMI .No3D
		CPY !Level+2 : BCS .Water
	.No3D	LDX $00
		LDY $02
		JSL !GetMap16
		CMP #$0006 : BCS .NoWater

	.Water	SEP #$30
		PLX
		LDA $9D : BNE .02A30C
		TXA
		CLC : ADC $14
		AND #$01 : BNE .02A2F3
	.02A2F9	JML $02A2F9

	.NoWater
		SEP #$30
	.Return	PLX
		LDA $9D : BNE .02A30C
	.02A2F3	JML $02A2F3
	.02A30C	JML $02A30C


;=================;
; PARTICLE SYSTEM ;
;=================;
incsrc "ParticleSystem.asm"



;=========;
; BANK 02 ;
;=========;
incsrc "FusionSprites/MalleableExtendedSprite.asm"

	; -- coin gfx fix --
	; (coin needs no fix)

	; -- minor gfx fix --
	org $028FCA
	BrickPiece:
		JSL DisplayGFX
		db $04,$FF
		db $00,$00,$00,$00
		LDA $00 : BEQ .Return
		LDA $14
		LSR A
		CLC : ADC $7698
		AND #$07
		TAY
		LDA $8B84,y
		LDY !OAMindex
		STA !OAM+$002-4,y
		LDA !Ex_Data1,x : BEQ .Return
		LDA !OAM+$003-4,y
		AND.b #$0E^$FF
		STA $00
		LDA $14
		AND #$0E
		ORA $00
		STA !OAM+$003-4,y
	.Return	RTS
	warnpc $02902D

	org $028EE1
	Sparkles:
		JSL DisplayGFX
		db $04,$FF
		db $00,$00,$00,$00
		LDA $00 : BEQ .Return
		LDA !Ex_Data1,x
		LSR #3
		TAY
		LDA !Ex_Num,x
		CMP #$02+!MinorOffset : BEQ .SmallStar
		.BlueSparkle
		INY #3
		.SmallStar
		LDA $8ECC,y				; same table but different offsets
		LDY !OAMindex
		STA !OAM+$002-4,y
	.Return	RTS
	warnpc $028F2B

	org $028F4D
	FireParticle:
		JSL DisplayGFX
		db $04,!GFX_LavaEffects-!GFX_status
		db $00,$00,$00,$00
		LDA $00 : BEQ .Return
		LDA !Ex_Data1,x
		LSR #3
		TAY
		LDA $8F2B,y
		CLC : ADC $0C
		LDY !OAMindex
		STA !OAM+$002-4,y
	.Return	RTS

	org $028E20
	Z:
		JSL DisplayGFX
		db $04,!GFX_RipVanFish-!GFX_status
		db $00,$00,$00,$00
		LDA $00 : BEQ .Return
		LDA !Ex_Data1,x
		LSR #5
		AND #$03
		TAY
		LDA $8DD7,y
		CLC : ADC $0C
		LDY !OAMindex
		STA !OAM+$002-4,y
	.Return	RTS
	warnpc $028E76

	org $028DEA
		BNE +
		STZ !Ex_Num,x		; make Z actually despawn when timer runs out
		RTS
		NOP
		+
	warnpc $028DF1

	org $028D42			; water splash tile table
		db $00,$00,$02,$02,$02	; $68 -> $00, $6A -> $02
	org $028D8B
	WaterSplash:
		LDA !Ex_Data1,x
		INC !Ex_Data1,x
		LSR A
		CMP #$0C
		BCC $02 : LDA #$0C
		TAY
		LDA $8D42,y : BEQ .Water00
		CMP #$02 : BEQ .Water02
		CMP #$66 : BNE .Smoke16x16		; catch 8x8 smoke tile
		.Smoke8x8
		JMP Smoke01_8
		.Smoke16x16
		PHA
		JSL DisplayGFX
		db $04,$FF
		db $00,$00,$00,$02
		PLA
		LDY $00 : BEQ .Return
		LDY !OAMindex
		STA !OAM+$002-4,y
	.Return	RTS
		.Water00
		JSL DisplayGFX
		db $04,!GFX_WaterEffects-!GFX_status
		db $00,$00,$00,$02
		RTS
		.Water02
		JSL DisplayGFX
		db $04,!GFX_WaterEffects-!GFX_status
		db $00,$00,$02,$02
		RTS
	warnpc $028DD7

	org $028CFF
	BooStream:
		JSL DisplayGFX
		db $04,!GFX_Boo-!GFX_status
		db $00,$00,$00,$02
		LDA $00 : BEQ .Return
		LDY !OAMindex
		PHX
		TXA
		AND #$0B
		TAX
		LDA $8CB8,x
		PLX
		CLC : ADC !OAM+$002-4,y
		STA !OAM+$002-4,y
		LDA !Ex_XSpeed,x
		LSR A
		AND #$40
		ORA !OAM+$003-4,y
		STA !OAM+$003-4,y
	.Return	RTS
	warnpc $028D42


	; -- extended gfx fix --
	org $02A362
	SmokeExtended:
		LDA !Ex_Data2,x
		LSR #2
		TAY
		LDA $A347,y
		CMP #$66 : BNE .16
	.8	JMP Smoke01_8

	.16	JSL DisplayGFX
		db $04,$FF
		db $00,$00,$00,$02
		LDA $00 : BEQ .Return
		LDA !Ex_Data2,x
		LSR #2
		TAY
		LDA $A347,y
		LDY !OAMindex
		STA !OAM+$002-4,y
	.Return	RTS
	warnpc $02A3AE

	org $02A178
	EnemyFireball:
		LDA !Ex_Num,x					;\ if num  = extended 02, this looks like mario's fireball
		CMP #$02+!ExtendedOffset : BEQ MarioFireball	;/ otherwise, it's a big fireball
		JSL DisplayGFX
		db $04,!GFX_ReznorFireball-!GFX_status
		db $00,$00,$00,$02
		LDA $00 : BEQ .Return
		LDY !OAMindex
		LDA !OAM+$003-4,y
		AND #$3F
		BIT !Ex_Data3,x
		BPL $02 : ORA #$C0
		BVC $02 : EOR #$40
		STA !OAM+$003-4,y
	.Return	RTS
	warnpc $02A1A4

	org $02A232
	TinyFlame:
		JSL DisplayGFX
		db $04,!GFX_HoppingFlame
		db $00,$00,$00,$00
		LDA $00 : BEQ .Return
		LDA !Ex_Data1,x
		AND #$04
		LSR #2
		TAY
		LDA $A217,y
		ADC $0C			; trick due to VERY limited space: the LSR always clears C
		LDY !OAMindex
		STA !OAM+$002-4,y
	.Return	RTS
	warnpc $02A254

	org $02A405
		JML HammerSpinJump
	org $02DAC3
		JML HammerSpawn		; org: LDA #$04 : STA $170B,y
		NOP
	org $02A2EF
		JML HammerWaterCheck	; org: LDA $9D : BNE $19 ($02A30C)

	org $02A317
	Hammer:
		JSL DisplayGFX
		db $04,!GFX_Hammer-!GFX_status
		db $00,$00,$00,$02
		LDA $00 : BEQ .Return
		LDY !OAMindex
		LDA !OAM+$003-4,y
		BIT !Ex_Data3,x
		BPL $02 : ORA #$C0
		BVC $02 : EOR #$40
		STA !OAM+$003-4,y
	.Return	RTS
	warnpc $02A344

	org $029FB3
		BRA 13 : NOP #13
	warnpc $029FC2
	org $02A03B
		JMP MarioFireball
	org $02A1A4
	MarioFireball:
		LDA !Ex_Num,x
		CMP.b #$02+!CustomOffset : BEQ .Luigi

	.Mario	JSL DisplayGFX
		db $04,!GFX_ReznorFireball-!GFX_status	; changed to reznor fireball
		db $FC,$F8,$00,$02			; changed coords from 00;00, changed size to 02, removed xflip
		BRA .Shared

	.Luigi	JSL DisplayGFX
		db $04,!GFX_LuigiFireball-!GFX_status
		db $00,$00,$00,$40

	.Shared	LDA $00 : BEQ .Return
		LDY !OAMindex
		LDA !OAM+$003-4,y
		BIT !Ex_XSpeed,x
		BMI $02 : EOR #$40
	;	AND #$3F
	;	BIT !Ex_Data3,x
	;	BPL $02 : ORA #$C0
	;	BVC $02 : EOR #$40
		STA !OAM+$003-4,y
	.Return	RTS


	warnpc $02A211

	org $02A2C3
	Bone:
		JSL DisplayGFX
		db $04,!GFX_Bone-!GFX_status
		db $00,$00,$00,$02
		LDA $00 : BEQ .Return
		TXA
		AND #$01
		BEQ $02 : LDA #$C0
		BIT !Ex_XSpeed,x
		BMI $02 : EOR #$40
		LDY !OAMindex
		ORA !OAM+$003-4,y
		STA !OAM+$003-4,y
	.Return	RTS
	warnpc $02A2EF			; we can overwrite the hammer tile table since it's unused
	org $03C44E
		BRA 6 : NOP #6		; spawn bone even if dry bones is off-screen
	warnpc $03C456

	org $029E9D
	LavaSplash:
		JSL DisplayGFX
		db $00,!GFX_LavaEffects-!GFX_status
		db $00,$00,$00,$00
		LDA $00 : BEQ .Return
		LDA !Ex_Data2,x
		LSR #3
		AND #$03
		TAY
		LDA $9E82,y
		LDY !OAMindex
		STA !OAM+$002-4,y
	.Return	RTS
	warnpc $029EE6

	org $029E39
	Code_029E39:

	org $029E3D
	TorpedoTedArm:
		LDY #$00
		LDA !Ex_Data2,x : BEQ Code_029E39
		CMP #$60 : BCS .Speed
		INY
		CMP #$30 : BCS .Speed
		INY
	.Speed	LDA $9D : BNE .GFX
		LDA $9E36,y : STA !Ex_YSpeed,x
		JSR $B560
	.GFX	LDA !Ex_Data2,x
		CMP #$60 : BCC .Tile08
	.Tile06	JSL DisplayGFX
		db $84,!GFX_TorpedoTed-!GFX_status
		db $00,$00,$06,$12
		RTS
	.Tile08	JSL DisplayGFX
		db $84,!GFX_TorpedoTed-!GFX_status
		db $00,$00,$08,$12
		RTS
	warnpc $029E82

	org $02A313
	EnemyFireballWithGravity:
		JSR MarioFireball
	warnpc $02A316

	org $029B51
	LotusPollen:
		LDA $14
		LSR A
		EOR $75E9
		LSR #2
		BCC .Tile10
	.Tile00	JSL DisplayGFX
		db $04,!GFX_LotusPollen-!GFX_status
		db $00,$00,$00,$00
		BRA .Done
	.Tile10	JSL DisplayGFX
		db $04,!GFX_LotusPollen-!GFX_status
		db $00,$00,$10,$00
		BRA .Done
	warnpc $029BA5
	org $029BA5
	.Done

	org $02A271
	Baseball:
		JSL DisplayGFX
		db $04,!GFX_Baseball-!GFX_status
		db $00,$00,$00,$00
		LDA $00 : BEQ .Return
		TXA
		AND #$01
		BEQ $02 : LDA #$C0
		BIT !Ex_XSpeed,x
		BMI $02 : EOR #$40
		LDY !OAMindex
		ORA !OAM+$003-4,y
		STA !OAM+$003-4,y
	.Return	RTS
	warnpc $02A2BF
	org $02C466
		LDA $32F0,x			;\ spawn baseball even if chuck is off-screen
		BEQ $03 : RTS : NOP #2		;/
	warnpc $02C46E

	org $029C88
	SpinJumpStars:
		JSL DisplayGFX
		db $04,$FF
		db $00,$00,$48,$00
		BRA .Done
	warnpc $029C98
	org $029C98
		.Done

	org $029F2A
	Bubble:
		LDA !Ex_Data1,x
		LSR #2
		AND #$03
		TAY
		LDA $9EEA,y
		BEQ .Disp00
		BMI .DispFF
	.Disp01	JSL DisplayGFX
		db $04,!GFX_WaterEffects-!GFX_status
		db $01,$05,$04,$00
		RTS
	.Disp00	JSL DisplayGFX
		db $04,!GFX_WaterEffects-!GFX_status
		db $00,$05,$04,$00
		RTS
	.DispFF	JSL DisplayGFX
		db $04,!GFX_WaterEffects-!GFX_status
		db $FF,$05,$04,$00
		RTS
	warnpc $029F61


	; -- smoke gfx fix --
	org $02999F
	SmokeGeneric:
		JSL DisplayGFX
		db $04,$FF
		db $00,$00,$00,$02
		LDA $00 : BEQ .Return
		LDY !OAMindex
		LDA !Ex_Data1,x
		LSR #2
		TAX
		LDA $9922,x : STA !OAM+$102-4,y
	.Return	LDX $7698
		RTS

	org $029701
	Smoke01:
		LDA !Ex_Data1,x
		LSR #2
		TAY
		LDA $96D8,y
		CMP #$66 : BNE .16
	.8	JSL DisplayGFX
		db $04,$FF
		db $04,$04,$5E,$00
		RTS

	.16	JSL DisplayGFX
		db $04,$FF
		db $00,$00,$00,$02
		LDA $00 : BEQ .Return
		LDA !Ex_Data1,x
		LSR #2
		TAY
		LDA $96D8,y
		LDY !OAMindex
		STA !OAM+$002-4,y
	.Return	RTS
	warnpc $02974A
	org $02974A
		JMP Smoke01

	org $0297B2
	ContactGFX:
		JSL DisplayGFX
		db $04,$FF
		db $00,$00,$66,$02
		LDA $00 : BEQ .Return
		LDY !Ex_Data1,x
		LDA.w .Tiles,y
		LDY !OAMindex
		STA !OAM+$002-4,y
	.Return	RTS
	.Tiles	db $6A,$6A,$6A,$68,$68,$68,$66,$66

	org $029936
		JMP $9793		; skip a pointless code that just writes 0xF0 to OAM Y

	org $02996F
	TurnSmoke:
		JSL DisplayGFX
		db $04,$FF
		db $00,$00,$00,$00
		LDA $00 : BEQ .Return
		LDY !OAMindex
		PHX
		LDA !Ex_Data1,x
		LSR #2
		TAX
		LDA.w $9922,x : STA !OAM+$002-4,y
		PLX
	.Return	RTS



	; to DO:
	; integrate GFX_expand edits
	; test EVERYTHING
	; make sure new GFX code works



incsrc "Remap.asm"




print " "
print "FusionCore V1.2"
print " - Ex_Num mapped to ........$", hex(!Ex_Num)
print " - Ex_Data1 mapped to ......$", hex(!Ex_Data1)
print " - Ex_Data2 mapped to ......$", hex(!Ex_Data2)
print " - Ex_Data3 mapped to ......$", hex(!Ex_Data3)
print " - Ex_XLo mapped to ........$", hex(!Ex_XLo)
print " - Ex_XHi mapped to ........$", hex(!Ex_XHi)
print " - Ex_YLo mapped to ........$", hex(!Ex_YLo)
print " - Ex_YHi mapped to ........$", hex(!Ex_YHi)
print " - Ex_XSpeed mapped to .....$", hex(!Ex_XSpeed)
print " - Ex_YSpeed mapped to .....$", hex(!Ex_YSpeed)
print " - Ex_XFraction mapped to ..$", hex(!Ex_XFraction)
print " - Ex_YFraction mapped to ..$", hex(!Ex_YFraction)
print dec(!DebugRemapCount), " addresses remapped"
print "Number of ExSprites allowed: ", dec(!Ex_Amount), " (0x", hex(!Ex_Amount), ")"
print "Number of ExSprite types: ", dec(HandleEx_PalsetIndex_End-HandleEx_PalsetIndex), " (0x", hex(HandleEx_PalsetIndex_End-HandleEx_PalsetIndex), ")"
print " "
