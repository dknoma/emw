NPC:

	namespace NPC

		!ID		=	$BE,x
		!Talking	=	$32B0,x
		!TalkTimer	=	$32E0,x


	INIT:
		PHB : PHK : PLB				; > Start of bank wrapper
		REP #$20				; > A 16-bit
		LDA.l !NPC_ID+1				;\
		AND #$FF00				; | Check for a defined NPC table
		BNE .TableFound				;/
		LDA.l !NPC_ID+1				;\
		BNE .TableFound				; | If there's no defined NPC table, use the default one
		LDA.w #DEFAULT+0 : STA !NPC_ID+0	; |
		LDA.w #DEFAULT>>8 : STA !NPC_ID+1	;/

		.TableFound
		STA $01					;\
		LDA.l !NPC_ID+0				; | Set up pointer
		STA $00					;/
		LDA.l !NPC_ID+0				;\
		INC A					; | Increment pointer for next NPC
		STA.l !NPC_ID+0				;/
		SEP #$20				; > A 8-bit
		LDA [$00]				;\ Store ID to sprite table
		STA !ID					;/
		TAY					;\ Set idle frame
		LDA ID_Frame,y : STA !SpriteAnimIndex	;/
		BNE +
		LDA #$10 : STA $32D0,x
		+
		PLB					; > End of bank wrapper


	MAIN:
		PHB : PHK : PLB
		LDA $9D
		BEQ PHYSICS
		JMP GRAPHICS

	DATA:
		.XSpeed
		db $10,$F0
		db $08,$F8

	ID:
		.Frame
		db $00,$07,$13

		.TalkFrame
		db $04,$0F,$1B

		.TalkTime
		db $40,$78,$40

		.TalkStart
		db $01,$00,$01


	PHYSICS:
		LDA $32D0,x
		CMP #$01 : BNE +
		JSL !GetVRAM
		REP #$20
		LDA #$0800 : STA.l !VRAMbase+!VRAMtable+$00,x
		LDA.w #$8008 : STA.l !VRAMbase+!VRAMtable+$02,x
		LDA.w #$3880 : STA.l !VRAMbase+!VRAMtable+$03,x
		LDA #$7000 : STA.l !VRAMbase+!VRAMtable+$05,x
		SEP #$20
		LDX !SpriteIndex
		+

		JSL SUB_HORZ_POS_Long
		TYA
		STA $3320,x

		LDA !TalkTimer					;\
		CMP #$01 : BNE .NoTalk				; |
		LDY !ID						; | End talk animation when timer runs out
		LDA ID_Frame,y : STA !SpriteAnimIndex		; |
		STZ !SpriteAnimTimer				; |
		.NoTalk						;/

		LDA !MsgTrigger					;\ Check if there's a message up right now
		BNE .Msg					;/
		STZ !Talking					; > Stop talking when the message is over
		BRA .NoMsg					; > Then skip talk code

		.Msg
		LDA !Talking : BEQ .NoMsg			; > Check if this NPC is the one talking
		LDA $404431 : BEQ .NoMsg			;\ Check and clear talk anim flag from MSG
		LDA #$00 : STA $404431				;/
		JSR Talk_Anim					; > Trigger talk anim
		.NoMsg


	INTERACTION:
		LDA $3220,x
		SEC : SBC #$20
		STA $04
		LDA $3250,x
		SBC #$00
		STA $0A
		LDA $3210,x
		SEC : SBC #$30
		STA $05
		LDA $3240,x
		SBC #$00
		STA $0B
		LDA #$50 : STA $06
		LDA #$40 : STA $07
		SEC : JSL !PlayerClipping
		BCC .NoTalk
		LSR A : BCC .P2Check
		PHA
		LDA !P2Blocked-$80
		ASL A
		AND $6DA6
		AND #$08
		BEQ .P2
		JSR Talk
	.P2	PLA

		.P2Check
		LSR A : BCC .NoTalk
		LDA !P2Blocked
		ASL A
		AND $6DA7
		AND #$08
		BEQ .NoTalk
		JSR Talk
		.NoTalk




	GRAPHICS:

		.ProcessAnim
		LDA !SpriteAnimIndex
		ASL #2
		TAY
		LDA !SpriteAnimTimer
		INC A
		CMP.w ANIM+2,y
		BNE .SameAnim

		.NewAnim
		LDA ANIM+3,y
		STA !SpriteAnimIndex
		ASL #2
		TAY
		LDA #$00

		.SameAnim
		STA !SpriteAnimTimer
		LDA.w ANIM+0,y : STA $04
		LDA.w ANIM+1,y : STA $05

		LDA !ID
		CMP #$01 : BNE .Tilemap
		REP #$20
		LDA $04 : STA $0C
		CLC : JSL !UpdateGFX
		REP #$20
		LDA.w #ANIM_32x32TM : STA $04
		SEP #$20

		.Tilemap
		JSL LOAD_PSUEDO_DYNAMIC_Long

		PLB
		RTL


	DEFAULT:
		db $00,$01,$02,$03,$04,$05,$06,$07
		db $08,$09,$0A,$0B,$0C,$0D,$0E,$0F


	Talk:
		LDA #$01 : STA !Talking			; > This NPC is the one talking
		LDY !ID					;\
		TYA					; | Set message
		INC A					; |
		STA !MsgTrigger				;/
		LDA ID_TalkStart,y			;\ Return if talk at start is not set
		BEQ .Return				;/

		.Anim
		LDY !ID					;\
		LDA ID_TalkFrame,y			; |
		STA !SpriteAnimIndex			; | Load animation data based on ID
		STZ !SpriteAnimTimer			; |
		LDA ID_TalkTime,y : STA !TalkTimer	;/

		.Return
		RTS


	ANIM:

	; Survivor's GFX is really small
	; He's not dynamic
		dw .SurvivorIdle0 : db $FF,$01		; 00
		dw .SurvivorIdle1 : db $08,$02		; 01
		dw .SurvivorIdle2 : db $08,$03		; 02
		dw .SurvivorIdle1 : db $08,$00		; 03

		dw .SurvivorTalk0 : db $03,$05		; 04
		dw .SurvivorTalk1 : db $0C,$06		; 05
		dw .SurvivorTalk0 : db $03,$00		; 06

	; Tinkerer's pointers are actually dynamos
	; His tilemap is always the same 32x32
		dw .TinkererIdle0 : db $1D,$08		; 07
		dw .TinkererIdle1 : db $05,$09		; 08
		dw .TinkererIdle2 : db $05,$0A		; 09
		dw .TinkererIdle3 : db $05,$0B		; 0A
		dw .TinkererIdle4 : db $05,$0C		; 0B
		dw .TinkererIdle5 : db $05,$0D		; 0C
		dw .TinkererIdle6 : db $1D,$0E		; 0D
		dw .TinkererIdle1 : db $05,$07		; 0E

		dw .TinkererTalk0 : db $06,$10		; 0F
		dw .TinkererTalk1 : db $06,$11		; 10
		dw .TinkererTalk2 : db $06,$12		; 11
		dw .TinkererTalk3 : db $06,$0F		; 12

	; Melody has a tiny GFX so she gets non-dynamic tilemaps
		dw .MelodyIdle0 : db $08,$14		; 13
		dw .MelodyIdle1 : db $06,$15		; 14
		dw .MelodyIdle0 : db $08,$16		; 15
		dw .MelodyIdle2 : db $06,$13		; 16

		dw .MelodyWalk0 : db $08,$18		; 17
		dw .MelodyWalk1 : db $08,$19		; 18
		dw .MelodyWalk0 : db $08,$1A		; 19
		dw .MelodyWalk2 : db $08,$17		; 1A

		dw .MelodyTalk0 : db $08,$1C		; 1B
		dw .MelodyTalk1 : db $1E,$1D		; 1C
		dw .MelodyTalk0 : db $08,$13		; 1D


	.32x32TM
		dw $0010
		db $2A,$F8,$F0,$C0
		db $2A,$08,$F0,$C2
		db $2A,$F8,$00,$E0
		db $2A,$08,$00,$E2

	.SurvivorIdle0
		dw $000C
		db $29,$F8,$F0,$00
		db $29,$F8,$00,$20
		db $29,$00,$00,$21
	.SurvivorIdle1
		dw $0010
		db $29,$F8,$F0,$03
		db $29,$00,$F0,$04
		db $29,$F8,$00,$23
		db $29,$00,$00,$24
	.SurvivorIdle2
		dw $000C
		db $29,$F8,$F0,$06
		db $29,$F8,$00,$26
		db $29,$00,$00,$27
	.SurvivorTalk0
		dw $0010
		db $29,$F7,$F0,$09	; 1px to the left since I moved it in the GFX file
		db $29,$FF,$F0,$0A
		db $29,$F7,$00,$29
		db $29,$FF,$00,$2A
	.SurvivorTalk1
		dw $0010
		db $29,$F0,$F0,$0C
		db $29,$00,$F0,$0E
		db $29,$F0,$00,$2C
		db $29,$00,$00,$2E


macro TinkererDyn(TileCount, SourceTile, DestVRAM)
	dw <TileCount>*$20
	dl <SourceTile>*$20+$388808
	dw <DestVRAM>*$10+$6000
endmacro


	.TinkererIdle0
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $000, $0C0)
		%TinkererDyn(4, $010, $0D0)
		%TinkererDyn(4, $020, $0E0)
		%TinkererDyn(4, $030, $0F0)
		..End
	.TinkererIdle1
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $004, $0C0)
		%TinkererDyn(4, $014, $0D0)
		%TinkererDyn(4, $024, $0E0)
		%TinkererDyn(4, $034, $0F0)
		..End
	.TinkererIdle2
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $008, $0C0)
		%TinkererDyn(4, $018, $0D0)
		%TinkererDyn(4, $028, $0E0)
		%TinkererDyn(4, $038, $0F0)
		..End
	.TinkererIdle3
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $00C, $0C0)
		%TinkererDyn(4, $01C, $0D0)
		%TinkererDyn(4, $02C, $0E0)
		%TinkererDyn(4, $03C, $0F0)
		..End
	.TinkererIdle4
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $040, $0C0)
		%TinkererDyn(4, $050, $0D0)
		%TinkererDyn(4, $060, $0E0)
		%TinkererDyn(4, $070, $0F0)
		..End
	.TinkererIdle5
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $044, $0C0)
		%TinkererDyn(4, $054, $0D0)
		%TinkererDyn(4, $064, $0E0)
		%TinkererDyn(4, $074, $0F0)
		..End
	.TinkererIdle6
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $048, $0C0)
		%TinkererDyn(4, $058, $0D0)
		%TinkererDyn(4, $068, $0E0)
		%TinkererDyn(4, $078, $0F0)
		..End
	.TinkererTalk0
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $04C, $0C0)
		%TinkererDyn(4, $05C, $0D0)
		%TinkererDyn(4, $06C, $0E0)
		%TinkererDyn(4, $07C, $0F0)
		..End
	.TinkererTalk1
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $080, $0C0)
		%TinkererDyn(4, $090, $0D0)
		%TinkererDyn(4, $0A0, $0E0)
		%TinkererDyn(4, $0B0, $0F0)
		..End
	.TinkererTalk2
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $084, $0C0)
		%TinkererDyn(4, $094, $0D0)
		%TinkererDyn(4, $0A4, $0E0)
		%TinkererDyn(4, $0B4, $0F0)
		..End
	.TinkererTalk3
		dw ..End-..Start
		..Start
		%TinkererDyn(4, $088, $0C0)
		%TinkererDyn(4, $098, $0D0)
		%TinkererDyn(4, $0A8, $0E0)
		%TinkererDyn(4, $0B8, $0F0)
		..End


	.MelodyIdle0
		dw $0008
		db $28,$00,$F8,$00
		db $28,$00,$00,$10
	.MelodyIdle1
		dw $0008
		db $28,$00,$F8,$02
		db $28,$00,$00,$12
	.MelodyIdle2
		dw $0008
		db $28,$00,$F8,$04
		db $28,$00,$00,$14
	.MelodyWalk0
		dw $0008
		db $28,$00,$F8,$06
		db $28,$00,$00,$16
	.MelodyWalk1
		dw $0008
		db $28,$00,$F8,$08
		db $28,$00,$00,$18
	.MelodyWalk2
		dw $0008
		db $28,$00,$F8,$0A
		db $28,$00,$00,$1A
	.MelodyTalk0
		dw $0008
		db $28,$00,$F8,$0C
		db $28,$00,$00,$1C
	.MelodyTalk1
		dw $0008
		db $28,$00,$F8,$0E
		db $28,$00,$00,$1E




	namespace off





