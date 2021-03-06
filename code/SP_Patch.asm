header
sa1rom

print "-- SP_PATCH --"

; --Defines--

incsrc "Defines.asm"

!Freespace = $138000

org !Freespace
db $53,$54,$41,$52
dw $FFF7
dw $0008


pushpc
org $04842E		; 048431 is taken by SP_Level
dl GENERATE_BLOCK

org $048434
dl SCROLL_OPTIONS_Main	; JSL read3($048334) will instantly scroll layer 2 and execute the HDMA code

; 048437	;\
; 04843A	; | used by Fe26
; 04843D	; |
; 048440	;/

org $048443
dl GET_DYNAMIC_TILE
dl UPDATE_CLAIMED_GFX
dl TRANSFORM_GFX
dl RealmSelect_Portrait_Long
dl GET_ROOT

; 048452	; used by SP_Level



pullpc



CODE_138008:
	PHB : PHK : PLB			;\
	JSR GET_MAP16			; | wrapper for GET_MAP16 routine, located at !Freespace+$08
	PLB				; |
	RTL				;/

CODE_138010:
	PHB : PHK : PLB			;\
	JSR KILL_OAM_Short		; | wrapper for OAM kill routine
	PLB				; |
	RTL				;/

CODE_138018:
	PHB : PHK : PLB			;\
	JSR GET_MAP16_ABSOLUTE		; | load coordinates in X/Y, then JSL here
	PLB				; |
	RTL				;/

CODE_138020:
	PHB : PHK : PLB			;\
	JSR YoshiCoins			; | wrapper for Yoshi Coin handler, called by level code
	PLB				; |
	RTL				;/

CODE_138028:
	PHB : PHK : PLB			;\
	JSR GET_VRAM			; | wrapper for the routine that gets the VRAM table index into X
	PLB				; |
	RTL				;/

CODE_138030:
	PHB : PHK : PLB			;\
	JSR GET_CGRAM			; | wrapper for the routine that gets the CGRAM table index into Y
	PLB				; |
	RTL				;/

CODE_138038:
	PHB : PHK : PLB
	JSR PLANE_SPLIT
	PLB
	RTL

CODE_138040:
	PHB : PHK : PLB
	JSR HurtPlayers
	PLB
	RTL

CODE_138048:
	JSR UPDATE_GFX
	RTL

CODE_13804C:
	JSR UPDATE_PAL
	RTL

CODE_138050:
	PHB : PHK : PLB
	JSR CONTACT16
	PLB
	RTL


CODE_138058:
	PHB : PHK : PLB
	JSR RGBtoHSL
	PLB
	RTL

CODE_138060:
	PHB : PHK : PLB
	JSR HSLtoRGB
	PLB
	RTL

CODE_138068:
	PHB : PHK : PLB
	JSR MixRGB
	PLB
	RTL

CODE_138070:
	PHB : PHK : PLB
	JSR MixRGB_Upload
	PLB
	RTL

CODE_138078:
	PHB : PHK : PLB
	JSR MixHSL
	PLB
	RTL

CODE_138080:
	PHB : PHK : PLB
	JSR MixHSL_Upload
	PLB
	RTL

CODE_138088:
	JSR UPDATE_3D_CLUSTER
	RTL

CODE_13808C:
	JSR UPDATE_2D_CLUSTER
	RTL

CODE_138090:
	PHB : PHK : PLB
	JSR GET_FILE_ADDRESS
	PLB
	RTL

CODE_138098:
	JSR UPDATE_FROM_FILE
	RTL

CODE_13809C:
	JSR DECOMP_FROM_FILE
	RTL

CODE_1380A0:
	JSR LOAD_FILE
	RTL

CODE_1380A4:
	JSR SPRITE_HUD
	RTL

CODE_1380A8:
	PHB : PHK : PLB
	JSR GET_BIG_CCDMA
	PLB
	RTL

CODE_1380B0:
	PHB : PHK : PLB
	JSR GET_SMALL_CCDMA
	PLB
	RTL

CODE_1380B8:
	PHB : PHK : PLB
	JSR BUILD_OAM
	PLB
	RTL

CODE_1380C0:
	JSR CHANGE_MAP16
	RTL

CODE_1380C4:
	JSR FADE_LIGHT
	RTL

CODE_1380C8:
	JSR GET_PARTICLE_INDEX
	RTL


incsrc "5bpp.asm"
incsrc "Transform_GFX.asm"


;=========;
;Get_MAP16;
;=========;
; --Instructions--
;
; Load A and Y with 16-bit X and Y offsets for block to check, then do:
; JSL !GetMap16Sprite
;
; Returns with the following:
; A	- 16-bit acts like setting
; [$00]	- pointer to map16 acts like settings
; $03	- 16-bit tile number
; [$05]	- pointer to high byte of map16 number
; A is 16-bit, X/Y are 8-bit
;
; Absolute mode:
; Load X and Y with their respective 16-bit coordinates.
; JSL with 16-bit XY and 8-bit A.
; Returns 8-bit XY, 16-bit A; A = acts like setting of block.



GET_MAP16:
	PHY				; Preserve Y offset (16-bit)
	PHA				; Preserve X offset (16-bit)
	SEP #$30			; All registers 8-bit
	LDA $3250,x
	XBA
	LDA $3220,x
	REP #$20			; A 16-bit
	STA $00
	PLA				; Restore X offset (16-bit)
	CLC
	ADC $00				; Add with sprite Xpos (16-bit)
	STA $02				; Store to scratch RAM
	SEP #$20			; A 8-bit

	LDA $3240,x
	XBA
	LDA $3210,x
	REP #$20			; A 16-bit
	STA $00
	PLA				; Restore Y offset (16-bit)
	CLC
	ADC $00				; Add with sprite Ypos (16-bit)
	STA $00				; Store to scratch RAM
	SEP #$20			; A 8-bit

	LDA $00				; Load sprite Y pos (lo)
	AND #$F0			; Check only the highest nybble
	STA $06				; Store to scratch RAM
	LDA $02				; Load sprite X pos (lo)
	LSR A				;\
	LSR A				; |
	LSR A				; | Divide by 16 (X pos is now in map16-tiles rather than pixels)
	LSR A				;/
	ORA $06				; High nybble is now high nybble of lo Ypos and low nybble is Xpos in tiles?
	PHA				; Preserve this most peculiar value
	LDA $5B				; Load screen mode
	AND #$01			; Check vertical layer 1
	BEQ .Horizontal			; Branch if clear

	.Vertical
	PLA				; Restore the weirdo value
	LDX $01				; Load sprite Y pos (hi) in X
	CLC				; Clear carry
	ADC.L $00BA80,x			; Add a massive map16 table (indexed by X) to weirdo-value
	STA $05				; Store to scratch RAM
	LDA.L $00BABC,x			; Load another massive map16 table (indexed by the same X)
	ADC $03				; Add with sprite X pos (hi)
	STA $06				; Store to scratch RAM
	BRA .Shared			; BRA to a shared routine

	.Horizontal
	PLA				; Restore weirdo-value
	LDX $03				; Load sprite X pos (hi)
	CLC				; Clear carry
	ADC.L $006CB6,x			; Add with massive map16 table
	STA $05				; Store to scratch RAM
	LDA.L $006CD6,x			; Load massive map16 table
	ADC $01				; Add with sprite Y pos (hi)
	STA $06				; Store to scratch RAM

	.Shared
	JSR .ABSOLUTE_Shared		; do the thing
	LDX !SpriteIndex		; Load sprite index in X

	.Return
	RTS				; Return


	.ABSOLUTE
	STY $00
	STX $02
	LDA $00
	AND #$F0 : STA $06
	LDA $02
	LSR #4
	ORA $06
	PHA
	SEP #$10
	LDA !RAM_ScreenMode
	LSR A : BCC ..Horz

	..Vert
	LDA $01
	CMP $5D : BCS ..OutOfBounds
	LDA $03
	CMP #$02 : BCS ..OutOfBounds
	PLA
	LDX $01
	CLC : ADC.l $00BA80,x
	STA $05
	LDA.l $00BABC,x
	ADC $03
	STA $06
	BRA ..Shared

	..OutOfBounds
	PLA
	REP #$20
	LDA #$0025
	RTS

	..Horz
	REP #$20
	LDA $00
	CMP $73D7
	SEP #$20
	BCS ..OutOfBounds
	LDA $03
	CMP $5D : BCS ..OutOfBounds
	PLA
	LDX $03
	CLC : ADC.l $006CB6,x
	STA $05
	LDA.l $006CD6,x
	ADC $01
	STA $06

	..Shared
	LDA #$40 : STA $07
	LDA [$05] : XBA
	INC $07
	LDA [$05] : XBA
	REP #$30
	STA $03
	CMP #$4000 : BCS ..40

..00	LDA !Map16ActsLike+0 : STA $00
	LDA !Map16ActsLike+1 : STA $01
	BRA ..read

..40	LDA !Map16ActsLike40+0 : STA $00
	LDA !Map16ActsLike40+1
	ORA #$0080				; shoutout to lunar magic
	STA $01

	..read
	LDA $03
	AND #$3FFF
	ASL A : TAY
	LDA [$00],y
	SEP #$10

	..Return
	RTS


;==============;
;GENERATE_BLOCK;
;==============;
; --Input--
; X = sprite index
; Y = Shatter brick flag (00 does nothing, 01-FF runs the shatter brick routine)
; $00 = Object to spawn from block.
; $02 = 16-bit X offset
; $04 = 16-bit Y offset
; $7C = Bounce sprite to spawn.
; $9C = Block to generate.

GENERATE_BLOCK:

	LDA $98					;\
	PHA					; |
	LDA $99					; |
	PHA					; | Preserve Mario's block values
	LDA $9A					; |
	PHA					; |
	LDA $9B					; |
	PHA					;/
	LDA $00					;\ Preserve object to spawn from block
	PHA					;/
	PHY					; Preserve shatter brick flag

	LDA $3210,x				;\
	STA $00					; |
	LDA $3240,x				; |
	STA $01					; |
	LDA $3250,x				; |
	XBA					; |
	LDA $3220,x				; |
	REP #$20				; | Set pos to sprite pos + offset
	CLC					; |
	ADC $02					; |
	AND.W #$FFF0				; |> Ignore lowest nybble
	STA $9A					; |
	LDA $00					; |
	CLC					; |
	ADC $04					; |
	AND.W #$FFF0				; |> Ignore lowest nybble
	STA $98					;/

GENERATE_BLOCK_SHORT:

	SEP #$20

	LDA $9C
	BEQ GENERATE_BLOCK_SHATTER

		JSL $00BEB0

	GENERATE_BLOCK_SHATTER:

		PLA				; Restore shatter brick flag
		BEQ GENERATE_BLOCK_BOUNCE
		PHB				;\
		LDA #$02			; |
		PHA				; | Bank wrapper
		PLB				; |
		LDA #$00			; |> Normal shatter (01 will spawn rainbow brick pieces)
		JSL $028663			; |> Shatter Block
		PLB				;/

	GENERATE_BLOCK_BOUNCE:

		LDA $7C
		BEQ GENERATE_BLOCK_OBJECT
		JSR BOUNCE_SPRITE		; Spawn bounce sprite of type $7C at ($98;$9A)

	GENERATE_BLOCK_OBJECT:

		PLA
		BEQ RETURN_GENERATE_BLOCK
		STA $05

		REP #$20
		LDA $98
		CLC
		ADC #$0003
		STA $98
		SEP #$20
		LDA $9A
		AND #$F0
		STA $9A

		PHB				;\
		LDA #$02			; |
		PHA				; | Bank wrapper
		PLB				; |
		JSL $02887D			; |> Spawn object
		PLB				;/

RETURN_GENERATE_BLOCK:

	PLA					;\
	STA $9B					; |
	PLA					; |
	STA $9A					; | Restore Mario's block values
	PLA					; |
	STA $99					; |
	PLA					; |
	STA $98					;/
	RTL

;===================;
;SPAWN BOUNCE SPRITE;
;===================;
; --Input--
; Load $00 with bounce sprite number
; Load $01 with tile bounce sprite should turn into (uses $009C values)
; Load $02 with 16 bit X offset
; Load $04 with 16 bit Y offset
; Load $06 with bounce sprite timer (how many frames it will exist)
; Bounce sprite of type $7C will be spawned at ($98;$9A) and will turn into $9C

BOUNCE_SPRITE:

	LDY #$03			; Highest bounce sprite index

LOOP_BOUNCE_SPRITE:

	LDA $7699,y			;\
	BEQ SPAWN_BOUNCE_SPRITE		; |
	DEY				; | Get bounce sprite number
	BPL LOOP_BOUNCE_SPRITE		; |
	RTS				;/

SPAWN_BOUNCE_SPRITE:

	STA $769D,y			; > INIT routine
	STA $76C9,y			; > Layer 1, going up
	STA $76B5,y			; > X speed
	LDA #$C0			;\ Y speed
	STA $76B1,y			;/

	LDA #$08			;\ How many frames bounce sprite will exist
	STA $76C5,y			;/
	LDA $9C				;\ Map16 tile bounce sprite should turn into
	STA $76C1,y			;/

	LDA $7C				;\ Bounce sprite number
	STA $7699,y			;/
	CMP #$07			;\
	BNE PROCESS_BOUNCE_SPRITE	; |
	LDA #$FF			; | Set turn block timer if spawning a turn block
	STA $786C,y			;/

PROCESS_BOUNCE_SPRITE:

	LDA $9A
	STA $76A5,y
	STA $76D1,y
	LDA $9B
	STA $76AD,y
	STA $76D5,y

	LDA $98
	STA $76A1,y
	STA $76D9,y
	LDA $99
	STA $76A9,y
	STA $76DD,y

	LDA $7699,y			;\
	CMP #$07			; |
	BNE RETURN_BOUNCE_SPRITE	; | Set Y speed to zero if spawning a turn block
	LDA #$00			; |
	STA $76B1,y			;/

RETURN_BOUNCE_SPRITE:

	RTS				; Return


;===========;
;YOSHI COINS;
;===========;
incsrc "YoshiCoins.asm"


;========;
;GET ROOT;
;========;
; Load unsigned 17-bit number in A + carry, then JSR here.
; A returns in same mode as before (PHP : PLP)
; A holds square root of input number.
GET_ROOT:	PHB : PHK : PLB
		JSR .Main
		PLB
		RTL


.Main		PHX
		PHP
		REP #$30
		BCS .010000
		CMP #$4000 : BCS .4000
		CMP #$1000 : BCS .1000
		CMP #$0400 : BCS .0400
		CMP #$0100 : BCS .0100
		ASL A
		TAX
		LDA.w .Table,x
		PLP
		PLX
		RTS

.010000		ROR A
		LSR A
.4000		XBA
		AND #$00FE
		ASL A
		TAX
		LDA.w .Table,x
		ASL #4
		PLP
		PLX
		BCC +
		ASL A
	+	RTS

.1000		XBA
		ROL #2
		AND #$00FE
		ASL A
		TAX
		LDA.w .Table,x
		ASL #3
		PLP
		PLX
		RTS

.0400		LSR #3
		AND #$FFFE
		TAX
		LDA.w .Table,x
		ASL #2
		PLP
		PLX
		RTS

.0100		LSR A
		AND #$FFFE
		TAX
		LDA.w .Table,x
		ASL A
		PLP
		PLX
		RTS



; Shifted 8 bits left to account for "hexadecimals"
.Table		dw $0000,$0100,$016A,$01BB,$0200,$023C,$0273,$02A5	; 00-07
		dw $02D4,$0300,$032A,$0351,$0377,$039B,$03BE,$03DF	; 08-0F
		dw $0400,$0420,$043E,$045C,$0479,$0495,$04B1,$04CC	; 10-17
		dw $04E6,$0500,$0519,$0532,$054B,$0563,$057A,$0591	; 18-1F
		dw $05A8,$05BF,$05D5,$05EB,$0600,$0615,$062A,$063F	; 20-27
		dw $0653,$0667,$067B,$068F,$06A2,$06B5,$06C8,$06DB	; 28-2F
		dw $06EE,$0700,$0712,$0724,$0736,$0748,$0759,$076B	; 30-37
		dw $077C,$078D,$079E,$07AE,$07BF,$07CF,$07E0,$07F0	; 38-3F
		dw $0800,$0810,$0820,$082F,$083F,$084E,$085E,$086D	; 40-47
		dw $087C,$088B,$089A,$08A9,$08B8,$08C6,$08D5,$08E3	; 48-4F
		dw $08F2,$0900,$090E,$091C,$092A,$0938,$0946,$0954	; 50-57
		dw $0961,$096F,$097D,$098A,$0997,$09A5,$09B2,$09BF	; 58-5F
		dw $09CC,$09D9,$09E6,$09F3,$0A00,$0A0D,$0A19,$0A26	; 60-67
		dw $0A33,$0A3F,$0A4C,$0A58,$0A64,$0A71,$0A7D,$0A89	; 68-6F
		dw $0A95,$0AA1,$0AAD,$0AB9,$0AC5,$0AD1,$0ADD,$0AE9	; 70-77
		dw $0AF4,$0B00,$0B0C,$0B17,$0B23,$0B2E,$0B3A,$0B45	; 78-7F
		dw $0B50,$0B5C,$0B67,$0B72,$0B7D,$0B88,$0B93,$0B9E	; 80-87
		dw $0BA9,$0BB4,$0BBF,$0BCA,$0BD5,$0BE0,$0BEB,$0BF5	; 88-8F
		dw $0C00,$0C0B,$0C15,$0C20,$0C2A,$0C35,$0C3F,$0C4A	; 90-97
		dw $0C54,$0C5F,$0C69,$0C73,$0C7D,$0C88,$0C92,$0C9C	; 98-9F
		dw $0CA6,$0CB0,$0CBA,$0CC4,$0CCE,$0CD8,$0CE2,$0CEC	; A0-A7
		dw $0CF6,$0D00,$0D0A,$0D14,$0D1D,$0D27,$0D31,$0D3B	; A8-AF
		dw $0D44,$0D4E,$0D57,$0D61,$0D6B,$0D74,$0D7E,$0D87	; B0-B7
		dw $0D91,$0D9A,$0DA3,$0DAD,$0DB6,$0DBF,$0DC9,$0DD2	; B8-BF
		dw $0DDB,$0DE4,$0DEE,$0DF7,$0E00,$0E09,$0E12,$0E1B	; C0-C7
		dw $0E24,$0E2D,$0E36,$0E3F,$0E48,$0E51,$0E5A,$0E63	; C8-CF
		dw $0E6C,$0E75,$0E7E,$0E87,$0E8F,$0E98,$0EA1,$0EAA	; D0-D7
		dw $0EB2,$0EBB,$0EC4,$0ECC,$0ED5,$0EDE,$0EE6,$0EEF	; D8-DF
		dw $0EF7,$0F00,$0F09,$0F11,$0F1A,$0F22,$0F2A,$0F33	; E0-E7
		dw $0F3B,$0F44,$0F4C,$0F54,$0F5D,$0F65,$0F6D,$0F76	; E8-EF
		dw $0F7E,$0F86,$0F8E,$0F97,$0F9F,$0FA7,$0FAF,$0FB7	; F0-F7
		dw $0FBF,$0FC8,$0FD0,$0FD8,$0FE0,$0FE8,$0FF0,$0FF8	; F8-FF



;========;
;GET VRAM;
;========;
GET_VRAM:
; -- Info --
;
; Caling this routine will set X to the proper VRAM table index.
; If this routine returns with a set carry, it means that the table is full.

		PHY : PHP
		SEP #$30
		LDA.b #!VRAMbank
		PHA : PLB
		REP #$20
		LDX #$00

.Loop		LDA.w !VRAMtable,x
		BEQ .SlotFound
		TXA
		CLC : ADC #$0007
		TAX
		BCC .Loop
		PLP : PLY
		SEC
		RTS

.SlotFound	PLP : PLY
		CLC
		RTS


;=========;
;GET CGRAM;
;=========;
GET_CGRAM:
		PHP
		SEP #$30
		LDA #!VRAMbank
		PHA : PLB
		REP #$20
		LDY #$00

.Loop		LDA !CGRAMtable,y
		BEQ .SlotFound
		TYA
		CLC : ADC #$0006
		TAY
		BCC .Loop
		PLP
		SEC
		RTS

.SlotFound	PLP
		CLC
		RTS




;========================;
;GET DYNAMIC TILE ROUTINE;
;========================;
; load A with number of extra slots to request, then call this (A=0 means you request 1 tile)
; if carry returns clear, no slot was found
; if carry returns set, then Y = index to table
;
; $00: number of extra tiles requested
; $01: number of tiles not yet checked for availability
; $02: used as a loop counter when checking several tiles for requests larger than 1
; $03: used as scratch
GET_DYNAMIC_TILE:
		PHX
		PHB : PHK : PLB
		STA $00

		LDY #$00
.Loop		STY $01
		LDA $00 : STA $02

.Process	LDX !DynamicTile,y
		CPX #$10 : BCS .CheckSpace
		LDA $3230,x : BEQ .CheckSpace
		LDA !ClaimedGFX
		CMP #$10 : BCC .CheckSpace
		AND #$0F
		STA $03
		CPY $03 : BNE .CheckSpace

.Next		LDA !ClaimedGFX
		LSR #4
		STA $03
		TYA
	-	CLC : ADC $03
		CMP #$10 : BCC +
		CLC

.Return		PLB
		PLX
		RTL

	+	TAY
		BRA .Loop

.CheckSpace	TYA
		EOR #$0F
		CMP $02 : BCC .Return
		DEC $02 : BMI .ThisOne
		INY
		CPY #$08 : BEQ .Loop
		BRA .Process

.ThisOne	TYA
		SEC : SBC $00
		TAY
		SEC
		BRA .Return





; Store dynamo pointer in $0C-$0D, as usual.
;==========================;
;UPDATE CLAIMED GFX ROUTINE;
;==========================;
UPDATE_CLAIMED_GFX:
		PHY
		LDA !ClaimedGFX
		AND #$0F
		ASL A
		CMP #$10
		BCC $03 : CLC : ADC #$10
		STA $02
		LDA !GFX_Dynamic
		AND #$70
		ASL A
		ADC $02
		STA $02
		LDA !GFX_Dynamic
		AND #$0F
		CLC : ADC $02
		STA $02
		STZ $03
		LDA !GFX_Dynamic
		BPL $02 : INC $03
		JSR UPDATE_GFX_Dynamic
		PLY
		RTL

; Store dynamo pointer in $0C-$0D.
; Set carry to add $02-$03 to destination, clear carry to not include $02-$03
; unit of $02 is number of tiles to add, NOT address bytes
;==================;
;UPDATE GFX ROUTINE;
;==================;
UPDATE_GFX:	BCS .Dynamic
.Static		STZ $02 : STZ $03			; < Clear this unless dynamic option is used
.Dynamic	PHX
		PHB
		JSR GET_VRAM
		PLB
		PHP
		REP #$30
		LDA $02					;\
		ASL #4					; | calculating this here is faster
		STA $02					;/
		LDA $0C : BEQ +				; < Return if dynamo is empty
		LDA ($0C) : STA $00
		LDY #$0000
		INC $0C
		INC $0C
	-	LDA ($0C),y
		STA !VRAMbase+!VRAMtable+$00,x
		INY #2
		LDA ($0C),y
		STA !VRAMbase+!VRAMtable+$02,x
		INY
		LDA ($0C),y
		STA !VRAMbase+!VRAMtable+$03,x
		INY #2
		LDA ($0C),y
		CLC : ADC $02
		STA !VRAMbase+!VRAMtable+$05,x
		INY #2
		CPY $00
		BCS +
		TXA
		CLC : ADC #$0007
		TAX
		BRA -

		+
		PLP
		PLX
		RTS


UPDATE_PAL:	JSR GET_CGRAM
		PHP
		REP #$30
		LDA $0C : BEQ +
		LDA ($0C) : STA $00
		LDY #$0000
		INC $0C
		INC $0C
	-	LDA ($0C),y
		STA !VRAMbase+!CGRAMtable+$00,x
		INY #2
		LDA ($0C),y
		STA !VRAMbase+!CGRAMtable+$02,x
		INY #2
		LDA ($0C),y
		STA !VRAMbase+!CGRAMtable+$04,x
		INY #2
		CPY $00
		BCS +
		TXA
		CLC : ADC #$0006
		TAX
		BRA -

		+
		PLP
		RTS



;==============;
;GET CCDMA SLOT;
;==============;
GET_BIG_CCDMA:
		PHP
		SEP #$30
		LDA.b #!VRAMbank
		PHA : PLB
		REP #$20
		LDX #$00
	.Loop	CPX #$80 : BCS .Fail
		LDA !CCDMAtable+$00,x : BEQ .ThisSlot
		TXA
		CLC : ADC #$0008
		TAX
		BRA .Loop

		.ThisSlot
		PLP
		CLC				; carry clear = at least 1 free slot
		RTS

		.Fail
		PLP
		SEC				; carry set = no free slots
		RTS

GET_SMALL_CCDMA:
		PHP
		SEP #$30
		LDA.b #!VRAMbank
		PHA : PLB
		REP #$20
		LDX #$80
	.Loop	CPX #$00 : BEQ .Fail
		LDA !CCDMAtable+$00,x : BEQ .ThisSlot
		TXA
		CLC : ADC #$0008
		TAX
		BRA .Loop

		.ThisSlot
		PLP
		CLC				; carry clear = at least 1 free slot
		RTS

		.Fail
		PLP
		SEC				; carry set = no free slots
		RTS



; remap all $00BEB0 calls
pushpc
org $00F25C : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $00F285 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $00F2D1 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $00F36F : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $01BCB5 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $01C1E9 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $01E33F : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $028784 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $0287E8 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $0291E8 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02B9B8 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02BB06 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02C2C1 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02C2DE : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02CD7B : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02D20B : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02E2D9 : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02E54A : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02E8DD : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $02E8FD : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $03939F : JSL Hijack00BEB0			; changed from JSL $00BEB0
org $03C01E : JSL Hijack00BEB0			; changed from JSL $00BEB0

pullpc


;====================;
;CHANGE MAP16 ROUTINE;
;====================;
;
; input:
;	A = 16-bit map16 number
;	$98 = 16-bit Ypos
;	$9A = 16-bit Xpos

CHANGE_MAP16:

;
; - update map16 table
; - see if tile is within zip (0, 1, 2 or 4 tiles)
; - use block update table to update any tiles within zip
;


; if a tile is within the zip box, it has to be updated
; otherwise it must not be updated
;
; $45	16 bytes for zip purposes
; order: left, right, top, bottom
; (first for BG1 then for BG2)

		PHP
		REP #$30
		STA $0E

		SEP #$30
		LDA $98
		AND #$F0
		STA $98
		LDA $9A
		AND #$F0
		STA $9A
		LSR #4
		ORA $98
		LDX $9B
		CLC : ADC $6CB6,x
		XBA
		LDA $99
		ADC $6CD6,x
		XBA
		REP #$30
		TAX
		SEP #$20
		LDA $0F : STA $410000,x
		XBA
		LDA $0E : STA $400000,x
		REP #$30
		ASL A
		PHP
		JSL $06F540
		PLP
		STA $0A

		LDA $9A : BMI .Fail
		CMP $45 : BCC .Fail
		CMP $47 : BCS .Fail
		LDA $98 : BMI .Fail
		CMP $49 : BCC .Fail
		CMP $4B : BCC .WithinScreen
	.Fail	PLP
		RTS

	.WithinScreen
		LDA $98							;\
		AND #$00F0						; | > only 256px tall so cut the lowest screen bit
		ASL #2							; |
		STA $02							; |
		LDA $9A							; |
		AND #$00F0						; | address within tilemap
		LSR #3							; | -----Xyy yyyxxxxx
		STA $00							; | (word address, each tile is 2 bytes)
		LDA $9A							; | $00: x
		AND #$0100						; | $02: y
		ASL #2							; | $04: X
		STA $04							; | $06: tilemap address
		LDA !BG1Address : STA $06				;/


		PHB
		PEA $4040
		PLB : PLB
		LDX !TileUpdateTable
		LDY #$0000						;\
		LDA [$0A],y : STA !TileUpdateTable+$04,x		; |
		LDY #$0002						; |
		LDA [$0A],y : STA !TileUpdateTable+$0C,x		; | tile data
		LDY #$0004						; |
		LDA [$0A],y : STA !TileUpdateTable+$08,x		; |
		LDY #$0006						; |
		LDA [$0A],y : STA !TileUpdateTable+$10,x		;/


		LDA $00							;\
		ORA $02							; |
		ORA $04							; | top left tile address
		ORA $06							; |
		STA !TileUpdateTable+$02,x				;/
		LDA $00							;\
		INC A							; |
		CMP #$0020						; |
		AND #$001F						; |
		BCC $03 : ORA #$0400					; | top right tile address
		STA $08							; |
		ORA $02							; |
		EOR $04							; |
		ORA $06							; |
		STA !TileUpdateTable+$06,x				;/
		LDA $02							;\
		CLC : ADC #$0020					; |
		AND #$03E0						; |
		STA $02							; | bot right tile address
		ORA $08							; |
		EOR $04							; |
		ORA $06							; |
		STA !TileUpdateTable+$0E,x				;/
		LDA $02							;\
		ORA $00							; |
		ORA $04							; | bot left tile address
		ORA $06							; |
		STA !TileUpdateTable+$0A,x				;/

		TXA
		CLC : ADC #$0010
		STA !TileUpdateTable

		PLB
		PLP
		RTS


	Hijack00BEB0:
	; NOTE!
	; if $9C = $01/$16/$17/$18, item memory bit has to be set!
		PHX
		PHP
		REP #$30
		LDA $9C
		AND #$00FF
		CMP #$0018
		BCC .SingleTile
		BEQ .YoshiCoin
		CMP #$0019 : BEQ .NetDoor
		CMP #$001A : BEQ .NetDoor

		; 1B and up uses this one
	.32x32
		LDA #$0025 : JSR CHANGE_MAP16
		LDA $98 : PHA
		CLC : ADC #$0010
		STA $98
		LDA #$0025 : JSR CHANGE_MAP16
		PLA : STA $98
		LDA $9A
		CLC : ADC #$0010
		STA $9A

	.YoshiCoin
		LDA #$0025 : JSR CHANGE_MAP16
		LDA $98
		CLC : ADC #$0010
		STA $98
		LDA #$0025 : JSR CHANGE_MAP16
		PLP
		PLX
		RTL

	.SingleTile
		ASL A
		TAX
		LDA.l .TileTranslation,x : BMI .Fail		; some values are invalid
		JSR CHANGE_MAP16
	.Fail	PLP
		PLX
		RTL

	.NetDoor
		PLP
		PLX
		RTL

	.TileTranslation
		dw $FFFF,$0025,$0025,$0006,$0049,$0048,$002B,$00A2	; 00-07
		dw $00C6,$0152,$011B,$0123,$011E,$0132,$0113,$0115	; 08-0F
		dw $0116,$012B,$012C,$0112,$0168,$0169,$0132,$015E	; 10-17



;==================;
;FADE LIGHT ROUTINE;
;==================;
; this routine will fade !LightR/G/B to the values in $00-$05
FADE_LIGHT:
		LDA !LightR
		CMP $00 : BEQ .RDone
		BCC .Rp
	.Rm	DEC #2
	.Rp	INC A
		STA !LightR
	.RDone
		LDA !LightG
		CMP $02 : BEQ .GDone
		BCC .Gp
	.Gm	DEC #2
	.Gp	INC A
		STA !LightG
	.GDone
		LDA !LightB
		CMP $04 : BEQ .BDone
		BCC .Bp
	.Bm	DEC #2
	.Bp	INC A
		STA !LightB
	.BDone
		RTS



;==============;
;PARTICLE CODES;
;==============;
GET_PARTICLE_INDEX:
		SEP #$20
		LDA #$41
		PHA : PLB
		REP #$30
		LDY.w #!Particle_Count-1
		LDA.l !Particle_Index : TAX

	.CheckIndex
		LDA !Particle_Type,x
		AND #$007F : BEQ .ThisOne

	.SearchForward
		TXA
		CLC : ADC.w #!Particle_Size
		CMP.w #!Particle_Size*!Particle_Count
		BCC $03 : LDA #$0000
		TAX
		DEY : BPL .CheckIndex

	.ThisOne
		TXA : STA.l !Particle_Index			; save index so we don't repeatedly check slots we have already confirmed are in use
		RTS


;=====================;
;HURT PLAYER 2 ROUTINE;
;=====================;
; bit 01 set: hurt player 1
; bit 02 set: hurt player 2
; (both can be set to hurt both players at once)
HurtPlayers:	LDY #$00				; > index 0
		LSR A : BCC +
		PHA
		LDA !CurrentMario
		CMP #$01 : BNE ++
		LDA $7497 : BNE +++
		JSR HurtP1_Mario			; > hurt Mario (P1, Y is already 0x00)
		BRA +++
	++	JSR HurtP1
	+++	PLA
	+	LSR A : BCC .Nope
		LDA !CurrentMario
		CMP #$02 : BNE HurtP2
		LDA $7497 : BNE .Nope
		LDY #$80 : JSR HurtP1_Mario		; > hurt Mario (P2)
.Nope		RTS



HurtP2:		LDY #$80				; > P2 index
HurtP1:		LDA !P2Invinc-$80,y			;\
		ORA !StarTimer				; | don't hurt player while star is active or player is invulnerable
		BNE .Return				;/

		LDA !P2Character-$80,y			;\
		ASL A					; |
		CMP.b #.Ptr_End-.Ptr			; |
		BCC $02 : LDA #$00			; | execute pointer
		TAX					; |
		LDA #$00				; > A = 0x00 so we can "STZ"
		JSR (.Ptr,x)				;/

		LDA #$F8 : STA !P2YSpeed-$80,y		; give player some Y speed
		LDA #$20 : STA !SPC1			; play Yoshi "OW" SFX
		LDA #$80 : STA !P2Invinc-$80,y		; set invincibility timer

		LDA !P2HP-$80,y				;\
		DEC A					; |
		STA !P2HP-$80,y				; | decrement HP and kill player 2 if zero
		BEQ .Kill				; |
		BMI .Kill				;/
		LDA #$0F : STA !P2HurtTimer-$80,y	;\ if player didn't die: set hurt animation timer and return
		RTS					;/

.Kill		LDA #$01 : STA !P2Status-$80,y		; > This player dies
		LDA #$C0 : STA !P2YSpeed-$80,y
		LDA !P2Status-$80 : BEQ .Return		;\ (this is actually correct! note the absent ",y")
		LDA !MultiPlayer : BEQ .Music		; | (ignore p2 on singleplayer)
		LDA !P2Status : BEQ .Return		; | If both players are dead, play death music
.Music		LDA #$01 : STA !SPC3			; |
		LDA #$FF : STA !MusicBackup		;/
		REP #$20				;\
		STZ !P1Coins				; | players lose all coins upon death
		STZ !P2Coins				; |
		SEP #$20				;/
.Return		RTS


		.Ptr
		dw .Mario		; 0
		dw .Luigi		; 1
		dw .Kadaal		; 2
		dw .Leeway		; 3
		dw .Alter		; 4
		dw .Peach		; 5
		..End

		.Mario
		LDA $19					;\
		BEQ $02 : LDA #$01			; | mario HP
		STA !P2HP-$80,y				;/
		LDA #$00				; A = 0x00
		STA !P2FastSwim-$80,y			;\ end fast swim
		STA !P2FastSwimAnim-$80,y		;/
		STA !P2FlareDrill-$80,y			; end flare drill
		STA !P2HangFromLedge-$80,y		; fall if hanging from ledge
		JSL !HurtMario				; hurt mario
		RTS

		.Luigi
		STA !P2FireTimer-$80,y			; reset fire timer
		STA !P2PickUp-$80,y			; end pickup animation
		STA !P2SpinAttack-$80,y			; end spin attack
		STA !P2KickTimer-$80,y			; end kick animation
		STA !P2TurnTimer-$80,y			; end turn animation
		RTS

		.Kadaal
		STA !P2Punch1-$80,y			;\ punch timers
		STA !P2Punch2-$80,y			;/
		STA !P2ShellSlide-$80,y			; end shell slide
		STA !P2ShellSpin-$80,y			; end shell spin attack
		STA !P2ShellSpeed-$80,y			; end fast shell slide status
		STA !P2Senku-$80,y			; end senku
		STA !P2AllRangeSenku-$80,y		; reset all range senku
		STA !P2SenkuSmash-$80,y			; end senku smash
		STA !P2ShellDrill-$80,y			; end shell drill
		STA !P2BackDash-$80,y			; end back dash
		RTS

		.Leeway
		STA !P2SwordAttack-$80,y		;\ end sword attack
		STA !P2SwordTimer-$80,y			;/
		STA !P2CrouchTimer-$80,y		; reset crouch timer
		STA !P2WallJumpInput-$80,y		;\ reset wall jump effect
		STA !P2WallJumpInputTimer-$80,y		;/
		STA !P2DashSlash-$80,y			; refund dash slash
		STA !P2ComboDash-$80,y			; clear combo flag (can't combo out of getting hit)
		STA !P2ComboDisable-$80,y		; clear combo used flag
		STA !P2WallClimb-$80,y			; fall off if climbing
		STA !P2WallClimbFirst-$80,y		; end climb start
		STA !P2WallClimbTop-$80,y		; end getup
		RTS

		.Alter
		RTS

		.Peach
		RTS







; Clipping 1:
; $00,$08: Xpos
; $01,$09: Ypos
; $02,$03: Dimensions
; Clipping 2:
; $04,$0A: Xpos
; $05,$0B: Ypos
; $06,$07: Dimensions
;
; $0C-$0F is used by this routine
;==================================;
;IMPROVED CONTACT DETECTION ROUTINE;
;==================================;
CONTACT16:
		PHX
		LDX #$01
	-	LDA $00,x : STA $0C	;\ Pos1 in $0C
		LDA $08,x : STA $0D	;/
		LDA $0A,x : XBA
		LDA $04,x
		REP #$20
		STA $0E			; > Pos2 in $0E
		LDA $02,x		;\
		AND #$00FF		; | Pos1 + Dim1 - Pos2
		CLC : ADC $0C		; |
		CMP $0E			;/
		BCC .Return		; > Return if smaller
		LDA $06,x		;\
		AND #$00FF		; | Pos2 + Dim2 - Pos1
		CLC : ADC $0E		; |
		CMP $0C			;/
		BCC .Return		; > Return if smaller
		SEP #$20
		DEX : BPL -		; > Check Y coordinates/height too
		PLX
		RTS

		.Return
		SEP #$20
		PLX
		RTS



;==============================;
;ROUTINES FOR HSL FORMAT COLORS;
;==============================;
;
; these codes will convert colors between RGB and HSL format
; RGB colors are stored at $6703 (like normal) and HSL colors are stored at !PaletteHSL
; the HSL section is 1KB long, with the first 768 bytes holding HSL mirrors of the RGB palette
; the last 256 bytes is scratch RAM / cache for processing HSL colors without overwriting stuff
;
; input:
;	A = color balance (00-1F between palette and buffer, used in mixers only)
;	X = color index (00-FF for colors 00-FF, 100-2FF to index HSL cache and buffer)
;	Y = number of colors to convert (00 or 100+ will convert entire palette)
;	8-bit and 16-bit modes are both accepted
;
; output:
;	for RGB to HSL, color is written to !PaletteHSL
;	for HSL to RGB, color is written to buffer at !PaletteHSL+$900 (also uploaded to CGRAM if _Upload version is used)
;	for RGB mixer, colors are written to buffer at !PaletteHSL+$900 (also uploaded to CGRAM if _Upload version is used)
;	for HSL mixer, colors from !PaletteHSL and !PaletteHSL+$300 are mixed and written to !PaletteHSL+$600
;
; scratch RAM use:
;	$00 = R
;	$02 = G
;	$04 = B
;	$06 = D
;	$08 = scratch
;	$0A = H + scratch
;	$0C = S + scratch
;	$0E = L
;
; HSL format:
;	3 bytes per color
;	$00 H: 0-239 with R pole at 0/240, G pole at 80, B pole at 160
;	$01 S: 0-63
;	$02 L: 0-63
;




	!color1		= !BigRAM+$00
	!color2		= !BigRAM+$02
	!color3		= !BigRAM+$04
	!colorloop	= !BigRAM+$06
	!colormix	= !BigRAM+$08	; uses 4 bytes

RGBtoHSL:
		PHP
		REP #$30
		CPY #$0000 : BEQ .Full
		CPY #$0100 : BCC .NotFull
	.Full	LDY #$0100
	.NotFull
		DEY
		STY !colorloop


; during the process, Y will index the RGB palette and X will index the HSL palette

		STX $00
		TXA
		ASL A
		TAY
		ADC $00
		TAX
		TYA
		AND #$01FF
		TAY


		TSC
		AND #$FF00
		CMP #$3700 : BEQ .Go
		STX $00
		STY $02
		SEP #$30
		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JSR $1E80
		PLP
		RTS

	.SA1
		PHB : PHK : PLB
		PEA.w ..return-1
		PHP
		REP #$30
		LDX $00
		LDY $02
		BRA .Go
		..return
		PLB
		RTL

	.Go

	-	CPY #$01FE			;\
		BCC $03 : LDY #$01FE		; | cap overflow
		CPX #$08FD			; |
		BCC $03 : LDX #$08FD		;/

		LDA $6703,y			;\
		AND #$001F			; | R
		STA $00				;/
		LDA $6703,y			;\
		LSR #5				; | G
		AND #$001F			; |
		STA $02				;/
		LDA $6703,y			;\
		XBA				; |
		LSR #2				; | B
		AND #$001F			; |
		STA $04				;/

		PHY
		TYA
		ASL #3
		XBA
		AND #$000F
		TAY
		LDA !LightList,y
		AND #$00FF
		CMP #$0001 : BNE ++
		LDA #$0100
		CMP !LightR : BNE +
		CMP !LightG : BNE +
		CMP !LightB : BEQ ++
	+	JSR ApplyLight
	++	JSR .Convert
		PLY

		SEP #$20
		LDA $0A : STA !PaletteHSL,x
		LDA $0C : STA !PaletteHSL+1,x
		LDA $0E : STA !PaletteHSL+2,x
		REP #$20

		INY #2
		INX #3
		DEC !colorloop : BPL -

		PLP
		RTS




; this code will convert RGB to HSL
	.Convert
		LDA $00
		CMP $02 : BCC .G
		CMP $04 : BCC .B
	.R	LDA $02
		CMP $04 : BCC .RBG
	.RGB	LDA $00				;\
		SEC : SBC $04			; |
		BRA +				; | get D (R greatest)
	.RBG	LDA $00				; |
		SEC : SBC $02			; |
	+	STA $06				;/
		LDA $02 : STA $08
		LDA $04 : STA $0A
		LDA #$0000
		BRA .LoadEquation

	.G	LDA $02
		CMP $04 : BCC .B
		LDA $00
		CMP $04 : BCC .GBR
	.GRB	LDA $02				;\
		SEC : SBC $04			; |
		BRA +				; | get D (G greatest)
	.GBR	LDA $02				; |
		SEC : SBC $00			; |
	+	STA $06				;/
		LDA $04 : STA $08
		LDA $00 : STA $0A
		LDA #$0050
		BRA .LoadEquation

	.B	LDA $00
		CMP $02 : BCC .BGR
	.BRG	LDA $04				;\
		SEC : SBC $02			; |
		BRA +				; | get D (B greatest)
	.BGR	LDA $04				; |
		SEC : SBC $00			; |
	+	STA $06				;/
		LDA $00 : STA $08
		LDA $02 : STA $0A
		LDA #$00A0

	.LoadEquation
		STA $0C
		SEP #$20
		STZ $2250
		REP #$20
		LDA $08
		SEC : SBC $0A
		STA $2251
		LDA #$0028 : STA $2253
		BRA $00 : NOP
		LDA $2306 : STA $2251
		SEP #$20
		LDA #$01 : STA $2250
		REP #$20
		LDA $06 : STA $2253
		NOP
		LDA $0C
		CLC : ADC $2306
		BPL $04 : CLC : ADC #$00F0
		CMP #$00F0
		BCC $03 : SBC #$00F0
		STA $0A				; H get!

	.SortColors
		LDA $00
		CMP $02 : BCC ..NotR
		CMP $04 : BCC ..NotR
		STA !color1			; greatest color = R
		LDA $02
		CMP $04 : BCC ..RBG
	..RGB	STA !color2
		LDA $04 : STA !color3
		BRA .ColorsDone
	..RBG	STA !color3
		LDA $04 : STA !color2
		BRA .ColorsDone

	..NotR	LDA $02
		CMP $04 : BCC ..NotG
		STA !color1
		LDA $00
		CMP $04 : BCC ..GBR
	..GRB	STA !color2
		LDA $04 : STA !color3
		BRA .ColorsDone
	..GBR	STA !color3
		LDA $04 : STA !color2
		BRA .ColorsDone

	..NotG	LDA $04 : STA !color1
		LDA $00
		CMP $02 : BCC ..BGR
	..BRG	STA !color2
		LDA $02 : STA !color3
		BRA .ColorsDone
	..BGR	STA !color3
		LDA $02 : STA !color2

	.ColorsDone
		LDA !color1
		CLC : ADC !color3
	;	LSR A
		STA $0E				; L get!

		SEP #$20
		STZ $2250
		REP #$20
		LDA $06 : STA $2251
		LDA #$003F : STA $2253
		BRA $00 : NOP
		LDA $2306 : STA $2251
		SEP #$20
		LDA #$01 : STA $2250
		REP #$20
		LDA $0E
		ASL A
		SEC : SBC #$003F
		BPL $04 : EOR #$FFFF : INC A
		SEC : SBC #$003F
		EOR #$FFFF : INC A
		STA $2253
		BRA $00 : NOP
		LDA $2306
		ASL A
		STA $0C				; S get!

		RTS


HSLtoRGB:
		PHP
		REP #$30
		CPY #$0000 : BEQ .Full
		CPY #$0100 : BCC .NotFull
	.Full	LDY #$0100
	.NotFull
		TYA
		ASL A
		DEY
		STY !colorloop
		STA !colormix				; save this for CGRAM upload
		STX !colormix+2				; save this for CGRAM upload

; during the process, Y will index the RGB palette and X will index the HSL palette

		STX $00
		TXA
		ASL A
		TAY
		ADC $00
		TAX
		TYA
		AND #$01FF
		TAY


		TSC
		AND #$FF00
		CMP #$3700 : BEQ .Go
		STX $00
		STY $02
		SEP #$30
		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JSR $1E80
		PLP
		RTS

	.SA1
		PHB : PHK : PLB
		PEA.w ..return-1
		PHP
		REP #$30
		LDX $00
		LDY $02
		BRA .Go
		..return
		PLB
		RTL

	.Go
	-	CPY #$01FE			;\
		BCC $03 : LDY #$01FE		; | cap overflow
		CPX #$08FD			; |
		BCC $03 : LDX #$08FD		;/

		LDA !PaletteHSL,x		;\
		AND #$00FF			; | H
		STA $0A				;/
		LDA !PaletteHSL+1,x		;\
		AND #$00FF			; | S
		STA $0C				;/
		LDA !PaletteHSL+2,x		;\
		AND #$00FF			; | L
		STA $0E				;/

		JSR .Convert
		PHY
		TYA
		ASL #3
		XBA
		AND #$000F
		TAY
		LDA !LightList-1,y : BPL ++
		LDA #$0100
		CMP !LightR : BNE +
		CMP !LightG : BNE +
		CMP !LightB : BEQ ++
	+	JSR ApplyLight
	++	PLY

		PHX
		TYX
		LDA $04				;\
		ASL #5				; |
		ORA $02				; | assemble RGB
		ASL #5				; |
		ORA $00				; |
		STA !PaletteHSL+$900,x		;/
		PLX

		INY #2
		INX #3
		DEC !colorloop : BPL -


		SEP #$30
		JSR GET_CGRAM
		LDA.b #!VRAMbank
		PHA : PLB
		LDA.b #!PaletteHSL>>16 : STA !CGRAMtable+$04,y	; bank (VRAM bank)
		LDA.l !colormix+2 : STA !CGRAMtable+$05,y	; dest CGRAM
		REP #$20
		AND #$00FF
		ASL A
		ADC.w #!PaletteHSL+$900
		STA !CGRAMtable+$02,y				; source address
		LDA.l !colormix : STA !CGRAMtable+$00,y		; upload size

	; leave bank because the end of the wrapper is after the RTS anyway

		PLP
		RTS



; this code will convert HSL to RGB
	.Convert
		SEP #$20
		STZ $2250
		REP #$20
		LDA $0E
		ASL A
		SEC : SBC #$003F
		BPL $04 : EOR #$FFFF : INC A
		SEC : SBC #$003F
		EOR #$FFFF : INC A
		STA $2251
		LDA $0C : STA $2253
		BRA $00 : NOP
		LDA $2306
		LSR #7
		STA !color1			; strongest color

; formula here is:
; (63 - pos(2L - 63)) x S / 128



		; get H / 20, but fractions
		; so 256 x H / 20

		SEP #$20
		LDA #$01 : STA $2250
		REP #$20
		LDA $0A
		XBA
		LSR A
		STA $2251
		LDA #$0028 : STA $2253
		BRA $00 : NOP
		LDA $2306
		ASL A
		AND #$01FF
		SEC : SBC #$0100
		BPL $04 : EOR #$FFFF : INC A
		SEC : SBC #$0100
		EOR #$FFFF : INC A
		STA $2251
		SEP #$20
		STZ $2250
		REP #$20
		LDA !color1 : STA $2253
		BRA $00 : NOP
		LDA $2307 : STA !color2		; middle color

; factor:
; 1 - pos((H / 40) mod2 - 1)
;
; 256 - pos((H / 40) mod 512 - 256)
		LDA $0E
	;	ASL A
		SEC : SBC !color1
		LSR A
		STA !color3			; weakest color
		CLC : ADC !color1		;\ complete strongest color
		STA !color1			;/
		LDA !color3			;\
		CLC : ADC !color2		; | complete middle color
		STA !color2			;/

		LDA $0A
		CMP #$0028 : BCC .RGB
		CMP #$0050 : BCC .GRB
		CMP #$0078 : BCC .GBR
		CMP #$00A0 : BCC .BGR
		CMP #$00C8 : BCC .BRG

	.RBG	LDA !color1 : STA $00
		LDA !color2 : STA $04
		LDA !color3 : STA $02
		RTS

	.RGB	LDA !color1 : STA $00
		LDA !color2 : STA $02
		LDA !color3 : STA $04
		RTS

	.GRB	LDA !color1 : STA $02
		LDA !color2 : STA $00
		LDA !color3 : STA $04
		RTS

	.GBR	LDA !color1 : STA $02
		LDA !color2 : STA $04
		LDA !color3 : STA $00
		RTS

	.BGR	LDA !color1 : STA $04
		LDA !color2 : STA $02
		LDA !color3 : STA $00
		RTS

	.BRG	LDA !color1 : STA $04
		LDA !color2 : STA $00
		LDA !color3 : STA $02
		RTS


MixRGB:
		PHP
		REP #$30
		AND #$00FF
		CMP #$0020
		BCC $03 : LDA #$0020
		STA !colormix
		LDA #$0020
		SEC : SBC !colormix
		STA !colormix+2
		CPY #$0000 : BEQ .Full
		CPY #$0100 : BCC .NotFull
	.Full	LDY #$0100
	.NotFull
		DEY
		STY !colorloop

; during the process, only X is required for indexing

		TXA
		ASL A
		TAX

		TSC
		AND #$FF00
		CMP #$3700 : BEQ .Go
		STX $00
		SEP #$30
		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JSR $1E80
		PLP
		RTS

	.SA1
		PHB : PHK : PLB
		PEA.w ..return-1
		PHP
		REP #$30
		LDX $00
		BRA .Go
		..return
		PLB
		RTL

	.Go

		SEP #$20			;\
		STZ $2250			; | prepare multiplication
		REP #$20			;/

	-	CPX #$01FE			;\ cap overflow
		BCC $03 : LDX #$01FE		;/

		LDA $6703,x			;\
		AND #$001F			; |
		STA $2251			; | R
		LDA !colormix : STA $2253	; |
		BRA $00 : NOP			; |
		LDA $2306 : STA $00		;/
		LDA $6703,x			;\
		LSR #5				; |
		AND #$001F			; |
		STA $2251			; | G
		LDA !colormix : STA $2253	; |
		BRA $00 : NOP			; |
		LDA $2306 : STA $02		;/
		LDA $6703,x			;\
		XBA				; |
		LSR #2				; |
		AND #$001F			; | B
		STA $2251			; |
		LDA !colormix : STA $2253	; |
		BRA $00 : NOP			; |
		LDA $2306 : STA $04		;/

		LDA !PaletteHSL+$900,x		;\
		AND #$001F			; |
		STA $2251			; |
		LDA !colormix+2 : STA $2253	; |
		BRA $00 : NOP			; | mix R
		LDA $2306			; |
		CLC : ADC $00			; |
		LSR #5				; |
		STA $00				;/
		LDA !PaletteHSL+$900,x		;\
		LSR #5				; |
		AND #$001F			; |
		STA $2251			; |
		LDA !colormix+2 : STA $2253	; | mix G
		BRA $00 : NOP			; |
		LDA $2306			; |
		CLC : ADC $02			; |
		LSR #5				; |
		STA $02				;/
		LDA !PaletteHSL+$900,x		;\
		XBA				; |
		LSR #2				; |
		AND #$001F			; |
		STA $2251			; | mix B
		LDA !colormix+2 : STA $2253	; |
		BRA $00 : NOP			; |
		LDA $2306			; |
		CLC : ADC $04			;/

		AND #$03E0			;\
		ORA $02				; |
		ASL #5				; | assemble and store mixed color
		ORA $00				; |
		STA !PaletteHSL+$900,x		;/


		INX #2
		DEC !colorloop : BMI $03 : JMP -


		PLP
		RTS



.Upload
		PHB : PHK : PLB
		PHP
		REP #$10
		PHX
		PHY
		JSR MixRGB

		REP #$20
		PLA
		ASL A
		STA !colormix
		PLA : STA !colormix+2

		SEP #$30
		JSR GET_CGRAM
		LDA.b #!VRAMbank
		PHA : PLB
		LDA.b #!PaletteHSL>>16 : STA !CGRAMtable+$04,y	; bank (VRAM bank)
		LDA.l !colormix+2 : STA !CGRAMtable+$05,y	; dest CGRAM
		REP #$20
		AND #$00FF
		ASL A
		ADC.w #!PaletteHSL+$900
		STA !CGRAMtable+$02,y				; source address
		LDA.l !colormix : STA !CGRAMtable+$00,y		; upload size


		PLP
		PLB
		RTS


MixHSL:
		PHP
		REP #$30
		AND #$00FF
		STA !colormix
		LDA #$00FF
		SEC : SBC !colormix
		STA !colormix+2
		CPY #$0000 : BEQ .Full
		CPY #$0100 : BCC .NotFull
	.Full	LDY #$0100
	.NotFull
		DEY
		STY !colorloop

; during the process, only X is required for indexing

		TXA
		STA $00
		ASL A
		CLC : ADC $00
		TAX

		TSC
		AND #$FF00
		CMP #$3700 : BEQ .Go
		STX $00
		SEP #$30
		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JSR $1E80
		PLP
		RTS

	.SA1
		PHB : PHK : PLB
		PEA.w ..return-1
		PHP
		REP #$30
		LDX $00
		BRA .Go
		..return
		PLB
		RTL

	.Go
		SEP #$20			;\
		STZ $2250			; | prepare multiplication
		REP #$20			;/

; 00 -> 20	+20 / m
; 00 -> 68	-10 / m
; 70 -> 68	-8 / m
;
;
;
; $00	hue 1
; $02	hue 2
; $08	hue 1 - hue 2
; $0A	hue 2 - hue 1
; $0E	|hue 2 - hue 1|

	.Loop	CPX #$02FD			;\ cap overflow
		BCC $03 : LDX #$02FD		;/
		LDA !PaletteHSL,x
		AND #$00FF
		STA $0A
		LDA !PaletteHSL+$300,x
		AND #$00FF
		SEC : SBC $0A
		STA $0C
		BMI .Calc
		CMP #$0078 : BCC .Calc

	.CClock	LDA #$00F0
		SEC : SBC $0C
		EOR #$FFFF : INC A

	.Calc	STA $2251
		LDA !colormix+2 : STA $2253		; amount to add is based on 32-m
		NOP : BRA $00
		LDA $2306 : BPL +
		EOR #$FFFF : INC A
		XBA : AND #$00FF
		EOR #$FFFF : INC A
		BRA ++
	+	XBA : AND #$00FF
	++	CLC : ADC $0A
		BPL $04 : CLC : ADC #$00F0
	-	CMP #$00F0 : BCC +
		SBC #$00F0 : BRA -
	+	STA $0A


		LDA !PaletteHSL+1,x			;\
		AND #$00FF				; |
		STA $2251				; |
		LDA !colormix : STA $2253		; |
		BRA $00 : NOP				; |
		LDA $2306 : STA $0C			; |
		LDA !PaletteHSL+$301,x			; |
		AND #$00FF				; | calculate S as m*S1 + (32-m)*S2
		STA $2251				; |
		LDA !colormix+2 : STA $2253		; |
		BRA $00 : NOP				; |
		LDA $2306				; |
		CLC : ADC $0C				; |
		XBA : AND #$00FF			; |
		STA $0C					;/
		LDA !PaletteHSL+2,x			;\
		AND #$00FF				; |
		STA $2251				; |
		LDA !colormix : STA $2253		; |
		BRA $00 : NOP				; |
		LDA $2306 : STA $0E			; |
		LDA !PaletteHSL+$302,x			; |
		AND #$00FF				; | calculate L as m*L1 + (32-m)*L2
		STA $2251				; |
		LDA !colormix+2 : STA $2253		; |
		BRA $00 : NOP				; |
		LDA $2306				; |
		CLC : ADC $0E				; |
		XBA : AND #$00FF			; |
		STA $0E					;/

		SEP #$20				;\
		LDA $0A : STA !PaletteHSL+$600,x	; |
		LDA $0C : STA !PaletteHSL+$601,x	; | assemble HSL
		LDA $0E : STA !PaletteHSL+$602,x	; |
		REP #$20				;/

		INX #3
		DEC !colorloop : BMI $03 : JMP .Loop

		PLP
		RTS


	.Upload
		PHB : PHK : PLB
		PHP
		PHX
		PHY
		JSR MixHSL
		PLY
		PLX
		REP #$30
		TXA
		AND #$00FF
		ORA #$0200				; HSL mix output buffer
		TAX
		JSR HSLtoRGB
		PLP
		PLB
		RTS



ApplyLight:
; $00: R
; $02: G
; $04: B
		STZ $2250
		LDA !LightR : STA $2251
		LDA $00 : STA $2253
		NOP : BRA $00
		LDA $2307 : STA $00
		LDA !LightG : STA $2251
		LDA $02 : STA $2253
		NOP : BRA $00
		LDA $2307 : STA $02
		LDA !LightB : STA $2251
		LDA $04 : STA $2253
		NOP : BRA $00
		LDA $2307 : STA $04
		RTS



;===================;
;JOINT CLUSTER CODES;
;===================;

; -- macros --



; input:
;	A = angle (0-1023 is a full rotation)
; output:
;	A = sine value
	macro Trig()
		PHX
		ASL #2
		AND #$03FF
		CMP #$0200
		PHP
		AND #$01FF
		TAX
		LDA.l !TrigTable,x
		PLP
		BCC $04 : EOR #$FFFF : INC A
		PLX
	endmacro

; input:
;	cache1 = coordinate 1
;	cache2 = coordinate 2
;	cache3 = coordinate 3
;	cache4 = coordinate 4
;	cache5 = angle
;
; output:
;	cache7 = coordinate 1
;	cache8 = coordinate 2
	macro Apply3DRotation()
		PHB : PHK : PLB
		LDA !3D_Cache5
		PHA
		CLC : ADC #$0040
		%Trig()
		STA !3D_Cache6			; cache2 = cos(a)
		PLA
		%Trig()
		STA !3D_Cache5			; cache1 = sin(a)

		LDA !3D_Cache6 : STA $2251
		LDA !3D_Cache1 : STA $2253
		NOP : BRA $00
		LDA $2307 : STA $06
	;	LDA $2306
	;	AND #$00FF
	;	CMP #$0080
	;	BCC $02 : INC $06			; $06 = product 1
		LDA !3D_Cache5 : STA $2251
		LDA !3D_Cache2 : STA $2253
		NOP : BRA $00
		LDA $2307 : STA $08
	;	LDA $2306
	;	AND #$00FF
	;	CMP #$0080
	;	BCC $02 : INC $08			; $08 = product 2
		LDA $06
		CLC : ADC $08
		STA !3D_Cache7			; cache7 = coordinate 1 (X or Y)

		LDA !3D_Cache5 : STA $2251
		LDA !3D_Cache3 : STA $2253
		NOP : BRA $00
		LDA $2307 : STA $06
	;	LDA $2306
	;	AND #$00FF
	;	CMP #$0080
	;	BCC $02 : INC $06			; $06 = product 3
		LDA !3D_Cache6 : STA $2251
		LDA !3D_Cache4 : STA $2253
		NOP : BRA $00
		LDA $2307 : STA $08
	;	LDA $2306
	;	AND #$00FF
	;	CMP #$0080
	;	BCC $02 : INC $08			; $08 = product 4
		LDA $06
		CLC : ADC $08
		STA !3D_Cache8			; cache8 = coordinate 2 (Y or Z)
		PLB
	endmacro



UPDATE_3D_CLUSTER:

	; can only be called by SA-1

	; input: A = xflip bit (usually from $3320,x, 0 to not use)

	; $00-$01: parent X position (16-bit)
	; $02-$03: parent Y position (16-bit)
	; $04-$05: parent Z position (16-bit)
	; $06-$07: calculating X position (16-bit)
	; $08-$09: calculating Y position (16-bit)
	; $0A-$0B: calculating Z position (16-bit)

	; Each parent position is pushed on the stack, then loaded into $06-$0B


; Start processing from index 0 and go all the way up
; The core has to be the first (lowest index) object of each cluster.
; Only the core has a true X/Y/Z coordinate.
; When an attachment is processed, its X/Y/Z coordinates are stored based on the parent's X/Y/Z coordinates.
; Therefore, each attachment must be processed after its parent.

		LSR A					;\
		ROR A					; |
		LSR A					; | xflip flag
		AND #$40				; |
		STA !BigRAM+$7F				;/

		PHB : PHB				;\ bank on stack and in cache
		PLA : STA.l !3D_BankCache		;/
		PHX					;\ back up X/P
		PHP					;/
		STZ $2250				; prepare multiplication
		LDA.b #!3D_Base>>16			;\ DB
		PHA : PLB				;/
		REP #$30				; all regs 16-bit

		PEI ($F0)
		PEI ($F2)
		PEI ($F4)
		PEI ($F6)
		PEI ($F8)
		PEI ($FA)
		PEI ($FC)
		PEI ($FE)



	; processing, step 1
	; here go through the tree of joints, calculating the coordinates of each one
	; core rotation is not yet applied

		LDX #$0000				;\
		LDY #$0000				; |
	-	LDA.w !3D_Slot,y			; |
		AND #$00FF : BEQ .Next			; | search for non-core joints
		TYA					; |
		CMP.w !3D_Attachment,y : BEQ .Core	; |
		LDX.w !3D_Attachment,y			;/
		JSR .UpdateJoint			; process joint
		BRA .Next				; then go to the next one
		.Core					;\
		PHY					; |
		LDA.w !3D_X,y : PHA			; | store core coordinates on the stack
		LDA.w !3D_Y,y : PHA			; |
		LDA.w !3D_Z,y : PHA			;/
		.Next					;\
		TYA					; |
		CLC : ADC #$0010			; | get next joint
		TAY					; |
		CPY #$0200 : BCC -			;/


	; processing, step 2
	; here, we go through the tree of joints again
	; this time we only apply core rotation

		PLA : STA $04
		PLA : STA $02
		PLA : STA $00
		PLX
		LDA.w !3D_AngleXY,x : BNE +		;\ skip rotation if no angles are set
		LDA.w !3D_AngleXZ,x : BEQ ++		;/
	+	JSR Transform3DCluster			; rotate around axes
	++

		STZ $0C
		LDX #$0000
		LDY #$0000
		STZ.w !3D_AssemblyCache			; how many objects will be added to tilemap
	-	LDA.w !3D_Slot,y : BEQ +
		LDA.w !3D_X,y
		SEC : SBC $00
		STA.w !3D_AssemblyCache+$02,x
		LDA.w !3D_Y,y
		SEC : SBC $02
		STA.w !3D_AssemblyCache+$03,x
		LDA.w !3D_Z,y
		AND #$00FF
		STA.w !3D_AssemblyCache+$04,x
		LDA.w !3D_Extra,y : STA.w !3D_AssemblyCache+$06,x
		INX #8
		STX.w !3D_AssemblyCache			; increment header
		INC $0C					; increment object count

	+	TYA
		CLC : ADC #$0010
		TAY
		CPY #$0200 : BCC -


	; processing, step 3
	; now all objects are in !3D_AssemblyCache
	; first 2 bytes is header
	; X is written to X+0
	; Y is written to X+1
	; Z is written to X+2
	; X+3 is clear (nonzero signals that this has been taken)
	; X+4 and X+5 is tilemap data
	; now we sort by Z value and transcribe the tilemaps from highest to lowest


	; key:
	; $0B = highest Z found so far
	; $0C = how many objects there are
	; $0D = how many objects have been transcribed
	; $0E = index of currently highest Z

		LDX #$0000
		LDY #$0000
		SEP #$20
		STZ $0B
		STZ $06						; for tilemap assembly

	.Loop	LDA.w !3D_AssemblyCache+$05,y : BNE +
		LDA.w !3D_AssemblyCache+$04,y
		CMP $0B : BCC +
		STA $0B
		STY $0E

	+	INY #8
		CPY.w !3D_AssemblyCache : BCC .Loop

	.Z	LDY $0E
		REP #$20
		LDA.w !3D_AssemblyCache+$02,y : STA $00		; X/Y offset
		STZ $02						; tile/prop data
		PHY
		LDA.w !3D_AssemblyCache+$06,y
		AND #$00FF
		ASL A
		TAY
		LDA.w !3D_TilemapPointer : STA $08
		SEP #$20
		PHB
		LDA.w !3D_BankCache : PHA : PLB
		REP #$20
		LDA ($08),y

	; add tilemap to !BigRAM here
		PHX
		PHP
		SEP #$10
		REP #$20
		LDX $06 : BNE .NotInit
		STZ !BigRAM+0
		.NotInit
		STA $04
		LDY #$00
		LDA ($04)
		AND #$00FF			; tilemap can not be larger than 256 bytes
		STA $08
		CLC : ADC !BigRAM+0
		STA !BigRAM+0
		INC $04
		LDA ($04)			; > get hi byte of header (GFX status to add)
		INC $04
		SEP #$20
		CMP #$00 : BEQ .LoopTM		; if index is 0, just start

		PEI ($00)			;\ back these up
		PHX				;/
		TAX				;\
		LDA !GFX_status,x		; |
		STZ $00				; |
		STA $01				; |
		AND #$70			; | unpack tile number offset
		ASL A				; |
		STA $00				; |
		LDA $01				; |
		AND #$0F			; |
		ORA $00				;/
		CLC : ADC $03			;\ store new tile number offset
		STA $03				;/
		LDA $01				;\
		ASL A				; |
		ROL A				; | store new property bits
		AND #$01			; |
		EOR $02				; |
		STA $02				;/
		PLX				;\
		REP #$20			; | restore these
		PLA : STA $00			; |
		SEP #$20			;/

	.LoopTM	LDA ($04),y			;\
		EOR $02				; | Prop
		STA !BigRAM+2,x			; |
		INY				;/
		LDA $00				;\
		BIT !BigRAM+$7F			; |
		BVC $02 : EOR #$FF		; > extra xflip to account for tilemap loader
		CLC : ADC ($04),y		; | X
		STA !BigRAM+3,x			; |
		INY				;/
		LDA ($04),y			;\
		CLC : ADC $01			; | Y
		STA !BigRAM+4,x			; |
		INY				;/
		LDA ($04),y			;\
		CLC : ADC $03			; | Tile
		STA !BigRAM+5,x			; |
		INY				;/
		INX #4
		CPY $08 : BCC .LoopTM
		STX $06
		PLP
		PLX

		PLB
		PLY
		SEP #$20
		STZ $0B
		INX #4
		LDA #$FF : STA.w !3D_AssemblyCache+$05,y
		LDY #$0000
		INC $0D
		LDA $0D
		CMP $0C : BEQ $03 : JMP .Loop



		.Return
		REP #$20
		PLA : STA $FE
		PLA : STA $FC
		PLA : STA $FA
		PLA : STA $F8
		PLA : STA $F6
		PLA : STA $F4
		PLA : STA $F2
		PLA : STA $F0
		PLP
		PLX
		PLB
		RTS





; process:
;
; z = d * cos(v)
; r = d * sin(v)
; x = r * cos(h)
; y = r * sin(h)
;
; add offsets to parent coordinates to get attachment coordinates

		.UpdateJoint
		LDA.w !3D_X,x : STA $00			;\
		LDA.w !3D_Y,x : STA $02			; | parent coordinates
		LDA.w !3D_Z,x : STA $04			;/
		PHY					;\
		PHP					; |
		SEP #$20				; |
		STZ $0D					; |
		STZ $0E					; | search for parent joint
		STZ $0F					; |
	-	STY $08					; |
		LDX.w !3D_Attachment,y			; |
		CPX $08 : BEQ +				;/
		STX $08					;\
		LDY.w !3D_Attachment,x			; | if parent is core, ignore its rotations for now
		CPY $08 : BEQ +				;/
		LDA.w !3D_AngleH,x			;\
		CLC : ADC $0E				; |
		STA $0E					; |
		LDA.w !3D_AngleV,x			; | add parent rotations...
		CLC : ADC $0F				; | ...and keep going up the tree all the way to the core
		STA $0F					; | this way we will get the full rotations no matter how long the chain is
		TXY					; |
		BRA -					;/
	+	PLP					;\ prepare index
		PLY					;/

		PHX					;\ preserve X and swap with Y so we can use more effective DB
		TYX					;/

		PHB : PHK : PLB				; bank wrapper start

		LDA !3D_AngleV,x			;\
		CLC : ADC $0F				; |
		PHA					; | get cosine of v
		CLC : ADC #$0040			; |
		%Trig()					;/
		STA $2251				;\
		LDA !3D_Distance,x : STA $2253		; | distance on XY plane
		NOP : BRA $00				; |
		LDA $2307 : STA $08			;/
	;	LDA $2306				;\
	;	AND #$00FF				; | round
	;	CMP #$0080				; | (do we really need this amount of precision?
	;	BCC $02 : INC $08			;/
		PLA					;\ get sine of v
		%Trig()					;/
		STA $2251				;\
		LDA !3D_Distance,x : STA $2253		; | Z coordinate
		NOP : BRA $00				; |
		LDA $2308 : STA $0A			;/
	;	LDA $2306				;\ round
	;	BPL $02 : INC $0A			;/

		LDA !3D_AngleH,x			;\
		CLC : ADC $0E				; |
		PHA					; | get cosine of h
		CLC : ADC #$0040			; |
		%Trig()					;/
		STA $2251				;\
		LDA $08 : STA $2253			; | X coordinate
		NOP : BRA $00				; |
		LDA $2308 : STA $06			;/
	;	LDA $2306				;\ round
	;	BPL $02 : INC $06			;/

		PLA					;\ get sine of h
		%Trig()					;/
		STA $2251				;\
		LDA $08 : STA $2253			; | Y coordinate
		NOP : BRA $00				; |
		LDA $2308 : STA $08			;/
	;	LDA $2306				;\ round
	;	BPL $02 : INC $08			;/

		PLB					; bank wrapper end
		LDA $06					;\
		CLC : ADC $00				; |
		STA.w !3D_X,y				; |
		LDA $08					; |
		CLC : ADC $02				; | add parent coords to offsets to get joint coords
		STA.w !3D_Y,y				; | (Y is unchanged so this is fine)
		LDA $0A					; |
		CLC : ADC $04				; |
		STA.w !3D_Z,y				;/
		PLX					; restore X
		RTS					; return




	Transform3DCluster:

		LDY #$0000

	.Loop	STY $0E
		CPX $0E : BNE .Process
		JMP .Next

		.Process
		LDA.w !3D_X,y
		SEC : SBC $00
		STA.w !3D_X,y
		LDA.w !3D_Y,y
		SEC : SBC $02
		STA.w !3D_Y,y
		LDA.w !3D_Z,y
		SEC : SBC $04
		STA.w !3D_Z,y
		LDA.w !3D_AngleXY,x			;\
		AND #$00FF : BNE .CalcXY		; |
		JMP .SkipXY				; |
		.CalcXY					; |
		LDA.w !3D_X,y				; |
		STA !3D_Cache1				; |
		STA !3D_Cache3				; |
		LDA.w !3D_Y,y				; |
		STA !3D_Cache4				; | rotation around z axis
		EOR #$FFFF : INC A			; |
		STA !3D_Cache2				; |
		LDA.w !3D_AngleXY,x : STA !3D_Cache5	; |
		%Apply3DRotation()			; |
		LDA !3D_Cache7 : STA.w !3D_X,y		; |
		LDA !3D_Cache8 : STA.w !3D_Y,y		; |
		.SkipXY					;/

		LDA.w !3D_AngleYZ,x			;\
		AND #$00FF : BNE .CalcYZ		; |
		JMP .SkipYZ				; |
		.CalcYZ					; |
		LDA.w !3D_Y,y				; |
		STA !3D_Cache1				; |
		STA !3D_Cache3				; |
		LDA.w !3D_Z,y				; |
		STA !3D_Cache4				; | rotation around x axis
		EOR #$FFFF : INC A			; |
		STA !3D_Cache2				; |
		LDA.w !3D_AngleYZ,x : STA !3D_Cache5	; |
		%Apply3DRotation()			; |
		LDA !3D_Cache7 : STA.w !3D_Y,y		; |
		LDA !3D_Cache8 : STA.w !3D_Z,y		; |
		.SkipYZ					;/

		LDA.w !3D_AngleXZ,x			;\
		AND #$00FF : BNE .CalcXZ		; |
		JMP .SkipXZ				; |
		.CalcXZ					; |
		LDA.w !3D_X,y				; |
		STA !3D_Cache1				; |
		EOR #$FFFF : INC A			; |
		STA !3D_Cache3				; |
		LDA.w !3D_Z,y				; | rotation around y axis
		STA !3D_Cache2				; |
		STA !3D_Cache4				; |
		LDA.w !3D_AngleXZ,x : STA !3D_Cache5	; |
		%Apply3DRotation()			; |
		LDA !3D_Cache7 : STA.w !3D_X,y		; |
		LDA !3D_Cache8 : STA.w !3D_Z,y		; |
		.SkipXZ					;/

		LDA.w !3D_X,y
		CLC : ADC $00
		STA.w !3D_X,y
		LDA.w !3D_Y,y
		CLC : ADC $02
		STA.w !3D_Y,y
		LDA.w !3D_Z,y
		CLC : ADC $04
		STA.w !3D_Z,y

		.Next
		TYA
		CLC : ADC #$0010
		TAY
		CPY #$0200 : BCS .Return
		JMP .Loop

		.Return
		RTS




; here, X indexes the current joint and Y indexes the parent joint
; before calling, store pointers to the tilemaps at !3D_TilemapCache and load A with $3320,x
	UPDATE_2D_CLUSTER:

		LSR A						;\
		ROR A						; |
		LSR A						; | xflip flag
		AND #$40					; |
		STA !BigRAM+$7F					;/

		PHB : PHB					;\ bank on stack and in cache
		PLA : STA.l !3D_BankCache			;/
		PHX						;\ back up X/P
		PHP						;/
		STZ $2250					; prepare multiplication
		LDA.b #!3D_Base>>16				;\ DB
		PHA : PLB					;/
		REP #$30					; all regs 16-bit
		STZ $06						; clear tilemap continue flag

		LDX #$0000					;\
		LDY #$0000					; |
	.Loop	LDA.w !2D_Slot,x				; | search for joints
		AND #$00FF : BNE .Process			; |
		JMP .Next					; |
		.Process					;/
		LDY.w !2D_Attachment,x				;\
		STY $00						; | core has no parent joint
		CPX $00 : BNE .Joint				; |
		JMP .Core					;/

	.Joint	SEP #$20					; A 8-bit
		LDA.w !2D_Rotation,y				;\
		CLC : ADC.w !2D_Angle,x				; | get total rotation
		STA.w !2D_Rotation,x				;/
		PHB : PHK : PLB					; start of bank wrapper
		REP #$20					; A 16-bit
		AND #$00FF					;\ full angle
		ASL #2						;/
		PHA						; preserve
		CLC : ADC #$0040					;\ cosine
		%Trig()						;/
		STA $2251					;\
		LDA !2D_Distance,x : STA $2253			; | X offset
		BRA $00 : NOP					; |
		LDA $2307 : STA $00				;/
		PLA						;\ sine
		%Trig()						;/
		STA $2251					;\
		LDA !2D_Distance,x : STA $2253			; | Y offset
		BRA $00 : NOP					; |	
		LDA $2307					;/
		PLB						; restore bank
		CLC : ADC.w !2D_Y,y				;\ store Y offset of joint
		STA.w !2D_Y,x					;/
		LDA $00						;\
		CLC : ADC.w !2D_X,y				; | store X offset of joint
		STA.w !2D_X,x					;/
		BRA .AppendTilemap				; go to tilemap code

	.Core	SEP #$20					;\
		LDA.w !2D_Angle,x : STA.w !2D_Rotation,x	; | save angle as total rotation
		REP #$20					;/

	.AppendTilemap
	; add tilemap to !BigRAM here
		LDA.w !2D_X,x					;\
		SEC : SBC.w !2D_X,y				; |
		STA $00						; |
		LDA.w !2D_Y,x					; | tilemap transcription parameters
		SEC : SBC.w !2D_Y,y				; |
		STA $01						; |
		STZ $02						;/
		LDA.w !2D_Tilemap,x				; A = tilemap index
		PHB : PHK : PLB					; start of bank wrapper
		PHX						; push X
		PHP						; push P
		SEP #$10					; index 8-bit
		REP #$20					; A 16-bit
		AND #$00FF					;\
		ASL A						; | get tilemap location
		TAX						; |
		LDA !3D_TilemapCache,x				;/
		LDX $06 : BNE .NotInit				;\
		STZ !BigRAM+0					; | check init
		.NotInit					;/
		STA $04						;\
		LDY #$00					; |
		LDA ($04)					; |
		AND #$00FF					; |
		STA $08						; |
		CLC : ADC !BigRAM+0				; | set up tilemap read and check for alt GFX index
		STA !BigRAM+0					; |
		INC $04						; |
		LDA ($04)					; |
		INC $04						; |
		SEP #$20					; |
		CMP #$00 : BEQ .LoopTM				;/

		PEI ($00)					;\ back these up
		PHX						;/
		TAX						;\
		LDA !GFX_status,x				; |
		STZ $00						; |
		STA $01						; |
		AND #$70					; | unpack tile number offset
		ASL A						; |
		STA $00						; |
		LDA $01						; |
		AND #$0F					; |
		ORA $00						;/
		CLC : ADC $03					;\ store new tile number offset
		STA $03						;/
		LDA $01						;\
		ASL A						; |
		ROL A						; | store new property bits
		AND #$01					; |
		EOR $02						; |
		STA $02						;/
		PLX						;\
		REP #$20					; | restore these
		PLA : STA $00					; |
		SEP #$20					;/

	.LoopTM	LDA ($04),y					;\
		EOR $02						; | prop
		STA !BigRAM+2,x					; |
		INY						;/
		LDA $00						;\
		BIT !BigRAM+$7F					; |
		BVC $02 : EOR #$FF				; > extra xflip to account for tilemap loader
		CLC : ADC ($04),y				; | X
		STA !BigRAM+3,x					; |
		INY						;/
		LDA ($04),y					;\
		CLC : ADC $01					; | Y
		STA !BigRAM+4,x					; |
		INY						;/
		LDA ($04),y					;\
		CLC : ADC $03					; | tile
		STA !BigRAM+5,x					; |
		INY						;/
		INX #4						;\ loop
		CPY $08 : BCC .LoopTM				;/
		STX $06						; save index
		PLP						; restore P
		PLX						; restore X
		PLB						; end of bank wrapper

	.Next	TXA						;\
		CLC : ADC #$000C				; |
		TAX						; | loop through entire table
		CPX #$0200 : BCS .Return			; |
		JMP .Loop					;/
		.Return						;\
		PLP						; |
		PLX						; | restore stuff and return
		PLB						; |
		RTS						;/





;================;
;GET FILE ADDRESS;
;================;

;
; how to use:
; load 16-bit Y (or 8-bit if index < 256) with file number
; then call here
; returns with !FileAddress set to the address of the file
;
; NOTE!!
; because file lists can change at any time, all file numbers should use a define
; NEVER hardcode a file number!!

GET_FILE_ADDRESS:
		PHB
		PHP
		REP #$10
		SEP #$20
		LDA.b #$30 : PHA : PLB				; bank
		REP #$20
		LDA.w $8409,y : STA.l !FileAddress+1
		LDA.w $8408,y : STA.l !FileAddress
		PLP
		PLB
		RTS


;===============;
;UPATE FROM FILE;
;===============;

UPDATE_FROM_FILE:
		PHB : PHK : PLB
		JSR GET_FILE_ADDRESS
		PLB

		PHP
		SEP #$30

		LDA !ClaimedGFX
		AND #$0F
		ASL A
		CMP #$10
		BCC $03 : CLC : ADC #$10
		STA $02
		LDA !GFX_Dynamic
		AND #$70
		ASL A
		ADC $02
		STA $02
		LDA !GFX_Dynamic
		AND #$0F
		CLC : ADC $02
		STA $02
		STZ $03
		LDA !GFX_Dynamic
		BPL $02 : INC $03

		PHX
		PHB
		JSR GET_VRAM
		PLB
		PHP
		REP #$30
		LDA $02					;\
		ASL #4					; | calculating this here is faster
		STA $02					;/
		LDA $0C : BEQ +				; return if dynamo is empty
		LDA ($0C) : BEQ +			; return if size is 0
		STA $00
		LDY #$0000
		INC $0C
		INC $0C
	-	LDA ($0C),y
		STA !VRAMbase+!VRAMtable+$00,x
		INY #2
		LDA ($0C),y
		CLC : ADC !FileAddress
		STA !VRAMbase+!VRAMtable+$02,x
		LDA !FileAddress+2 : STA !VRAMbase+!VRAMtable+$04,x
		INY #3
		LDA ($0C),y
		CLC : ADC $02
		STA !VRAMbase+!VRAMtable+$05,x
		INY #2
		CPY $00
		BCS +
		TXA
		CLC : ADC #$0007
		TAX
		BRA -

		+
		PLP
		PLX

		PLP
		RTS


;================;
;DECOMP FROM FILE;
;================;
DECOMP_FROM_FILE:

		PHB : PHK : PLB
		JSR GET_FILE_ADDRESS
		PLB

		PHP
		SEP #$30

		LDA !ClaimedGFX
		AND #$0F
		ASL A
		CMP #$10
		BCC $02 : ADC #$0F
		STA $02
		LDA !GFX_Dynamic
		AND #$70
		ASL A
		ADC $02
		STA $02
		LDA !GFX_Dynamic
		AND #$0F
		CLC : ADC $02
		STA $02
		STZ $03
		LDA !GFX_Dynamic
		BPL $02 : INC $03

		PHX
		PHB
		JSR GET_VRAM
		PLB
		PHP
		REP #$30
		LDA $02					;\
		ASL #4					; | this is just better to do here
		ORA #$6000				; |
		STA $02					;/
		LDA $0C : BEQ +				; return if dynamo is empty
		LDA ($0C)
		AND #$00FF : BEQ +			; return if size is 0
		STA $00
		LDY #$0000
		INC $0C					; increment past header (only 1 byte for compressed format)

	-	LDA ($0C),y
		AND #$001E
		ASL #4
		STA !VRAMbase+!VRAMtable+$00,x
		LDA ($0C),y
		AND #$7FE0
		CLC : ADC !FileAddress
		STA !VRAMbase+!VRAMtable+$02,x
		LDA !FileAddress+2 : STA !VRAMbase+!VRAMtable+$04,x
		INY #2
		LDA ($0C),y
		ASL #4
		AND #$0FF0
		CLC : ADC $02
		STA !VRAMbase+!VRAMtable+$05,x
		INY
		CPY $00 : BCS +
		TXA
		CLC : ADC #$0007
		TAX
		BRA -

		+
		PLP
		PLX

		PLP
		RTS

;=========;
;LOAD FILE;
;=========;
;
; input:
;	Y = file number
;	A = dest VRAM
;
LOAD_FILE:
		PHP
		PHA
		PHB : PHK : PLB
		JSR GET_FILE_ADDRESS
		PLB

		PHB
		JSR GET_VRAM
		PLB

		LDA !FileAddress : STA !VRAMbase+!VRAMtable+$02,x
		LDA !FileAddress+2 : STA !VRAMbase+!VRAMtable+$04,x
		PLA : STA !VRAMbase+!VRAMtable+$05,x
		LDA #$0800 : STA !VRAMbase+!VRAMtable+$00,x

		PLP
		RTS


;==========;
;SPRITE HUD;
;==========;
; input:
;	$00 - x offset
;	$01 - y offset
;	$02 - 16-bit tilemap pointer (X, Y, T, P)
;	$0D - size bit (same for all tiles)
;	$0E - byte count of tilemap

SPRITE_HUD:
		PHP
		SEP #$20
		STZ $0F
		REP #$30
		LDY #$0000
		LDA !OAMindex_p3 : TAX
	.Loop	LDA ($02),y
		CLC : ADC $00				; this works as long as X doesn't overflow
		STA !OAM_p3+$000,x
		INY #2
		LDA ($02),y : STA !OAM_p3+$002,x
		INY #2
		PHX
		TXA
		LSR #2
		TAX
		LDA $0D
		AND #$0002
		STA !OAMhi_p3+$00,x
		PLX
		INX #4
		CPY $0E : BCC .Loop
		TXA : STA !OAMindex_p3
		PLP
		RTS


;===========;
;LOAD SCREEN;
;===========;
LOAD_SCREEN:


;========;
;HDMA FIX;
;========;
; Disable HDMA during game mode 0x11

HDMA_FIX:

		.A
		LDA !GameMode
		CMP #$11
		BEQ ..Nope
		LDA $6D9F : STA $420C
		RTL
	..Nope	STZ $420C
		LDA #$00 : STA !DizzyEffect
		RTL

		.Y
		LDY !GameMode
		CPY #$11
		BEQ ..Nope
		LDY $6D9F : STY $420C
		RTL
	..Nope	LDY #$00 : STY $420C
		LDA #$00 : STA !DizzyEffect
		RTL



;================;
;CLEAR CHARACTERS;
;================;
;CLEAR_CHARACTERS:
;
;		LDA #$00			;\ Clear player 1 and 2 characters
;		STA !Characters			;/
;		STA !HDMAptr+0
;		STA !HDMAptr+1
;		STA !HDMAptr+2
;		STA !MultiPlayer		; > Disable Multiplayer
;
;		JSR CLEAR_VR2
;
;		LDY #$0C			;\ Overwritten code
;		LDX #$03			;/
;		RTL



;=========;
;KEEP DATA;
;=========;
KEEP_DATA:
	pushpc
	org $00A1B2
		JSL .Main			;\
		SEP #$10			; | org: LDX #$07CE : STZ $73D3,x : DEX
		RTS				;/ > (should return with index 8-bit)
	org $00A5E1
		BRA $04				; skip past a JSL inserted by Lunar Magic
						; org: NOP #2 : JSL $XXXXXX (all.log: LDA #$01EF : MVN $00,$00)
	pullpc
		.Main
		LDX #$0564
	-	STZ $73D3,x
		DEX : BPL -
		LDX #$0209
	-	STZ $7998,x
		DEX : BPL -
		RTL

; clear $73D3-$7937
; clear $7998-$7BA1
; basically, we're just keeping $7938 since that's where !LevelTable4 is



;==============;
;CLEAR PLAYER 2;
;==============;
;
; this is called from RealmSelect.asm
;
CLEAR_PLAYER2:
		STZ !BossData+0			;\
		STZ !BossData+1			; |
		STZ !BossData+2			; |
		STZ !BossData+3			; | Clear boss data
		STZ !BossData+4			; |
		STZ !BossData+5			; |
		STZ !BossData+6			;/

		LDA #$00			; > Set up clear
		STA !NPC_ID+0			;\
		STA !NPC_ID+1			; | Clear NPC ID pointer
		STA !NPC_ID+2			;/
		STA !NPC_Talk+0			;\
		STA !NPC_Talk+1			; | Clear NPC talk pointer
		STA !NPC_Talk+2			;/
		STA !MsgMode			; > Clear message mode
		STA !HDMAptr+0			;\
		STA !HDMAptr+1			; | clear HDMA pointer
		STA !HDMAptr+2			;/

		REP #$20			;\
		LDA !P2CoinIncrease		; |
		AND #$00FF			; |
		CLC : ADC !P2Coins		; | Add up coin increase to make sure player's aren't cheated
		STA !P2Coins			; |
		LDA !P1CoinIncrease		; |
		AND #$00FF			; |
		CLC : ADC !P1Coins		;/
		CLC : ADC !P2Coins		;\
		BEQ .NoCoins			; |
		STZ !P1Coins			; |
		STZ !P2Coins			; |
		CLC : ADC !CoinHoard+0		; |
		STA !CoinHoard+0		; | Put coins in hoard
		LDA !CoinHoard+2		; |
		ADC #$0000			; |
		STA !CoinHoard+2		;/


		LDA #$0F42
		CMP !CoinHoard+1
		BCC .CapHoard			; > If less, then cap hoard
		BNE .NoCoins			; > If greater than, don't cap hoard
		LDA !CoinHoard+0		;\ If equal, check lowest byte
		CMP #$423F : BCC .NoCoins	;/
		LDA #$0F42			; > If it overflows, cap hoard

		.CapHoard
		STA !CoinHoard+1
		LDA #$423F : STA !CoinHoard+0

		.NoCoins
		SEP #$20		
		STZ !P1CoinIncrease		;\ Clear coin increase
		STZ !P2CoinIncrease		;/

		STZ !P1Dead			;\
		LDX #$7F			; | revive and reset players
	-	STZ !P2Base-$80,x		; |
		STZ !P2Base,x			; |
		DEX : BPL -			;/
		RTL

;=========;
;CLEAR MSG;
;=========;
CLEAR_MSG:
		LDA.b #.SA1 : STA $3180			;\
		LDA.b #.SA1>>8 : STA $3181		; | have SA-1 clear message box RAM
		LDA.b #.SA1>>16 : STA $3182		; |
		JMP $1E80				;/

		.SA1
		PHP
		PHB
		LDA #$40
		PHA : PLB
		STZ.w !MsgRAM+$FF
		REP #$30
		LDA.w #$00FE
		LDX.w #!MsgRAM+$FF
		LDY.w #!MsgRAM+$FE
		MVP $40,$40
		PLB
		PLP
		RTL


;==========;
;FIX MIDWAY;
;==========;
FIX_MIDWAY:
		LDA #$01 : STA $73CE			; set midway flag
		LDX !Translevel				;\
		LDA !LevelTable1,x			; | set checkpoint flag
		ORA #$40				; |
		STA !LevelTable1,x			;/
		LDA !Level : STA !LevelTable2,x		;\
		LDA !Level+1 : BEQ .Return		; |
		LDA !LevelTable1,x			; | store level number to table
		ORA #$20				; |
		STA !LevelTable1,x			;/
	.Return	JML $00CA30				; > Return to RTS


;===============;
;DEATH GAME MODE;
;===============;
DEATH_GAMEMODE:

		LDA #$0F : STA !GameMode
		JML $009C8E

.Init		STZ !P2Status				; > Reload player 2
		LDX #$14				;\ Death message = GAME OVER
		STX $743B				;/
		LDY #$15				;\ Game mode = fade to GAME OVER
		STY $6100				;/
		LDA #$C0				;\ GAME OVER animation = 0xC0
		STA $743C				;/
		LDA #$FF				;\ GAME OVER timer = 0xFF
		STA $743D				;/
		JML $00D107

;.MidwayBits	db $04,$0C				; Attribute bits for exits

;===========;
;DELAY DEATH;
;===========;
DELAY_DEATH:

		LDA !MultiPlayer : BNE .HandleMario	;\
		LDA !Characters				; > !P2Character is not yet filled out
		AND #$F0 : BEQ .HandleMario		; | special case: single player without mario
		LDA !P2Status-$80			; |
		CMP #$02 : BCS $03 : JMP .NoDeath	; |
		.HandleMario				;/

		LDA !P2Status-$80 : BEQ .NoMusic
		LDA !P2Status : BEQ .NoMusic
		LDA #$01 : STA !SPC3			; set music
		.NoMusic

		LDA !P1Dead : BNE .Die
		LDA !CurrentMario : BEQ .Die
		DEC A					;\
		LSR A					; |
		ROR A					; | mark mario as dying in PCE reg
		AND #$80				; |
		TAY					; |
		LDA #$01 : STA !P2Status-$80,y		;/
		REP #$20				;\
		LDA $96					; |
		SEC : SBC $1C				; | see if mario has fallen off the level yet
		CMP #$0180				; |
		SEP #$20				;/
		BMI .Fall
		BCC .Fall

		.Die
		LDA #$01 : STA !P1Dead			;\ mario has died
		STZ $7496				;/
		LDA !MultiPlayer : BEQ .ReallyDeath	; if single player, return and end level
		LDA !CurrentMario : BEQ .2PCE		; see if mario is in play
		DEC A					;\
		LSR A					; |
		ROR A					; |
		AND #$80				; |
		EOR #$80				; | special case: mario + PCE
		TAY					; |
		LDA !P2Status-$80,y			; |
		CMP #$02 : BCC .NoDeath			; |
		BRA .ReallyDeath			;/

	.2PCE	LDA !P2Status-$80			;\
		CMP #$02 : BCC .NoDeath			; |
		REP #$20				; |
		LDA !P2XPosLo : STA !P2XPosLo-$80	; | special case: two PCE characters
		LDA !P2YPosLo : STA !P2YPosLo-$80	; |
		SEP #$20				; |
		LDA !P2Status				; |
		CMP #$02 : BCC .NoDeath			;/

.ReallyDeath	REP #$20				;\
		STZ !P1Coins				; | players lose all coins upon death
		STZ !P2Coins				; |
		SEP #$20				;/

		.Return
		STZ $19					;\ Overwritten code
		LDA #$3E				;/
		JML $00D0BA				; > execute rest of routine

		.Fall
		LDA #$25 : STA $7496
		BRA .Return

.NoDeath	LDA #$7F : STA !MarioMaskBits		; hide mario
		LDA !CurrentMario : BEQ .Snap1
		DEC A
		LSR A
		ROR A
		AND #$80
		TAY
		LDA #$02 : STA !P2Status-$80,y		; mark mario as dead in PCE reg
		TYA
		EOR #$80
	.Snap1	TAY
		REP #$20
		LDA !P2XPosLo-$80,y : STA $94
		LDA !P2YPosLo-$80,y : STA $96
		SEP #$20
		BRA .Fall


;======================;
;SCROLL OPTIONS ROUTINE;
;======================;


; don't restore the other ones, they set up the camera and Mario's position and stuff

	pushpc
	org $00F70D
	;	LDA #$00C0			;\ restore SMW code from LM3
	;	JSR $F7F4			;/

	org $00F77B
		SEC : SBC $742C,y		; restore SMW code from LM3


	org $00F79D
		; this is my hijack :)

	org $00F871
	;	LDY #$04			;\ restore SMW code from LM3
	;	BRA $0C				;/

	org $05DA17
	;	SEP #$30			;\ restore SMW code from LM3
	;	LDA !Translevel			;/
	pullpc

SCROLL_OPTIONS:


; this routine is called once at level load (game mode == 0x11) to set initial screen coordinates
; if I just rewrite those I can decide where the camera ends up
; when this routine is called in this way, !Level is already set properly so I do know where I'm going


; culprit: $80C426 (probably a LM routine)

; LM table:
; $832C		00
; $832A		01
; $8329		02
; $8325		03
; $8328		04
; $8327		05
; $8326		06
; $8324		07

; $833E		00
; $8338		01
; $8337		02
; $8333		03
; $8336		04
; $8335		05
; $8334		06
; $8332		07

; $FFFF



		LDX !GameMode					;\
		CPX #$11 : BNE .NoInit				; |
		PHP						; |
		SEP #$20					; |
		LDX !Level					; |
		LDA.l .LevelTable,x				; |
		LDX !Level+1					; |
		AND.l .LevelSwitch,x				; |
		BEQ .NormalCoords				; | game mode 0x11 = INIT camera
		CMP #$10 : BCC +				; |
		LSR #4						; |
	+	DEC A						; |
		ASL A						; |
		CMP.b #.CoordsEnd-.CoordsPtr			; |
		BCS .NormalCoords				; |
		TAX						; |
		JSR (.CoordsPtr,x)				; |
	.NormalCoords						; |
		PLP						; |
		JML $00F7C2					;/

	.NoInit	CPX #$14 : BNE .NoBox				; if not game mode 0x14, no camera box

		.Expand						;\
		LDY #$01					; |
	-	LDX !CameraForceTimer,y : BEQ .NextForce	; |
		DEX						; |
		TXA						; |
		SEP #$20					; |
		STA !CameraForceTimer,y				; |
		REP #$20					; |
		LDX !CameraForceDir,y				; |
		PHY						; |
		LDY #$00					; |
		TXA						; |
		AND #$0002					; | apply forced camera movement
		BNE $02 : LDY #$02				; |
		STY $55						; |
		PLY						; |
		LDA !CameraBackupX				; |
		CLC : ADC.l .ForceTableX,x			; |
		AND #$FFF8					; |
		STA $1A						; |
		LDA !CameraBackupY				; |
		CLC : ADC.l .ForceTableY,x			; |
		AND #$FFF8					; |
		STA $1C						; |
		JMP .CameraBackup				; |
.NextForce	DEY : BPL -					;/

		BIT !CameraBoxU : BMI .NoBox			;\
		LDA.w #.SA1 : STA $3180				; |
		LDA.w #.SA1>>8 : STA $3181			; |
		PHP						; | if camera box is enabled, have SA-1 run that code then jump to backup
		SEP #$20					; | otherwise run the no box code
		JSR $1E80					; |
		PLP						; |
		JMP .CameraBackup				;/

		.NoBox
		LDX !SmoothCamera : BEQ .CameraBackup		; > see if smooth cam is enabled
		PHB : PHK : PLB					;\
		STZ $00						; |
		LDX $5D						; |
		DEX						; |
		STX $01						; |
		LDA !LevelHeight				; |
		SEC : SBC #$00E0				; |
		STA $02						; |
		LDA !P2XPosLo-$80				; |
		CLC : ADC !P2XPosLo				; |
		LSR A						; |
		SEC : SBC #$0080				; |
		BPL $03 : LDA #$0000				; |
		CMP $00						; |
		BCC $02 : LDA $00				; |
		STA $1A						; |
		LDY !EnableVScroll : BEQ +			; |
		LDA !P2YPosLo-$80				; |
		CLC : ADC !P2YPosLo				; | smooth cam logic
		BPL $03 : LDA #$0000				; |
		LSR A						; |
		SEC : SBC #$0070				; |
		BPL $03 : LDA #$0000				; |
		CMP $02						; |
		BCC $02 : LDA $02				; |
		STA $1C						; |
	+	LDX #$02					; |
	-	LDA !CameraBackupX,x				; |
		CMP $1A,x : BEQ +				; |
		LDY #$00					; |
		BCC $02 : LDY #$02				; |
		CLC : ADC.w .SmoothSpeed,y			; |
		STA $00						; |
		LDA !CameraBackupX,x				; |
		SEC : SBC $1A,x					; |
		BPL $04 : EOR #$FFFF : INC A			; |
		CMP #$0006 : BCC +				; |
		LDA $00 : STA $1A,x				; |
	+	DEX #2 : BPL -					; |
		PLB						;/

		.CameraBackup
		LDA !CameraBackupX : STA !BG1ZipRowX		;\
		LDA !CameraBackupY : STA !BG1ZipRowY		; | coordinates from previous frame
		LDA $1E : STA !BG2ZipRowX			; | (used for updating tilemap)
		LDA $20 : STA !BG2ZipRowY			;/
		LDA $1A : STA !CameraBackupX			;\ backup for next frame
		LDA $1C : STA !CameraBackupY			;/

		JSL .Main

		LDA.l !HDMAptr+0 : BEQ .Return			;\
		STA $00						; |
		LDA.l !HDMAptr+1				; |
		STA $01						; | Execute HDMA code
		PEA $0000 : PLB					; |
		PEA $F7C2-1					; |
		JML [$3000]					;/

	.Return	JML $00F7C2


	.ForceTableY
		dw $0000,$0000
	.ForceTableX
		dw $0008,$FFF8,$0000,$0000

	.SmoothSpeed
		dw $0006,$FFFA

	.CameraOffset
		dw $0100,$00E0
	.CameraCenter
		dw $0080,$0070


		.SA1
		PHB : PHK : PLB
		PHP
		SEP #$10
		REP #$20

		JSR .Aim					; get camera target
		JSR .Forbiddance				; apply forbiddance box
		JSR .Process					; process movement

		LDX #$02					;\
	-	LDY #$00					; |
		LDA $1A,x					; |
		CMP !CameraBackupX,x : BEQ +			; | special backup for camera box
		BCC $02 : LDY #$02				; |
		STY $55						; |
	+	DEX #2 : BPL -					;/

		LDA !CameraBoxL					;\
		SEC : SBC #$0020				; |
		STA $04						; |
		LDA !CameraBoxR					; |
		CLC : ADC #$0110				; |
		STA $06						; | coords from box borders
		LDA !CameraBoxU					; |
		SEC : SBC #$0020				; |
		STA $08						; |
		LDA !CameraBoxD					; |
		CLC : ADC #$00F0				; |
		STA $0A						;/

		LDX #$0F					;\
	-	LDY $3230,x : BNE $03 : JMP .Next		; |
		LDA $3470,x					; |
		ORA #$0004					; |
		STA $3470,x					; |
		LDY !CameraForceTimer : BNE .Freeze		; |
		LDY $3220,x : STY $00				; | search for sprites to interact with
		LDY $3250,x : STY $01				; |
		LDY $3210,x : STY $02				; |
		LDY $3240,x : STY $03				; |
		LDA $00						; |
		SEC : SBC $04					; |
		BPL .CheckR					; |
		CMP #$FF00 : BCC .Delete			; |
		CMP #$FFE0 : BCC .Freeze			;/

	.Delete	LDA $3230,x					;\
		AND #$FF00					; |
		STA $3230,x					; |
		LDY $33F0,x					; |
		CPY #$FF : BEQ .Next				; |
		PHX						; |
		TYX						; | delete sprite
		LDA $418A00,x					; |
		AND #$00FF					; |
		CMP #$00EE : BEQ +				; |
		LDA $418A00,x					; |
		AND #$FF00					; |
		STA $418A00,x					; |
	+	PLX						; |
		BRA .Next					;/

	.CheckR	LDA $00						;\
		SEC : SBC $06					; |
		BMI .GoodX					; | see if fully outside
		CMP #$0020 : BCC .Delete			; |
		CMP #$0100 : BCS .Delete			;/

	.Freeze	LDA !SpriteStasis,x				;\
		ORA #$0002					; | freeze sprite
		STA !SpriteStasis,x				; |
		BRA .Next					;/

	.GoodX	LDA $02						;\
		CMP $08 : BMI .Freeze				; | see if sprite should freeze
		CMP $0A : BPL .Freeze				;/
	.Next	DEX : BMI $03 : JMP -				; > next sprite

		PLP						; return
		PLB
		RTL


		.Aim
		LDA !P2XPosLo-$80				;\
		CLC : ADC !P2XPosLo				; |
		LSR A						; |
		SEC : SBC #$0080				; |
		CMP #$4000					; |
		BCC $03 : LDA #$0000				; |
		STA $1A						; |
		LDA !P2YPosLo-$80				; | logic for finding camera target
		CLC : ADC !P2YPosLo				; |
		LSR A						; |
		SEC : SBC #$0070				; |
		CMP #$4000					; |
		BCC $03 : LDA #$0000				; |
		STA $1C						; |
		RTS						;/

		.Process
		LDX #$02
	-	LDA $1A,x
		CMP !CameraBoxL,x : BCS +
		LDA !CameraBoxL,x : STA $1A,x
		BRA ++
	+	CMP !CameraBoxR,x : BCC ++ : BEQ ++
		LDA !CameraBoxR,x : STA $1A,x
	++	LDA !CameraBackupX,x				; apply smooth camera
		CMP $1A,x : BEQ +
		LDY #$00
		BCC $02 : LDY #$02
		CLC : ADC.w .SmoothSpeed,y
		STA $00
		LDA !CameraBackupX,x
		SEC : SBC $1A,x
		BPL $04 : EOR #$FFFF : INC A
		CMP #$0006 : BCC +
		LDA $00 : STA $1A,x
	;	TXA
	;	EOR #$0002
	;	TAX
	;	LDA !CameraBackupX,x : STA $1A,x
	;	BRA .Absolute
	+	DEX #2 : BPL -
	..R	RTS


		.Absolute
		LDA $1A,x
		CMP !CameraBoxL,x : BCS +
		LDA !CameraBoxL,x : STA $1A,x
		RTS
	+	CMP !CameraBoxR,x : BCC + : BEQ +
		LDA !CameraBoxR,x : STA $1A,x
	+	RTS


		.Forbiddance
		LDX !CameraForbiddance
		CPX #$FF : BEQ .Process_R
		LDA !CameraForbiddance
		AND #$003F
		TAX

		LDA !CameraBoxU : STA $0A	; forbiddance top border start
		LDA !CameraBoxL
	-	CPX #$00 : BEQ +
		DEX
		CLC : ADC #$0100
		STA $08
		CMP !CameraBoxR : BCC - : BEQ -
		LDA $0A
		CLC : ADC #$00E0
		STA $0A				; forbiddance top border
		LDA !CameraBoxL
		BRA -

	+	STA $08				; forbiddance left border
		LDA !CameraForbiddance
		ASL #2
		AND #$1F00
		CLC : ADC $08
		CLC : ADC #$0100
		STA $0C				; forbiddance right border
		LDA !CameraForbiddance
		AND #$F800
		LSR #3
		PHA
		LSR #3
		STA $0E
		PLA
		SEC : SBC $0E
		CLC : ADC $0A
		CLC : ADC #$00E0
		STA $0E				; forbiddance bottom border


		LDA $1A
		CMP $0C : BCS .NoForbid
		ADC #$0100
		CMP $08 : BCC .NoForbid
		LDA $1C
		CMP $0E : BCS .NoForbid
		ADC #$00E0
		CMP $0A : BCC .NoForbid


		LDX #$02
	-	LDA $08,x
		CLC : ADC $0C,x
		LSR A
		STA !BigRAM+0
		LDA $1A,x
		CLC : ADC .CameraCenter,x
		CMP !BigRAM+0
		BCS ..RD
	..LU	LDA $08,x : STA $00,x
		SEC : SBC .CameraOffset,x
		BRA +
	..RD	LDA $0C,x : STA $00,x
	+	SEC : SBC $1A,x
		BPL $04 : EOR #$FFFF : INC A
		STA $04,x
		DEX #2 : BPL -


		LDX #$00
		LDA $04
		CMP $06
		BCC $02 : LDX #$02
		LDA $00,x
		CMP !CameraBoxL,x : BNE +
		TXA
		EOR #$0002
		TAX
		LDA $00,x
	+	CMP $08,x : BNE +
		SEC : SBC .CameraOffset,x
		BPL $03 : LDA #$0000
	+	STA $1A,x

		.NoForbid
		RTS



		.Main
		LDA !BG2ModeH			;\
		ASL A				; | X = pointer index
		TAX				;/
		BNE .ProcessHorz		;\ 0%
		STZ $1E				;/

		.ProcessHorz
		LDA $1A				; > A = BG1 HScroll
		JMP (.HPtr,x)			; > Execute pointer

		.HPtr
		dw .NoHorz			; 0 - 0%
		dw .ConstantHorz		; 1 - 100%
		dw .VariableHorz		; 2 - 50%
		dw .SlowHorz			; 3 - 6.25%
		dw .Variable2Horz		; 4 - 25%
		dw .Variable3Horz		; 5 - 12.5%
		dw .CloseHorz			; 6 - 87.5%
		dw .Close2Horz			; 7 - 75%
		dw .CloseHalfHorz		; 8 - 43.75%
		dw .Close2HalfHorz		; 9 - 37.5%
		dw .40PercentHorz		; A - 40%
		dw .DoubleHorz			; B - 200%

.DoubleHorz	ASL A
		BRA .ConstantHorz
.40PercentHorz	ASL #2
		STA $4204
		LDX #$0A
		STX $4206
		JSR .GetDiv
		LDA $4216
		CMP #$0005
		LDA $4214
		ADC #$0000
		BRA .ConstantHorz
.CloseHalfHorz	LSR A
.Close2HalfHorz	LSR #2
		SEC : SBC $1A
		EOR #$FFFF
		INC A
		LSR A
		BRA .ConstantHorz
.CloseHorz	LSR A
.Close2Horz	LSR #2
		SEC : SBC $1A
		EOR #$FFFF
		INC A
		BRA .ConstantHorz
.SlowHorz	LSR A
.Variable3Horz	LSR A
.Variable2Horz	LSR A
.VariableHorz	LSR A
.ConstantHorz	STA $1E
.NoHorz		LDA !BG2ModeV
		ASL A
		TAX
		BNE .ProcessVert		;\ 0%
		STZ $20				;/

		.ProcessVert
		LDA $1C
		JMP (.VPtr,x)

		.VPtr
		dw .NoVert			; 0 - 0%
		dw .ConstantVert		; 1 - 100%
		dw .VariableVert		; 2 - 50%
		dw .SlowVert			; 3 - 6.25%
		dw .Variable2Vert		; 4 - 25%
		dw .Variable3Vert		; 5 - 12.5%
		dw .CloseVert			; 6 - 87.5%
		dw .Close2Vert			; 7 - 75%
		dw .CloseHalfVert		; 8 - 43.75%
		dw .Close2HalfVert		; 9 - 37.5%
		dw .40PercentVert		; A - 40%
		dw .DoubleVert			; B - 200%

.DoubleVert	ASL A
		BRA .ConstantVert
.40PercentVert	ASL #2
		STA $4204
		LDX #$0A
		STX $4206
		JSR .GetDiv
		LDA $4216
		CMP #$0005
		LDA $4214
		ADC #$0000
		BRA .ConstantVert
.CloseHalfVert	LSR A
.Close2HalfVert	LSR #2
		SEC : SBC $1C
		EOR #$FFFF
		INC A
		LSR A
		BRA .ConstantVert
.CloseVert	LSR A
.Close2Vert	LSR #2
		SEC : SBC $1C
		EOR #$FFFF
		INC A
		BRA .ConstantVert
.SlowVert	LSR A
.Variable3Vert	LSR A
.Variable2Vert	LSR A
.VariableVert	LSR A
.ConstantVert	CLC : ADC !BG2BaseV		;\ Add temporary BG2 VScroll and write
		STA $20				;/
		RTL

.NoVert		LDA !BG2BaseV
		STA $20
		RTL

.GetDiv		NOP #2
		RTS


; honestly i don't really know what this is...
; some way of setting camera coords on level init?

; lo nybble is used by levels 0x000-0x0FF, hi nybble is used by levels 0x100-0x1FF
; 0 means it's unused, so just use normal coords
; any other number is treated as an index to the coordinate routine pointer table

.LevelTable	db $00,$00,$00,$00,$00,$00,$00,$00		; 00-07
		db $00,$00,$00,$00,$00,$00,$00,$00		; 08-0F
		db $00,$00,$00,$00,$01,$00,$00,$00		; 10-17
		db $00,$00,$00,$00,$00,$00,$00,$00		; 18-1F
		db $00,$00,$00,$00,$00,$00,$00,$00		; 20-27
		db $00,$00,$00,$00,$00,$00,$00,$00		; 28-2F
		db $00,$00,$00,$00,$01,$00,$00,$00		; 30-37
		db $00,$00,$00,$00,$00,$00,$00,$00		; 38-3F
		db $00,$00,$00,$00,$00,$00,$00,$00		; 40-47
		db $00,$00,$00,$00,$00,$00,$00,$00		; 48-4F
		db $00,$00,$00,$00,$00,$00,$00,$00		; 50-57
		db $00,$00,$00,$00,$00,$00,$00,$00		; 58-5F
		db $00,$00,$00,$00,$00,$00,$00,$00		; 60-67
		db $00,$00,$00,$00,$00,$00,$00,$00		; 68-6F
		db $00,$00,$00,$00,$00,$00,$00,$00		; 70-77
		db $00,$00,$00,$00,$00,$00,$00,$00		; 78-7F
		db $00,$00,$00,$00,$00,$00,$00,$00		; 80-87
		db $00,$00,$00,$00,$00,$00,$00,$00		; 88-8F
		db $00,$00,$00,$00,$00,$00,$00,$00		; 90-97
		db $00,$00,$00,$00,$00,$00,$00,$00		; 98-9F
		db $00,$00,$00,$00,$00,$00,$00,$00		; A0-A7
		db $00,$00,$00,$00,$00,$00,$00,$00		; A8-AF
		db $00,$00,$00,$00,$00,$00,$00,$00		; B0-B7
		db $00,$00,$00,$00,$00,$00,$00,$00		; B8-BF
		db $00,$00,$00,$00,$00,$00,$00,$00		; C0-C7
		db $00,$00,$00,$00,$00,$00,$00,$00		; C8-CF
		db $00,$00,$00,$00,$00,$00,$00,$00		; D0-D7
		db $00,$00,$00,$00,$00,$00,$00,$00		; D8-DF
		db $00,$00,$00,$00,$00,$00,$00,$00		; E0-E7
		db $00,$00,$00,$00,$00,$00,$00,$00		; E8-EF
		db $00,$00,$00,$00,$00,$00,$00,$00		; F0-F7
		db $00,$00,$00,$00,$00,$00,$00,$00		; F8-FF


.LevelSwitch	db $0F,$F0


	; this is entered with all regs 8-bit
	; PLP is used at return, so no need to bother keeping track of P


	.CoordsPtr
	dw .Coords1
	.CoordsEnd


	.Coords1
		STZ $1A
		REP #$20
		LDX #$00
		LDA $1C
	-	CMP #$00E0 : BCC ..Yes
		INX #2
		SBC #$00E0
		BRA -

	..Yes	CMP #$0070
		BCC $02 : INX #2
		LDA.l ..Y,x : STA $1C
		LDX #$02
	-	LDA $1A,x
		STA !CameraBackupX,x
		STA !CameraBoxL,x
		STA $7462,x
		INC A
		STA !CameraBoxR,x
		DEX #2
		BPL -
		RTS

	..Y	dw $0000,$00E0,$01C0,$02A0
		dw $0380,$0460,$0540,$0620


;==========;
;1-UP BLOCK;
;==========;

	UpBlock:
		CPY #$0C : BNE .028905		;\ Replace Yoshi with 1-up
		LDY #$05 : STY $05		;/
	.028905	JML $028905			; > Go to shared routine


;========;
;TIDE FIX;
;========;
pushpc
org $00DA58
	BRA $03			; > Source: BEQ $03
org $00DA6F
	BRA $08			; > Source: BEQ $08

pullpc



;============;
;ENTRANCE FIX;
;============;
EntranceFix:
		STA $1C				;\ camera backup
		STA !CameraBackupY		;/
		RTL


;====================;
;LOAD HIDEOUT ROUTINE;
;====================;
LOAD_HIDEOUT:
		LDA $73D2			;\
		ORA $7B86			; | Don't allow cancelling OW processes
		ORA $7B87			; |
		BNE .Return			;/
		LDA $73C1			; Tile player is standing on
		CMP #$56			;\ Return if less than 0x56
		BCC .Return			;/
		CMP #$87			;\ Return if equal to or greater than 0x86
		BCS .Return			;/
		INC $73F2			; Set load hideout flag

	; The following code is the level load init routine from all.log, starting at $04919F.

.Main

		LDY #$10
		LDA $7F13
		AND #$08
		BEQ +
		LDY #$12
	+	TYA
		STA $7F13
		LDA #$02
		STA $6DB1
		LDA #$80
		STA !SPC3
		INC !GameMode			; Increment game mode to initiate level load
.Return		JML HIDEOUT_CHECK_Skip

.Load		LDA $73F2
		BEQ .NormalLevel
		LDA #$00			;\ Load level 0x000
		STA !Translevel			;/
		RTL

.NormalLevel	LDA $743B			;\ If level was loaded from OW, handle as usual
		BEQ +				;/
		STZ $743B			; > Clear game over
		LDY !Translevel			; > Y = translevel number
		LDA $73CE			;\ If the midway point has not been reached, load the main entrance
		BEQ .NoMidway			;/
		LDA $7EA2,y			;\
		ORA #$40			; | If the midway point has been reached, carry on from there
		STA $7EA2,y			;/
.NoMidway	TYA				; > A = translevel number
		RTL				; > Return

	+	LDA $40D000,x			; Overwritten code
		RTL




macro oamtable(source)
		LDA.w !OAMindex_<source> : BEQ ?next
		CMP $00 : BCC ?notcapped
		LDA $00
		STZ $00
		BRA ?go
	?notcapped:
		LDA $00
		SEC : SBC.w !OAMindex_<source>
		STA $00
		LDA.w !OAMindex_<source>
	?go:
		DEC A
		LDX.w #!OAM_<source>
		PHB
		MVN $00,!OAM_<source>>>16
		PLB
	?next:
endmacro

macro oamtablehi(source)
		LDA.w !OAMindex_<source> : BEQ ?next
		LSR #2
		STA $02
		CMP $00 : BCC ?notcapped
		LDA $00
		STZ $00
		BRA ?go
	?notcapped:
		LDA $00
		SEC : SBC $02
		STA $00
		LDA $02
	?go:
		DEC A
		LDX.w #!OAMhi_<source>
		PHB
		MVN $00,!OAMhi_<source>>>16
		PLB
	?next:
endmacro


;=========;
;BUILD OAM;
;=========;
BUILD_OAM:
		TSC
		XBA
		CMP #$37 : BEQ .SA1
		LDA.b #.Assemble : STA $3180
		LDA.b #.Assemble>>8 : STA $3181
		LDA.b #.Assemble>>16 : STA $3182
		JMP $1E80

		.SA1
		JSL .Assemble
		RTS


		.Assemble
		PHB
		PHP
		SEP #$30
		LDA #$41
		PHA : PLB
		REP #$30
		LDA #$0200 : STA $00			; lo table size
		LDY.w #!OAM				; dest address (lo table)
		%oamtable(p3)				;\ prio 3 lo table
		LDA $00 : BEQ ..hitable			;/
		%oamtable(p2)				;\ prio 2 lo table
		LDA $00 : BEQ ..hitable			;/
		%oamtable(p1)				;\ prio 1 lo table
		LDA $00 : BEQ ..hitable			;/
		%oamtable(p0)				; prio 0 lo table

		..hitable
		LDA #$0080 : STA $00			; hi table size
		LDY.w #!OAMhi				; dest address (hi table)
	..p3	%oamtablehi(p3)				;\ prio 3 hi table
		LDA $00 : BEQ ..finish			;/
	..p2	%oamtablehi(p2)				;\ prio 2 hi table
		LDA $00 : BEQ ..finish			;/
	..p1	%oamtablehi(p1)				;\ prio 1 hi table
		LDA $00 : BEQ ..finish			;/
	..p0	%oamtablehi(p0)				; prio 0 hi table

		..finish
		SEP #$30
		LDA #$00
		PHA : PLB
		LDY #$1E				; > Start loop at 0x1E to reach all tiles (32 bytes)
	-	LDX.w $8475,y				;\
		LDA.w !OAMhi+3,x			; |
		ASL #2					; |
		ORA.w !OAMhi+2,x			; |
		ASL #2					; |
		ORA.w !OAMhi+1,x			; |
		ASL #2					; |
		ORA.w !OAMhi+0,x			; | Assemble hi OAM table
		STA.w !OAM+$200,y			; |
		LDA.w !OAMhi+7,x			; |
		ASL #2					; |
		ORA.w !OAMhi+6,x			; |
		ASL #2					; |
		ORA.w !OAMhi+5,x			; |
		ASL #2					; |
		ORA.w !OAMhi+4,x			; |
		STA.w !OAM+$201,y			; |
		DEY #2					; |
		BPL -					;/
		PLP
		PLB
		RTL					; > Return






;========;
;KILL OAM;
;========;

	KILL_OAM:

		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JSR $1E80
		RTL

		.Short
		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JMP $1E80

		.SA1
		PHB : PHK : PLB
		PHP
		SEP #$30
		LDA #$F0
		STA !OAM+$001 : STA !OAM+$005 : STA !OAM+$009 : STA !OAM+$00D
		STA !OAM+$011 : STA !OAM+$015 : STA !OAM+$019 : STA !OAM+$01D
		STA !OAM+$021 : STA !OAM+$025 : STA !OAM+$029 : STA !OAM+$02D
		STA !OAM+$031 : STA !OAM+$035 : STA !OAM+$039 : STA !OAM+$03D
		STA !OAM+$041 : STA !OAM+$045 : STA !OAM+$049 : STA !OAM+$04D
		STA !OAM+$051 : STA !OAM+$055 : STA !OAM+$059 : STA !OAM+$05D
		STA !OAM+$061 : STA !OAM+$065 : STA !OAM+$069 : STA !OAM+$06D
		STA !OAM+$071 : STA !OAM+$075 : STA !OAM+$079 : STA !OAM+$07D
		STA !OAM+$081 : STA !OAM+$085 : STA !OAM+$089 : STA !OAM+$08D
		STA !OAM+$091 : STA !OAM+$095 : STA !OAM+$099 : STA !OAM+$09D
		STA !OAM+$0A1 : STA !OAM+$0A5 : STA !OAM+$0A9 : STA !OAM+$0AD
		STA !OAM+$0B1 : STA !OAM+$0B5 : STA !OAM+$0B9 : STA !OAM+$0BD
		STA !OAM+$0C1 : STA !OAM+$0C5 : STA !OAM+$0C9 : STA !OAM+$0CD
		STA !OAM+$0D1 : STA !OAM+$0D5 : STA !OAM+$0D9 : STA !OAM+$0DD
		STA !OAM+$0E1 : STA !OAM+$0E5 : STA !OAM+$0E9 : STA !OAM+$0ED
		STA !OAM+$0F1 : STA !OAM+$0F5 : STA !OAM+$0F9 : STA !OAM+$0FD
		STA !OAM+$101 : STA !OAM+$105 : STA !OAM+$109 : STA !OAM+$10D
		STA !OAM+$111 : STA !OAM+$115 : STA !OAM+$119 : STA !OAM+$11D
		STA !OAM+$121 : STA !OAM+$125 : STA !OAM+$129 : STA !OAM+$12D
		STA !OAM+$131 : STA !OAM+$135 : STA !OAM+$139 : STA !OAM+$13D
		STA !OAM+$141 : STA !OAM+$145 : STA !OAM+$149 : STA !OAM+$14D
		STA !OAM+$151 : STA !OAM+$155 : STA !OAM+$159 : STA !OAM+$15D
		STA !OAM+$161 : STA !OAM+$165 : STA !OAM+$169 : STA !OAM+$16D
		STA !OAM+$171 : STA !OAM+$175 : STA !OAM+$179 : STA !OAM+$17D
		STA !OAM+$181 : STA !OAM+$185 : STA !OAM+$189 : STA !OAM+$18D
		STA !OAM+$191 : STA !OAM+$195 : STA !OAM+$199 : STA !OAM+$19D
		STA !OAM+$1A1 : STA !OAM+$1A5 : STA !OAM+$1A9 : STA !OAM+$1AD
		STA !OAM+$1B1 : STA !OAM+$1B5 : STA !OAM+$1B9 : STA !OAM+$1BD
		STA !OAM+$1C1 : STA !OAM+$1C5 : STA !OAM+$1C9 : STA !OAM+$1CD
		STA !OAM+$1D1 : STA !OAM+$1D5 : STA !OAM+$1D9 : STA !OAM+$1DD
		STA !OAM+$1E1 : STA !OAM+$1E5 : STA !OAM+$1E9 : STA !OAM+$1ED
		STA !OAM+$1F1 : STA !OAM+$1F5 : STA !OAM+$1F9 : STA !OAM+$1FD
		REP #$20
		LDA #$0000
		STA !OAMindex
		STA !OAMindex_p0
		STA !OAMindex_p1
		STA !OAMindex_p2
		STA !OAMindex_p3
		PLP
		PLB
		RTL


;===================;
;CHECKPOINTS ROUTINE;
;===================;
incsrc "Checkpoints.asm"


;===============;
;REALM SELECTION;
;===============;
incsrc "RealmSelect.asm"



;=================;
;LEVEL INTROS TEXT;
;=================;
incsrc "LevelIntros.asm"




;===================;
;BRICK ANIMATION FIX;
;===================;
; $14 & F:
; 0 ->	question block, animated, tile 0x0060
;	water, animated, tile 0x0070
; 1 ->	question block, animated 2 (?), tile 0x0078
;	muncher, tile 0x005C
; 2 ->	coin, tile 0x0054
; 3 ->	coin 2 (?), tile 0x006C
; 4 ->	used block, static, tile 0x0058
; 5 ->	corner man (!!???), tile 0x00EE (ExAnimation)
; 6 ->	?????
; 7 ->	?????
; 8 ->	question block, static (?), tile 0x0040
; 9 ->	[repeat of 1]
; A ->	[repeat of 2]
; B ->	[repeat of 3]
; C ->	[repeat of 4]
; D ->	[repeat of 5]
; E ->	?????
; F ->	?????

; Brick updates at:
; $14&7 = 1
; Read from $6D7E

pushpc
org $05BBA2
	JML BrickAnim	; Source: SEP #$20 : PLB : RTL
pullpc

	BrickAnim:
		LDA $6D7E
		CMP #$0EA0 : BNE .Return
		LDA $14
		AND #$00FF
		CMP #$0020 : BCC .Return

		LDA #$9600 : STA $6D78		; Delay animation

		.Return
		SEP #$20
		PLB
		RTL


; Plan: Read LM's VRAM table to check for address 0x0EA0 (AND #$7FFF)
; Then use that to figure out if it should be delayed

; Data (bank 7F)
; $C003: backup frame counter?
; $C00A: ExAnimation enable?
; $C00E: Highest ExAnimation frame slot?
; $C019: Unknown

; $C0C0: VRAM table
; $00-$01:	Data size
; $02-$03:	VRAM address (highest bit has unknown meaning)
; $04-$06:	Source address

;=============;
;SIDE EXIT FIX;
;=============;
SideExitFix:

		LDA !RAM_ScreenMode
		LSR A : BCS .Ok
		LDA $1B : BEQ .Ok
		INC A
		CMP $5D : BEQ .Ok
		RTL

	.Ok	STZ $6109
		LDA #$00
		JML $05B165


;=====================;
;TILE UPDATE OPTIMIZER;
;=====================;
; this routine is heavilty altered by Lunar Magic, I'd better be careful...
; there's another routine at $00C227 that ends at $00C299, can probably wire that up too (nope (yep))

pushpc
org $00C143
	JSL TileOptimize_Init		; > Source: SEP #$20 : LDA $06
org $00C1A7
	JSL TileOptimize		; > Source: STA $7F837B

org $00C227
	JSL TileOptimize_Init
org $00C299
	JSL TileOptimize		; > Source: STA $7F837B


pullpc

	TileOptimize:
	; A:		next empty index
	; X:		last used index
	; $0000:	first index to convert


	; 2000 = layer 1	->	!BG1Address
	; 3000 = layer 2	->	!BG2Address
	; 5000 = layer 3 (not remapped)

		STA $7F837B				; > Overwritten code
		LDA $1C
		STA $04
		LDA $20
		STA $06
		LDY $0000
		PHB
		PEA $7F7F
		PLB : PLB

		LDA.l !VRAMbase+!TileUpdateTable : TAX
	.Loop	LDA $837D,y
		XBA
		CMP #$8000 : BCC .Go
		PLB
		RTL


	.Go	CMP #$5000 : BCS .BG3
		JSR TransformAddress					; convert address
	.BG3	STA $0E

		LDA #$FFFF : STA $837D,y

		LDA #$0001 : STA $0C					; address increment for horizontal
		LDA $837F,y
		AND #$0080 : BEQ +
		LDA #$0020 : STA $0C					; address increment for vertical
		+

		LDA $837F,y
		XBA
		CMP #$C000 : BCS +
		CMP #$8000 : BCS ++
		CMP #$4000 : BCS +
	++	INC A
	+	AND #$3FFF
		CMP #$0008
		BCC $03 : LDA #$0008
		STA $02							; number of bytes to copy from stripe
		ASL A							;\
		CLC : ADC.l !VRAMbase+!TileUpdateTable+$00		; | update header to tile update table
		STA.l !VRAMbase+!TileUpdateTable+$00			;/

		TYA
		CLC : ADC #$8381
		STA $00

		PHY
		LDY #$0000
	-	LDA $0E : STA.l !VRAMbase+!TileUpdateTable+$02,x
		CLC : ADC $0C
		STA $0E
		LDA ($00),y : STA.l !VRAMbase+!TileUpdateTable+$04,x
		INX #4
		INY #2
		CPY $02 : BCC -
		PLY

		LDA $837F,y
		AND #$0040 : BEQ +
		LDA #$0006
		BRA ++
	+	LDA $02
		CLC : ADC #$0004
	++	STA $02


	.Next	TYA
		CLC : ADC $02
		TAY
		JMP .Loop


		.Init
		STX $0000				; > Preserve original index in $0000
		SEP #$20
		LDA $06
		RTL


	TransformAddress:
		STA $00
		AND #$0800
		BEQ $03 : LDA #$0100
		STA $08
		LDA $00
		AND #$03E0
		LSR #2
		TSB $08					; > Y position (looping pixels)
		LDA !RAM_ScreenMode
		LSR A
		BCS +
		LDA $98
		BRA ++
	+	LDA $9A
	++	AND #$FF00
		TSB $08

		LDA $00
		CMP #$3000
		LDA $08
		BCC .BG1
	.BG2	SEC : SBC $06
		BRA .Check
	.BG1	SEC : SBC $04
	.Check	CMP #$00E8 : BCC .Valid
		CMP #$FFE8 : BCS .Valid
		LDA #$FFFF : STA $837D,y
		LDA $837F,y
		XBA
		CMP #$C000 : BCS .RLE
		CMP #$8000 : BCS .Normal
		CMP #$4000 : BCS .RLE
	.Normal	INC A
		AND #$3FFF
		CLC : ADC #$0004
		BRA .End
	.RLE	LDA #$0006
	.End	STA $02
		PLA : JMP TileOptimize_Next		; out of bounds: NEXT!!

	.Valid	LDA $00					;\
		AND #$F7FF				; | final transformation for valid BG1/BG2
		CMP #$3000 : BCC ..BG1			;/
	..BG2	AND #$07FF				;\ remap
		ORA.l !BG2Address			;/
		RTS

	..BG1	AND #$07FF				;\ remap
		ORA.l !BG1Address			;/
		RTS


;	LDA $1C
;	SEC : SBC #$0080
;	STA $08
;	LDA $08
;	AND #$FFF0
;	BMI .upper
;	CMP $0C : BCS .return
;	.upper
;	CLC : ADC #$0200
;	CMP $0C : BEQ .return
;	BCS .go
;	.return
;	RTS
;	.go
;	; actual VRAM code


;	REP #$10
;	STA $4314
;	LDY #$0000

;	.Next
;	LDA [$00],y
;	BPL .Go
;	SEP #$30
;	RTS

;	.Go
;	STA $04
;	INY
;	LDA [$00],y
;	STA $03
;	INY
;	LDA [$00],y
;	STZ $07
;	ASL A
;	ROL $07
;	LDA #$18 : STA $4311
;	LDA [$00],y
;	AND #$40
;	LSR #3
;	STA $05
;	STZ $06
;	ORA #$01
;	STA $4310
;	REP #$20
;	LDA $03
;	STA $2116
;	LDA [$00],y
;	XBA
;	AND #$3FFF
;	TAX
;	INX
;	INY #2
;	TYA
;	CLC : ADC $00
;	STA $3212
;	STX $4315
;	LDA $05 : BEQ +
;	SEP #$20
;	LDA $07 : STA $2115
;	LDA #$02 : STA $420B
;	LDA #$19 : STA $4311
;	REP #$21
;	LDA $03 : STA $2116
;	TYA
;	ADC $00
;	INC A
;	STA $4312
;	STX $4315
;	LDX #$0002
;
;+	STX $03
;	TYA
;	CLC : ADC $03
;	TAY
;	SEP #$20
;	LDA $07
;	ORA #$80
;	STA $2115
;	LDA #$02 : STA $420B
;	JMP .Next


;==============;
;MAP16 EXPANDER;
;==============;
; this code allows for some massive objects that can overwrite standard map16 codes
; does not apply to PCE characters unless CORE/LAYER_INTERACTION is updated

MAP16_EXPAND:
		PHA
		LDA !3DWater : BEQ .Return
		LDA !ProcessingSprites
		REP #$20
		BNE .Sprites
		LDA $98 : BRA .Shared
.Sprites	LDA $0C
.Shared		BMI .AboveLevel
		CMP !Level+2
		SEP #$20
		BCC .Return
		LDA !IceLevel : BNE .Ice
.Return		PLA
		TAY : BNE .00F577
		LDY $7693
.00F54B		JML $00F54B
.00F577		JML $00F577


.AboveLevel	SEP #$20
		BRA .Return


.Ice		PLA
		LDA #$30 : STA $7693
		LDY #$01
		RTL







;================;
;CHARACTER SELECT;
;================;
;
; To do:
;	- Remap buttons (camera to X, character select to start, close window to B)
;	- Make it work for one player at a time
;	- Make sure PCE keeps track of which player/character is being processed
;
; Seems to work like this:
;	- $04828A does a multiplayer check to see if showing the menu is valid
;	- $04828F does a JSR to a pointer handler
;	- Pointers 2-4 are used ONLY for lives exchanger (other pointers are for other things)
;	- Third entry in pointer table goes to lives exchanger
;	- Lives exchanger JSL's to $009C13, which enables stripe image by jumping to $009D29
;	- $04F513 is a short routine that checks for any player pushing start.
;		- Doing so closes the window and stores lives to the current player.
;	- $04F52B is the bulk of the routine that calculates lives and does stripe image stuff.
;	- $04F415 is the routine that handles opening/closing the window (pointer 2/4)


CHARACTER_SELECT:


	PHP				; > Preserve processor
	LDA $7B8A			;\
	CMP #$10			; | Reset some stuff (otherwise this starts at 0x40)
	BCC $03 : STZ $7B8A		;/
	INC $7B8B			; > Update flash timer
	LDA !CurrentPlayer : TAX	; > X = Player index
	LDA !Characters			;\
	CPX #$00 : BEQ +		; |
	LSR #4				; | $0D = other player's character
+	AND #$0F			; |
	STA $0D				;/
	LDA $6DA6,x			;\
	AND #$0C			; |
	BEQ .ControlInput		; | Process controller input
	LDY #$23 : STY !SPC4		; > Play SFX
	STZ $7B8B			; > Reset flash timer
	CMP #$08 : BEQ .Up		;/
.Down	INC $7B8A			;\ Move down
	BRA .ControlInput		;/
.Up	DEC $7B8A			; > Move up
	LDA !MultiPlayer		;\ Ignore char checks during singleplayer
	BEQ .SinglePlayer		;/
	LDA $7B8A			;\
	CMP $0D : BNE .SinglePlayer	; | Prevent selecting the same character
	DEC $7B8A			;/

	.ControlInput
	LDA !MultiPlayer		;\ Ignore char checks during singleplayer
	BEQ .SinglePlayer		;/
	LDA $7B8A			;\
	CMP $0D : BNE .SinglePlayer	; | Prevent selecting the same character with Mario/down
	INC $7B8A			;/

	.SinglePlayer
	LDA #$04 : STA $00		;\
	INC A : STA $01			; > Set up RAM index for player menu size
	INC A : STA $02			; |
	LDA $7B8A			; |
	BMI .Bottom			; |
	CMP $01,x : BCC .NoInput	; | Make sure selection stays within limits
	LDA #$00 : BRA .Write		; |
.Bottom	LDA $00,x			; |
.Write	STA $7B8A			; |
	CMP $0D : BNE .NoInput		; > Make sure you can't choose Mario with both at the same time
	INC $7B8A			; |
	.NoInput			;/

	LDA.b #.SNES : STA $0183	;\
	LDA.b #.SNES>>8 : STA $0184	; |
	LDA.b #.SNES>>16 : STA $0185	; | Have the SNES do the rest since SA-1 can't access $7E0000-$7FFFFF
	LDA #$D0 : STA $2209		; |
-	LDA $018A : BEQ -		; |
	STZ $018A			;/
	PLP				; > Restore regs
	RTL				; > Return


	.SNES
	PHP				; > Register backup
	PHB : PHK : PLB			; > Bank backup
	LDA !CurrentPlayer
	REP #$30			; > All regs 16-bit
	BNE +				;\
	LDY.w #.EndEarly-.Table		; | "DROP OUT" option doesn't exist for player 1
	BRA $03				;/
+	LDY.w #.EndTable-.Table		;\	(0x50)
	TYA				; |
	CLC : ADC $7F837B		; |
	STA $7F837B			; | Write character names
	TAX				; |
	SEP #$20			; > A 8-bit
	LDA #$FF : STA $7F837D,x	; \ Write end of table
	DEX				; /
	DEY				; |
-	LDA .Table,y			; |	($04:F4B2)
	STA $7F837D,x			; |
	DEX				; |
	DEY				; |
	BPL -				;/

	INX				; > Get index to start of upload
	STX $0E				; > Backup in $0E
	LDA $7B8B			;\
	AND #$18			; | Only flash certain frames
	EOR #$18			; |
	BEQ .Return			;/
	LDA #$00 : XBA			;\
	LDA $7B8A			; | Y = position of selection
	TAY				;/
-	BEQ .Flash			; > If this is the selection, perform FLASH
	STX $00				;\
	LDA $7F8380,x			; |
	CLC : ADC #$05			; |
	CLC : ADC $00			; |
	XBA : ADC $01			; | Find proper stripe location
	XBA : TAX			; |
	DEY				; |
	BMI .Return			; |
	BRA -				;/

	.Flash
	REP #$20
	LDA $7F8380,x			; > Check length
	AND #$00FF
	TAY
	TXA
	CLC : ADC #$8381
	STA $00
	SEP #$20
	LDA #$7F : STA $02
	LDA #$3C
-	STA [$00],y
	DEY #2
	BPL -

	.Return
	SEP #$20
	LDA !CurrentPlayer
	BEQ .P1

	.P2
	LDA !Characters			;\
	LSR #4				; | Visually disable P1's character
	STA $00				; |
	JSR .Prevent			;/
	LDA $7B8A
	CMP #$01 : BEQ +		;\
	CMP #$04 : BEQ +		; | Only allow legal characters
	CMP #$06 : BEQ +		;/
	AND #$0F : STA $00		;\
	LDA !Characters			; | Store P2 character
	AND #$F0 : ORA $00		; |
	STA !Characters			;/
	LDA #$01 : STA !MultiPlayer	; > Enable multiplayer
	BRA +				; > Return

	.P1
	LDA !MultiPlayer		;\ Ignore P2 if multiplayer is off
	BEQ ..NoPrevent			;/
	LDA !Characters			;\
	AND #$0F			; |
	STA $00				; | Visually disable P2's character
	JSR .Prevent			; |
	..NoPrevent			;/
	LDA $7B8A
	CMP #$01 : BEQ +		; < Luigi not inserted
	CMP #$04 : BEQ +		; < Alter not inserted
	CMP #$06 : BEQ +		; < Drop out function should not be used by P1
	ASL #4 : STA $00		;\
	LDA !Characters			; | Store P1 character
	AND #$0F : ORA $00		; |
	STA !Characters			;/
+	PLB				; > Restore bank
	PLP				; > Restore processor
	RTL				; > Return


	.Prevent
	LDX $0E
	LDA #$00 : XBA			;\ Y = stripe to disable
	LDA $00 : TAY			;/
-	BEQ ..Prevent			;\
	STX $00				; |
	LDA $7F8380,x			; |
	CLC : ADC #$05			; |
	CLC : ADC $00			; | Find proper stripe location
	XBA : ADC $01			; |
	XBA : TAX			; |
	DEY				; |
	BMI ..Return			; |
	BRA -				;/
	..Prevent
	LDA $7F837E,x			;\
	AND.b #$1F^$FF			; | Move 1 step to the right
	ORA #$06			; |
	STA $7F837E,x			;/
	..Return
	RTS


	.ERASE
	LDA.b #..SNES : STA $0183	;\
	LDA.b #..SNES>>8 : STA $0184	; |
	LDA.b #..SNES>>16 : STA $0185	; | Have the SNES do the rest since SA-1 can't access $7E0000-$7FFFFF
	LDA #$D0 : STA $2209		; |
-	LDA $018A : BEQ -		; |
	STZ $018A			;/
	RTL				; > Return

	..SNES
	PHP
	SEP #$30
	PHB : PHK : PLB
	LDA $7B87			;\
	CMP #$02 : BEQ +		; | Only when opening/closing character select menu
	CMP #$04 : BNE ++		;/
+	REP #$30
	LDY.w #.EndClear-.Clear-1
	TYA
	CLC : ADC $7F837B
	STA $7F837B
	TAX
	SEP #$20
-	LDA .Clear,y
	STA $7F837D,x
	DEX
	DEY
	BPL -
	STZ $7B8A			; > Reset selection
++	LDX #$00 : LDA $6DB4		; > Restore overwritten code
	PLB
	PLP
	RTL


	.REMAP1				; > Choosing a level

;	LDA #$00

	LDA !MultiPlayer
	BEQ ..P1
	LDA $6DA7
	ORA $6DA9
..P1	ORA $6DA6
	ORA $6DA8
	RTL


	.REMAP2				; > Choosing a character in the menu
	LDA !CurrentPlayer
	BNE ..P2
	LDA $6DA6			;\ Player 1
	ORA $6DA8			;/
	RTL
..P2	LDA $7B8A
	CMP #$06 : BNE ++
	LDA $6DA7			;\
	ORA $6DA9			; |
	AND #$80 : BEQ +		; | Player 2 dropping out
	LDA #$00 : STA !MultiPlayer	; |
	LDA #$80			;/
+	RTL
++	LDA $6DA7			;\ Player 2 not dropping out
	ORA $6DA9			;/
	RTL


	.REMAP3				; > Enabling free camera
	LDA $6DA6
	AND #$10
	BEQ ..NoP1
	LDA #$00 : STA !CurrentPlayer
	LDA #$10
	RTL
	..NoP1
	LDA $6DA7
	AND #$10
	BEQ ..Return
	LDA #$01 : STA !CurrentPlayer
	LDA #$10
	..Return
	RTL


	.REMAP4				; > Moving on OW

;	LDA #$00


	LDA !MultiPlayer		;\
	BEQ ..P1			; | Include P2 input during multiplayer
	LDA $6DA7			;/
..P1	ORA $6DA6			; > Add P1 input
	AND #$0F			; > Get directional input
	RTL				; > Return


; E	1:80	0x01	> End flag
; H	1:40	0x04	\
; H	1:20	0x02	 | VRAM destination
; H	1:10	0x01	/
; Yh	1:08	0x20	> Hi bit of Y
; Xh	1:04	0x20	> Hi bit of X
; y	1:02	0x10	\
; y	1:01	0x08	 |
; y	2:80	0x04	 | Lo position of y
; y	2:40	0x02	 |
; y	2:20	0x01	/
; xlo	2:1F	0x1F	> lo position of x
; D	3:80	0x01	> Direction (0 = horizontal, 1 = vertical)
; R	3:40	0x01	> RLE flag
; l	3:3F	0x3F	> RLE length
; L	4:FF	0xFF	> Non-RLE length


.Table
db $51,$85,$00,$09			; < "MARIO"
db $16,$28,$0A,$28,$1B,$28,$12,$28,$18,$28
db $51,$A5,$00,$09			; < "LUIGI"
db $15,$28,$1E,$28,$12,$28,$10,$28,$12,$28
db $51,$C5,$00,$0B			; < "KADAAL"
db $14,$28,$0A,$28,$0D,$28,$0A,$28,$0A,$28,$15,$28
db $51,$E5,$00,$0B			; < "LEEWAY"
db $15,$28,$0E,$28,$0E,$28,$20,$28,$0A,$28,$22,$28
db $52,$05,$00,$09			; < "ALTER"
db $0A,$28,$15,$28,$1D,$28,$0E,$28,$1B,$28
.EndEarly
db $52,$45,$00,$0F			; < "DROP OUT"
db $0D,$28,$1B,$28,$18,$28,$19,$28,$FC,$38,$18,$28,$1E,$28,$1D,$28
.EndTable

.Clear
db $51,$85,$40,$10
db $FC,$38
db $51,$A5,$40,$10
db $FC,$38
db $51,$C5,$40,$10
db $FC,$38
db $51,$E5,$40,$10
db $FC,$38
db $52,$05,$40,$10
db $FC,$38
db $52,$45,$40,$10
db $FC,$38
db $FF
.EndClear





; This is actually pretty complicated.
; Each character has 7 components:
; - Upload sprite GFX
; - Upload sprite tilemap
; - Upload sprite palette
; - Unpack portrait
; - Upload portrait GFX
; - Upload portrait tilemap
; - Upload portrait palette

.CharacterTable
	dw ..Mario
	dw ..Luigi
	dw ..Kadaal
	dw ..Leeway
	;dw ..Alter

..Mario

..Luigi

..Kadaal

..Leeway

..Alter



..SpritePal

..SpriteOAM

..MarioPortrait

..LuigiPortrait

..KadaalPortrait

..LeewayPortrait

..AlterPortrait

..UploadPortrait

..UploadPalette

..DrawPortrait

;=========;
;BRK RESET;
;=========;
BRK:

		SEP #$30			; Make sure the SNES is doing this
		TSC
		XBA
		CMP #$37 : BNE .SNES
		LDA.b #.SNES : STA $0183
		LDA.b #.SNES>>8 : STA $0184
		LDA.b #.SNES>>16 : STA $0185
		LDA #$D0 : STA $2209
		BRA $FE

		.SNES
		STZ $4200			; Set up RESET
		SEI
		SEP #$30
		LDA #$FF
		STA $2141
		LDA #$00
		PHA : PLB
		STZ $420C

		REP #$20
		LDA #$8008 : STA $4300
		LDA.w #.some00 : STA $4302
		LDA.w #.some00>>8 : STA $4303
		STZ $4305
		STZ $2181
		STZ $2182
		LDX #$01 : STX $420B
		STZ $4305
		STZ $2181
		STX $2183
		STX $420B
		SEP #$20

	;	JML $008016
		JML $000000+read2($00FFFC)	; Go to RESET vector


	.some00
		db $00

End:
print "$", hex(End-$138000), " bytes used"



;=================;
;BLOCK ADJUSTMENTS;
;=================;
org $00F05C+$0D
	db $07		; org: $06

org $00F0C8+$0D


;=======;
;HIJACKS;
;=======;

org $00828C
	JSL HDMA_FIX_Y			;\ Source: LDY $6D9F : STY $420C
	NOP #2				;/

org $0082B6
	JSL HDMA_FIX_A			;\ Source: LDA $6D9F : STA $420C
	NOP #2				;/


;org $00939A				; Game mode 00 routine
;	JSL CLEAR_CHARACTERS		; now handled by SP_Menu.asm

; skip the LDA #$0F : STA !2100 opcodes at $0093CA
org $0096AB
	JMP $93CF			; org: JMP $93CA
org $009756
	JMP $93CF			; org: JMP $93CA

org $009E24
	LDA #$04 : STA $6DB4,x

org $009F66
	LDA #$0F			; < Enable mosaic on all layers


org $00CA2B
	JML FIX_MIDWAY			;\ Source: LDA #$01 : STA $13CE
	NOP				;/

org $00D0D5
	BRA +				; skip game over check
org $00D0E6
	+
org $00D0B6
	JML DELAY_DEATH			; Source : STZ $19 : LDA #$3E

org $00D0D8
	NOP #3				;\ Skip game over code (source: DEC $6DBE : BPL $09)
	BRA $09				;/
org $00E98F
	BEQ $10				; Disable side exit for Mario (Source: BEQ $10)


org $00F545
	JML MAP16_EXPAND		;\ org: TAY : BNE $2F ($00F577) : LDY $7693
	NOP #2				;/

org $00F60C
	NOP : NOP : NOP			; Source : STA $1DFB

org $00F79D
	JML SCROLL_OPTIONS		; Source: LDY $1413 : BEQ $08 (00F7AA)

org $01C39D
	db $20				; Priority set by powerups

org $01C4A2
	db $20				; Priority set by powerups

org $01EC3D
	NOP : NOP : NOP			; Prevent Yoshi from saying anything when he hatches. (Source: STA $1426)

org $0288F9
	JML UpBlock			; > Source: CPY #$0C : BNE $08 ($028905)

org $0296C0
;	JML SmokeFix			;\ Main routine for smoke sprites
;	NOP				;/ Source: LDA $77C0,x : BEQ $12 ($0296D7)

	LDA !Ex_Num,x : BEQ $12


org $02A3F6
	BRA $06 : NOP #6		; source: LDA !Ex_Data3,x : EOR $1779,x : BNE Return


org $048086

;	JSL CLEAR_PLAYER2		; Hijack some Overworld routine
		REP #$30
		STZ $03

org $04824B
	HIDEOUT_CHECK:
		BEQ .Skip		; Enable an unused beta routine

		; There's 20 bytes of unused code here, so I'm not overwriting anything important.

		LDA $6DA4
		ORA $6DA8
		BNE .Skip
		JML LOAD_HIDEOUT
		dl GENERATE_BLOCK	;\ 8 bytes free at $048259, used as vectors
		NOP #5			;/
		.Skip

org $04828A
	BRA $03 : NOP #3		; LDY $6DB2 : BEQ $06, enable character select always

org $048366
	JSL CHARACTER_SELECT_REMAP3	;\ LDA $6DA8 : ORA $6DA9
	NOP #2				;/
	NOP #2				; > AND #$30

org $04837D
	LDA $18				;\ LDA $16 : AND #$10
	AND #$40			;/

org $049150
	JSL CHARACTER_SELECT_REMAP1	;\ LDA $16 : ORA $18
	AND #$80			;/ AND #$C0

org $04925F
	JSL CHARACTER_SELECT_REMAP4	; > LDA $16 : AND #$0F

org $04F415
	JSL CHARACTER_SELECT_ERASE	;\ LDX #$00 : LDA $6DB4
	NOP				;/

org $04F513
	JSL CHARACTER_SELECT_REMAP2	;\ LDA $6DA6 : ORA $6DA7
	NOP #2				;/
	AND #$80			; > AND #$10

org $04F52B
	JSL CHARACTER_SELECT		;\ LDA $6DA6 : AND #$C0
	RTS				;/

org $05B161
	JML SideExitFix			; STZ $6109 : LDA #$00
	NOP

org $05D80B
	JSL EntranceFix			; org: STA $1C : LDA $00 (need to update camera backup here)

org $05D89B
	JSL LOAD_HIDEOUT_Load		; Hijack level load init

org $05D9D7
;	JML CHECKPOINTS			; Checkpoint check routine
;	NOP

	LDA !LevelTable1,x
	AND #$40


;==========;
;FREE $6F40;
;==========;
org $05CD04
	NOP #3		; STA

org $05CEDD
	NOP #3		;\ LDA : BEQ
	BRA $23		;/

org $05CEED
	NOP #3		; STA

org $05CF36
	NOP #5		; LDA : BNE

org $05CF66
	NOP #3		;\ LDA : BEQ
	BRA $35		;/

;=========;
;BUILD OAM;
;=========;

;org $008449
;	STZ $4300
;	REP #$20
;	STZ $2102
;	LDA #$0004 : STA $4301
;	LDA.w #!OAM>>8 : STA $4303
;	LDA #$0220 : STA $4305
;	LDY #$01 : STY $420B
;	SEP #$20
;	LDA #$80 : STA $2103
;	LDA $3F : STA $2102
;	RTS
;warnpc $008475


org $008494
				; < This is hijacked by SA-1 but WE'RE OVERWRITING IT!! >:D
	LDA.b #BUILD_OAM_Assemble	;\
	STA $3180			; |
	LDA.b #BUILD_OAM_Assemble>>8	; |
	STA $3181			; | Send SA-1 to subroutine
	LDA.b #BUILD_OAM_Assemble>>16	; |
	STA $3182			; |
	JMP $1E80			;/
	NOP #34				; > Wipe the rest of the routine
warnpc $0084C8


;==============;
;KILL OAM REMAP;
;==============;

org $008027
	BRA +
org $00804A
	+
org $008642
	JSL KILL_OAM
org $0094FD
	JSL KILL_OAM
org $0095AB
	JSL KILL_OAM
org $009632
	JSL KILL_OAM
org $009759
	JSL KILL_OAM
org $009870
	JSL KILL_OAM
org $009888
	JSL KILL_OAM
org $009A6F
	JSL KILL_OAM
org $009C9F
	JSL KILL_OAM
;org $00A1C3				;\ main hijack for realm select
;	JSL KILL_OAM			;/
;org $00A295				;\ This one is handled by SP_Level
;	JSL KILL_OAM_Special		;/


;================;
;BRK RESET MAPPER;
;================;

org $00FFE6
	dw $8A58
org $00FFF6
	dw $8A58


org $008A58
	JML BRK


print " "