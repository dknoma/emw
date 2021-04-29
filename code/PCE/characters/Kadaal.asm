;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

namespace Kadaal

; --Build 6.4--
;
;
; Upgrade data:
;	bit 0 (01)	Senku smash
;	bit 1 (02)	Can senku in 8 directions
;	bit 2 (04)	Can start senku in midair
;	bit 3 (08)	Landslide (hold down when landing with enough X-speed)
;	bit 4 (10)	Down + Y in midair to perform a shell drill attack, breaks bricks
;	bit 5 (20)	+1 HP, protects against some attacks while ducking
;	bit 6 (40)	Ground spin (can spin attack while ducking or sliding)
;	bit 7 (80)	Push X to perform ultimate attack



	!Kad_Idle	= $00
	!Kad_Walk	= $04
	!Kad_Spin	= $08
	!Kad_Squat	= $0C
	!Kad_Shell	= $0D
	!Kad_Fall	= $11
	!Kad_Turn	= $12
	!Kad_Senku	= $13
	!Kad_Punch1	= $14
	!Kad_Punch2	= $18
	!Kad_Hurt	= $1C
	!Kad_Dead	= $1D
	!Kad_Dash	= $1E
	!Kad_Climb	= $24
	!Kad_Duck	= $26
	!Kad_SenkuSmash	= $28
	!Kad_ShellDrill	= $2D
	!Kad_DrillLand	= $32




	MAINCODE:
		PHB : PHK : PLB

	LDA #$FF : STA !KadaalUpgrades

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
		JSR CORE_KNOCKED_OUT
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
		LDA !P2Platform				;\
		BEQ ++					; |
		CMP !P2SpritePlatform : BEQ +		; | Account for platforms
	++	STA !P2PrevPlatform			; |
		+					;/
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

		LDA !P2Kick
		BEQ +
		BPL ++
		INC !P2Kick
		BRA +
	++	DEC !P2Kick : BNE +
		LDA #$F0 : STA !P2Kick
		LDA !P2ShellSlide : BNE ++
		BIT !P2Water : BPL ++
		LDA #!Kad_Duck+1
		BRA +++
	++	LDA #!Kad_Shell
	+++	STA !P2Anim
		STZ !P2AnimTimer
		STZ !P2Buffer
		+


	PIPE:
		JSR CORE_PIPE
		BCC $03 : JMP ANIMATION_HandleUpdate



	CONTROLS:

		JSR CORE_COYOTE_TIME


		LDX !P2Direction
		LDA !P2Water
		LSR A : BCS .Turn
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

		LDA !P2Water
		LSR A
		BCC $03 : JMP .NoDuck

		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		ORA !P2SpritePlatform
		BNE ..Ground
		JMP .NoGround

	..Ground
		LDA !P2BackDash
		CMP #$08 : BCC ..BackDash
		BRA ..NoDir

	..BackDash
		LDA $6DA9
		AND #$30 : BEQ .NoBackDash
		AND #$10 : BEQ +
		LDA !P2Direction			; R is perfect pivot
		INC A
		TSB $6DA3
		EOR #$03
		TRB $6DA3

	+	LDA #$10 : STA !P2BackDash
		LDA $6DA3
		AND #$03 : BEQ +
		CMP #$03 : BEQ +
		DEC A
		EOR #$01
		STA !P2Direction
		BRA ++
	+	LDA !P2Direction
	++	EOR #$01
		TAY
		LDA .XSpeedSenku,y : JSR CORE_SET_XSPEED
		LDA #$2D : STA !SPC1			; slide SFX
		STZ !P2Punch1
		STZ !P2Punch2
		STZ !P2Senku
	..NoDir	LDA #$0F				;\
		TRB $6DA3				; | clear directionals during back dash
		TRB $6DA7				;/
		LDA #$01 : STA !P2Dashing
		.NoBackDash


		LDA !P2ShellDrill : BEQ .NoPound	;\
		STZ !P2ShellDrill			; |
		JSR .StartSpin				; | shell drill landing
		LDA #$09 : STA !SPC4			; > smash SFX
		LDA #$17 : STA !P2JumpLag		; |
		LDA #!Kad_DrillLand : STA !P2Anim	; |
		RTS					; |
		.NoPound				;/


		LDA !P2Anim				;\
		CMP #!Kad_DrillLand : BCC .NoDrillLand	; | force crouch physics during drill land
		BRA .ForceCrouch			; |
		.NoDrillLand				;/


		LDA $6DA3				;\
		AND #$04 : BNE +			; |
		STZ !P2ShellSlide			; |
		STZ !P2ShellSpeed			; |
		BRA .NoGround				; |
	+	LDA !P2ShellSlide : BEQ .NoGround	; |
	-	JSR .GSpin				; > Hook ground spin here
		LDA !P2Blocked				; |
		AND #$03 : BEQ +			; |
		DEC A					; |
		AND #$01				; | Shell slide code
		STA !P2Direction			; |
		LDA #$01 : STA !SPC1			; |
	+	LDY !P2Direction			; |
		LDA .XSpeedSenku,y : JSR CORE_SET_XSPEED; |
		LDA #$01 : STA !P2ShellSpeed		; |
		LDA #$03				; |
		TRB $6DA3				; |
		TRB $6DA5				; |
		BRA .NoDuck				; |
		.NoGround				;/

		LDA !P2Senku : BEQ +
		CMP #$20 : BCC .NoDuck
	+	LDA !P2Blocked
		LDY !P2Platform
		BEQ $02 : ORA #$04
		AND $6DA3
		AND #$04 : BEQ .NoDuck
		BIT $6DA7
		BPL $03 : JMP .SenkuJump

		LDA !KadaalUpgrades			;\
		AND #$08 : BEQ .ForceCrouch		; |
		LDA !P2XSpeed				; |
		BPL $03 : EOR #$FF : INC A		; | allow shell slide with upgrade
		CMP #$20 : BCC .ForceCrouch		; |
		JSR StartSlide				; |
		BRA -					;/


	.ForceCrouch
		LDA #$00 : JSR CORE_SET_XSPEED
		LDA #$80 : TSB !P2Water
		STZ !P2Punch1
		STZ !P2Punch2
		STZ !P2Dashing
		STZ !P2Senku
	.GSpin	LDA !P2Kick : BNE .SpinR		;\
		LDA !KadaalUpgrades			; |
		AND #$40 : BEQ .SpinR			; |
		BIT $6DA7 : BVC .SpinR			; | Allow ground spin with upgrade
		.StartSpin				; > JSR here to start spin
		LDA #$10 : STA !P2Kick			; |
		LDA #!Kad_Spin : STA !P2Anim		; |
		LDA #$3E : STA !SPC4			; | > spin SFX
		STZ !P2IndexMem1			; |
		STZ !P2IndexMem2			; |
		STZ !P2AnimTimer			;/
	.SpinR	RTS
		.NoDuck


		LDA #$80 : TRB !P2Water
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
		LSR A
		BCC +
		LDA #$01 : STA !P2SenkuDir
		BRA .ProcessSenku
	+	LSR A
		BCS +

		.NoInitSenku
		LDA #$00
		LDA !P2Direction : STA !P2SenkuDir
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
	..Write	JSR CORE_SET_XSPEED
		STZ !P2JumpLag
		STZ !P2DashTimerR1
		STZ !P2DashTimerL1
		STZ !P2Buffer
		LDA #$01 : TRB !P2Water
		LDA !P2Senku
		CMP #$20
		BCS +
		LDA !P2SenkuDir				;\
		EOR #$01				; |
		INC A					; | Don't keep momentum after senku-ing into a block
		AND !P2Blocked				; |
		BEQ $06					; |
		STZ !P2XSpeed : STZ !P2Dashing		;/
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
		LDA !KadaalUpgrades			;\
		ORA !P2Blocked				; | Air senku is only allowed with proper upgrade
		AND #$04				; |
		BEQ .NoSenku				;/

		BIT $6DA9 : BPL .NoSenku
		STZ !P2ShellSlide
		LDA !P2Kick : BMI $02 : BNE .NoSenku
		LDA #$30 : STA !P2Senku
		LDA #$01 : STA !P2SenkuUsed
		STZ !P2ShellDrill
		RTS
		.NoSenku


		LDA !P2Water			; Check for vine/net climb
		LSR A : BCC .NoClimb
		STZ !P2ShellSlide
		LDA $6DA3
		LSR A
		BCC +
		LDA #$01 : STA !P2Direction
		BRA ++
	+	LSR A
		BCC ++
		STZ !P2Direction
	++	BIT $6DA7
		BPL +
		LDA #$01 : TRB !P2Water		; vine/net jump
		LDA #$B8 : STA !P2YSpeed
		LDA #$2B : STA !SPC1		; jump SFX
	+	RTS
		.NoClimb


		LDA !P2Blocked			;\
		AND #$04			; |
		LDY !P2Platform			; | $01 = ground flag
		BEQ $02 : ORA #$04		; |
		STA $01				;/
		BIT !P2Water			;\ Water check
		BVS .Water : JMP .NoWater	;/

		.Water
		STZ !P2ShellSlide		; no shell slide underwater
		LDA !P2Anim			;\
		CMP #$11			; |
		BNE +				; | Fall -> swim animation
		LDA #!Kad_Shell : STA !P2Anim	; |
		STZ !P2AnimTimer		; |
		+				;/
		LDA $6DA3			;\
		AND #$0F			; | Swim speed index
		TAY				;/
		LDA !P2YSpeed			;\
		CMP .AllRangeSpeedY,y		; |
		BEQ +				; | Swimming Y speed
		BPL $02 : INC #2		; |
		DEC A				; |
	+	STA !P2YSpeed			;/
		LDA $01 : BEQ +			; Check ground flag
		LDA $6DA3			;\
		AND #$03			; | Walking speed index
		TAY				;/
		BEQ .NoSwimDir			;\
		LDA .SwimDir,y			; | Walking direction
		STA !P2Direction		; |
		.NoSwimDir			;/
		LDA !P2XSpeed			;\
		CMP .WaterSpeedX,y		; | Walking X speed
		BEQ ++				; |
		BPL $02 : INC #2		; |
		DEC A				; |
		STA !P2XSpeed			; |
		BRA ++				; |
		+				;/
		LDA !P2XSpeed			;\
		CMP .AllRangeSpeedX,y		; |
		BEQ +				; | Swimming X speed
		BPL $02 : INC #2		; |
		DEC A				; |
		STA !P2XSpeed			; |
		+				;/
		BPL $02 : EOR #$FF		;\ Store absolute X speed
		STA $00				;/
		LDA !P2YSpeed			;\
		BPL $02 : EOR #$FF		; | Do animation if there is speed
		CLC : ADC $00			; |
		BNE +				;/
		LDA !P2Kick			;\ Always animate spin at 50% rate
		BNE ++				;/
		STZ !P2AnimTimer		;\ Otherewise no animation
		BRA +++				;/
	+	CMP #$20			;\ Animate at 100% rate if |X|+|Y|>0x1F
		BCS +++				;/
	++	LDA $14				;\
		LSR A				; | Animate at 50% rate
		BCC +++				; |
		DEC !P2AnimTimer		;/
	+++	STZ !P2SenkuUsed		; > No animation
		LDA $14				;\
		AND #$7F			; | Only spawn every 128 frames
		BNE +				;/
		LDY #!Ex_Amount-1		; > Number of indexes
	-	DEY				;\
		BMI +				; | Loop for slot
		LDA !Ex_Num,y			; |
		BNE -				;/
		LDA #$12+!ExtendedOffset : STA !Ex_Num,y		;\
		LDA !P2YPosLo			; |
		SEC : SBC #$08			; |
		STA !Ex_YLo,y			; |
		LDA !P2YPosHi			; |
		SBC #$00			; |
		STA !Ex_YHi,y			; | Spawn bubble
		LDX !P2Direction		; |
		LDA .BubbleX,x			; |
		CLC : ADC !P2XPosLo		; |
		STA !Ex_XLo,y			; |
		LDA !P2XPosHi			; |
		ADC #$00			; |
		STA !Ex_XHi,y			;/
	+	RTS
		.NoWater


		LDA !P2ShellSlide : BNE ..Skip		; > Can't punch during shell slide
		BIT !P2Buffer				;\ Skip regular input if buffered
		BVS +					;/
		BIT $6DA7
		BVS $03
	..Skip	JMP .NoPunch
	+	STZ !P2BackDash				; > clear back dash when an attack is started
		LDA !P2Kick : BEQ +			; see if a spin is happening already
		LDA !KadaalUpgrades			;\
		AND #$10 : BEQ ..NoC			; | kadaal can cancel spin into drill
		LDA $6DA3				; |
		AND #$04 : BNE .StartKick_Drill		;/
	..NoC	LDA #$40 : STA !P2Buffer		;\ don't change buffer here if spin is active
		JMP .NoPunch				;/
	+	LDA !P2Anim				;\ can't start spin or shell drill during smash
		CMP #$28 : BCC $03 : JMP .NoPunch	;/
		LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		BEQ .StartKick
		BRA .NoKick

		.StartKick
		LDA !KadaalUpgrades
		AND #$10 : BEQ ..Spin
		LDA $6DA3
		AND #$04 : BEQ ..Spin
	..Drill	LDA #$01 : STA !P2ShellDrill		; start shell drill
		STZ !P2Kick				; cancel shell spin
		LDA #!Kad_ShellDrill : STA !P2Anim
		STZ !P2AnimTimer
		STZ !P2ShellSlide
		STZ !P2ShellSpeed
		BRA .NoPunch

	..Spin	LDA #$10 : STA !P2Kick
		LDA #!Kad_Spin : STA !P2Anim
		LDA #$3E : STA !SPC4			; spin SFX
		STZ !P2AnimTimer
		STZ !P2Punch1
		STZ !P2Punch2
		STZ !P2IndexMem1
		STZ !P2IndexMem2
		BRA .NoPunch

		.PunchBuffer
		LDA #$40 : TSB !P2Buffer		;\ Set punch buffer and clear jump buffer
		LDA #$80 : TRB !P2Buffer		;/
		BRA .NoPunch

		.NoKick
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
		LDA #$37 : STA !SPC4			; SFX
		STZ !P2Punch1
		STZ !P2IndexMem1
		STZ !P2IndexMem2
		BRA .NoPunch

		.Punch1
		LDA #$14 : STA !P2Punch1
		LDA #$40 : TRB !P2Buffer
		LDA #$38 : STA !SPC4			; SFX
		STZ !P2Punch2
		STZ !P2IndexMem1
		STZ !P2IndexMem2
		.NoPunch


		LDA !P2ShellDrill : BEQ .NoDrill	;\
		LDA $6DA7				; |
		AND #$08 : BEQ +			; |
		STZ !P2ShellDrill			; | Can cancel drill with up
		LDA #!Kad_Squat : STA !P2Anim		; |
		STZ !P2AnimTimer			; |
		BRA .NoDrill				;/

	+	STZ !P2XSpeed				;\
		LDA #$08 : STA !P2Invinc		; > invulnerable during shell drill
		LDA #$14				; |
		LDY !P2Anim				; |
		CPY #!Kad_ShellDrill : BEQ +		; | Shell drill code
		LDA #$40				; |
	+	STA !P2YSpeed				; |
		RTS					; |
		.NoDrill				;/



		LDA !P2CoyoteTime : BMI +		;\ coyote time
		BNE .InitJump				;/
	+	LDA !P2JumpLag				;\
		BEQ .ProcessJump			; |
		BIT $6DA7 : BPL $05			; | Allow jump buffer from land lag
		LDA #$80 : TSB !P2Buffer		; |
		JMP .Friction				;/


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
		LDA !P2ShellSlide		;\ This is necessary for some platforms to work
		BNE $03 : STZ !P2Kick		;/
		LDA !P2Buffer
		ORA $6DA7
		BPL .NoJump
		STZ !P2CoyoteTime		; clear coyote time
		STZ !P2ShellSlide		; Clear shell slide
		LDA #!Kad_Squat : STA !P2Anim
		STZ !P2AnimTimer
	;	LDA !P2Punch1			;\
	;	ORA !P2Punch2			; |
	;	BEQ .SenkuJump			; | Allow players to buffer jump from punch
	;	LDA #$80 : STA !P2Buffer	; |
	;	BRA .NoJump			;/

		.SenkuJump
		LDA #$80 : TRB !P2Buffer	; > Clear jump from buffer
		STZ !P2Punch1			;\ Clear punch
		STZ !P2Punch2			;/
		STZ !P2BackDash			; > Clear back dash
		STZ !P2Senku			; > Clear senku
		LDA !P2XSpeed			;\
		BPL $03 : EOR #$FF : INC A	; |
		LDX !P2Dashing			; |
		BEQ $02 : LDA #$30		; |
		STA $00				; | Calculate max jump speed based on X speed
		ASL A				; |
		CLC : ADC $00			; |
		LSR #3				; |
		SEC : SBC #$58			; |
		STA !P2YSpeed			;/

	LDA #$04 : TRB !P2Blocked		; Instantly leave ground

		LDA #$2B : STA !SPC1		; > jump SFX
		LDA #!Kad_Squat : STA !P2Anim	; > Start next animation right away for clipping purposes
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
		INC A				; > 2 = right, 1 = left
		AND $6DA3
		BEQ .NoDashCancel
		BRA ++

	+	LDA $6DA3
		AND #$03
		BNE .NoDashCancel
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


		LDA !P2XSpeed : BEQ +
		BMI .StopLeft

		.StopRight
		DEC A
		BEQ $01 : DEC A
		JSR CORE_SET_XSPEED
		RTS

		.StopLeft
		INC A
		BEQ $01 : INC A
		JSR CORE_SET_XSPEED
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
	++	JSR CORE_SET_XSPEED
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
		BCS +				;/
	+++	LDA .XSpeedLeft,x
		BRA ++
	+	DEC #3
	++	JSR CORE_SET_XSPEED
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
		db $00,$01,$00,$01

		.BubbleX
		db $00,$08

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


		JSR HITBOX


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
		JSR CORE_SPRITE_INTERACTION


	EXSPRITE_INTERACTION:
		JSR CORE_EXSPRITE_INTERACTION


	UPDATE_SPEED:
		LDA #$03				; gravity when holding B is 3
		BIT $6DA3				;\ gravity without holding B is 6
		BMI $02 : LDA #$06			;/
		BIT !P2Water				;\ gravity in water is 0
		BVC $02 : LDA #$00			;/
		STA !P2Gravity				; store gravity
		LDA #$46 : STA !P2FallSpeed		; fall speed is 0x46


		LDA !P2Platform
		BEQ .Main
		AND #$0F
		TAX
		LDA $9E,x : STA !P2YSpeed
		LDA $3260,x : STA !P2YFraction
		LDA !P2Blocked : PHA
		LDA !P2XSpeed : PHA
		LDA !P2XFraction : PHA
		BIT !P2Platform
		BVC .Horizontal

		.Vertical
		STZ !P2XSpeed
		BRA .Platform

		.Horizontal
		LDA $AE,x : STA !P2XSpeed
		LDA $3270,x : STA !P2XFraction

		.Platform
		JSR CORE_UPDATE_SPEED
		PLA : STA !P2XFraction
		PLA : STA !P2XSpeed
		PLA : TSB !P2Blocked
		STZ !P2YSpeed

		.Main
		JSR CORE_UPDATE_SPEED
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
		LDA ANIM+$06,y				;\
		STA $F0					; |
		CLC : ADC #$0004			; | Pointers to clipping
		STA $F2					; |
		CLC : ADC #$0004			; |
		STA $F4					;/
		SEP #$30
		JSR CORE_LAYER_INTERACTION
		PLA
		EOR !P2Blocked
		AND #$04
		BEQ +
		LDA !P2Blocked
		AND #$04
		BEQ +
		LDA #$07 : STA !P2JumpLag
		STZ !P2Kick

		LDA !KadaalUpgrades			;\
		AND #$08 : BEQ +			; |
		LDA !P2XSpeed				; |
		BPL $03 : EOR #$FF : INC A		; |
		CMP #$20 : BCC +			; |
		LDA $6DA3				; | Allow shell slide with upgrade
		AND #$04 : BEQ +			; |
		JSR StartSlide				; |
		+					;/

		JSR CORE_CLIMB_GROUND


	SCREEN_BORDER:			; This might bug with auto-scrollers
		JSR CORE_SCREEN_BORDER


	ANIMATION:

		LDA !P2ExternalAnimTimer			;\
		BEQ .ClearExternal				; |
		DEC !P2ExternalAnimTimer			; | Enforce external animations
		LDA !P2ExternalAnim : STA !P2Anim		; |
		DEC !P2AnimTimer				; |
		JMP .HandleUpdate				;/

		.ClearExternal
		STZ !P2ExternalAnim


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
		STZ !P2Kick
	+	LDA !P2Kick
		BEQ $03 : JMP .HandleUpdate

	; slide check
		LDA !P2ShellSlide
		BEQ .NoSlide
		LDA !P2Anim
		CMP #!Kad_Shell : BCC +
		CMP #!Kad_Shell+4 : BCC ++
	+	LDA #!Kad_Shell : STA !P2Anim
		STZ !P2AnimTimer
	++	JMP .HandleUpdate
		.NoSlide


		LDA !P2Water
		LSR A : BCC .NoClimb
		LDA !P2Anim
		CMP #!Kad_Climb : BEQ +
		CMP #!Kad_Climb+1 : BEQ +
		LDA #!Kad_Climb : STA !P2Anim
		STZ !P2AnimTimer
	+	LDA $6DA3
		AND #$0F
		BNE +
		STZ !P2AnimTimer
	+	JMP .HandleUpdate
		.NoClimb

	; duck check
		BIT !P2Water : BPL .NoDuck
		LDA !P2Anim
		CMP #!Kad_Duck : BEQ +
		CMP #!Kad_Duck+1 : BEQ +
		LDA #!Kad_Duck : STA !P2Anim
		STZ !P2AnimTimer
	+	JMP .HandleUpdate
		.NoDuck

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

		LDA !P2Senku : BEQ +
		CMP #$20 : BCC .Senku
		LDA #!Kad_Walk+1
		STZ !P2AnimTimer
		BRA .SenkuEnd

		.Senku
		LDA #!Kad_Senku

		.SenkuEnd
		STA !P2Anim
		JMP .HandleUpdate

	+	LDA !P2Anim
		CMP #!Kad_SenkuSmash : BCC $03 : JMP .HandleUpdate

		LDA !P2JumpLag : BEQ +
	-	LDA #!Kad_Squat : STA !P2Anim
		STZ !P2AnimTimer
		JMP .HandleUpdate
	+	LDA !P2Blocked
		AND #$04
		ORA !P2Platform
		ORA !P2SpritePlatform
		BNE .OnGround
		BIT !P2Water : BVS +
		LDA !P2YSpeed : BMI +
		CMP #$08 : BCC -		; > Half-shell frame at 0x00 < speed < 0x08
		LDA !P2Anim
		CMP #!Kad_Squat : BNE $03 : JMP .HandleUpdate
		CMP #!Kad_Shell : BCC .Fall
		CMP #!Kad_Shell+4 : BCC -

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
		CMP #!Kad_Idle+4 : BCC .HandleUpdate
		STZ !P2Anim
		STZ !P2AnimTimer
		BRA .HandleUpdate

		.Move
		LDX !P2BackDash : BNE .Turn		; back dash frame
		LDX !P2Dashing
		BEQ .Walk
		BIT !P2Water
		BVS .Walk
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
		BRA .HandleUpdate
		.NoTurn

		.Dash
		LDA !P2Anim
		CMP #!Kad_Dash-1 : BCC +
		CMP #!Kad_Dash+6 : BCC .HandleUpdate
	+	LDA #!Kad_Dash : STA !P2Anim
		STZ !P2AnimTimer
		BRA .HandleUpdate

		.Walk
		LDA !P2Anim
		CMP #!Kad_Walk-1 : BCC +
		CMP #!Kad_Walk+4 : BCC .HandleUpdate
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
		LDA !CurrentPlayer
		BEQ +
		LDA $14
		LSR A
		BCS .ThisOne
		BRA .OtherOne
	+	LDA $14
		LSR A
		BCC .ThisOne

		.OtherOne
		REP #$30
		LDA !P2Anim2
		AND #$00FF
		ASL #3
		TAY
		LDA ANIM+$00,y
		STA $0E
		SEP #$30
		BRA GRAPHICS

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

		LDA.w #!BigRAM : JSR CORE_GENERATE_RAMCODE
		SEP #$30
		LDA !P2Anim : STA !P2Anim2


	GRAPHICS:
		LDA !P2HurtTimer : BNE .DrawTiles

		LDA !P2Anim
		CMP #!Kad_SenkuSmash : BCS .DrawTiles
		CMP #!Kad_Spin : BCC +
		CMP #!Kad_Spin+4 : BCC .DrawTiles
		+


		LDA !P2Invinc : BEQ .DrawTiles
		AND #$06 : BNE .DrawTiles
		PLB
		RTS


		.DrawTiles
		LDA $0E : STA $04
		LDA $0F : STA $05
		JSR CORE_LOAD_TILEMAP
		PLB
		RTS



	StartSlide:
		LDA #$01 : STA !P2ShellSlide		;\
		LDA !P2XSpeed				; |
		ROL #2					; |
		AND #$01				; | Set slide
		EOR #$01				; |
		STA !P2Direction			; |
		RTS					;/



;==============;
;HITBOX HANDLER;
;==============;

	HITBOX:

		LDA !P2Kick : BEQ .CheckPunch

		.Spin
		REP #$20
		LDY #$00
		LDA !P2XPosLo
		CLC : ADC SPIN+0,y
		STA $00
		STA $07
		STA !P2Hitbox+0
		LDA !P2YPosLo
		CLC : ADC SPIN+2,y
		STA !P2Hitbox+2
		SEP #$20
		STA $01
		XBA
		STA $09
		LDA SPIN+4,y
		STA $02
		STA !P2Hitbox+4
		LDA SPIN+5,y
		STA $03
		STA !P2Hitbox+5
		BRA .GetClipping

		.CheckPunch
		LDA !P2Punch1
		ORA !P2Punch2
		CMP #$05 : BCS .DoPunch
		STZ !P2IndexMem1
		STZ !P2IndexMem2
		RTS

		.DoPunch
		CMP #$0E
		BCS .Punch0
		LDY #$0C
		LDA !P2Direction
		BEQ .PunchShared
		LDY #$12
		BRA .PunchShared

		.Punch0
		LDY !P2Direction			;\ Direction
		BEQ $02 : LDY #$06			;/

		.PunchShared
		REP #$20				; > A 16 bit
		LDA !P2XPosLo				;\ Get Xpos
		CLC : ADC PUNCH+0,y			;/
		STA $00					; > Lo byte in $00
		STA $07					; > Hi byte in $08
		STA !P2Hitbox+0				; Store hitbox X
		LDA !P2YPosLo				;\ Get Ypos
		CLC : ADC PUNCH+2,y			;/
		STA !P2Hitbox+2				; Store hitbox Y
		SEP #$20				; > A 8 bit
		STA $01					; > Lo byte in $01
		XBA					;\ Hi byte in $09
		STA $09					;/
		LDA PUNCH+4,y : STA $02			; > Width
		STA !P2Hitbox+4				; Store hitbox W
		LDA PUNCH+5,y : STA $03			; > Height
		STA !P2Hitbox+5				; Store hitbox H

		.GetClipping
		LDX #$0F

		.Loop
		CPX #$08 : BCS +			;\
		LDA !P2IndexMem1 : BRA ++		; | check index memory
	+	LDA !P2IndexMem2			; |
	++	AND CORE_BITS,x : BNE .LoopEnd		;/



		LDA !AnimToggle				;\ If animation is off, there's an advanced enemy nearby
		BEQ .Normal				;/

		.Advanced
		LDA $3230,x
		CMP #$02 : BEQ .Valid
		CMP #$08 : BCC .LoopEnd
	.Valid	LDA !ExtraBits,x
		AND #$08
		BEQ +
		LDA !NewSpriteNum,x
		CMP #$08
		BNE +
		JSR CaptainWarrior
		BRA ++

		.Normal
		LDA $3230,x
		CMP #$02 : BEQ +
		CMP #$08 : BCC .LoopEnd
	+	JSL $03B69F
	++	JSL $03B72B
		BCC .LoopEnd

		JSR CORE_ATTACK_Setup

		LDA !ExtraBits,x
		AND #$08
		BEQ .LoBlock

		.HiBlock
		LDY !NewSpriteNum,x
		LDA HIT_TABLE+$100,y
		BRA .AnyBlock

		.LoBlock
		LDY $3200,x
		LDA HIT_TABLE,y

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

		LDX #!Ex_Amount-1

		.HammerLoop
		LDA !Ex_Num,x
		AND #$7F
		CMP #$04+!ExtendedOffset : BNE .HammerEnd
		LDA !Ex_Data3,x
		LSR A : BCS .HammerEnd
		LDA !Ex_XLo,x : STA $04		;\ Xpos
		LDA !Ex_XHi,x : STA $0A		;/
		LDA !Ex_YLo,x : STA $05		;\ Ypos
		LDA !Ex_YHi,x : STA $0B		;/
		LDA #$10 : STA $06		; > Width
		STA $07				; > Height
		JSL $03B72B			;\ Check for contact
		BCC .HammerEnd			;/
		JSR CORE_DISPLAYCONTACT		; contact gfx
		LDA #$02 : STA !SPC1
		STZ !Ex_YSpeed,x		; > Yspeed = 0
		LDY !P2Direction		;\
		LDA KNOCKOUT_XSpeed,y		; | XSpeed depends on p2 direction
		STA !Ex_XSpeed,x		;/
		LDA !Ex_Data3,x
		ORA #$01
		STA !Ex_Data3,x			; > Hammer belongs to players

		.HammerEnd
		DEX
		BPL .HammerLoop

		.Return
		RTS

	.Smash
		LDY #$06
		JMP .Spin


	; Hitbox format is Xdisp (lo+hi), Ydisp (lo+hi), width, height.

	PUNCH:
	.0
	dw $FFF8,$FFFA : db $08,$0C		; Left
	dw $0010,$FFFA : db $08,$0C		; Right
	.1
	dw $FFF4,$FFFA : db $0C,$0C		; Left
	dw $0010,$FFFA : db $0C,$0C		; Right


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
		JSR CORE_ATTACK_Main
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
		TSB !P2IndexMem1 : BRA ++
	+	TSB !P2IndexMem2
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
		JSR CORE_ATTACK_Main
		JMP KNOCKBACK

	HIT_04:
		; Knock back and stun
		LDA $3230,x
		CMP #$08
		BEQ .Main
		CMP #$09
		BNE HIT_07

		.Main
		JSR CORE_ATTACK_Main
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
		JSR CORE_ATTACK_Main
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
		JMP CORE_INT_0B+3		; skip LDX $7695 to avoid index confusion

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
		JSR CORE_ATTACK_Main
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
		JSR CORE_ATTACK_Main
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
		JMP CORE_INT_1A+$03
	+	LDA $35F0,x : BNE HIT_19
		JMP CORE_INT_1A+$03

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
		JMP CORE_ATTACK_Main

	HIT_1D:
		LDA #$3F : STA $3360,x		; > Set hurt timer
		LDA #$28 : STA !SPC4		; > OW! sound
		STZ $32D0,x			; > Reset main timer
		DEC $3280,x			; > Deal damage
		LDA CORE_BITS,x
		CPX #$08
		BCS +
		TSB !P2IndexMem1
		RTS
		+
		TSB !P2IndexMem2

		.Return
		RTS


	KNOCKOUT:
		LDA #$02 : STA $3230,x
		LDA #$D8 : STA $9E,x
		LDA #$02 : STA !SPC1
		LDY !P2Direction
		LDA !P2Character			;\
		CMP #$01				; | luigi borrows this routine
		BNE $02 : INY #2			;/
		LDA .XSpeed,y
		STA $AE,x

		TXY
		LDA CORE_BITS,y
		CPY #$08 : BCS +
		TSB !P2IndexMem1 : BRA ++
	+	TSB !P2IndexMem2
		++

		JSR CORE_DISPLAYCONTACT
		RTS

	.XSpeed
	db $F0,$10
	db $E0,$20


	KNOCKBACK:
		LDA #$E8 : STA $9E,x
		LDY !P2Direction
		LDA !P2Character			;\
		CMP #$01				; | luigi borrows this routine
		BNE $02 : INY #2			;/
		LDA KNOCKOUT_XSpeed,y
		STA $AE,x
		LDA !P2Kick : BEQ .GFX			;\
		TXY					; | spin has increased i-frames
		LDA #$20 : STA ($0E),y			;/
		LDA CORE_BITS,y
		CPY #$08 : BCS +
		TSB !P2IndexMem1 : BRA ++
	+	TSB !P2IndexMem2
		++

		.GFX
		LDA #$02 : STA !SPC1
		JSR CORE_DISPLAYCONTACT
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
	dw .DashTM0 : db $FF,!Kad_Turn
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
	dw .ClippingStandard
	.Dash1				; 1F
	dw .DashTM1 : db $06,!Kad_Dash+2
	dw .DashDynamo1
	dw .ClippingStandard
	.Dash2				; 20
	dw .DashTM1 : db $06,!Kad_Dash+3
	dw .DashDynamo2
	dw .ClippingStandard
	.Dash3				; 21
	dw .DashTM0 : db $06,!Kad_Dash+4
	dw .DashDynamo0
	dw .ClippingStandard
	.Dash4				; 22
	dw .DashTM1 : db $06,!Kad_Dash+5
	dw .DashDynamo3
	dw .ClippingStandard
	.Dash5				; 23
	dw .DashTM1 : db $06,!Kad_Dash
	dw .DashDynamo4
	dw .ClippingStandard

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

	.SenkuSmash0			; 28
	dw .SmashTM0 : db $04,!Kad_SenkuSmash+1
	dw .SenkuSmashDynamo0
	dw .ClippingStandard
	.SenkuSmash1			; 29
	dw .SmashTM0 : db $04,!Kad_SenkuSmash+2
	dw .SenkuSmashDynamo1
	dw .ClippingStandard
	.SenkuSmash2			; 2A
	dw .SmashTM0 : db $04,!Kad_SenkuSmash+3
	dw .SenkuSmashDynamo2
	dw .ClippingStandard
	.SenkuSmash3			; 2B
	dw .SmashTM0 : db $08,!Kad_SenkuSmash+4
	dw .SenkuSmashDynamo3
	dw .ClippingStandard
	.SenkuSmash4			; 2C
	dw .SmashTM1 : db $08,!Kad_Fall
	dw .SenkuSmashDynamo4
	dw .ClippingStandard

	.ShellDrill0			; 2D
	dw .SmashTM0 : db $04,!Kad_ShellDrill+1
	dw .ShellDrillDynamoInit
	dw .ClippingStandard
	.ShellDrill1			; 2E
	dw .ShellDrillTM00 : db $02,!Kad_ShellDrill+2
	dw .ShellDynamo0
	dw .ClippingShell
	.ShellDrill2			; 2F
	dw .ShellDrillTM01 : db $02,!Kad_ShellDrill+3
	dw .ShellDynamo1
	dw .ClippingShell
	.ShellDrill3			; 30
	dw .ShellDrillTM02 : db $02,!Kad_ShellDrill+4
	dw .ShellDynamo2
	dw .ClippingShell
	.ShellDrill4			; 31
	dw .ShellDrillTMX : db $02,!Kad_ShellDrill+1
	dw .ShellDynamo1
	dw .ClippingShell

	.DrillLand0			; 32
	dw .FlipSpinTM0 : db $02,!Kad_DrillLand+1
	dw .SpinDynamo0
	dw .ClippingShell
	.DrillLand1			; 33
	dw .FlipSpinTM1 : db $02,!Kad_DrillLand+2
	dw .SpinDynamo1
	dw .ClippingShell
	.DrillLand2			; 34
	dw .FlipSpinTM2 : db $02,!Kad_DrillLand+3
	dw .SpinDynamo0
	dw .ClippingShell
	.DrillLand3			; 35
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
	db $2E,$F8,$F8,!P2Tile1
	db $2E,$08,$F8,!P2Tile2
	db $2E,$F8,$00,!P2Tile3
	db $2E,$08,$00,!P2Tile4
	.DashTM1
	dw $0010
	db $2E,$FC,$F8,!P2Tile1
	db $2E,$04,$F8,!P2Tile1+1
	db $2E,$FC,$00,!P2Tile3
	db $2E,$04,$00,!P2Tile3+1

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


	.ClippingStandard
	db $0D,$02,$05,$05		; < X offset
	db $FF,$FF,$10,$F4		; < Y offset
	db $10,$10,$05,$05		; < Size

	.ClippingShell
	db $0D,$02,$05,$05		; < X offset
	db $05,$05,$10,$00		; < Y offset
	db $0A,$0A,$05,$05		; < Size



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
			db $06,$02,$00,$07,$07,$08,$08,$00,$08,$00,$00,$07,$09,$07,$0A,$0A	;| 01X
			db $07,$0B,$0C,$0C,$0C,$0C,$07,$07,$07,$00,$07,$07,$00,$00,$07,$0D	;| 02X
			db $0E,$0E,$0E,$07,$07,$00,$00,$07,$07,$07,$07,$07,$07,$07,$0D,$06	;| 03X
			db $04,$0F,$0F,$0F,$07,$00,$10,$00,$07,$0F,$11,$0A,$00,$12,$12,$01	;| 04X
			db $01,$0A,$00,$00,$00,$0F,$0F,$0F,$0F,$00,$00,$0F,$0F,$0F,$0F,$00	;| 05X
			db $00,$0F,$0F,$0F,$00,$07,$07,$07,$07,$00,$00,$00,$00,$00,$13,$13	;| 06X
			db $00,$01,$01,$01,$1A,$1A,$1A,$1A,$1A,$00,$00,$11,$00,$00,$00,$00	;| 07X
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 08X
			db $00,$10,$10,$10,$10,$10,$00,$10,$10,$07,$07,$0A,$0F,$00,$07,$14	;| 09X
			db $00,$07,$02,$00,$07,$07,$07,$00,$07,$07,$07,$15,$00,$00,$07,$16	;| 0AX
			db $07,$00,$07,$07,$07,$00,$07,$17,$17,$00,$0F,$0F,$00,$01,$0A,$18	;| 0BX
			db $0F,$00,$07,$07,$0F,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 0CX
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$07,$02	;| 0DX
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 0EX
			db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;| 0FX

			db $00,$01,$15,$15,$15,$15,$1C,$07,$1B,$00,$00,$1D,$00,$00,$00,$00	;| 10X
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















