Projectile:

	namespace Projectile


; This sprite is quite customizible.
; Behaviour is determined by $BE,x and graphics are determined by $33D0,x
; Setting the highest bit of $BE,x will cause the sprite to animate.
; $33E0 is number of frames.
; $3340 is current frame.
; $3420 is how long current frame should be shown.
; $3310 is how long to show each frame.


; --Defines--

	!LastFrame	= $33E0,x
	!CurrentFrame	= $3340,x
	!AnimTimer	= $3420,x
	!AnimFreq	= $3310,x
	!AnimType	= $35D0,x		; 00 = normal type
						; 01 = spinning type
						; 02 = big type


	!HardProp	= $3410,x		; Setting this causes sprite to use $33C0,x for YXPPCCCT


		INIT:
		MAIN:
		PHB : PHK : PLB
		JSR SPRITE_OFF_SCREEN		; Handle sprite while offscreen
		LDA $3230,x
		SEC : SBC #$08
		ORA $9D
		BNE Graphics
		LDA $7493
		BEQ LoadAction
		STZ $32D0,x			; Kill sprite
LoadAction:	PHX				; Preserve sprite index
		LDA $BE,x
		AND #$3F
		ASL A
		TAX				; X = pointer index
		JMP (ActionPointer,x)
ReturnAction:	LDA $32D0,x			; Check life timer
		BNE Graphics
		BIT $BE,x
		BVC +
		STZ $3230,x
		PLB
		RTL

	+	LDA #$04
		STA $3230,x			; Kill sprite
		LDA #$1F
		STA $32D0,x
		STA $3300,x			; > Prevent player 2 glitch
		PLB
		RTL

Graphics:	LDA !AnimType
		CMP #$02 : BNE .NormalType

		.BigType
		LDA !HardProp : BEQ +
		LDA $33C0,x
		BRA ++
	+	LDY $3320,x			;\
		LDA Property,y			; | YXPPCCCT byte (basic)
	++	STA $00				;/
		LDA $33D0,x : STA $01
		REP #$20
		LDA #$0010 : STA $6F86+$00
		LDA #$F8F8 : STA $6F86+$03
		LDA #$F808 : STA $6F86+$07
		LDA #$08F8 : STA $6F86+$0B
		LDA #$0808 : STA $6F86+$0F
		SEP #$20

		LDA $14
		AND #$04
		BEQ $02 : LDA #$01
		TAY
		LDA $00
		CLC : ADC BigTiles+0,y
		STA $6F86+$05
		INC #2
		STA $6F86+$09
		CLC : ADC BigTiles+2,y
		STA $6F86+$0D
		INC #2
		STA $6F86+$11

		LDA $14
		AND #$04
		BEQ $02 : LDA #$80
		EOR $01
		STA $6F86+$02
		STA $6F86+$06
		STA $6F86+$0A
		STA $6F86+$0E
		JMP FinishGFX


		.NormalType
		LDA #$04
		STA $6F86+$00			;\ Tilemap size: 4 bytes
		STZ $6F86+$01			;/
		STZ $6F86+$03			; > No Xdisp
		STZ $6F86+$04			; > No Ydisp
		LDA !HardProp : BEQ +
		LDA $33C0,x
		BRA ++
	+	LDY $3320,x			;\
		LDA Property,y			; | YXPPCCCT byte (basic)
	++	STA $6F86+$02			;/
		LDA !AnimType
		CMP #$01 : BNE .ReallyNormal

		.SpinType
		LDA $14
		AND #$0C
		LSR #2
		TAY
		LDA $33D0,x
		CLC : ADC SpinTile,y
		STA $6F86+$05
		LDA $6F86+$02
		EOR SpinFlip,y
		STA $6F86+$02
		BRA FinishGFX


		.ReallyNormal
		LDA !AnimTimer
		BNE +
		LDA !AnimFreq
		STA !AnimTimer
		LDA !CurrentFrame
		INC A
		CMP !LastFrame
		BNE ++
		LDA #$00
	++	STA !CurrentFrame
	+	LDA !CurrentFrame
		ASL A
		STA $03				; > $03 = frame
		BIT $BE,x			; Check highest bit
		BMI Animate
		STZ $03				; > Clear animation frequency
Animate:	LDA $33D0,x			;\
		CLC : ADC $03			; | Write tile number
		STA $6F86+$05			;/

FinishGFX:	LDA.b #$6F86 : STA $04
		LDA.b #$6F86>>8 : STA $05
		JSR LOAD_TILEMAP
ReturnMAIN:	PLB
		RTL

Property:	db $75				; Y0 X1 PP11 CCC010 T1
		db $35				; Y0 X0 PP11 CCC010 T1

BigTiles:	db $00,$20,$1E,$DE

SpinTile:	db $00,$02,$00,$02
SpinFlip:	db $00,$00,$C0,$C0





ActionPointer:	dw Action00
		dw Action01
		dw Action02
		dw BigShot

Action00:	PLX				; X = sprite index

		BIT $BE,x
		BVC +
		JSL $01801A
		JSL $018022
		LDA $9E,x
		CLC : ADC #$03
		BMI ++
		CMP #$40
		BCC $02 : LDA #$40
	++	STA $9E,x
		JMP ReturnAction

	+	JSL $01802A			; Apply speed with gravity

		LDA !AnimType : BNE NoXFlip00	; Don't xflip if spin is set
		LDA $14
		AND #$08			; Xflip sprite every 08 frames
		BNE NoXFlip00
		LDA $3320,x
		EOR #$01
		STA $3320,x
NoXFlip00:	LDA $32E0,x
		ORA !P1Dead
		BNE NoContact00
		JSL $03B664			;\
		JSL $03B69F			; | Check for Mario contact
		JSL $03B72B			;/
		BCC NoContact00
		JSL $00F5B7			; Hurt Mario
		STZ $32D0,x			; Kill sprite
NoContact00:	LDA $3330,x
		BEQ Return00
		STZ $32D0,x			; Kill sprite
Return00:	JMP ReturnAction


XSpeed_01:	db $01,$FF

Action01:	PLX				; X = sprite index
		JSL $01802A			; Apply speed with gravity
		LDA #$01
		STA $00				; Set up loop
		LDA $14
		AND #$0F
		BNE EndLoop01			; Only spawn every 0F frames
		LDY #$0C
Loop01:		DEY
		BMI EndLoop01
		LDA $77F0,y
		BNE Loop01
		LDA #$01			;\ Minor ExSprite = Brick Piece
		STA $77F0,y			;/
		LDA $3210,x			;\
		CLC				; |
		ADC #$0C			; |
		STA $77FC,y			; |
		LDA $3240,x			; | Spawn 0C pixels below sprite
		ADC #$00			; |
		STA $7814,y			; |
		LDA $3220,x			; |
		STA $7808,y			; | Spawn at sprite pos
		LDA $3250,x			; |
		STA $78EA,y			;/
		LDA #$FD			;\ Set Y speed
		STA $7820,y			;/
		PHY				;\
		LDY $00				; |
		LDA XSpeed_01,y			; | Set X speed
		PLY				; |
		STA $782C,y			;/
		LDA #$00			;\ Set timer
		STA $7850,y			;/
		DEC $00
		BPL Loop01			; Loop once
EndLoop01:	LDA $32E0,x
		ORA !P1Dead
		BNE NoContact01
		JSL $03B664			;\
		JSL $03B69F			; | Check for Mario contact
		JSL $03B72B			;/
		BCC NoContact01
		JSL $00F5B7			; Hurt Mario
NoContact01:	LDA $3330,x
		AND #$03
		BEQ Return01
		STZ $32D0,x			; Kill sprite
Return01:	JMP ReturnAction

Action02:	PLX
		JSL $01801A
		JSL $018022
		LDA $32E0,x
		ORA !P1Dead
		BNE Return02
		JSL $03B664			;\
		JSL $03B69F			; | Check for Mario contact
		JSL $03B72B			;/
		BCC Return02
		JSL $00F5B7			; Hurt Mario
Return02:	JMP ReturnAction

BigShot:	PLX
		STZ $9E,x			;\ Apply speed with gravity but no y speed
		JSL $01802A			;/
		LDA $3330,x
		AND #$0F : BNE .Kill
		LDA $3220,x
		SEC : SBC #$02
		STA $04
		LDA $3250,x
		SBC #$00
		STA $0A
		LDA $3210,x
		SEC : SBC #$02
		STA $05
		LDA $3240,x
		SBC #$00
		STA $0B
		LDA #$14
		STA $06
		STA $07
		LDA !P1Dead : BNE .Return
		JSL !GetP1Clipping
		JSL !CheckContact
		BCC .Return
		JSL $00F5B7

		.Kill
		STZ $32D0,x
.Return		JMP ReturnAction


	namespace off


