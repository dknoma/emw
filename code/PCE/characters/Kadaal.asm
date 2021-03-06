;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

namespace Kadaal

; --Build 6.7--
;
;
; Upgrade data:
;	bit 0 (01)	Senku smash
;	bit 1 (02)	Can senku in 8 directions
;	bit 2 (04)	Can start senku in midair
;	bit 3 (08)	----
;	bit 4 (10)	----
;	bit 5 (20)	+1 HP, getting hit during shell slide will not deal damage to you (but will still knock you back)
;	bit 6 (40)	----
;	bit 7 (80)	Push X to perform ultimate attack


; new upgrade layout:
;	bit 0	senku smash
;	bit 1	directional senku
;	bit 2	air senku
;	bit 3	shadow step
;	bit 4	fancy footwork (backdash/pivot)
;	bit 5	sturdy shell
;	bit 6	---- ????
;	bit 7	ultimate: shun koopa satsu



	MAINCODE:
		PHB : PHK : PLB

		LDA #$02 : STA !P2Character
		LDA #$02 : STA !P2MaxHP
		LDA !KadaalUpgrades		;\
		AND #$20			; | +1 Max HP with upgrade
		BEQ $03 : INC !P2MaxHP		;/
		LDA !P2Status : BEQ .Process
		STZ !P2Invinc
		CMP #$02 : BEQ .SnapToP1
		CMP #$03 : BNE .KnockedOut

		.Snapped			; State 03
		REP #$20
		LDA $94 : STA !P2XPosLo
		LDA $96 : STA !P2YPosLo
		SEP #$20
		PLB
		RTS

		.KnockedOut			; State 01
		JSL CORE_KNOCKED_OUT
		BMI .Fall
		BCC .Fall
		LDA #$02 : STA !P2Status
		PLB
		RTS

		.Fall
		LDA #!Kad_Dead : STA !P2Anim
		STZ !P2AnimTimer
		JMP ANIMATION_HandleUpdate

		.SnapToP1			; State 02
		REP #$20
		LDA !P2XPosLo
		CMP $94
		BCS +
		ADC #$0004
		BRA ++
	+	SBC #$0004
	++	STA !P2XPosLo
		SEC : SBC $94
		BPL $03 : EOR #$FFFF
		CMP #$0008
		BCS +
		INC !P2Status
	+	SEP #$20

		.Return
		PLB
		RTS

		.Process				; State 00
		LDA !P2MaxHP				;\
		CMP !P2HP				; | Enforce max HP
		BCS $03 : STA !P2HP			;/

		REP #$20						;\
		LDA !P2Hitbox2IndexMem1 : TSB !P2Hitbox1IndexMem1	; | merge index mem for hitboxes
		SEP #$20						;/

		LDA !P2JumpLag
		BEQ $03 : DEC !P2JumpLag
		LDA !P2HurtTimer
		BEQ $03 : DEC !P2HurtTimer
		LDA !P2Invinc
		BEQ $03 : DEC !P2Invinc
		LDA !P2Senku
		BEQ $03 : DEC !P2Senku
		LDA !P2Punch1
		BEQ $03 : DEC !P2Punch1
		LDA !P2Punch2
		BEQ $03 : DEC !P2Punch2
		LDA !P2SlantPipe
		BEQ $03 : DEC !P2SlantPipe
		LDA !P2BackDash
		BEQ $03 : DEC !P2BackDash

		LDA !P2ShellSpin
		BEQ +
		BPL ++
		INC !P2ShellSpin
		BRA +
	++	DEC !P2ShellSpin : BNE +
		LDA #$F0 : STA !P2ShellSpin
		LDA !P2ShellSlide : BNE ++
		LDA !P2Ducking : BEQ ++
		LDA #!Kad_Duck+1
		BRA +++
	++	LDA #!Kad_Shell
	+++	STA !P2Anim
		STZ !P2AnimTimer
		STZ !P2Buffer
		+


	PIPE:
		JSL CORE_PIPE
		BCC $03 : JMP ANIMATION_HandleUpdate



	CONTROLS:

		JSL CORE_COYOTE_TIME


		LDA !P2InAir : BNE .NoForceCrouch	;\
		JSL CORE_CHECK_ABOVE			; |
		BCC .NoForceCrouch			; | force down input if kadaal is on ground with a solid block above
		LDA #$04 : TSB $6DA3			; |
		.NoForceCrouch				;/


		LDX !P2Direction
		LDA !P2ShellSlide : BNE .Turn
		LDA !P2Climbing : BNE .Turn
		LDA !P2Water : BNE .Turn
		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		BEQ .NoTurn

		.Turn
		LDX #$FF

		.NoTurn
		PHX
		PEA PHYSICS-1

		LDA !P2HurtTimer : BEQ $01 : RTS

		LDA !P2Climbing : BEQ $03 : JMP .NoDuck

		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		ORA !P2SpritePlatform
		BNE ..Ground
		LDA !P2ShellSlide : BNE .ShellSlide	; maintain shell slide in midair
		JMP .NoGround

	..Ground
;		LDA !P2BackDash
;		CMP #$08 : BCC ..BackDash
;		BRA ..NoDir

	..BackDash
;		LDA $6DA9
;		AND #$30 : BEQ .NoBackDash
;		AND #$10 : BEQ +
;		LDA !P2Direction			; R is perfect pivot
;		INC A
;		TSB $6DA3
;		EOR #$03
;		TRB $6DA3
;	+	LDA #$10 : STA !P2BackDash
;		LDA $6DA3
;		AND #$03 : BEQ +
;		CMP #$03 : BEQ +
;		DEC A
;		EOR #$01
;		STA !P2Direction
;		BRA ++
;	+	LDA !P2Direction
;	++	EOR #$01
;		TAY
;		LDA .XSpeedSenku,y : JSL CORE_SET_XSPEED
;		LDA #$2D : STA !SPC1			; slide SFX
;		STZ !P2Punch1
;		STZ !P2Punch2
;		STZ !P2Senku
;	..NoDir	LDA #$0F				;\
;		TRB $6DA3				; | clear directionals during back dash
;		TRB $6DA7				;/
;		LDA #$01 : STA !P2Dashing
		.NoBackDash


		LDA !P2ShellDrill : BEQ .NoPound		;\
		STZ !P2ShellDrill				; |
		JSR .StartSpin					; | shell drill landing
		LDA #$09 : STA !SPC4				; > smash SFX
		LDA #$17 : STA !P2JumpLag			; |
		LDA #!Kad_DrillLand : STA !P2Anim		; |
		RTS						; |
		.NoPound					;/


		LDA !P2Anim					;\
		CMP #!Kad_DrillLand : BCC .NoDrillLand		; | force crouch physics during drill land
		JMP .ForceCrouch				; |
		.NoDrillLand					;/


		.ShellSlide					;\
		LDA $6DA3					; |
		AND #$04 : BNE +				; |
		LDA !P2ShellSlide : BEQ ++			; |
		LDA #$01 : STA !P2Dashing			; > shell slide can be canceled into a dash
	++	STZ !P2ShellSlide				; |
		STZ !P2ShellSpeed				; |
		BRA .NoGround					; |
	+	LDA !P2ShellSlide : BEQ .NoGround		; |
	-	JSR .GSpin					; > Hook ground spin here
		LDA !P2Blocked					; |
		AND #$03 : BEQ +				; |
		DEC A						; |
		AND #$01					; | Shell slide code
		STA !P2Direction				; |
		LDA !P2XSpeed					; |
		EOR #$FF : INC A				; |
		STA !P2XSpeed					; |
		LDA #$01 : STA !SPC1				; |
	+	LDY !P2Direction				; |
		LDA !P2XSpeed					; |
		SEC : SBC .XSpeedSenku,y			; |
		INC A						; |
		CMP #$03 : BCC +				; |
		LDA !P2XSpeed					; |
		CLC : ADC .ShellSlideAcc,y			; |
		BRA ++						; |
	+	LDA .XSpeedSenku,y				; |
	++	JSL CORE_SET_XSPEED				; |
		LDA #$01 : STA !P2ShellSpeed			; |
		LDA #$03					; |
		TRB $6DA3					; |
		TRB $6DA7					; |
	-	JMP .NoDuck					; |
		.NoGround					;/

		LDA !P2Senku : BEQ +
		CMP #$20 : BCC -
	+	LDA !P2Blocked
		LDY !P2Platform
		BEQ $02 : ORA #$04
		AND $6DA3
		AND #$04 : BEQ .NoDuck
		BIT $6DA7
		BPL $03 : JMP .SenkuJump
		LDA !P2Senku : BEQ +			;\
		LDA $6DA7				; | must press down to cancel senku (this allows senku out of shell slide)
		AND #$04 : BEQ .NoDuck			; |
		+					;/

		LDA !P2Water : BNE .ForceCrouch		; can't shell slide underwater
	;	LDA !KadaalUpgrades			;\
	;	AND #$08 : BEQ .ForceCrouch		; > no more upgrade requirement for shell slide
		LDA !P2Slope : BNE +			; > always start sliding on slopes
		LDA !P2XSpeed				; |
		BPL $03 : EOR #$FF : INC A		; | start shell slide with enough speed
		CMP #$20 : BCC .ForceCrouch		; |
	+	JSR StartSlide				; |
		JMP .Friction				;/ > skip remaining inputs this frame


	.ForceCrouch
		LDA #$00 : JSL CORE_SET_XSPEED
		LDA #$01 : STA !P2Ducking
		STZ !P2Punch1
		STZ !P2Punch2
		STZ !P2Dashing
		STZ !P2Senku
	.GSpin	LDA !P2ShellSpin : BNE .SpinR		;\
	;	LDA !KadaalUpgrades			; |
	;	AND #$40 : BEQ .SpinR			; |
		BIT $6DA7 : BVC .SpinR			; | ground spin
		.StartSpin				; > JSR here to start spin
		LDA #$10 : STA !P2ShellSpin		; |
		LDA #!Kad_Spin : STA !P2Anim		; |
		LDA #$3E : STA !SPC4			; | > spin SFX
		STZ !P2Hitbox1IndexMem1			; |
		STZ !P2Hitbox1IndexMem2			; |
		STZ !P2AnimTimer			;/
	.SpinR	RTS
		.NoDuck


		STZ !P2Ducking
		LDA !P2Senku
		BNE $03 : JMP .InitSenku
		CMP #$20 : BCC .ProcessSenku
		BNE .NoInitSenku			;\ Set invulnerability timer
		STA !P2Invinc				;/
		LDA !KadaalUpgrades			;\
		AND #$02 : BEQ ..Basic			; | Store all-range senku direction if upgrade is attained
		LDA $6DA3				; |
		AND #$0F : STA !P2AllRangeSenku		;/
		..Basic
		LDA $6DA3
		LSR A : BCC +
		LDA #$01 : STA !P2SenkuDir
		BRA .ProcessSenku
	+	LSR A : BCS +

		.NoInitSenku
		LDA !P2Direction : STA !P2SenkuDir
		LDA #$00
		BRA .ReturnSenku

	+	STZ !P2SenkuDir

		.ProcessSenku
		LDA #$01 : STA !P2ShellSpeed
		LDA #$0F
		STA !P2DashTimerR2
		STA !P2DashTimerL2
		LDA #$01 : STA !P2Dashing

		LDY !P2AllRangeSenku : BEQ ..Basic	;\
		CPY #$03 : BCC ..Fast			; |
		STZ !P2ShellSpeed			; |
	..Fast	LDA .AllRangeSpeedY,y : STA !P2YSpeed	; | Allow for 2-dimensional travel with upgrade
		LDA .AllRangeSpeedX,y			; |
		BRA .ReturnSenku_Write			;/

	..Basic	LDY !P2SenkuDir
		LDA .XSpeedSenku,y

		.ReturnSenku
		STZ !P2YSpeed
	..Write	JSL CORE_SET_XSPEED
		STZ !P2JumpLag
		STZ !P2DashTimerR1
		STZ !P2DashTimerL1
		STZ !P2Buffer
		STZ !P2Climbing
		LDA !P2Senku
		CMP #$20
		BCS +
		LDA !P2SenkuDir					;\
		EOR #$01					; |
		INC A						; | Don't keep momentum after senku-ing into a block
		AND !P2Blocked					; |
		BEQ $06						; |
		STZ !P2XSpeed : STZ !P2Dashing			;/
		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		BNE ++
		LDA #$01 : STA !P2SenkuUsed
		++
		BIT $6DA7
		BPL $06 : STZ !P2Invinc : JMP .SenkuJump
	+	RTS

		.InitSenku
		LDA !P2SenkuUsed : BNE .NoSenku
		LDA !KadaalUpgrades				;\
		ORA !P2Blocked					; | air senku is only allowed with proper upgrade
		AND #$04					; |
		BEQ .NoSenku					;/

		BIT $6DA9 : BPL .NoSenku
		STZ !P2Climbing					; drop from net/vine
		LDA !P2ShellSpin : BMI $02 : BNE .NoSenku
		STZ !P2ShellSlide				;\ end slide
		STZ !P2ShellSpeed				;/
		STZ !P2Ducking					; end crouch
		STZ !P2Dashing					; end dash
		STZ !P2XSpeed					; clear X speed
		LDA #$30 : STA !P2Senku
		LDA #$01 : STA !P2SenkuUsed
		STZ !P2ShellDrill
		RTS
		.NoSenku


		LDA !P2Climbing : BEQ .NoClimb			; Check for vine/net climb
		STZ !P2ShellSlide
		LDA $6DA3
		LSR A : BCC +
		LDA #$01 : STA !P2Direction
		BRA ++
	+	LSR A : BCC ++
		STZ !P2Direction
	++	BIT $6DA7
		BPL +
		STZ !P2Climbing					; vine/net jump
		LDA #$B8 : STA !P2YSpeed
		LDA #$2B : STA !SPC1				; jump SFX
	+	RTS
		.NoClimb


		.CheckWater
		LDA !P2Blocked					;\
		AND #$04					; |
		LDY !P2Platform					; | $01 = ground flag
		BEQ $02 : ORA #$04				; |
		STA $01						;/
		LDA !P2Water					;\ Water check
		BNE .Water : JMP .NoWater			;/

		.Water
		STZ !P2ShellSlide				;\ no shell slide underwater
		STZ !P2ShellSpeed				;/
		STZ !P2Dashing					; no dash underwater
		LDA !P2Anim					;\
		CMP.b #!Kad_Fall : BNE +			; |
		LDA #!Kad_Swim : STA !P2Anim			; | fall -> swim anim
		STZ !P2AnimTimer				; |
		+						;/
		LDA $6DA3					;\
		AND #$0F					; | Swim speed index
		TAY						;/
		LDA !P2YSpeed					;\
		CMP .AllRangeSpeedY,y				; |
		BEQ +						; | Swimming Y speed
		BPL $02 : INC #2				; |
		DEC A						; |
	+	STA !P2YSpeed					;/
		LDA $01 : BNE .WaterGround
		LDA !P2XSpeed
		CMP #$F0 : BCS +
		CMP #$10 : BCC +
		ASL A
		ROL A
		AND #$01
		EOR #$01
		STA !P2Direction
		BRA +

		.WaterGround
		LDA $6DA3					;\
		AND #$03					; |
		TAY						; | underwater dir
		LDA .SwimDir,y : BMI .NoSwimDir			; |
		STA !P2Direction				; |
		.NoSwimDir					;/
		LDA !P2XSpeed					;\
		CMP .WaterSpeedX,y				; | underwater walking X speed
		BEQ ++						; |
		BPL $02 : INC #2				; |
		DEC A						; |
		STA !P2XSpeed					; |
		BRA ++						; |
		+						;/
		LDA !P2XSpeed					;\
		CMP .AllRangeSpeedX,y				; |
		BEQ +						; | Swimming X speed
		BPL $02 : INC #2				; |
		DEC A						; |
		STA !P2XSpeed					; |
		+						;/
		BPL $02 : EOR #$FF				;\ Store absolute X speed
		STA $00						;/
		LDA !P2YSpeed					;\
		BPL $02 : EOR #$FF				; | Do animation if there is speed
		CLC : ADC $00					; |
		BNE +						;/
		LDA !P2ShellSpin : BNE ++			; always animate spin at 50% rate
		STZ !P2AnimTimer				;\ Otherewise no animation
		BRA +++						;/
	+	CMP #$20					;\ Animate at 100% rate if |X|+|Y|>0x1F
		BCS +++						;/
	++	LDA $14						;\
		LSR A						; | Animate at 50% rate
		BCC +++						; |
		DEC !P2AnimTimer				;/
	+++	STZ !P2SenkuUsed				; > No animation
		LDA $14						;\ only spawn every 128 frames
		AND #$7F : BNE .NoWater				;/
		%Ex_Index_X_fast()				;\
		LDA #$12+!ExtendedOffset : STA !Ex_Num,x	; |
		LDA !P2YPosLo					; |
		SEC : SBC #$08					; |
		STA !Ex_YLo,x					; |
		LDA !P2YPosHi					; |
		SBC #$00					; | spawn bubble
		STA !Ex_YHi,x					; |
		LDY !P2Direction				; |
		LDA .BubbleX,y					; |
		CLC : ADC !P2XPosLo				; |
		STA !Ex_XLo,x					; |
		LDA !P2XPosHi					; |
		ADC #$00					; |
		STA !Ex_XHi,x					;/
		.NoWater

		LDA !P2ShellSlide : BNE ..Skip			; > Can't punch during shell slide
		BIT !P2Buffer					;\ Skip regular input if buffered
		BVS +						;/
		BIT $6DA7
		BVS $03
	..Skip	JMP .NoPunch
	+	STZ !P2BackDash					; > clear back dash when an attack is started
		LDA !P2ShellSpin : BEQ +			; see if a spin is happening already
;		LDA !KadaalUpgrades				;\
;		AND #$10 : BEQ ..NoC				; | kadaal can cancel spin into drill
;		LDA $6DA3					; |
;		AND #$04 : BNE .StartSpin_Drill			;/
	..NoC	LDA #$40 : STA !P2Buffer			;\ don't change buffer here if spin is active
		JMP .NoPunch					;/
	+	LDA !P2Anim					;\ can't start spin or shell drill during smash
		CMP #$28 : BCC $03 : JMP .NoPunch		;/
		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		BEQ .AirSpin
		BRA .NoSpin

		.AirSpin
	;	LDA !KadaalUpgrades
	;	AND #$10 : BEQ ..Spin
	;	LDA $6DA3
	;	AND #$04 : BEQ ..Spin
	;..Drill	LDA #$01 : STA !P2ShellDrill			; start shell drill
	;	STZ !P2ShellSpin				; cancel shell spin
	;	LDA #!Kad_ShellDrill : STA !P2Anim
	;	STZ !P2AnimTimer
	;	STZ !P2ShellSlide
	;	STZ !P2ShellSpeed
	;	BRA .NoPunch

	..Spin	LDA #$10 : STA !P2ShellSpin
		LDA #!Kad_Spin : STA !P2Anim
		LDA #$3E : STA !SPC4				; spin SFX
		STZ !P2AnimTimer
		STZ !P2Punch1
		STZ !P2Punch2
		STZ !P2Hitbox1IndexMem1
		STZ !P2Hitbox1IndexMem2
		BRA .NoPunch
		.PunchBuffer
		LDA #$40 : TSB !P2Buffer			;\ Set punch buffer and clear jump buffer
		LDA #$80 : TRB !P2Buffer			;/
		BRA .NoPunch
		.NoSpin

		LDA !P2Punch1
		CMP #$08
		BCS .PunchBuffer
		LDA !P2Punch2
		CMP #$08
		BCS .PunchBuffer
		TAX
		BNE .Punch1

		.Punch2
		LDA #$14 : STA !P2Punch2
		LDA #$40 : TRB !P2Buffer
		LDA #$37 : STA !SPC4				; punch 1 SFX
		STZ !P2Punch1
		STZ !P2Hitbox1IndexMem1
		STZ !P2Hitbox1IndexMem2
		BRA .NoPunch

		.Punch1
		LDA #$14 : STA !P2Punch1
		LDA #$40 : TRB !P2Buffer
		LDA #$38 : STA !SPC4				; punch 2 SFX
		STZ !P2Punch2
		STZ !P2Hitbox1IndexMem1
		STZ !P2Hitbox1IndexMem2
		.NoPunch


		LDA !P2ShellDrill : BEQ .NoDrill		;\
		LDA $6DA7					; |
		AND #$08 : BEQ +				; |
		STZ !P2ShellDrill				; | Can cancel drill with up
		LDA #!Kad_Squat : STA !P2Anim			; |
		STZ !P2AnimTimer				; |
		BRA .NoDrill					;/

	+	STZ !P2XSpeed					;\
		LDA #$08 : STA !P2Invinc			; > invulnerable during shell drill
		LDA #$14					; |
		LDY !P2Anim					; |
		CPY #!Kad_ShellDrill : BEQ +			; | Shell drill code
		LDA #$40					; |
	+	STA !P2YSpeed					; |
		RTS						; |
		.NoDrill					;/


		LDA !P2Water : BEQ +				;\
		RTS						; | return here if underwater
		+						;/




		LDA !P2CoyoteTime : BMI +			;\ coyote time
		BNE .InitJump					;/
	+	LDA !P2JumpLag					;\
		BEQ .ProcessJump				; |
		BIT $6DA7 : BPL $05				; | Allow jump buffer from land lag
		LDA #$80 : TSB !P2Buffer			; |
		JMP .Friction					;/


	; THIS IS THE MAIN JUMP CODE

		.ProcessJump
		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		BEQ .NoJump
	;	LDA !P2Floatiness		;\
	;	CMP #$1A : BCS .NoJump		; |
	;	BIT $6DA3 : BMI .NoJump		; |
	;	STZ !P2Floatiness		; | stop ascent if player lets go of B
	;	BIT !P2YSpeed : BPL .NoJump	; |
	;	LDA !P2YSpeed			; |
	;	CLC : ADC #$20			; |
	;	BMI $02 : LDA #$00		; |
	;	STA !P2YSpeed			; |
	;	BRA .NoJump			;/

		.InitJump
		LDA !P2Buffer
		ORA $6DA7
		BPL .NoJump
		LDA !P2ShellSlide : BNE ..maintainspin	; if not in shell slide...
		STZ !P2ShellSpin			; ...clear shell spin
		LDA #!Kad_Squat : STA !P2Anim		; ...set anim right away
		..maintainspin
		STZ !P2CoyoteTime			; clear coyote time
		STZ !P2AnimTimer
	;	LDA !P2Punch1				;\
	;	ORA !P2Punch2				; |
	;	BEQ .SenkuJump				; | Allow players to buffer jump from punch
	;	LDA #$80 : STA !P2Buffer			; |
	;	BRA .NoJump				;/

		.SenkuJump
		LDA #$80 : TRB !P2Buffer		; > Clear jump from buffer
		STZ !P2Punch1				;\ Clear punch
		STZ !P2Punch2				;/
		STZ !P2BackDash				; > Clear back dash
		STZ !P2Senku				; > Clear senku
		LDA !P2XSpeed				;\
		BPL $03 : EOR #$FF : INC A		; |
		LDX !P2Dashing				; |
		BEQ $02 : LDA #$24			; > use 0x24 during dash to prevent jumps from being inconsistent
		LDX !P2ShellSlide			; |
		BEQ $02 : LDA #$10			; > use 0x10 during shell slide for a really big jump
		STA $00					; | calculate max jump speed based on X speed
		ASL A					; |
		CLC : ADC $00				; |
		LSR #3					; |
		SEC : SBC #$58				; |
		STA !P2YSpeed				;/

		LDA #$04 : TRB !P2Blocked		; instantly leave ground
		LDA #$2B : STA !SPC1			; jump SFX
		.NoJump


		LDA !P2Punch1
		ORA !P2Punch2
		BEQ $03 : JMP .Friction



		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		BNE +
		LDA !P2XSpeed
		AND #$80
		CLC : ROL #2
		EOR #$01
		INC A					; > 2 = right, 1 = left
		AND $6DA3 : BEQ .NoDashCancel
		BRA ++

	+	LDA $6DA3
		AND #$03 : BEQ ++
		CMP #$03 : BNE .NoDashCancel		; end dash if pressing left and right at the same time
	++	STZ !P2Dashing
		.NoDashCancel

		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		BEQ +
		LDA $6DA7
		LSR A
		BCC +
		LDX !P2DashTimerR2
		BEQ +
		STX !P2Dashing
		+
		LSR A
		BCC +
		LDX !P2DashTimerL2
		BEQ +
		STX !P2Dashing
		+

		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		BEQ ++
		LDA $6DA3
		LSR A
		BCS .ResetRight
		LDX #$08 : STX !P2DashTimerR1
		LDX !P2DashTimerR2
		BEQ +
		DEC !P2DashTimerR2
		BRA +
		.ResetRight
		LDX #$0F : STX !P2DashTimerR2
		LDY !P2Dashing
		BEQ $03 : STX !P2DashTimerL2
		LDX !P2DashTimerR1
		BEQ +
		DEC !P2DashTimerR1
		+

		LSR A
		BCS .ResetLeft
		LDX #$08 : STX !P2DashTimerL1
		LDX !P2DashTimerL2
		BEQ +
		DEC !P2DashTimerL2
		BRA +
		.ResetLeft
		LDX #$0F : STX !P2DashTimerL2
		LDY !P2Dashing
		BEQ $03 : STX !P2DashTimerR2
		LDX !P2DashTimerL1
		BEQ +
		DEC !P2DashTimerL1
		+
		BRA +++
		++
		STZ !P2DashTimerR1
		STZ !P2DashTimerR2
		STZ !P2DashTimerL1
		STZ !P2DashTimerL2
		+++

		LDX #$01			; Base index = 0
		LDA !P2Dashing
		BEQ $02 : LDX #$02
		LDA !P2ShellSpeed
		BEQ $02 : LDX #$03

		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		STA $00
		LDA $6DA3
		LSR A
		BCS .Right
		LSR A
		BCS .Left
		LDA $00
		BEQ ++

		.Friction			; This code definitely only runs on the ground
		LDA !P2ShellSlide : BNE ++	;\ Clear shell speed upon touching the ground without shell slide
		STZ !P2ShellSpeed		;/
		++


		LDA !P2Slope
		CLC : ADC #$04
		TAX
		LDA !P2XSpeed
		SEC : SBC .SlopeSpeed,x
		BEQ +
		BMI .StopLeft
		.StopRight
		DEC A
		BEQ $01 : DEC A
		BRA ++
		.StopLeft
		INC A
		BEQ $01 : INC A
	++	CLC : ADC .SlopeSpeed,x
		JSL CORE_SET_XSPEED
	+	RTS

		.Right
		LDA !P2ShellSpeed : BNE $07	; Shell speed flag has priority over lacking dash flag
		LDA !P2DashTimerR1
		BEQ $02 : LDX #$00
		LDA !P2XSpeed
		BMI +
		LDY $00 : BNE +++		;\
		CMP .XSpeedRight,x		; | Don't turn abruptly in mid-air
		BCC +				;/
	+++	LDA .XSpeedRight,x
		BRA ++
	+	INC #3
	++	JSL CORE_SET_XSPEED
		LDA #$01 : STA !P2Direction
		RTS

		.Left
		LDA !P2ShellSpeed : BNE $07	; Shell speed flag has priority over lacking dash flag
		LDA !P2DashTimerL1
		BEQ $02 : LDX #$00
		LDA !P2XSpeed
		BEQ +
		BPL +
	++	LDY $00 : BNE +++		;\
		CMP .XSpeedLeft,x		; | Don't turn abruptly in mid-air
		BEQ ++				; |
		BCS +				;/
	+++	LDA .XSpeedLeft,x
		BRA ++
	+	DEC #3
	++	JSL CORE_SET_XSPEED
		STZ !P2Direction
		RTS

		.XSpeed
		.XSpeedLeft
		db $F4,$E8,$DC,$D0		; Startup, walk, dash, shell slide

		.XSpeedRight
		db $0C,$18,$24,$30		; Startup, walk, dash, shell slide

		.XSpeedSenku
		db $D0,$30			; Left, right

		.AllRangeSpeedX			; For improved senku and swimming
		db $00,$30,$D0,$00
		db $00,$22,$DD,$00
		db $00,$22,$DD,$00
		db $00,$30,$D0,$00
		.AllRangeSpeedY
		db $00,$00,$00,$00
		db $30,$22,$22,$30
		db $D0,$DD,$DD,$D0
		db $00,$00,$00,$00

		.WaterSpeedX			; For walking underwater
		db $00,$10,$F0,$00

		.SwimDir
		db $FF,$01,$00,$FF

		.BubbleX
		db $00,$08

		.SlopeSpeed
		db $E0,$F0,$00,$00,$00,$00,$00,$10,$20

		.ShellSlideAcc
		db $FC,$04			; added on top of friction, that's why this is so high


	PHYSICS:

		PLA
		BMI $03 : STA !P2Direction


	.SenkuSmash			; This has to be before sprite interaction so custom sprites can set the flag
		LDA !KadaalUpgrades
		LSR A : BCC ..Return
		LDA !P2Senku : BEQ ..Return
		LDA !P2SenkuSmash : BEQ ..Return
		BIT $6DA7 : BVC ..Return
		LDA #!Kad_SenkuSmash : STA !P2Anim
		STZ !P2AnimTimer
		LDA #$A0 : STA !P2YSpeed
		LDA #$1C : STA !P2Invinc
		STZ !P2Senku
		LDA #$02 : STA !SPC1		; SFX
		LDA !P2Direction
		EOR #$01
		STA !P2Direction
		ASL #2
		INC A
		TAY
		LDA CONTROLS_XSpeed,y : STA !P2XSpeed
		STZ !P2SenkuUsed
		PEA .Collisions-1
		JMP HITBOX_Smash
		..Return


		LDA !P2SlantPipe : BEQ +
		LDA #$40 : STA !P2XSpeed
		LDA #$C0 : STA !P2YSpeed
		+

	.Collisions
		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		BNE .OnGround
		LDA !P2XSpeed
		BEQ .NoWall
		CLC : ROL #2
		INC A				; 1 = right, 2 = left
		AND !P2Blocked
		BEQ .NoWall
		STZ !P2Dashing
		STZ !P2XSpeed
		BRA .NoWall

		.OnGround
		STZ !P2KillCount
		STZ !P2SenkuUsed
		LDA !P2XSpeed
		BEQ .NoWall
		BMI .LeftWall

		.RightWall
		LDA !P2Blocked
		LSR A
		BCC .NoWall
		STZ !P2XSpeed
		BRA .NoWall

		.LeftWall
		LDA !P2Blocked
		AND #$02
		BEQ .NoWall
		STZ !P2XSpeed

		.NoWall



	SPRITE_INTERACTION:
		JSL CORE_SPRITE_INTERACTION


	EXSPRITE_INTERACTION:
		JSL CORE_EXSPRITE_INTERACTION


	UPDATE_SPEED:
		LDA #$03				; gravity when holding B is 3
		BIT $6DA3				;\ gravity without holding B is 6
		BMI $02 : LDA #$06			;/
		BIT !P2Water				;\ gravity in water is 0
		BVC $02 : LDA #$00			;/
		STA !P2Gravity				; store gravity
		LDA #$46 : STA !P2FallSpeed		; fall speed is 0x46
		JSL CORE_UPDATE_SPEED
		LDA !P2Platform
		BEQ +
		LDA #$04 : TSB !P2Blocked
		+


	OBJECTS:
		LDA !P2Blocked : PHA
		REP #$30
		LDA !P2Anim
		AND #$00FF
		ASL #3
		TAY
		LDA ANIM+$06,y : JSL CORE_COLLISION

		LDA !P2Climbing : BEQ .NotClimbing
		STZ !P2Senku
		STZ !P2SenkuUsed
		STZ !P2ShellSpin
		STZ !P2ShellDrill
		STZ !P2Dashing
		STZ !P2ShellSpeed
		STZ !P2SenkuSmash
		.NotClimbing

		PLA
		EOR !P2Blocked
		AND #$04 : BEQ .LandingDone
		LDA !P2Blocked
		AND #$04 : BEQ .LandingDone

	; landing code

		LDA !P2ShellSpin : BEQ .HardLanding	;\
		LDA $6DA3				; | if holding down during shell spin, get smooth landing
		AND #$04 : BNE .LandingDone		;/

		.HardLanding
		LDA #$07 : STA !P2JumpLag
		STZ !P2ShellSpin
		LDA !P2Water : BNE .LandingDone		; can't shell slide underwater
	;	LDA !KadaalUpgrades			;\
	;	AND #$08 : BEQ +			; |
		LDA !P2Slope : BNE +
		LDA !P2XSpeed				; |
		BPL $03 : EOR #$FF : INC A		; |
		CMP #$20 : BCC .LandingDone		; | allow shell slide with upgrade
	+	LDA $6DA3				; |
		AND #$04 : BEQ .LandingDone		; |
		JSR StartSlide				; |
		.LandingDone				;/


	SCREEN_BORDER:			; This might bug with auto-scrollers
		JSL CORE_SCREEN_BORDER


	ATTACK:
		JSR HITBOX


	ANIMATION:

		LDA !P2ExternalAnimTimer			;\
		BEQ .ClearExternal				; |
		DEC !P2ExternalAnimTimer			; | Enforce external animations
		LDA !P2ExternalAnim : STA !P2Anim		; |
		DEC !P2AnimTimer				; |
		JMP .HandleUpdate				;/

		.ClearExternal
		STZ !P2ExternalAnim

	; pipe check
		LDA !P2Pipe : BEQ .NoPipe			;\
		BMI .VertPipe					; |
		.HorzPipe					; |
		JMP .Walk					; |
		.VertPipe					; | pipe animations
		LDA #!Kad_Idle : STA !P2Anim			; |
		STZ !P2AnimTimer				; |
		JMP .HandleUpdate				; |
		.NoPipe						;/

	; hurt check
		LDA !P2HurtTimer : BEQ .NoHurt
		LDA #!Kad_Hurt : STA !P2Anim
	-	JMP .HandleUpdate
		.NoHurt

	; drill land check
		LDA !P2Anim
		CMP #!Kad_DrillLand : BCC .NoDrillLand
		LDA !P2JumpLag : BNE -
		STZ !P2Anim
		STZ !P2AnimTimer
		.NoDrillLand

	; spin check before duck and slide checks
		LDA !P2Anim
		CMP #!Kad_Fall : BNE +
		STZ !P2ShellSpin
	+	LDA !P2ShellSpin
		BEQ $03 : JMP .HandleUpdate

	; slide check
		LDA !P2ShellSlide : BEQ .NoSlide
		LDA !P2Anim
		CMP #!Kad_Shell : BCC +
		CMP #!Kad_Shell_over : BCC ++
	+	LDA #!Kad_Shell : STA !P2Anim
		STZ !P2AnimTimer
	++	JMP .HandleUpdate
		.NoSlide


	; climb check
		LDA !P2Climbing : BEQ .NoClimb
		LDA !P2Anim
		CMP #!Kad_Climb : BCC +
		CMP #!Kad_Climb_over : BCC ++
	+	LDA #!Kad_Climb : STA !P2Anim
		STZ !P2AnimTimer
	++	LDA $6DA3
		AND #$0F : BNE +
		STZ !P2AnimTimer
	+	JMP .HandleUpdate
		.NoClimb

	; duck check
		LDA !P2Ducking : BEQ .NoDuck
		LDA !P2Anim
		CMP #!Kad_Duck : BCC +
		CMP #!Kad_Duck_over : BCC ++
	+	LDA #!Kad_Duck : STA !P2Anim
		STZ !P2AnimTimer
	++	JMP .HandleUpdate
		.NoDuck

	; punch checks
		LDA !P2Punch1 : BEQ .NoPunch1
		CMP #!Kad_Punch1 : BNE .ReturnPunch
		LDA #!Kad_Punch1 : STA !P2Anim
		STZ !P2AnimTimer
		.ReturnPunch
		JMP .HandleUpdate
		.NoPunch1
		LDA !P2Punch2 : BEQ .NoPunch2
		CMP #!Kad_Punch1 : BNE .ReturnPunch
		LDA #!Kad_Punch2 : STA !P2Anim
		STZ !P2AnimTimer
		JMP .HandleUpdate
		.NoPunch2

	; senku check
		LDA !P2Senku : BEQ .NoSenku
		CMP #$20 : BCC .Senku
		LDA #!Kad_Walk+1
		STZ !P2AnimTimer
		BRA .SenkuEnd
		.Senku
		LDA #!Kad_Senku
		.SenkuEnd
		STA !P2Anim
		JMP .HandleUpdate
		.NoSenku

	; senku smash check
		LDA !P2Anim
		CMP #!Kad_SenkuSmash : BCC $03 : JMP .HandleUpdate

	; squat/swim check
		LDA !P2JumpLag : BEQ +
	-	LDA #!Kad_Squat : STA !P2Anim
		STZ !P2AnimTimer
		JMP .HandleUpdate
	+	LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		ORA !P2SpritePlatform
		BNE .OnGround
		BIT !P2Water : BVC .NotInWater
		LDA !P2Anim
		CMP #!Kad_Spin : BCC ++			;\ can't cancel spin into swim anim
		CMP #!Kad_Spin_over : BCC +		;/
	++	CMP #!Kad_Swim : BCC .Swim
		CMP #!Kad_Swim_over : BCC +
	.Swim	LDA #!Kad_Swim : STA !P2Anim
		STZ !P2AnimTimer
	+	JMP .HandleUpdate
		.NotInWater

		LDA !P2YSpeed : BMI +
		CMP #$08 : BCC -		; > Half-shell frame at 0x00 < speed < 0x08
		LDA !P2Anim
		CMP #!Kad_Squat : BNE $03 : JMP .HandleUpdate
		CMP #!Kad_Shell : BCC .Fall
		CMP #!Kad_Shell_over : BCC -

	.Fall	LDA #!Kad_Fall : STA !P2Anim
		STZ !P2AnimTimer
		JMP .HandleUpdate
	+	LDA !P2Anim
		CMP #!Kad_Fall
		BNE $03 : JMP .HandleUpdate
		BCS +
		CMP #!Kad_Shell : BCS .HandleUpdate
	+	LDA #!Kad_Shell : STA !P2Anim
		STZ !P2AnimTimer
		BRA .HandleUpdate

		.OnGround
		LDA $6DA3
		AND #$03
		ORA !P2XSpeed
		BNE .Move

		.Idle
		LDA !P2Anim
		CMP #!Kad_Idle_over : BCC .HandleUpdate
		STZ !P2Anim
		STZ !P2AnimTimer
		BRA .HandleUpdate

		.Move
		LDX !P2BackDash : BNE .Turn		; back dash frame
		LDX !P2Dashing : BEQ .Walk
		BIT !P2Water : BVS .Walk
		ROL #2
		EOR !P2Direction
		LSR A
		BCS .NoTurn
		LDA !P2XSpeed
		BPL $03 : EOR #$FF : INC A
		CMP #$10
		BCC .NoTurn
	.Turn	LDA #!Kad_Turn : STA !P2Anim
		LDA #$2D : STA !SPC1
		JSL CORE_SMOKE_AT_FEET
		BRA .HandleUpdate
		.NoTurn

		.Dash
		LDA !P2Anim
		CMP #!Kad_Dash : BCC +
		CMP #!Kad_Dash_over : BCC .HandleUpdate
	+	LDA #!Kad_Dash : STA !P2Anim
		STZ !P2AnimTimer
		BRA .HandleUpdate

		.Walk
		LDA !P2Anim
		CMP #!Kad_Walk : BCC +
		CMP #!Kad_Walk_over : BCC .HandleUpdate
	+	LDA #!Kad_Walk
		STA !P2Anim
		STZ !P2AnimTimer

		.HandleUpdate
		LDA !P2Anim
		REP #$30
		AND #$00FF
		ASL #3
		TAY
		LDA ANIM+$00,y
		STA $0E
		SEP #$20
		LDA !P2AnimTimer
		INC A
		CMP ANIM+$02,y
		BNE .NoUpdate
		LDA ANIM+$03,y
		STA !P2Anim
		REP #$20
		AND #$00FF
		ASL #3
		TAY
		LDA ANIM+$00,y
		STA $0E
		SEP #$20
		LDA #$00

		.NoUpdate
		STA !P2AnimTimer
		LDA !MultiPlayer : BEQ .ThisOne		; animate at 60fps on single player
		LDA $14
		AND #$01
		CMP !CurrentPlayer : BEQ .ThisOne

		.OtherOne
		REP #$30
		LDA !P2Anim2
		AND #$00FF
		ASL #3
		TAY
		LDA ANIM+$00,y
		STA $0E
		SEP #$30
		JMP GRAPHICS

		.ThisOne
		REP #$30
		LDA ANIM+$04,y : STA $00


; -- dynamo format --
;
; 1 byte header (size)
; for each upload:
; 	cccssss-
; 	-ccccccc
; 	ttttt---
;
; ssss:		DMA size (shift left 4)
; cccccccccc:	character (formatted for source address)
; ttttt:	tile number (shift left 1 then add VRAM offset)

		LDY.w #!File_Kadaal
		JSL !GetFileAddress

		SEP #$20
		STZ $2250
		LDA !P2Anim
		CMP.b #!Kad_Swim : BCC +
		CMP.b #!Kad_Swim_over : BCS +
		LDA !SD_KadaalLinear : STA $02
		AND #$C0 : BMI .40
	.7E	LDA #$7E : BRA ++
	.40	LDA #$40
	++	BIT $02
		BVC $01 : INC A
		STA !FileAddress+2
		REP #$20
		LDA !SD_KadaalLinear
		AND #$003F
		ASL #2
		STA !FileAddress+0

		LDA $785F
		BPL $04 : EOR #$FFFF : INC A
		XBA
		AND #$00FF
		STA $2251
		LDA #$0200 : STA $2253
		LDA !FileAddress+0
		CLC : ADC $2306
		STA !FileAddress+0

	+	REP #$20


		LDA ($00)					;\
		AND #$00FF					; |
		STA $02						; |
		LDX #$0000					; |
		LDY #$0000					; |
		INC $00						; |
	-	LDA ($00),y					; |
		AND #$001E					; |
		ASL #4						; |
		STA !BigRAM+$00+2,x				; |
		LDA ($00),y					; |
		AND #$7FE0					; |
		CLC : ADC !FileAddress				; |
		STA !BigRAM+$02+2,x				; | unpack dynamo data
		LDA !FileAddress+2 : STA !BigRAM+$04+2,x	; |
		INY #2						; |
		LDA ($00),y					; |
		ASL A						; |
		AND #$01F0					; |
		ORA #$6200					; |
		STA !BigRAM+$05+2,x				; |
		INY						; |
		TXA						; |
		CLC : ADC #$0007				; |
		TAX						; |
		CPY $02 : BCC -					;/
		STX !BigRAM+0					; > set size

		LDA.w #!BigRAM : JSL CORE_GENERATE_RAMCODE
		SEP #$30
		LDA !P2Anim : STA !P2Anim2


	GRAPHICS:
		LDA !P2HurtTimer : BNE .DrawTiles

		LDA !P2Anim
		CMP #!Kad_SenkuSmash : BCS .DrawTiles
		CMP #!Kad_Spin : BCC +
		CMP #!Kad_Spin_over : BCC .DrawTiles
		+

		LDA !P2Invinc : BEQ .DrawTiles
		AND #$06 : BEQ OUTPUT_HURTBOX

		.DrawTiles
		LDA $0E : STA $04
		LDA $0F : STA $05
		JSL CORE_LOAD_TILEMAP


	OUTPUT_HURTBOX:
		REP #$30
		LDA.w #ANIM
		JSL CORE_OUTPUT_HURTBOX
		PLB
		RTS




	StartSlide:
		LDA #$01 : STA !P2ShellSlide		;\
		LDA !P2Slope : BEQ .NoSlope		; |
		BRA .GetDir				; |
		.NoSlope				; |
		LDA !P2XSpeed				; |
		.GetDir					; |
		ROL #2					; |
		AND #$01				; | set slide
		EOR #$01				; |
		STA !P2Direction			; |
	.Return	RTS					;/



;==============;
;HITBOX HANDLER;
;==============;

	HITBOX:

		JSL CORE_ATTACK_Setup

		LDA !P2ShellSpin : BEQ .CheckPunch

		.Spin
		REP #$20				; A 16-bit
		LDA !P2XPosLo				;\
		CLC : ADC SPIN+0			; | hitbox X
		STA !P2Hitbox1XLo			;/
		LDA !P2YPosLo				;\
		CLC : ADC SPIN+2			; | hitbox Y
		STA !P2Hitbox1YLo			;/
		LDA SPIN+4 : STA !P2Hitbox1W		; hitbox W + H
		SEP #$20				; A 8-bit
		BRA .SetSpeed

		.CheckPunch
		LDA !P2Punch1
		ORA !P2Punch2
		CMP #$05 : BCS .DoPunch
		STZ !P2Hitbox1IndexMem1
		STZ !P2Hitbox1IndexMem2
	-	RTS

		.DoPunch
		CMP #$12 : BCS -
		CMP #$0E : BCS .Punch0
		LDY #$0C
		LDA !P2Direction : BEQ .PunchShared
		LDY #$12
		BRA .PunchShared

		.Punch0
		LDY !P2Direction			;\ Direction
		BEQ $02 : LDY #$06			;/

		.PunchShared
		REP #$20				; A 16-bit
		LDA !P2XPosLo				;\
		CLC : ADC PUNCH+0,y			; | hitbox X
		STA !P2Hitbox1XLo			;/
		LDA !P2YPosLo				;\
		CLC : ADC PUNCH+2,y			; | hitbox Y
		STA !P2Hitbox1YLo			;/
		LDA PUNCH+4,y : STA !P2Hitbox1W		; hitbox W + H
		SEP #$20				; A 8-bit


		.SetSpeed
		LDA #$10
		LDX !P2Punch2
		BEQ $02 : LDA #$04
		LDX !P2Direction
		BNE $03 : EOR #$FF : INC A
		STA !P2Hitbox1XSpeed
		LDA #$E8 : STA !P2Hitbox1YSpeed

		JSL CORE_ATTACK_ActivateHitbox1
		JSR .GetClipping


		.HammerCheck
		LDX #!Ex_Amount-1

		.HammerLoop
		LDA !Ex_Num,x
		AND #$7F
		CMP #$04+!ExtendedOffset : BNE .HammerEnd
		LDA !Ex_Data3,x
		LSR A : BCS .HammerEnd
		LDA !Ex_XLo,x : STA $04				;\ Xpos
		LDA !Ex_XHi,x : STA $0A				;/
		LDA !Ex_YLo,x : STA $05				;\ Ypos
		LDA !Ex_YHi,x : STA $0B				;/
		LDA #$10 : STA $06				; > Width
		STA $07						; > Height
		JSL !CheckContact				;\ Check for contact
		BCC .HammerEnd					;/
		JSL CORE_DISPLAYCONTACT				; contact gfx
		LDA #$02 : STA !SPC1
		LDA !P2Hitbox1XSpeed : STA !Ex_XSpeed,x		; > Xspeed
		LDA !P2Hitbox1YSpeed : STA !Ex_YSpeed,x		; > Yspeed
		LDA !Ex_Data3,x
		ORA #$01
		STA !Ex_Data3,x					; > Hammer belongs to players

		.HammerEnd
		DEX
		BPL .HammerLoop

		.Return
		RTS


		.GetClipping
		LDX #$0F

		.Loop
		TXY
		LDA ($0E),y : BNE .LoopEnd

		LDY !P2ActiveHitbox			;\
		CPX #$08 : BCS +			; |
		LDA !P2Hitbox1IndexMem1,y : BRA ++	; | check index memory
	+	LDA !P2Hitbox1IndexMem2,y		; |
	++	AND CORE_BITS,x : BNE .LoopEnd		;/
		LDA $3230,x				;\
		CMP #$02 : BEQ .Hit			; | check sprite status
		CMP #$08 : BCC .LoopEnd			;/
	.Hit	LDA $0F : PHA				;\
		JSL !GetSpriteClipping04		; |
		JSL !CheckContact			; | check contact
		PLA : STA $0F				; |
		BCC .LoopEnd				;/

		LDA !ExtraBits,x
		AND #$08 : BNE .HiBlock
		.LoBlock
		LDY $3200,x
		LDA HIT_TABLE,y
		BRA .AnyBlock
		.HiBlock
		LDY !NewSpriteNum,x
		LDA HIT_TABLE_Custom,y
		.AnyBlock
		ASL A : TAY
		PEA .LoopEnd-1
		REP #$20
		LDA HIT_Ptr+0,y
		DEC A
		PHA
		SEP #$20
		RTS

		.LoopEnd
		DEX : BPL .Loop
		JSL CORE_GET_TILE_Attack
		RTS


	.Smash
		LDY #$06
		JMP .Spin


	; Hitbox format is Xdisp (lo+hi), Ydisp (lo+hi), width, height.

	PUNCH:
	.0
	dw $FFF8,$FFFA : db $08,$12		; Left
	dw $0010,$FFFA : db $08,$12		; Right
	.1
	dw $FFF4,$FFFA : db $0C,$12		; Left
	dw $0010,$FFFA : db $0C,$12		; Right


	SPIN:
	dw $FFF8,$0000 : db $20,$10		; Same for both directions

	SMASH:
	dw $FFF8,$FFF8 : db $20,$20		; Same for both directions


	CaptainWarrior:
		LDY $3320,x
		BEQ $02 : LDY #$06
		LDA $3220,x
		CLC : ADC .Data+$00,y
		STA $04
		LDA $3250,x
		ADC .Data+$01,y
		STA $0A
		LDA $3210,x
		CLC : ADC .Data+$02,y
		STA $05
		LDA $3240,x
		ADC .Data+$03,y
		STA $0B
		LDA .Data+$04,y : STA $06
		LDA .Data+$05,y : STA $07
		RTS

	.Data
	dw $FFF8,$FFE4 : db $18,$30		; Right
	dw $FFF8,$FFE4 : db $18,$30		; Left


	HIT_Ptr:
	dw HIT_00
	dw HIT_01
	dw HIT_02
	dw HIT_03
	dw HIT_04
	dw HIT_05
	dw HIT_06
	dw HIT_07
	dw HIT_08
	dw HIT_09
	dw HIT_0A
	dw HIT_0B
	dw HIT_0C
	dw HIT_0D
	dw HIT_0E
	dw HIT_0F
	dw HIT_10
	dw HIT_11
	dw HIT_12
	dw HIT_13
	dw HIT_14
	dw HIT_15
	dw HIT_16
	dw HIT_17
	dw HIT_18
	dw HIT_19
	dw HIT_1A
	dw HIT_1B	; < Captain Warrior
	dw HIT_1C
	dw HIT_1D


	HIT_00:
		RTS

	HIT_01:
		; Knock out always
		JMP KNOCKOUT

	HIT_02:
		; Knock out of shell, send shell flying
		LDA $3230,x
		CMP #$02 : BEQ .Knockback
		CMP #$08 : BEQ .Standard
		CMP #$09 : BEQ .Knockback
		CMP #$0A : BNE HIT_00
		LDA $3200,x			;\
		CMP #$07 : BNE .Knockback	; | Shiny shell is immune to attacks
		LDA #$02 : STA !SPC1		; |
		RTS				;/

		.Knockback
		JSL CORE_ATTACK_Main
		LDA #$09 : STA $3230,x
		JMP KNOCKBACK

		.Standard
		LDA $3200,x
		CMP #$08
		BCS .Stun

		JSL $02A9DE			; Get new sprite number into Y
		BMI .Stun			; If there are no empty slots, don't spawn

		LDA $3200,x
		SEC : SBC #$04
		STA $3200,y			; Store sprite number for new sprite
		LDA #$08 : STA $3230,y		; > Status: normal
		LDA $3220,x			;\
		STA $3220,y			; |
		LDA $3250,x			; |
		STA $3250,y			; | Set positions
		LDA $3210,x			; |
		STA $3210,y			; |
		LDA $3240,x			; |
		STA $3240,y			;/
		PHX				;\
		TYX				; | Reset tables for new sprite
		JSL $07F7D2			; |
		PLX				;/
		LDA #$10			;\
		STA $32B0,y			; | Some sprite tables that SMW normally sets
		STA $32D0,y			; |
		LDA #$01 : STA $3310,y		;/


		LDA CORE_BITS,y
		CPY #$08 : BCS +
		TSB !P2Hitbox1IndexMem1 : BRA ++
	+	TSB !P2Hitbox1IndexMem2
		++

		LDA #$10 : STA $3300,y		; > Temporarily disable player interaction
		LDA $3430,x			;\ Copy "is in water" flag from sprite
		STA $3430,y			;/
		LDA #$02 : STA $32D0,y		;\ Some sprite tables
		LDA #$01 : STA $30BE,y		;/

		PHX
		LDA !P2Direction
		EOR #$01
		STA $3320,y
		TAX				; X = new sprite direction
		LDA CORE_KOOPA_XSPEED,x		; Load X speed table indexed by direction
		STA $30AE,y			; Store to new sprite X speed
		PLX

		.Stun
		LDA #$09 : STA $3230,x		; > Stun sprite
		LDA $3200,x			;\
		CMP #$08			; | Check if sprite is a Koopa
		BCC .DontStun			;/
		LDA #$FF : STA $32D0,x		; > Stun if not

		.DontStun
		RTS


	HIT_03:
		; Knock back and clip wings
		LDA $3230,x
		CMP #$08
		BNE HIT_02_DontStun
		LDA $3200,x			; Load sprite sprite number
		SEC : SBC #$08			; Subtract base number of Parakoopa sprite numbers
		TAY
		LDA CORE_PARAKOOPACOLOR,y	; Load new sprite number
		STA $3200,x			; Set new sprite number
		LDA #$01 : STA $3230,x		; > Initialize sprite
		JSL CORE_ATTACK_Main
		JMP KNOCKBACK

	HIT_04:
		; Knock back and stun
		LDA $3230,x
		CMP #$08
		BEQ .Main
		CMP #$09
		BNE HIT_07

		.Main
		JSL CORE_ATTACK_Main
		LDA $3200,x
		CMP #$40
		BEQ .ParaBomb
		LDA #$09			;\
		STA $3230,x			; | Regular Bobomb code (stuns it)
		BRA .Shared			;/

		.ParaBomb
		LDA #$0D : STA $3200,x		; > Sprite = Bobomb
		LDA #$01 : STA $3230,x		; > Initialize sprite
		JSL $07F7D2			; > Reset sprite tables

		.Shared
		JMP KNOCKBACK

	HIT_05:
		; Knock back and stun
		LDA $3230,x
		CMP #$08
		BEQ .Main
		CMP #$09
		BNE HIT_07

		.Main
		JSL CORE_ATTACK_Main
		LDA #$09 : STA $3230,x
		LDA #$FF : STA $32D0,x
		JMP KNOCKBACK

	HIT_06:
		; Knock back, stun, and clip wings
		LDA $3230,x
		CMP #$08
		BNE HIT_07
		LDA #$0F : STA $3200,x		; Set new sprite number
		JSL $07F7D2			; Reset sprite tables
		BRA HIT_05_Main			; Handle like normal

	HIT_07:
		; Do nothing
		RTS

	HIT_08:
		; Knock out always
	HIT_09:
		; Knock out always
	HIT_0A:
		; Knock out always
		JMP KNOCKOUT

	HIT_0B:
		; Collect
		PHK : PEA.w .Return-1
		PEA.w CORE_SPRITE_INTERACTION_RTL-1
		JML CORE_INT_0B+$03
		.Return
		RTS

	HIT_0C:
		; Knock out if at same depth
		LDA $3410,x			;\ Don't process interaction while sprite is behind scenery
		BNE HIT_0D			;/
		JMP KNOCKOUT

	HIT_0D:
		; Do nothing
		RTS

	HIT_0E:
		; Collapse
		LDA $32C0,x
		BNE .Return
		LDA #$01 : STA $32C0,x
		LDA #$FF : STA $32D0,x
		LDA #$07 : STA !SPC1
		LDY !P2Direction
		JMP KNOCKBACK_GFX

		.Return
		RTS


	HIT_0F:
		; Do nothing
		RTS

	HIT_10:
		; Stun and damage
		JSL CORE_ATTACK_Main
		STZ $3420,x			; Reset unknown sprite table
		LDA $BE,x			;\
		CMP #$03			; |
		BEQ HIT_0F			;/> Return if sprite is still recovering from a stomp
		INC $32B0,x			; Increment sprite stomp count
		LDA $32B0,x
		CMP #$03
		BEQ .Kill
		LDA #$03 : STA $BE,x		; Stun sprite
		LDA #$03 : STA $32D0,x		; Set sprite stunned timer to 3 frames
		STZ $3310,x			; Reset follow player timer
		LDY !P2Direction
		JMP KNOCKBACK_GFX

		.Kill
		JMP KNOCKOUT


	HIT_11:
		; Do nothing
		RTS

	HIT_12:
		; Knock out if emerged
		LDA $BE,x			;\
		BEQ .Return			; | Only interact if sprite has emerged from the ground
		LDA $32D0,x			; |
		BEQ .Process			;/

		.Return
		RTS

		.Process
		JMP KNOCKOUT


	HIT_13:
		; Knock back and damage
		LDA $3200,x
		CMP #$6E
		BEQ .Large

		.Small
		JMP KNOCKOUT

		.Large
		LDA #$6F : STA $3200,x		; Sprite num
		LDA #$01 : STA $3230,x		; Init sprite
		JSL $07F7D2			; Reset sprite tables
		LDA #$02 : STA $BE,x		; Action: fire breath up
		JMP KNOCKBACK


	HIT_14:
		; Do nothing
		RTS

	HIT_15:
		; Knock back and damage
		LDY $BE,x
		LDA $3280,x
		AND #$04 : BNE .Aggro
		CPY #$01 : BNE +
		LDA #$20 : STA $32F0,x
		LDA #$02 : STA $BE,x
		JMP KNOCKOUT
	+	LDA #$04 : STA $34D0,x		; Half smush timer
		BRA .Shared

		.Return
		RTS

		.Aggro
		LDA $35D0,x : BNE .Return
		LDA #$40 : STA $35D0,x
		LDA $33E0,x
		BEQ .NoRoar
		LDA #$01 : STA $33E0,x

		.NoRoar
		CPY #$02
		BNE .Shared
		LDA #$20 : STA $32F0,x
		JMP KNOCKOUT

		.Shared
		INC $BE,x
		JSL CORE_ATTACK_Main
		LDA $3340,x			;\
		ORA #$0D			; | Set jump, getup, and knockback flags
		STA $3340,x			;/
		LDA $3330,x			;\
		AND.b #$04^$FF			; | Put sprite in midair
		STA $3330,x			;/
		LDA $3280,x			;\
		AND.b #$08^$FF			; | Clear movement disable
		STA $3280,x			;/
		BIT $3280,x			;\
		BVC .NoChase			; |
		BIT $3340,x			; |
		BVS .NoChase			; | Aggro off of being punched
		LDA !CurrentPlayer		; |
		CLC : ROL #4			; |
		ORA #$40			; |
		ORA $3340,x			; |
		STA $3340,x			;/

		.NoChase
		STZ $32A0,x			; > Disable hammer
		JMP KNOCKBACK



	HIT_16:
		; Do nothing
	HIT_17:
		; Do nothing
		RTS

	HIT_18:
		; Knock back without doing damage
		LDA !P2Direction
		EOR #$01
		STA $3320,x
		JMP KNOCKBACK


	HIT_19:
		; Do nothing
		RTS

	HIT_1A:
		; Collect
		LDA !CurrentPlayer : BNE +
		LDA $32E0,x : BNE HIT_19
		BRA ++
	+	LDA $35F0,x : BNE HIT_19
	++	PHK : PEA.w .Return-1
		PEA.w CORE_SPRITE_INTERACTION_RTL-1
		JML CORE_INT_1A+$03
		.Return
		RTS

	HIT_1B:
		LDA !BossData+0
		CMP #$81 : BNE .Return
		LDA !BossData+2
		AND #$7F
		CMP #$04 : BEQ .Return
		LDA $3420,x
		BNE .Return
		LDA !Difficulty
		AND #$03 : TAY
		LDA .InvincTime,y
		STA $3420,x
		LDA #$28 : STA !SPC4		; > OW! sound
		LDY !P2Direction
		LDA .XSpeed,y
		STA $AE,x
		LDA #$07 : STA !BossData+2
		LDA #$7F : STA !BossData+3
		DEC !BossData+1

		.Return
		RTS

		.InvincTime
		db $4F,$5F,$7F

		.XSpeed
		db $F0,$10

	HIT_1C:
		LDA !ExtraBits,x
		AND #$04 : BNE HIT_19		; can't hit mask
		LDA $3280,x
		AND #$03
		CMP #$01 : BNE HIT_19
		LDA $BE,x
		AND #$0F
		ORA #$C0
		STA $BE,x
		JSL CORE_ATTACK_Main
		RTS

	HIT_1D:
		LDA #$3F : STA $3360,x		; > Set hurt timer
		LDA #$28 : STA !SPC4		; > OW! sound
		STZ $32D0,x			; > Reset main timer
		DEC $3280,x			; > Deal damage
		LDA CORE_BITS,x
		CPX #$08
		BCS +
		TSB !P2Hitbox1IndexMem1
		RTS
		+
		TSB !P2Hitbox1IndexMem2

		.Return
		RTS







	KNOCKOUT:
		LDA #$04 : STA $9D

		LDA #$02 : STA $3230,x
		LDA !P2HitboxOutputY
		SEC : SBC #$10
		STA !SpriteYSpeed,x
		LDA !P2HitboxOutputX : STA !SpriteXSpeed,x
		LDA #$02 : STA !SPC1
		LDY !P2Direction

		JSL CORE_ATTACK_Main_mem

		JSL CORE_DISPLAYCONTACT
		RTS

	KNOCKBACK:
		LDA #$04 : STA $9D

		LDA !P2HitboxOutputX : STA $AE,x
		LDA !P2HitboxOutputY : STA $9E,x
		LDA !P2Character			;\ luigi check since he borrows this routine
		CMP #$01 : BEQ .GFX			;/
		LDA !P2ShellSpin : BEQ .GFX		;\
		TXY					; | spin has increased i-frames
		LDA #$20 : STA ($0E),y			;/
		JSL CORE_ATTACK_Main_mem

		.GFX
		LDA #$02 : STA !SPC1
		JSL CORE_DISPLAYCONTACT
		RTS



	; Changes:
	;
	; Shell (last frame is second frame but x-flipped), still 16x16
	; Shell $044-$048 -> $040-$044 ($04A is cut)
	; Dash
	;	$07C (32x24)
	;	$0A0 (24x24)
	;	$0A3 (24x24)
	;	$07C (32x24)	REPEATED
	;	$0A6 (24x24)
	;	$0A9 (24x24)	LOOP HERE
	; Punch 1
	;	$10D -> $0D0
	;	$14A -> $0D2
	;	$14D -> $0D5
	; Climb
	;	$148 -> $0D8
	; Spin attack (new)
	;	$046 (24x16)
	;	$049 (24x16)	+ efx
	;	$046 (24x16)	X
	;	$049 (24x16)	X + efx LOOP HERE
	; EFX (new)
	;	$0DA (16x16)


	; Plan:
	;	move dash (08-0B) -> 1A-1F
	;	put spin attack at 08-0B
	;	move punches (28-2B) -> 20-23



	; Anim format:
	; dw $TTTT : db $tt,$NN
	; dw $DDDD
	; dw $CCCC
	; TTTT is tilemap pointer.
	; tt is frame count.
	; NN is next anim.
	; DDDD is dynamo pointer.
	; CCCC is clipping pointer.




	ANIM:
	.Idle0				; 00
	dw .IdleTM : db $06,!Kad_Idle+1
	dw .IdleDynamo0
	dw .ClippingStandard
	.Idle1				; 01
	dw .IdleTM : db $06,!Kad_Idle+2
	dw .IdleDynamo1
	dw .ClippingStandard
	.Idle2				; 02
	dw .IdleTM : db $06,!Kad_Idle+3
	dw .IdleDynamo0
	dw .ClippingStandard
	.Idle3				; 03
	dw .IdleTM : db $06,!Kad_Idle
	dw .IdleDynamo3
	dw .ClippingStandard

	.Walk0				; 04
	dw .IdleTM : db $06,!Kad_Walk+1
	dw .WalkDynamo0
	dw .ClippingStandard
	.Walk1				; 05
	dw .WalkTM : db $06,!Kad_Walk+2
	dw .WalkDynamo1
	dw .ClippingStandard
	.Walk2				; 06
	dw .IdleTM : db $06,!Kad_Walk+3
	dw .WalkDynamo2
	dw .ClippingStandard
	.Walk3				; 07
	dw .WalkTM : db $06,!Kad_Walk
	dw .WalkDynamo3
	dw .ClippingStandard

	.Spin0				; 08
	dw .SpinTM0 : db $02,!Kad_Spin+1
	dw .SpinDynamo0
	dw .ClippingShell
	.Spin1				; 09
	dw .SpinTM1 : db $02,!Kad_Spin+2
	dw .SpinDynamo1
	dw .ClippingShell
	.Spin2				; 0A
	dw .SpinTM2 : db $02,!Kad_Spin+3
	dw .SpinDynamo0
	dw .ClippingShell
	.Spin3				; 0B
	dw .SpinTM3 : db $02,!Kad_Spin
	dw .SpinDynamo1
	dw .ClippingShell

	.Squat				; 0C
	dw .SquatTM : db $04,!Kad_Fall
	dw .SquatDynamo
	dw .ClippingShell

	.Shell0				; 0D
	dw .ShellTM : db $06,!Kad_Shell+1
	dw .ShellDynamo0
	dw .ClippingShell
	.Shell1				; 0E
	dw .ShellTM : db $06,!Kad_Shell+2
	dw .ShellDynamo1
	dw .ClippingShell
	.Shell2				; 0F
	dw .ShellTM : db $06,!Kad_Shell+3
	dw .ShellDynamo2
	dw .ClippingShell
	.Shell3				; 10
	dw .ShellTMX : db $08,!Kad_Shell
	dw .ShellDynamo1
	dw .ClippingShell

	.Fall				; 11
	dw .IdleTM : db $FF,!Kad_Fall
	dw .FallDynamo
	dw .ClippingShell

	.Turn				; 12
	dw .TurnTM : db $FF,!Kad_Turn
	dw .TurnDynamo
	dw .ClippingStandard

	.Senku				; 13
	dw .IdleTM : db $FF,!Kad_Senku
	dw .SenkuDynamo
	dw .ClippingStandard

	.1Punch0			; 14
	dw .IdleTM : db $02,!Kad_Punch1+1
	dw .PunchDynamo0
	dw .ClippingStandard
	.1Punch1			; 15
	dw .IdleTM : db $04,!Kad_Punch1+2
	dw .1PunchDynamo1
	dw .ClippingStandard
	.1Punch2			; 16
	dw .EndPunchTM : db $04,!Kad_Punch1+3
	dw .1PunchDynamo2
	dw .ClippingStandard
	.1Punch3			; 17
	dw .EndPunchTM : db $04,!Kad_Idle+1
	dw .1PunchDynamo3
	dw .ClippingStandard

	.2Punch0			; 18
	dw .IdleTM : db $02,!Kad_Punch2+1
	dw .PunchDynamo0
	dw .ClippingStandard
	.2Punch1			; 19
	dw .IdleTM : db $04,!Kad_Punch2+2
	dw .2PunchDynamo1
	dw .ClippingStandard
	.2Punch2			; 1A
	dw .EndPunchTM : db $04,!Kad_Punch2+3
	dw .2PunchDynamo2
	dw .ClippingStandard
	.2Punch3			; 1B
	dw .EndPunchTM : db $04,!Kad_Idle+1
	dw .2PunchDynamo3
	dw .ClippingStandard

	.Hurt				; 1C
	dw .IdleTM : db $FF,!Kad_Hurt
	dw .HurtDynamo
	dw .ClippingStandard

	.Dead				; 1D
	dw .IdleTM : db $FF,!Kad_Dead
	dw .DeadDynamo
	dw .ClippingStandard

	.Dash0				; 1E
	dw .DashTM0 : db $06,!Kad_Dash+1
	dw .DashDynamo0
	dw .ClippingDash
	.Dash1				; 1F
	dw .DashTM1 : db $06,!Kad_Dash+2
	dw .DashDynamo1
	dw .ClippingDash
	.Dash2				; 20
	dw .DashTM1 : db $06,!Kad_Dash+3
	dw .DashDynamo2
	dw .ClippingDash
	.Dash3				; 21
	dw .DashTM0 : db $06,!Kad_Dash+4
	dw .DashDynamo0
	dw .ClippingDash
	.Dash4				; 22
	dw .DashTM1 : db $06,!Kad_Dash+5
	dw .DashDynamo3
	dw .ClippingDash
	.Dash5				; 23
	dw .DashTM1 : db $06,!Kad_Dash
	dw .DashDynamo4
	dw .ClippingDash

	.Climb0				; 24
	dw .IdleTM : db $10,!Kad_Climb+1
	dw .ClimbDynamo
	dw .ClippingStandard
	.Climb1				; 25
	dw .ClimbTM : db $10,!Kad_Climb
	dw .ClimbDynamo
	dw .ClippingStandard

	.Duck0				; 26
	dw .SquatTM : db $06,!Kad_Duck+1
	dw .SquatDynamo
	dw .ClippingShell
	.Duck1				; 27
	dw .ShellTM : db $FF,!Kad_Duck+1
	dw .ShellDynamo1
	dw .ClippingShell

	.Swim0				; 28
	dw .ShellTMX : db $06,!Kad_Swim+1
	dw .SwimDynamo0
	dw .ClippingShell
	.Swim1				; 29
	dw .ShellTMX : db $06,!Kad_Swim+2
	dw .SwimDynamo1
	dw .ClippingShell
	.Swim2				; 2A
	dw .ShellTMX : db $06,!Kad_Swim+3
	dw .SwimDynamo2
	dw .ClippingShell
	.Swim3				; 2B
	dw .ShellTMX : db $08,!Kad_Swim
	dw .SwimDynamo3
	dw .ClippingShell

	.SenkuSmash0			; 2C
	dw .SmashTM0 : db $04,!Kad_SenkuSmash+1
	dw .SenkuSmashDynamo0
	dw .ClippingStandard
	.SenkuSmash1			; 2D
	dw .SmashTM0 : db $04,!Kad_SenkuSmash+2
	dw .SenkuSmashDynamo1
	dw .ClippingStandard
	.SenkuSmash2			; 2E
	dw .SmashTM0 : db $04,!Kad_SenkuSmash+3
	dw .SenkuSmashDynamo2
	dw .ClippingStandard
	.SenkuSmash3			; 2F
	dw .SmashTM0 : db $08,!Kad_SenkuSmash+4
	dw .SenkuSmashDynamo3
	dw .ClippingStandard
	.SenkuSmash4			; 30
	dw .SmashTM1 : db $08,!Kad_Fall
	dw .SenkuSmashDynamo4
	dw .ClippingStandard

	.ShellDrill0			; 31
	dw .SmashTM0 : db $04,!Kad_ShellDrill+1
	dw .ShellDrillDynamoInit
	dw .ClippingStandard
	.ShellDrill1			; 32
	dw .ShellDrillTM00 : db $02,!Kad_ShellDrill+2
	dw .ShellDynamo0
	dw .ClippingShell
	.ShellDrill2			; 33
	dw .ShellDrillTM01 : db $02,!Kad_ShellDrill+3
	dw .ShellDynamo1
	dw .ClippingShell
	.ShellDrill3			; 34
	dw .ShellDrillTM02 : db $02,!Kad_ShellDrill+4
	dw .ShellDynamo2
	dw .ClippingShell
	.ShellDrill4			; 35
	dw .ShellDrillTMX : db $02,!Kad_ShellDrill+1
	dw .ShellDynamo1
	dw .ClippingShell

	.DrillLand0			; 36
	dw .FlipSpinTM0 : db $02,!Kad_DrillLand+1
	dw .SpinDynamo0
	dw .ClippingShell
	.DrillLand1			; 37
	dw .FlipSpinTM1 : db $02,!Kad_DrillLand+2
	dw .SpinDynamo1
	dw .ClippingShell
	.DrillLand2			; 38
	dw .FlipSpinTM2 : db $02,!Kad_DrillLand+3
	dw .SpinDynamo0
	dw .ClippingShell
	.DrillLand3			; 39
	dw .FlipSpinTM3 : db $02,!Kad_DrillLand
	dw .SpinDynamo1
	dw .ClippingShell


	.IdleTM
	dw $0008
	db $2E,$00,$F0,!P2Tile1
	db $2E,$00,$00,!P2Tile2

	.WalkTM
	dw $0008
	db $2E,$00,$EF,!P2Tile1
	db $2E,$00,$FF,!P2Tile2

	.DashTM0
	dw $0010
	db $2E,$F0,$F8,!P2Tile1
	db $2E,$00,$F8,!P2Tile2
	db $2E,$F0,$00,!P2Tile3
	db $2E,$00,$00,!P2Tile4
	.DashTM1
	dw $0010
	db $2E,$F4,$F8,!P2Tile1
	db $2E,$FC,$F8,!P2Tile1+1
	db $2E,$F4,$00,!P2Tile3
	db $2E,$FC,$00,!P2Tile3+1

	.TurnTM
	dw $0010
	db $2E,$F8,$F8,!P2Tile1
	db $2E,$08,$F8,!P2Tile2
	db $2E,$F8,$00,!P2Tile3
	db $2E,$08,$00,!P2Tile4

	.SquatTM
	dw $0008
	db $2E,$00,$F8,!P2Tile1
	db $2E,$00,$00,!P2Tile2

	.ShellTM
	dw $0004
	db $2E,$00,$00,!P2Tile1
	.ShellTMX
	dw $0004
	db $6E,$00,$00,!P2Tile1

	.PunchTM
	dw $0010
	db $2E,$F8,$F0,!P2Tile1
	db $2E,$00,$F0,!P2Tile2
	db $2E,$F8,$00,!P2Tile3
	db $2E,$00,$00,!P2Tile4
	.EndPunchTM
	dw $0010
	db $2E,$F8,$F0,!P2Tile1
	db $2E,$00,$F0,!P2Tile1+1
	db $2E,$F8,$00,!P2Tile3
	db $2E,$00,$00,!P2Tile3+1

	.SpinTM0
	dw $0008
	db $2E,$FC,$FC,!P2Tile1
	db $2E,$04,$FC,!P2Tile1+1
	.SpinTM1
	dw $0010
	db $2E,$08,$05,!P2Tile4
	db $2E,$FC,$FC,!P2Tile1
	db $2E,$04,$FC,!P2Tile1+1
	db $6E,$08,$FF,!P2Tile4
	.SpinTM2
	dw $0008
	db $6E,$FC,$FC,!P2Tile1
	db $6E,$04,$FC,!P2Tile1+1
	.SpinTM3
	dw $0010
	db $6E,$08,$05,!P2Tile4
	db $6E,$FC,$FC,!P2Tile1
	db $6E,$04,$FC,!P2Tile1+1
	db $2E,$08,$FF,!P2Tile4

	.FlipSpinTM0
	dw $0008
	db $AE,$FC,$FC,!P2Tile1
	db $AE,$04,$FC,!P2Tile1+1
	.FlipSpinTM1
	dw $0010
	db $AE,$08,$05,!P2Tile4
	db $AE,$FC,$FC,!P2Tile1
	db $AE,$04,$FC,!P2Tile1+1
	db $EE,$08,$FF,!P2Tile4
	.FlipSpinTM2
	dw $0008
	db $EE,$FC,$FC,!P2Tile1
	db $EE,$04,$FC,!P2Tile1+1
	.FlipSpinTM3
	dw $0010
	db $EE,$08,$05,!P2Tile4
	db $EE,$FC,$FC,!P2Tile1
	db $EE,$04,$FC,!P2Tile1+1
	db $AE,$08,$FF,!P2Tile4


	.ShellDrillTM00
	dw $000C
	db $EE,$08,$01,!P2Tile7
	db $AE,$08,$FD,!P2Tile7
	db $AE,$00,$00,!P2Tile1
	.ShellDrillTM01
	dw $0004
	db $AE,$00,$00,!P2Tile1
	.ShellDrillTM02
	dw $000C
	db $AE,$08,$01,!P2Tile7
	db $EE,$08,$FD,!P2Tile7
	db $AE,$00,$00,!P2Tile1
	.ShellDrillTMX
	dw $0004
	db $EE,$00,$00,!P2Tile1


	.ClimbTM
	dw $0008
	db $6E,$00,$F0,!P2Tile1
	db $6E,$00,$00,!P2Tile2

	.SmashTM0
	dw $0010
	db $6E,$FC,$F8,!P2Tile1
	db $6E,$04,$F8,!P2Tile1+1
	db $6E,$FC,$00,!P2Tile3
	db $6E,$04,$00,!P2Tile3+1
	.SmashTM1
	dw $0008
	db $6E,$00,$F0,!P2Tile1
	db $6E,$00,$00,!P2Tile2


;macro KadDyn(TileCount, TileNumber, Dest)
;	dw <TileCount>*$20
;	dl <TileNumber>*$20+$328008
;	dw <Dest>*$10+$6000
;endmacro

macro KadDyn(TileCount, TileNumber, Dest)
	db (<TileCount>*2)|((<TileNumber>&$07)<<5)
	db <TileNumber>>>3
	db <Dest>*8
endmacro




	.IdleDynamo0				; Used by 0, 2
	db ..End-..Start
	..Start
	%KadDyn(2, $000, !P2Tile1)
	%KadDyn(2, $010, !P2Tile1+$10)
	%KadDyn(2, $020, !P2Tile2)
	%KadDyn(2, $030, !P2Tile2+$10)
	..End
	.IdleDynamo1				; Used by 1
	db ..End-..Start
	..Start
	%KadDyn(2, $002, !P2Tile1)
	%KadDyn(2, $012, !P2Tile1+$10)
	%KadDyn(2, $022, !P2Tile2)
	%KadDyn(2, $032, !P2Tile2+$10)
	..End
	.IdleDynamo3				; Used by 3
	db ..End-..Start
	..Start
	%KadDyn(2, $004, !P2Tile1)
	%KadDyn(2, $014, !P2Tile1+$10)
	%KadDyn(2, $024, !P2Tile2)
	%KadDyn(2, $034, !P2Tile2+$10)
	..End

	.WalkDynamo0
	db ..End-..Start
	..Start
	%KadDyn(2, $000, !P2Tile1)
	%KadDyn(2, $010, !P2Tile1+$10)
	%KadDyn(2, $020, !P2Tile2)
	%KadDyn(2, $030, !P2Tile2+$10)
	..End
	.WalkDynamo1
	db ..End-..Start
	..Start
	%KadDyn(2, $006, !P2Tile1)
	%KadDyn(2, $016, !P2Tile1+$10)
	%KadDyn(2, $026, !P2Tile2)
	%KadDyn(2, $036, !P2Tile2+$10)
	..End
	.WalkDynamo2
	db ..End-..Start
	..Start
	%KadDyn(2, $008, !P2Tile1)
	%KadDyn(2, $018, !P2Tile1+$10)
	%KadDyn(2, $028, !P2Tile2)
	%KadDyn(2, $038, !P2Tile2+$10)
	..End
	.WalkDynamo3
	db ..End-..Start
	..Start
	%KadDyn(2, $00A, !P2Tile1)
	%KadDyn(2, $01A, !P2Tile1+$10)
	%KadDyn(2, $02A, !P2Tile2)
	%KadDyn(2, $03A, !P2Tile2+$10)
	..End

	.DashDynamo0				; Used by frames 0, 3
	db ..End-..Start
	..Start
	%KadDyn(4, $07C, !P2Tile1)
	%KadDyn(4, $08C, !P2Tile1+$10)
	%KadDyn(4, $08C, !P2Tile3)
	%KadDyn(4, $09C, !P2Tile3+$10)
	..End
	.DashDynamo1				; Used by frame 1
	db ..End-..Start
	..Start
	%KadDyn(3, $0A0, !P2Tile1)
	%KadDyn(3, $0B0, !P2Tile1+$10)
	%KadDyn(3, $0B0, !P2Tile3)
	%KadDyn(3, $0C0, !P2Tile3+$10)
	..End
	.DashDynamo2				; Used by frame 2
	db ..End-..Start
	..Start
	%KadDyn(3, $0A3, !P2Tile1)
	%KadDyn(3, $0B3, !P2Tile1+$10)
	%KadDyn(3, $0B3, !P2Tile3)
	%KadDyn(3, $0C3, !P2Tile3+$10)
	..End
	.DashDynamo3				; Used by frame 4
	db ..End-..Start
	..Start
	%KadDyn(3, $0A6, !P2Tile1)
	%KadDyn(3, $0B6, !P2Tile1+$10)
	%KadDyn(3, $0B6, !P2Tile3)
	%KadDyn(3, $0C6, !P2Tile3+$10)
	..End
	.DashDynamo4				; Used by frame 5
	db ..End-..Start
	..Start
	%KadDyn(3, $0A9, !P2Tile1)
	%KadDyn(3, $0B9, !P2Tile1+$10)
	%KadDyn(3, $0B9, !P2Tile3)
	%KadDyn(3, $0C9, !P2Tile3+$10)
	..End

	.SquatDynamo				; Also used by .Duck0
	db ..End-..Start
	..Start
	%KadDyn(2, $060, !P2Tile1)
	%KadDyn(2, $070, !P2Tile1+$10)
	%KadDyn(2, $070, !P2Tile2)
	%KadDyn(2, $080, !P2Tile2+$10)
	..End

	.ShellDynamo0				; Also used by .Duck1
	db ..End-..Start
	..Start
	%KadDyn(2, $040, !P2Tile1)
	%KadDyn(2, $050, !P2Tile1+$10)
	..End
	.ShellDynamo1
	db ..End-..Start
	..Start
	%KadDyn(2, $042, !P2Tile1)
	%KadDyn(2, $052, !P2Tile1+$10)
	..End
	.ShellDynamo2
	db ..End-..Start
	..Start
	%KadDyn(2, $044, !P2Tile1)
	%KadDyn(2, $054, !P2Tile1+$10)
	..End

	.FallDynamo
	db ..End-..Start
	..Start
	%KadDyn(2, $064, !P2Tile1)
	%KadDyn(2, $074, !P2Tile1+$10)
	%KadDyn(2, $084, !P2Tile2)
	%KadDyn(2, $094, !P2Tile2+$10)
	..End

	.TurnDynamo
	db ..End-..Start
	..Start
	%KadDyn(4, $04C, !P2Tile1)
	%KadDyn(4, $05C, !P2Tile1+$10)
	%KadDyn(4, $05C, !P2Tile3)
	%KadDyn(4, $06C, !P2Tile3+$10)
	..End

	.SenkuDynamo
	db ..End-..Start
	..Start
	%KadDyn(2, $062, !P2Tile1)
	%KadDyn(2, $072, !P2Tile1+$10)
	%KadDyn(2, $082, !P2Tile2)
	%KadDyn(2, $092, !P2Tile2+$10)
	..End

	.PunchDynamo0				; Used by both punches
	db ..End-..Start
	..Start
	%KadDyn(2, $00C, !P2Tile1)
	%KadDyn(2, $01C, !P2Tile1+$10)
	%KadDyn(2, $02C, !P2Tile2)
	%KadDyn(2, $03C, !P2Tile2+$10)
	..End

	.1PunchDynamo1
	db ..End-..Start
	..Start
	%KadDyn(2, $00E, !P2Tile1)
	%KadDyn(2, $01E, !P2Tile1+$10)
	%KadDyn(2, $02E, !P2Tile2)
	%KadDyn(2, $03E, !P2Tile2+$10)
	..End
	.1PunchDynamo2
	db ..End-..Start
	..Start
	%KadDyn(3, $066, !P2Tile1)
	%KadDyn(3, $076, !P2Tile1+$10)
	%KadDyn(3, $086, !P2Tile3)
	%KadDyn(3, $096, !P2Tile3+$10)
	..End
	.1PunchDynamo3
	db ..End-..Start
	..Start
	%KadDyn(3, $069, !P2Tile1)
	%KadDyn(3, $079, !P2Tile1+$10)
	%KadDyn(3, $089, !P2Tile3)
	%KadDyn(3, $099, !P2Tile3+$10)
	..End

	.2PunchDynamo1
	db ..End-..Start
	..Start
	%KadDyn(2, $0D0, !P2Tile1)
	%KadDyn(2, $0E0, !P2Tile1+$10)
	%KadDyn(2, $0F0, !P2Tile2)
	%KadDyn(2, $100, !P2Tile2+$10)
	..End
	.2PunchDynamo2
	db ..End-..Start
	..Start
	%KadDyn(3, $0D2, !P2Tile1)
	%KadDyn(3, $0E2, !P2Tile1+$10)
	%KadDyn(3, $0F2, !P2Tile3)
	%KadDyn(3, $102, !P2Tile3+$10)
	..End
	.2PunchDynamo3
	db ..End-..Start
	..Start
	%KadDyn(3, $0D5, !P2Tile1)
	%KadDyn(3, $0E5, !P2Tile1+$10)
	%KadDyn(3, $0F5, !P2Tile3)
	%KadDyn(3, $105, !P2Tile3+$10)
	..End

	.HurtDynamo
	db ..End-..Start
	..Start
	%KadDyn(2, $0AC, !P2Tile1)
	%KadDyn(2, $0BC, !P2Tile1+$10)
	%KadDyn(2, $0CC, !P2Tile2)
	%KadDyn(2, $0DC, !P2Tile2+$10)
	..End

	.DeadDynamo
	db ..End-..Start
	..Start
	%KadDyn(2, $0AE, !P2Tile1)
	%KadDyn(2, $0BE, !P2Tile1+$10)
	%KadDyn(2, $0CE, !P2Tile2)
	%KadDyn(2, $0DE, !P2Tile2+$10)
	..End

	.SpinDynamo0
	db ..End-..Start
	..Start
	%KadDyn(3, $046, !P2Tile1)
	%KadDyn(3, $056, !P2Tile1+$10)
	..End
	.SpinDynamo1
	db ..End-..Start
	..Start
	%KadDyn(3, $049, !P2Tile1)
	%KadDyn(3, $059, !P2Tile1+$10)
	%KadDyn(2, $0DA, !P2Tile4)
	%KadDyn(2, $0EA, !P2Tile4+$10)
	..End

	.ClimbDynamo				; Used by both frames
	db ..End-..Start
	..Start
	%KadDyn(2, $0D8, !P2Tile1)
	%KadDyn(2, $0E8, !P2Tile1+$10)
	%KadDyn(2, $0F8, !P2Tile2)
	%KadDyn(2, $108, !P2Tile2+$10)
	..End

	.SenkuSmashDynamo0
	db ..End-..Start
	..Start
	%KadDyn(3, $110, !P2Tile1)
	%KadDyn(3, $120, !P2Tile1+$10)
	%KadDyn(3, $120, !P2Tile3)
	%KadDyn(3, $130, !P2Tile3+$10)
	..End
	.SenkuSmashDynamo1
	db ..End-..Start
	..Start
	%KadDyn(3, $113, !P2Tile1)
	%KadDyn(3, $123, !P2Tile1+$10)
	%KadDyn(3, $123, !P2Tile3)
	%KadDyn(3, $133, !P2Tile3+$10)
	..End
	.SenkuSmashDynamo2
	db ..End-..Start
	..Start
	%KadDyn(3, $116, !P2Tile1)
	%KadDyn(3, $126, !P2Tile1+$10)
	%KadDyn(3, $126, !P2Tile3)
	%KadDyn(3, $136, !P2Tile3+$10)
	..End
	.SenkuSmashDynamo3
	db ..End-..Start
	..Start
	%KadDyn(3, $119, !P2Tile1)
	%KadDyn(3, $129, !P2Tile1+$10)
	%KadDyn(3, $129, !P2Tile3)
	%KadDyn(3, $139, !P2Tile3+$10)
	..End
	.SenkuSmashDynamo4
	db ..End-..Start
	..Start
	%KadDyn(2, $11C, !P2Tile1)
	%KadDyn(2, $12C, !P2Tile1+$10)
	%KadDyn(2, $13C, !P2Tile2)
	%KadDyn(2, $14C, !P2Tile2+$10)
	..End

	.ShellDrillDynamoInit
	db ..End-..Start
	..Start
	%KadDyn(3, $119, !P2Tile1)
	%KadDyn(3, $129, !P2Tile1+$10)
	%KadDyn(3, $129, !P2Tile3)
	%KadDyn(3, $139, !P2Tile3+$10)
	%KadDyn(2, $0DA, !P2Tile7)
	%KadDyn(2, $0EA, !P2Tile7+$10)
	..End

	.SwimDynamo0
	db ..End-..Start
	..Start
	%KadDyn(2, $00C, !P2Tile1)
	%KadDyn(2, $00E, !P2Tile1+$10)
	..End
	.SwimDynamo1
	db ..End-..Start
	..Start
	%KadDyn(2, $008, !P2Tile1)
	%KadDyn(2, $00A, !P2Tile1+$10)
	..End
	.SwimDynamo2
	db ..End-..Start
	..Start
	%KadDyn(2, $004, !P2Tile1)
	%KadDyn(2, $006, !P2Tile1+$10)
	..End
	.SwimDynamo3
	db ..End-..Start
	..Start
	%KadDyn(2, $000, !P2Tile1)
	%KadDyn(2, $002, !P2Tile1+$10)
	..End





	.ClippingStandard
	; X
	db $0E,$01,$0E,$01		; R/L/R/L
	db $04,$0B,$08,$08		; D/D/U/C
	; Y
	db $FF,$FF,$0A,$0A		; R/L/R/L
	db $10,$10,$F8,$02		; D/D/U/C
	; hurtbox
	dw $0001,$FFF8			; X/Y
	db $0D,$17			; W/H

	.ClippingDash
	; X
	db $0E,$01,$0E,$01		; R/L/R/L
	db $04,$0B,$08,$08		; D/D/U/C
	; Y
	db $FF,$FF,$0A,$0A		; R/L/R/L
	db $10,$10,$F8,$02		; D/D/U/C
	; hurtbox
	dw $0006,$FFFE			; X/Y
	db $13,$11			; W/H

	.ClippingShell
	; X
	db $0E,$01,$0E,$01		; R/L/R/L
	db $04,$0B,$08,$08		; D/D/U/C
	; Y
	db $06,$06,$0A,$0A		; R/L/R/L
	db $10,$10,$00,$08		; D/D/U/C
	; hurtbox
	dw $0001,$0000			; X/Y
	db $0D,$0F			; W/H



.End
print "  Anim data: $", hex(.End-ANIM), " bytes"
print "  - sequence data: $", hex(.IdleTM-ANIM), " bytes (", dec((.IdleTM-ANIM)*100/(.End-ANIM)), "%)"
print "  - tilemap data:  $", hex(.IdleDynamo0-.IdleTM), " bytes (", dec((.IdleDynamo0-.IdleTM)*100/(.End-ANIM)), "%)"
print "  - dynamo data:   $", hex(.ClippingStandard-.IdleDynamo0), " bytes (", dec((.ClippingStandard-.IdleDynamo0)*100/(.End-ANIM)), "%)"
print "  - clipping data: $", hex(.End-.ClippingStandard), " bytes (", dec((.End-.ClippingStandard)*100/(.End-ANIM)), "%)"



;			   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |			|
;	LO NYBBLE	   |YY0|YY1|YY2|YY3|YY4|YY5|YY6|YY7|YY8|YY9|YYA|YYB|YYC|YYD|YYE|YYF|	HI NYBBLE	|
;	--->		   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |			V

HIT_TABLE:		db $01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04,$00,$05	;| 00X
			db $06,$02,$00,$01,$01,$08,$08,$00,$08,$00,$00,$07,$09,$07,$0A,$0A	;| 01X
			db $07,$0B,$0C,$0C,$0C,$0C,$07,$07,$07,$00,$07,$07,$00,$00,$07,$0D	;| 02X
			db $0E,$0E,$0E,$07,$07,$00,$00,$07,$07,$07,$07,$07,$07,$01,$0D,$06	;| 03X
			db $04,$0F,$0F,$0F,$07,$00,$10,$00,$07,$0F,$11,$0A,$00,$12,$12,$01	;| 04X
			db $01,$0A,$00,$00,$00,$0F,$0F,$0F,$0F,$00,$00,$0F,$0F,$0F,$0F,$00	;| 05X
			db $00,$0F,$0F,$0F,$00,$07,$07,$07,$07,$00,$00,$00,$00,$00,$13,$13	;| 06X
			db $00,$01,$01,$01,$1A,$1A,$1A,$1A,$1A,$00,$00,$11,$00,$00,$00,$00	;| 07X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 08X
			db $00,$10,$10,$10,$10,$10,$00,$10,$10,$07,$07,$0A,$0F,$00,$07,$14	;| 09X
			db $00,$07,$02,$00,$07,$07,$07,$00,$07,$07,$07,$15,$00,$00,$07,$16	;| 0AX
			db $07,$00,$07,$07,$07,$00,$07,$17,$17,$00,$0F,$0F,$00,$01,$0A,$18	;| 0BX
			db $0F,$00,$01,$07,$0F,$07,$00,$00,$00					;| 0CX

.Custom			db $00,$00,$00,$00,$00,$00,$1C,$07,$1B,$00,$00,$1D,$00,$00,$00,$00	;| 10X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 11X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 12X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 13X
			db $19,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 14X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 15X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 16X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 17X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 18X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 19X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 1AX
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 1BX
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 1CX
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 1DX
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 1EX
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 1FX





namespace off
















