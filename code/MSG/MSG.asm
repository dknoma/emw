header
sa1rom

;==============;
;MESSAGE ENGINE;
;==============;
; - Info:
; This routine should be called at $00A1DF with a JSL, to hijack SMW's routine at the very start.
; It will not conflict with Lunar Magic, since it hijacks the routine much later.
; I made this primarily because I'm too stubborn to use RPG Hacker's VWF Dialogues patch in one of my own projects.
; The patch does rely on SP_Patch.asm to clear !MsgRAM at game save load.
;
; this patch uses the CCDMA work area and cache as follows:
; - work area -
; $000-$1FF:	copy of second column of text box (px 8-15), used for  dialogue arrow
; $200-$27F:	work space for constructing the tilemap for the two lines currently being worked on
; $280-$29F:	cached 8x16 linear arrow GFX (used for dialogue arrow)
; $2A0-$2BF:	rendering buffer for dialogue arrow (superimposes arrow on text column), 8x16 linear
; $2C0-$2FD:	----
; $2FC-$2FD:	word to fill layer 3 GFX with when clearing box (0x0000, empty tile)
; $2FE-$2FF:	word to fill layer 3 tilemap with within text box (0x32FC, empty tile)
; $300-$3FF:	backup of GFX overwritten by border
; $400-$7FF:	backup of GFX overwritten by portrait
; $C00-$FFF:	work space for rendering the two lines currently being worked on
; - cache -
; $000-$FFF:	cached font image, width encoding 128px, cached with SA-1 DMA
; - extended cache -
; $000-$3FF:	backup of layer 3 tilemap
;

; layer 3 GFX are backed up to SNES WRAM $001000 / $7E1000
; this takes up $900 bytes for normal mode (144 x 64 px) and $D90 bytes for cinematic mode (248 x 56 px)
; max size is $E00

; - Hijacks:


	org $00A1DF
	print "-- MSG --"
	print "Inserted hijack at $", pc, "."

		autoclean JML MESSAGE_ENGINE		; Hijack message box routine


; - Defines:

	incsrc "../Defines.asm"



; - Code:

	freecode
	print "Lunar Magic's message data is located at $", hex(read3($03BC0B)), "."
	print "Custom code inserted at $", pc, "."


	; this code is only run if MSG was called with a normal JSL
	; if it was called with the %CallMSG() macro, this part is skipped
	TrueReturn:
		%TrackCPU(!TrackMSG)

		LDA $400000+!MsgImportant : BNE .NoSkip	;\
		LDA #$10				; |
		TRB $6DA6				; | if skip is enabled, clear start input to prevent accidental pausing
		TRB $6DA7				; |
		.NoSkip					;/

		LDA.l !MsgMode : BEQ .Mode0
		CMP #$01 : BEQ .Mode1
		CMP #$02 : BEQ .Mode2

		.Mode0					; full pause mode
		JML !BuildOAM

		.Mode1					; run animations but don't let players move
		LDA #$02
		STA !P2Stasis-$80
		STA !P2Stasis

		.Mode2					; everything moves during message
		LDX #$25				;\
		LDA #$02				; |
	-	STA !OAMhi,x				; | Set proper OAM size
		DEX					; |
		CPX #$03 : BNE -			;/
		LDA #$98 : STA !OAMindex		; > Set OAM index to after message tiles
		REP #$20
		LDA $01,s
		INC #2
		STA $01,s
		SEP #$20
		RTL


	MESSAGE_ENGINE:
		PHK : PEA.w TrueReturn-1		; Set proper return address

		%TrackSetup(!TrackMSG)

		LDA $400000+!MsgInit
		CMP #$80 : BEQ .NoInit
		LDA #$80 : STA $400000+!MsgInit
		PHP
		REP #$10
		LDX #$01BE
		LDA #$FF
	-	STA $0200,x
		STZ $0201,x
		DEX #2 : BPL -
		PLP
		JSR MAKE_BACKUP				; will also call CLEAR_BOX at the end
		JSR ApplyHeader
		REP #$20				;\
		STZ $6DA2				; |
		STZ $6DA4				; |
		STZ $6DA6				; | don't buffer inputs on frame 1
		STZ $6DA8				; |
		SEP #$20				; |
		BRA .NoBuffer				;/
		.NoInit

		LDX #$07				;\
	-	LDA $6DA2,x				; |
		ORA $400000+!MsgInputBuffer,x		; | buffer input every frame
		STA $400000+!MsgInputBuffer,x		; |
		DEX : BPL -				; |
		.NoBuffer				;/

		PHB : LDA #$40
		PHA : PLB


		LDA !MsgImportant : BNE .NoSkip
		JSR CHECK_INPUT_Start
		BEQ .NoSkip
		LDA #$FF : STA !MsgImportant		; buffer message skip
		BRA .NoDelay				; no delay when skipping message
		.NoSkip
		LDA !MsgWaitFlag : BEQ .NoWait
		.SearchInput
		JSR CHECK_INPUT_Press
		AND #$C0 : BEQ .Return
		.InputFound
		STZ !MsgWaitFlag
	.Return	PLB
		RTL
		.NoWait
		LDA !MsgDelay : BEQ .NoDelay		; do nothing during delay (might wanna change this to at least read inputs)
		DEC !MsgDelay
		PLB
		RTL

		.NoDelay
		PHK : PLB				; Change bank

		LDX !WindowDir				; X = Window growing/shrinking flag
		LDA $400000+!MsgCinematic : BEQ +
		LDA !WindowSize
		CMP.w WindowSize+2,x
		BRA ++

	+	LDA !WindowSize				; A = Window size
		CMP.w WindowSize,x
	++	BEQ .WindowOpen				; check window size
		LDA #$04 : STA $400000+!MsgStartupTimer	; timer = 4
		REP #$20				;\
		LDA #$0000				; |
		STA $400000+!MsgInputBuffer+0		; | clear hold buffer
		STA $400000+!MsgInputBuffer+2		; |
		SEP #$20				;/
		JMP HANDLE_WINDOWING			; handle windowing

		.WindowOpen
		TXA : BNE .LastFrame			; if dir = 0, start loading message data
		LDA $400000+!MsgImportant
		CMP #$FF : BNE .NoSkipBuffer
		LDA.l !MsgMode : BNE +
		JSL !KillOAM
	+	JMP LOAD_MESSAGE_Close
		.NoSkipBuffer
		JMP LOAD_MESSAGE


		.LastFrame
		; this code runs on the last frame of the window being open
		LDA #$04 : TRB !HDMA
		STZ !MsgTrigger				; otherwise close the message and restore a bunch of regs from backups
		STZ !WindowDir				;
		LDA $400000+!MsgBackup41 : STA $41
		LDA $400000+!MsgBackup42 : STA $42
		LDA $400000+!MsgBackup43 : STA $43
		LDA $400000+!MsgBackup44 : STA $44
		LDA $400000+!MsgBackupMainScreen : STA !MainScreen
		LDA $400000+!MsgBackupSubScreen : STA !SubScreen
		LDA $400000+!MsgBackup22 : STA $22
		LDA $400000+!MsgBackup23 : STA $23
		LDA $400000+!MsgBackup24 : STA $24
		LDA $400000+!MsgBackup25 : STA $25
		LDA $400000+!MsgBackup13D5 : STA $73D5
		LDA $400000+!MsgBackup3E : STA $3E

		LDA #$40
		PHA : PLB
		LDA #$00 : STA.l !MsgMode		; this one is not stored with the rest of MsgRAM
		STZ !MsgInit				; clear init flag
		STZ !MsgIndex
		STZ !MsgIndexHi
		STZ !MsgX
		STZ !MsgRow
		STZ !MsgOptions
		STZ !MsgArrow
		STZ !MsgOptionRow
		STZ !MsgDestination
		STZ !MsgScroll
		STZ !MsgTargScroll
		STZ !MsgVertOffset
		PLB
		RTL


	LOAD_MESSAGE:
		LDA #$1F						;\
		STA !MainScreen						; | everything on main screen, nothing on subscreen
		STZ !SubScreen						;/
		LDA #$09 : STA !2105					; > mode 1 with absolute priority for layer 3
		LDA.l !MsgMode : BEQ .NoClear				;\
		JSL !KillOAM						; | manually clear OAM during message modes 1 and 2
		.NoClear						;/


		LDA.l $400000+!MsgVertOffset				;\
		AND #$40 : BNE .BorderDone				; | draw border
		JSR DRAW_BORDER						; | (unless it's disabled by the 0x40 bit in !MsgVertOffset)
		.BorderDone						;/
		LDA #$40						;\ Switch to bank 40
		PHA : PLB						;/
		LDA !MsgPortrait : BEQ .PortraitDone			;\
		JSR DRAW_PORTRAIT					; | draw portrait
		.PortraitDone						;/
		LDA !MsgStartupTimer : BEQ .TimerDone			;\
		DEC !MsgStartupTimer					; | decrement startup timer
		.TimerDone						;/

		LDA !MsgEnd : BEQ .Text					;\
		LDX !MsgCounter : BEQ .SkipText				; |
		DEX							; | if message is over, see if another one should be loaded
		STX !MsgCounter						; |
		LDA !MsgSequence,x					; |
		STA.l !MsgTrigger					;/
		JSR CLEAR_BOX						; clear previous text
		STZ !MsgEnd						; reset message
		JSR ApplyHeader						;\
		PLB							; | load header of next message and return
		RTL							;/


		.Text
		LDA !MsgScroll						;\ don't upload text during scroll animation
		CMP !MsgTargScroll : BEQ .Upload			;/
		JSR CHECK_INPUT_Press					;\
		AND #$C0 : BEQ .SkipText				; | skip scroll animation on input
		LDA !MsgTargScroll : STA !MsgScroll			;/
		.Upload
		JSR UPLOAD_TEXT						; upload text
		.SkipText
		JSR UPDATE_COORDS					; update coordinates

		JSR CHECK_INPUT_Press
		AND #$F0 : BNE .HandleAction				; if an action button (A/B/X/Y) is pressed, handle that


	; this code handles the dialogue arrow
		LDA !MsgOptions : BEQ .Return				; return if there is no dialogue options
		LDA !MsgEnd : BEQ .Return				; only process arrow at the end of a message
		JSR UPDATE_ARROW					; update arrow tile
		LDA $00							;\
		AND #$0C : BEQ .Return					; |
		CMP #$0C : BEQ ..SFX					; |
		CMP #$08 : BEQ ..Up					; |
	..Down	LDA !MsgArrow						; |
		INC A							; |
		CMP !MsgOptions : BCC ..W				; | move dialogue arrow
		LDA #$00 : BRA ..W					; |
	..Up	LDA !MsgArrow						; |
		DEC A							; |
		BPL ..W							; |
		LDA !MsgOptions						; |
		DEC A							; |
	..W	STA !MsgArrow						;/
	..SFX	LDA #$06 : STA.l !SPC4					; cursor SFX
	.Return	PLB
		RTL


		.HandleAction
		LDA !MsgEnd : BNE .Close				; close message on input if it's done
		LDA !MsgOptions : BEQ .Return

	; dialogue feedback code

		STZ !MsgOptions
		LDA !MsgArrow
		INC A
		LDX !MsgDestination : BEQ .Level
		CPX #$01 : BEQ .MSG
		PLB
		RTL

	.MSG	LDX !MsgCounter
		CLC : ADC.l !MsgTrigger
		STA !MsgSequence,x
		DEC !MsgCounter

		PLB
		RTL

	.Level	STA.l !Level+4


		.Close
		PLB							; > restore bank
		LDA #$01 : STA !WindowDir				; > close window
		LDA #$04						;\
		TRB !MainScreen						; | hide layer 3 while window is closing
		TRB !SubScreen						;/
		LDA.b #.SA1 : STA $3180					;\
		LDA.b #.SA1>>8 : STA $3181				; | have SA-1 clear/restore stuff
		LDA.b #.SA1>>16 : STA $3182				; |
		JSR $1E80						;/
		RTL							; > Return


		.SA1
		PHP
		PHB
		LDA #$40 : PHA : PLB					;\
		LDA !MsgInit : PHA					; > preserve
		LDA !MsgVertOffset : PHA				; > preserve
		LDA !MsgCinematic : PHA					; > preserve
		LDX #$7F						; |
	-	STZ !MsgRAM,x						; |
		CPX.b #!MsgTalk-!MsgRAM : BNE +				; | clear !MsgRAM, skipping the backup block and preserving the init flag
		LDX.b #!MsgFont-!MsgRAM					; |
		BRA -							; |
	+	DEX : BPL -						;/
		PLA : STA !MsgCinematic					; > don't mess up the window close animation
		PLA : STA !MsgVertOffset				; > we need to keep this flag for the window closing
		PLA : STA !MsgInit					; > don't reset init until the last frame

		JSL !GetVRAM
		LDA.b #!GFX_buffer>>16					;\
		STA !VRAMtable+$04,x					; |
		STA !VRAMtable+$0B,x					; |
		STA !VRAMtable+$12,x					; |
		STA !VRAMtable+$19,x					; |
		STA !VRAMtable+$20,x					; |
		STA !VRAMtable+$27,x					; |
		STZ !VRAMtable+$2E,x					; > SNES WRAM
		REP #$20						; |
		LDA.w #!GFX_buffer+$300 : STA !VRAMtable+$02,x		; |
		LDA.w #!GFX_buffer+$380 : STA !VRAMtable+$09,x		; |
		LDA.w #!GFX_buffer+$400 : STA !VRAMtable+$10,x		; |
		LDA.w #!GFX_buffer+$500 : STA !VRAMtable+$17,x		; |
		LDA.w #!GFX_buffer+$600 : STA !VRAMtable+$1E,x		; |
		LDA.w #!GFX_buffer+$700 : STA !VRAMtable+$25,x		; |
		LDA #$1000 : STA !VRAMtable+$2C,x			; > SNES WRAM
		LDA !MsgVRAM3 : STA !VRAMtable+$05,x			; |
		CLC : ADC #$0100					; |
		STA !VRAMtable+$0C,x					; | restore GFX overwritten by border and portrait
		LDA !MsgVRAM1 : STA !VRAMtable+$13,x			; |
		CLC : ADC #$0100					; |
		STA !VRAMtable+$1A,x					; |
		LDA !MsgVRAM2 : STA !VRAMtable+$21,x			; |
		CLC : ADC #$0100					; |
		STA !VRAMtable+$28,x					; |
		LDA #$0080						; |
		STA !VRAMtable+$00,x					; |
		STA !VRAMtable+$07,x					; |
		LDA #$0100						; |
		STA !VRAMtable+$0E,x					; |
		STA !VRAMtable+$15,x					; |
		STA !VRAMtable+$1C,x					; |
		STA !VRAMtable+$23,x					;/
		LDA.l !210C						;\
		AND #$000F						; |
		XBA							; | restore layer 3 GFX overwritten by text
		ASL #4							; | (backed up in SNES WRAM
		ORA #$0014*8						; |
		STA !VRAMtable+$2F,x					; |
		LDA #$0E00 : STA !VRAMtable+$2A,x			;/

		LDA.l !2109						;\
		AND #$00FC						; |
		XBA							; |
		STA !VRAMtable+$36,x					; | restore layer 3 tilemap
		LDA.w #!ImageCache+$1000 : STA !VRAMtable+$33,x		; |
		LDA.w #!ImageCache+$1000>>8 : STA !VRAMtable+$34,x	; |
		LDA #$0400 : STA !VRAMtable+$31,x			;/

		PHK : PLB

		SEP #$20
		LDA #$F0
		LDX !OAMindex
		REP #$10						; prevent negative flag fail
	-	STA !OAM+$001,x
		DEX #4 : BPL -
		STZ !OAMindex

		PLB
		PLP
		RTL


CHECK_INPUT:
		.Press
		LDA !MsgStartupTimer : BNE .Buffer			; check for startup timer
		LDA !MultiPlayer : BEQ ..1P				;\
	..2P	LDA !MsgInputBuffer+5					; |
		ORA !MsgInputBuffer+7					; | check press input
	..1P	ORA !MsgInputBuffer+4					; |
		ORA !MsgInputBuffer+6					; |
		AND #$C0						;/
		TRB !MsgInputBuffer+5					;\
		TRB !MsgInputBuffer+7					; | clear all read inputs
		TRB !MsgInputBuffer+4					; |
		TRB !MsgInputBuffer+6					;/
		BRA .Return						; go to shared

		.Hold
		LDA !MsgStartupTimer : BNE .Buffer			; check for startup timer
		LDA !MultiPlayer : BEQ ..1P				;\
	..2P	LDA !MsgInputBuffer+1					; |
		ORA !MsgInputBuffer+3					; | check hold input
	..1P	ORA !MsgInputBuffer+0					; |
		ORA !MsgInputBuffer+2					; |
		AND #$C0						;/
		TRB !MsgInputBuffer+1					;\
		TRB !MsgInputBuffer+3					; | clear all read inputs
		TRB !MsgInputBuffer+0					; |
		TRB !MsgInputBuffer+2					;/
		BRA .Return						; go to shared

		.Start
		LDA !MsgStartupTimer : BNE .Buffer			; check for startup timer
		LDA !MultiPlayer : BEQ ..1P				;\
	..2P	LDA !MsgInputBuffer+5					; | check start press input
	..1P	ORA !MsgInputBuffer+4					; |
		AND #$10						;/
		TRB !MsgInputBuffer+5					;\ clear all read inputs
		TRB !MsgInputBuffer+4					;/

		.Return
		STA $00							; set input
		RTS							; return

		.Buffer							;\
		STZ !MsgInputBuffer+2					; |
		STZ !MsgInputBuffer+3					; | during startup timer: input = 00
		STZ !MsgInputBuffer+4					; | press buffer is not cleared
		STZ !MsgInputBuffer+5					; | hold buffer is cleared
		LDA #$00 : STA $00					; |
		RTS							;/




UPDATE_COORDS:
		PHP
		SEP #$20
		LDA !MsgVertOffset			;\
		AND #$3F				; |
		ASL A					; | get vertical window offset
		STA $00					; |
		STZ $01					;/

		LDA !MsgScroll				;\
		CMP !MsgTargScroll : BEQ .Yes		; | update scrolling
		INC #2					; |
		STA !MsgScroll				; |
		CMP !MsgTargScroll : BCC .Yes		; |
		LDA !MsgTargScroll : STA !MsgScroll	;/ > prevent desync

	.Yes	LDA !MsgCinematic : BEQ .Normal
		CMP #$01 : BEQ .CinematicTop

		.CinematicBottom
		LDA !MsgScroll
		REP #$20				;\
		AND #$00FF				; | Ypos
		SEC : SBC #$009E			; > base Ypos = -0x9E (cinematic bottom)
		STA $24					;/
		BRA .CinematicX

		.CinematicTop
		LDA !MsgScroll
		REP #$20				;\
		AND #$00FF				; | Ypos
		SEC : SBC #$0002			; > base Ypos = -0x02 (cinematic top)
		STA $24					;/

		.CinematicX
		LDA !MsgPortrait
		AND #$00FF : BEQ .CenterX
		AND #$0040 : BEQ +
		LDA #$FFD8 : STA $22			; > Xpos (cinematic mode, cut by left-side portrait)
		PLP
		RTS

	+	LDA #$FFFC : STA $22
		PLP
		RTS

		.CenterX
		LDA #$0020				;\
		SEC : SBC !MsgWidth			; |
		AND #$00FF				; | center text for cinematic mode
		ASL #2					; |
		EOR #$FFFF : INC A			; |
		STA $22					;/
		PLP
		RTS

		.Normal
		LDA !MsgScroll
		REP #$20				;\
		AND #$00FF				; | Ypos
		SEC : SBC #$0040			; > base Ypos = -0x40 (normal mode)
		SEC : SBC $00				; |
		STA $24					;/
		LDA #$FFC8 : STA $22			; > Xpos (normal mode)
		PLP
		RTS



MAKE_BACKUP:
		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JMP $1E80


		.SA1
		PHB : PHK : PLB
		PHP

		SEP #$30
		LDA $41 : STA $400000+!MsgBackup41
		LDA $42 : STA $400000+!MsgBackup42
		LDA $43 : STA $400000+!MsgBackup43
		LDA $44 : STA $400000+!MsgBackup44
		LDA !MainScreen : STA $400000+!MsgBackupMainScreen
		LDA !SubScreen : STA $400000+!MsgBackupSubScreen
		LDA $22 : STA $400000+!MsgBackup22
		LDA $23 : STA $400000+!MsgBackup23
		LDA $24 : STA $400000+!MsgBackup24
		LDA $25 : STA $400000+!MsgBackup25
		LDA $73D5 : STA $400000+!MsgBackup13D5
		LDA $3E : STA $400000+!MsgBackup3E

		LDX #$40						;\ Set bank
		PHX : PLB						;/
		JSL !GetVRAM						; > Get VRAM table index

		LDA.b #!GFX_buffer>>16					;\
		STA !VRAMtable+$04,x					; |
		STA !VRAMtable+$0B,x					; |
		STA !VRAMtable+$12,x					; |
		STA !VRAMtable+$19,x					; |
		STA !VRAMtable+$20,x					; |
		STA !VRAMtable+$27,x					; |
		STZ !VRAMtable+$2E,x					; > buffer in SNES WRAM
		REP #$20						; |
		LDA.w #!GFX_buffer+$300 : STA !VRAMtable+$02,x		; |
		LDA.w #!GFX_buffer+$380 : STA !VRAMtable+$09,x		; |
		LDA.w #!GFX_buffer+$400 : STA !VRAMtable+$10,x		; |
		LDA.w #!GFX_buffer+$500 : STA !VRAMtable+$17,x		; |
		LDA.w #!GFX_buffer+$600 : STA !VRAMtable+$1E,x		; |
		LDA.w #!GFX_buffer+$700 : STA !VRAMtable+$25,x		; |
		LDA.w #$1000 : STA !VRAMtable+$2C,x			; > buffer in SNES WRAM
		LDA !MsgVRAM3						; |
		ORA #$8000						; |
		STA !VRAMtable+$05,x					; |
		CLC : ADC #$0100					; |
		STA !VRAMtable+$0C,x					; | backup GFX that will be overwritten by border and portrait
		LDA !MsgVRAM1						; |
		ORA #$8000						; |
		STA !VRAMtable+$13,x					; |
		CLC : ADC #$0100					; |
		STA !VRAMtable+$1A,x					; |
		LDA !MsgVRAM2						; |
		ORA #$8000						; |
		STA !VRAMtable+$21,x					; |
		CLC : ADC #$0100					; |
		STA !VRAMtable+$28,x					; |
		LDA #$0080						; |
		STA !VRAMtable+$00,x					; |
		STA !VRAMtable+$07,x					; |
		LDA #$0100						; |
		STA !VRAMtable+$0E,x					; |
		STA !VRAMtable+$15,x					; |
		STA !VRAMtable+$1C,x					; |
		STA !VRAMtable+$23,x					;/
		LDA.l !210C						;\
		AND #$000F						; |
		XBA							; |
		ASL #4							; | backup all the layer 3 GFX that the text will use in SNES WRAM
		ORA #$8000+($0014*8)					; |
		STA !VRAMtable+$2F,x					; |
		LDA #$0E00 : STA !VRAMtable+$2A,x			;/

		SEP #$20						; adjust index
		TXA
		CLC : ADC #$31
		TAX

		PHP							;\
		REP #$10						; |
		LDY.w #!File_default_border				; | get address of border file
		JSL !GetFileAddress					; |
		PLP							;/


	;	LDA.b #GFX>>16						;\
	LDA !FileAddress+2
		STA !VRAMtable+$04,x					; | bank
		STA !VRAMtable+$0B,x					;/
		REP #$20						; > A 16 bit
		LDA #$0080						;\
		STA !VRAMtable+$00,x					; | size
		STA !VRAMtable+$07,x					;/
	;	LDA #GFX_Borders					;\
	LDA !FileAddress
		STA !VRAMtable+$02,x					; | source
		CLC : ADC #$00A0					; |
		STA !VRAMtable+$09,x					;/
		LDA !MsgVRAM3						;\
		STA !VRAMtable+$05,x					; | VRAM
		CLC : ADC #$0100					; |
		STA !VRAMtable+$0C,x					;/

		LDA.l !2109						;\
		AND #$00FC						; |
		XBA							; |
		ORA #$8000						; | backup layer 3 tilemap
		STA !VRAMtable+$13,x					; |
		LDA.w #!ImageCache+$1000 : STA !VRAMtable+$10,x		; |
		LDA.w #!ImageCache+$1000>>8 : STA !VRAMtable+$11,x	; |
		LDA #$0400 : STA !VRAMtable+$0E,x			;/

		LDA #$004F
		JSR READ_FONT_CHAR
		LDA $0E
		AND #$000F						; |
		ASL #3							; |
		STA $00							; | $00 = index to character in cached font
		LDA $0E							; |
		AND #$00F0						; |
		XBA							; |
		LSR #2							; |
		TSB $00							;/

	;	AND #$000F
	;	ASL A
	;	STA $00
	;	LDA $0E
	;	AND #$00F0
	;	ASL #4
	;	TSB $00

		REP #$10						; |
		LDX $00							;/
		LDA.w !ImageCache+$000,x : STA.w !GFX_buffer+$280	;\
		LDA.w !ImageCache+$020,x : STA.w !GFX_buffer+$282	; |
		LDA.w !ImageCache+$040,x : STA.w !GFX_buffer+$284	; |
		LDA.w !ImageCache+$060,x : STA.w !GFX_buffer+$286	; |
		LDA.w !ImageCache+$080,x : STA.w !GFX_buffer+$288	; |
		LDA.w !ImageCache+$0A0,x : STA.w !GFX_buffer+$28A	; |
		LDA.w !ImageCache+$0C0,x : STA.w !GFX_buffer+$28C	; |
		LDA.w !ImageCache+$0E0,x : STA.w !GFX_buffer+$28E	; | cache arrow GFX in 8px wide format
		LDA.w !ImageCache+$100,x : STA.w !GFX_buffer+$290	; |
		LDA.w !ImageCache+$120,x : STA.w !GFX_buffer+$292	; |
		LDA.w !ImageCache+$140,x : STA.w !GFX_buffer+$294	; |
		LDA.w !ImageCache+$160,x : STA.w !GFX_buffer+$296	; |
		LDA.w !ImageCache+$180,x : STA.w !GFX_buffer+$298	; |
		LDA.w !ImageCache+$1A0,x : STA.w !GFX_buffer+$29A	; |
		LDA.w !ImageCache+$1C0,x : STA.w !GFX_buffer+$29C	; |
		LDA.w !ImageCache+$1E0,x : STA.w !GFX_buffer+$29E	;/

		REP #$10						;\
		LDX #$01FE						; | clear second half of rendering buffer
	-	STZ.w !GFX_buffer+$000,x				; | (first half will be cleared automatically when the first line starts rendering)
		STZ.w !GFX_buffer+$E00,x				; | (also clear backup buffer)
		DEX #2 : BPL -						;/

		JSR CLEAR_BOX

		PLP
		PLB
		RTL



CLEAR_BOX:
; wipe message box

		PHP
		SEP #$30

		PHB : PHK : PLB						;\
		LDA #$04						; |
		TRB !MainScreen						; | hide BG3 for 1 frame
		TRB !SubScreen						; |
		PLB							;/

		STZ !MsgScroll
		STZ !MsgTargScroll
		STZ !MsgX
		STZ !MsgRow

		JSL !GetVRAM
		REP #$20
		LDA #$38FC : STA.w !GFX_buffer+$2FE
		LDA.w #!GFX_buffer+$2FE : STA !VRAMtable+$02,x
		LDA.w #!GFX_buffer+$2FE>>8 : STA !VRAMtable+$03,x
		LDA.l !2109
		AND #$00FC
		XBA
		STA !VRAMtable+$05,x
		LDA #$4400 : STA !VRAMtable+$00,x

		LDA #$0000 : STA.w !GFX_buffer+$2FC			;\
		LDA.w #!GFX_buffer+$2FC : STA !VRAMtable+$09,x		; |
		LDA.w #!GFX_buffer+$2FC>>8 : STA !VRAMtable+$0A,x	; |
		LDA.l !210C						; |
		AND #$000F						; | queue clear of layer 3 GFX
		XBA							; |
		ASL #4							; |
		ORA.w #$0014*8						; |
		STA !VRAMtable+$0C,x					; |
		LDA #$4E00 : STA !VRAMtable+$07,x			;/

		REP #$30						;\
		LDX #$01FE						; |
	-	STZ.w !GFX_buffer+$000,x				; | clear rendering buffers
		STZ.w !GFX_buffer+$C00,x				; |
		STZ.w !GFX_buffer+$E00,x				; |
		DEX #2 : BPL -						;/


		PLP
		RTS


HANDLE_WINDOWING:
		LDA #$04				;\
		TRB !MainScreen				; | hide layer 3 while window is opening/closing
		TRB !SubScreen				;/
		LDA #$01 : STA $73D5			; disable layer 3 scroll

		PHB : LDA #$40
		PHA : PLB

	; HDMA setting is:
	; mode:		41	(2 regs write once, indirect)
	; reg:		26	(window 1 left edge + window 1 right edge)
	; source:	$00927C	(that table holds the data: $F0,$A0,$04,$F0,$80,$05,$00)
	; bank:		$00	(indirect)
	; The indirect table almost certainly means that:
	; $64A0 is read for 0x70 scanlines
	; $6580 is read for 0x70 scanlines
	; $00 terminates the channel
	; The actual window begins at $650C (scanline 0x36)


	;	STZ !MsgIndex				;\
	;	STZ !MsgIndexHi				; |
	;	STZ !MsgX				; |
	;	STZ !MsgRow				; | make sure the counters don't mess up
	;	STZ !MsgScroll				; |
	;	STZ !MsgTargScroll			; |
	;	STZ !MsgDelay				;/
		LDA !MsgCinematic			; load, baby!
		PLB					; this actually affects z...

		CMP #$00 : BEQ .NormalMode		; ...so we have to CMP #$00 like a fucking peasant
		STA $00
		LDA !WindowSize
		LDY !WindowDir : BNE +
		CMP #$30 : BNE +
		LDX #$22 : STX !SPC4			; message box sfx
	+	CLC : ADC.w WindowSpeed,y
		STA !WindowSize
		REP #$20
		AND #$00FF
		ASL A
		LDX $00
		STA $00
		CPX #$02 : BEQ .CinematicBottom

		.CinematicTop
		LDX #$00
		LDA #$FF00
		CPX $00 : BEQ ..end1			; if size is 0, skip to loop 2 immediately
	..loop1	STA $0200,x
		INX #2
		CPX $00 : BCC ..loop1
		..end1
		LDA #$00FF
	..loop2	STA $0200,x
		INX #2
		CPX #$80 : BCC ..loop2
		BRA .SetHDMA

		.NormalMode
		LDA !WindowSize
		LDY !WindowDir : BNE +
		CMP #$40 : BNE +
		LDX #$22 : STX !SPC4			; message box sfx
	+	CLC : ADC.w WindowSpeed,y
		STA !WindowSize
		CLC : ADC #$80
		XBA
		LDA.l $400000+!MsgVertOffset
		AND #$3F
		ASL #2
		STA $00					; store window offset
		TAX					; X = window offset
		CLC : ADC #$50				;\ Y = window offset + 0x50
		TAY					;/
		SEC : SBC #$50				;\
		CLC : ADC !WindowSize			; | set up mirror of !WindowSize
		STA $01					;/
		LDA #$80
		SEC : SBC !WindowSize
		REP #$20				; > A 16 bit
..loop		CPX $01 : BCC +				;\
		LDA.w #$00FF				; |
	+	STA $026C,y				; |
		STA $02BC,x				; | normal mode window
		INX #2					; |
		DEY #2					; |
		CPY $00 : BNE ..loop			;/
		BRA .SetHDMA

		.CinematicBottom
		LDA #$00A6				;\
		SEC : SBC $00				; | we're writing 0xB0 bytes and we want to swap A when we enter the window zone (0xA6 - size bytes left)
		STA $00					;/
		LDX #$00
		LDA #$00FF
	..loop1	STA $0300,x
		INX #2
		CPX $00 : BCC ..loop1
		CPX #$B0 : BEQ .SetHDMA
		LDA #$FF00
	..loop2	STA $0300,x
		INX #2
		CPX #$B0 : BCC ..loop2

.SetHDMA	SEP #$20				; A 8-bit
		LDA.l $400000+!MsgVertOffset		;\
		AND #$40 : BEQ .ClippingWindow		; |
		STZ $41					; | if window is disabled, only clip layer 3 (outside the text area)
		STZ $43					; |
		BRA +					;/

		.ClippingWindow
		LDA #$22 : STA $41			;\ Enable window 1 for BG1 and BG2
		LDA #$22 : STA $43			;\ Enable window 1 for color and sprite layers
		LDA #$20 : STA $44
	+	LDA #$03 : STA $42			;\ enable inverted layer 3 masking
		LDX #$04				;\
	-	LDA HDMAsettings,x			; | enable HDMA settings
		STA $4320,x				; |
		DEX : BPL -				;/
		STZ $4327				; > indirect HDMA bank
		LDA #$04 : TSB !HDMA			; HDMA on channel 2
.Return		PLB
		RTL

;.NoWindow	;LDA #$04 : TRB !HDMA
		;LDA #$04 : STA !MainScreen
		;LDA #$1B : STA !SubScreen

;		LDA $400000+!MsgBackupMainScreen : STA !MainScreen
;		LDA $400000+!MsgBackupSubScreen : STA !SubScreen

;		PLB
;		RTL

	pushpc
	org $00927C
		db $F0 : dw $64A0			; indirect HDMA pointer table
		db $F0 : dw $6580
		db $00
	warnpc $009283
	pullpc



HDMAsettings:	db $41,$26
		dl HDMAtable

HDMAtable:	db $F0 : dw $0200
		db $F0 : dw $02E0
		db $00


WindowSize:	db $48,$00				; Maximum/minimum values for window size. Minimum should be 00.
		db $38,$00
WindowSpeed:	db $08,$F8				; Message box growing/shrinking speed.


;============;
;APPLY HEADER;
;============;
ApplyHeader:	PHB : PHK : PLB
		PHP
		SEP #$20
		LDA.b #.Main : STA $3180
		LDA.b #.Main>>8 : STA $3181
		LDA.b #.Main>>16 : STA $3182
		JSR $1E80
		PLP
		PLB
		RTS

		.Main
		PHB : PHK : PLB
		PHP
		REP #$30
		LDA !MsgTrigger
		AND #$00FF
		DEC A
		ASL A
		TAY
		LDA !Translevel
		AND #$00FF
		ASL A
		TAX
		LDA Text_MainPtr,x : STA $08
		LDA ($08),y : STA $08
		SEP #$20
		PHK : PLA						;\ bank byte of pointer
		STA $0A							;/
		LDA #$40						;\ swap bank
		PHA : PLB						;/

		; apply default settings here
		LDA #$00 : STA !MsgCinematic				;\
		LDA #$12 : STA !MsgWidth				; |
		LDA #$00 : STA !MsgVertOffset				; |
		LDA #$00 : STA !MsgPortrait				; | default settings for mesage
		LDA #$00 : STA !MsgMode					; |
		LDA #$00 : STA !MsgFont					; |
		LDA #$08 : STA !MsgSpeed				; |
		LDA #$01 : STA !MsgFillerColor				; |
		LDA #$00 : STA !MsgImportant				;/

		; read header
		LDY #$0000 : STY !MsgIndex				; reset index
	.Next	LDA [$08],y : BPL .HeaderDone				;\
		PEA.w .Next-1						; | keep applying commands until first text byte is hit
		JMP HANDLE_COMMANDS					;/ (!MsgIndex is auto-incremented by command handler)

		.HeaderDone
		STY !MsgIndex						; store index to actual text data
		JSR UpdateFont
		PLP
		PLB
		RTL

	UpdateFont:
		PHB : PHK : PLB						;\
		PHP							; |
		REP #$30						; |
		LDA $400000+!MsgFont					; |
		AND #$00FF						; |
		ASL A							; |
		TAX							; |
		LDY.w GFX_FontGFX,x					; |
		CMP #$FFFF						; |
		BNE $03 : LDY.w GFX_FontGFX				; > see which file should be loaded
		JSL !GetFileAddress					; > get address of file
		LDA !FileAddress : STA $2232				; |
		LDA.w #$1000 : STA $2238				; | use SA-1 DMA to cache font
		LDA.w #!ImageCache : STA $2235				; |
		SEP #$20						; |
		LDA #$C4 : STA $2230					; > DMA settings
		LDA !FileAddress+2 : STA $2234				; > bank
		LDA.b #!ImageCache>>16 : STA $2237			; > dest bank (this write starts the DMA)
	-	LDA $318C : BEQ -					; |
		STZ $318C						; |
		STZ $2230						; |
		LDA $400000+!MsgFont : STA $400000+!MsgCachedFont	; > remember which font was just cached
	.Return	PLP							; |
		PLB							; |
		RTS							;/

	; it seems like this is treated as instant on emulator
	; according to the dev manual, it should take 4.58% of a frame, about 12 scanlines, to complete
	; i don't think this is a major problem, but it's worth noting





; this should be run by SA-1
; actually, it HAS to be run by SA-1 since it calls RENDER_TEXT

;======================;
;TEXT UPLOADING ROUTINE;
;======================;
UPLOAD_TEXT:	PHB : PHK : PLB
		PHP
		SEP #$20
		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JSR $1E80
		PLP
		PLB
		RTS


		.SA1
		PHB
		PHP
		SEP #$20
		LDA #$40
		PHA : PLB
		LDA !MsgRow : PHA					; this needs to be pushed here as it could increase during the .Main call
		STZ !MsgTerminateRender					; clear terminate flag at the start of each render
		STZ !MsgWordLength					; treat each render as the start of a new word
		STZ !MsgCharCount					; number of characters rendered on this frame
		LDA !MsgImportant
		CMP #$02 : BEQ +
		JSR CHECK_INPUT_Hold
		AND #$C0 : BEQ +
		LDA #$01 : STA !MsgInstantLine
		+



		JSR .Main


	; NOTE!
	; be careful about stack usage here as LDA dp,s is used as an optimization!
	; make sure they're lined up

		SEP #$20
		LDA #$00 : STA.l $2250					; prepare multiplication
		JSL !GetBigCCDMA					; X = index to CCDMA table
		LDA #$16 : STA !CCDMAtable+$07,x			; > width = 256px, bit depth = 2bpp
		LDA.b #!GFX_buffer>>16 : STA !CCDMAtable+$04,x		;\
		REP #$20						; | source adddress
		LDA.w #!GFX_buffer+$C00 : STA !CCDMAtable+$02,x		;/
		LDA $01,s						;\
		AND #$00FF						; |
		STA.l $2251						; |
		LDA !MsgWidth						; |
		AND #$00FF						; | write upload size while settup up VRAM calculation
		ASL #3							; |
		STA.l $2253						; |
		ASL A							; |
		STA !CCDMAtable+$00,x					;/
		LDA.l !210C						;\
		AND #$000F						; |
		XBA							; |
		ASL #4							; | finish VRAM calculation
		ORA.l $2306						; |
		CLC : ADC.w #$0014*8					; |
		STA !CCDMAtable+$05,x					;/

		SEP #$20
		JSL !GetBigCCDMA					; X = index to CCDMA table
		LDA #$16 : STA !CCDMAtable+$07,x			; > width = 256px, bit depth = 2bpp
		LDA.b #!GFX_buffer>>16 : STA !CCDMAtable+$04,x		;\
		REP #$20						; | source adddress
		LDA.w #!GFX_buffer+$E00 : STA !CCDMAtable+$02,x		;/
		LDA $01,s						;\
		AND #$00FF						; |
		INC A							; > next row
		STA.l $2251						; |
		LDA !MsgWidth						; |
		AND #$00FF						; | write upload size while settup up VRAM calculation
		ASL #3							; |
		STA.l $2253						; |
		ASL A							; |
		STA !CCDMAtable+$00,x					;/
		LDA.l !210C						;\
		AND #$000F						; |
		XBA							; |
		ASL #4							; | finish VRAM calculation
		ORA.l $2306						; |
		CLC : ADC.w #$0014*8					; |
		STA !CCDMAtable+$05,x					;/
		SEP #$20

		LDA !MsgTerminateRender : BEQ .NotTerminated		;\
		PLA							; > pop !MsgRow
		PLP							; | if render was terminated by a commmand, don't update tilemap this frame
		PLB							; |
		RTL							;/

		.NotTerminated
		LDA !MsgImportant					;\
		CMP #$02 : BEQ +					; | holding A/B/X/Y increases text speed unless fast forward is disabled
		JSR CHECK_INPUT_Hold					; |
		AND #$C0 : BNE .NoDelay					;/
	+	LDA !MsgSpeed						;\
		CMP #$08 : BCC .NoDelay					; |
		SBC #$08						; | delay on these speeds
		STA !MsgDelay						; |
		.NoDelay						;/

		LDA #$00 : STA.l $2250
		PLA
		REP #$20
		AND #$00FF
		STA.l $2251
		PHA
		ASL #5							;\ store starting row * 32 in scratch
		STA $00							;/
		LDA !MsgWidth
		AND #$00FF
		STA.l $2253
		PHA
		LDA !TextPal-1
		AND #$FF00
		ORA #$2000
		STA $0C
		LDA #$0014
		CLC : ADC.l $2306
		ORA $0C
		LDX #$0000
	-	STA.w !GFX_buffer+$200,x
		INC A
		INX #2
		CPX #$0040 : BCC -
		PLA : STA.l $2251
		PLA
		INC A
		STA.l $2253
		LDX #$0000
		LDA #$0014
		CLC : ADC.l $2306
		ORA $0C
	-	STA.w !GFX_buffer+$240,x
		INC A
		INX #2
		CPX #$0040 : BCC -
		SEP #$30
		JSL !GetVRAM
		REP #$20
		LDA.w #!GFX_buffer+$200 : STA !VRAMtable+$02,x
		LDA.w #!GFX_buffer+$200>>8 : STA !VRAMtable+$03,x
		LDA.w #!GFX_buffer+$240 : STA !VRAMtable+$09,x
		LDA.w #!GFX_buffer+$240>>8 : STA !VRAMtable+$0A,x
		LDA.l !2109						;\
		AND #$00FC						; |
		XBA							; |
		ORA $00
		STA !VRAMtable+$05,x
		CLC : ADC #$0020
		STA !VRAMtable+$0C,x
		LDA !MsgWidth
		AND #$00FF
		ASL A
		STA !VRAMtable+$00,x
		STA !VRAMtable+$07,x
		PLP
		PLB
		RTL





	; actual text loader here
	; it is responsible for reading the text data, allocating text to rows, and calling the renderer and command handler
		.Main
		PHK : PLA					;\ bank byte of pointer
		STA $0A						;/
		REP #$30					; all regs 16-bit
		LDA.l !MsgTrigger				;\
		AND #$00FF					; |
		DEC A						; | Y = index to main pointer table
		ASL A						; |
		TAY						;/
		LDA.l !Translevel				;\
		AND #$00FF					; |
		ASL A						; | lo/mid bytes of pointer
		TAX						; |
		LDA.l Text_MainPtr,x : STA $08			;/
		LDA [$08],y : STA $08				; get pointer
		SEP #$20					; A 8-bit
	.Process
		LDY !MsgIndex					; Y = index
		LDA !MsgWordLength : BNE .Ok			; if we're already processing a word, keep rendering it

	.WordLength
		XBA						; clear B
		PHY						;\
	-	LDA [$08],y					; |
		INY						; |
		CMP #$FF : BEQ ..end				; |
		CMP #$FE : BEQ ..end				; | calculate length of word (defined as a string ended by 7F, FE, or FF, ignoring values of 80-FD)
		CMP #$7F : BEQ ..end				; | (commands 80-EF all have a length of 1 byte)
		BCC ..char					; |
		CMP #$F0 : BCC -				; |
		BNE ..commandlength				;/
	--	LDA [$08],y : BPL +				;\
		INY : BRA -					; | command F0 has a variable length, ending at any value 80+
	+	INY : BRA --					;/
		..commandlength					;\
		REP #$20					; |
		AND #$000F					; |
		TAX						; |
		STY $0E						; | read length for commands F1-FD
		LDA.l HANDLE_COMMANDS_CommandLength,x		; |
		CLC : ADC $0E					; |
		TAY						; |
		SEP #$20					; |
		BRA -						;/
	..char	JSR READ_FONT_CHAR				;\
		LDA $0F						; |
		CLC : ADC !MsgWordLength			; | read character width
		STA !MsgWordLength				; |
		BRA -						;/
	..end	PLY						;\
		LDA !MsgWordLength				; |
		CLC : ADC !MsgX					; |
		BCS ..wrap					; > detect wrap
		STA $0F						; | see if word will fit on the current line
		LDA !MsgWidth					; |
		ASL #3						; |
		BNE $01 : DEC A					; |
		CMP $0F : BCS .Ok				;/
	..wrap	INC !MsgRow					;\
		STZ !MsgX					; | if it won't fit, start new line
		STZ !MsgInstantLine				; > clear instant line flag
		RTS						;/



	.Ok	REP #$20				;\
		INC !MsgIndex				; | increment index
		SEP #$20				;/
		LDA [$08],y : BPL ..Text		; 00-7F are text, 80-FF are commands

	..Command
		CMP #$FE : BCS +			; FE and FF always terminate the current render
		PEA.w ..CommandReturn-1			; whereas other commands always continue the loop after being processed
	+	JMP HANDLE_COMMANDS
		..CommandReturn
		LDA !MsgTerminateRender : BEQ ..Full	; see if the most recent command requires the render to be terminated
		RTS



	..Text	INC !MsgCharCount			; 1 more character rendered
		REP #$20				;\
		AND #$00FF				; | check for space
		CMP #$007F : BNE ..Char			;/

	; code for rendering a space
		SEP #$20				;\
		STZ !MsgWordLength			; > new word
		LDA !MsgX : BNE ..Space			; |

	; code for starting a new line with a space
		JSR RENDER_TEXT_Clear			; | special case when line starts with a space
		SEP #$20				; |
		LDA #$06 : STA !MsgX			; |
		LDA !MsgInstantLine : BNE ..Full	; > keep going if instant line flag is set
		LDA !MsgSpeed : BEQ ..Full		; > end at new word unless max speed
		RTS					; |
	..Full	JMP .Process				;/

	; code for rendering a space on an existing line
	..Space	CLC : ADC #$06				;\
		BCS +					; > detect wrap
		STA !MsgX				; |
		LDA !MsgWidth				; | add a space on the current line
		ASL #3					; |
		BNE $01 : DEC A				; |
		CMP !MsgX : BCC +			;/
		LDA !MsgInstantLine : BNE ..Full	; > keep going if instant line flag is set
		LDA !MsgSpeed : BNE .Return		; end at new word unless rendering full line
		JMP .Process				; if we didn't hit a new row, just get next character
	+	INC !MsgRow				;\
		STZ !MsgX				; | new row from space
		STZ !MsgInstantLine			; > clear instant line flag
	;	LDA !MsgSpeed : BNE .Return		; > end at new word unless rendering full line
	;	JMP .Process				;/
		RTS


	; code for rendering a character
	..Char	JSR READ_FONT_CHAR			;\
		LDA $0E					; |
		AND #$000F				; |
		ASL #3					; |
		STA $00					; | $00 = index to character in cached font
		LDA $0E					; |
		AND #$00F0				; |
		XBA					; |
		LSR #2					; |
		TSB $00					;/
		LDA $0F					;\
		AND #$00FF				; | $04 = width of character
		STA $04					;/

		LDA !MsgWidth				;\
		AND #$00FF				; |
		ASL #3					; | render width
		CMP #$0100				; | capped at 255px (no, not 256)
		BCC $03 : LDA #$00FF			; |
		STA $0E					;/
		SEP #$20
		STZ $03					; hi byte of X coordinate should always be 0

		LDA !MsgX
		CLC : ADC $04
		CMP $0E
		BEQ .Go
		BCC .Go
		INC !MsgRow				;\ start new row
		STZ !MsgX				;/
		STZ !MsgInstantLine			; clear instant line flag
		STY !MsgIndex				; make sure the character isn't skipped
	.Return	RTS					; starting a new row always ends the transfer

	.Go	LDA !MsgX : STA $02			; lo byte of output index = X coordinate of character
		CLC : ADC $04				;\ increment X by width of the character
		STA !MsgX				;/
		SEP #$20
		LDA !MsgRow : STA $03			; hi byte of output index = row of character
		LDA !MsgFillerColor : STA $06		; set filler color
		JSR RENDER_TEXT				; render character to buffer

; NOTE FOR FUTURE ERIC
; this works out to adding 9px to each row: 8px from moving the buffer up by 8px and 1px from adding the row number (0-7)
; this means that the first row uses rows 0-8 of the buffer, the second row uses rows 1-9 of the buffer, and so on
; also remember that we're using the virtual buffer, so each px is 1 byte despite the 2bpp format
;


		.Continue
		SEP #$20				; A 8-bit

		LDA !MsgInstantLine : BNE .Next
		LDA !MsgSpeed
		CMP #$02 : BCC .Next
		CMP #$08 : BCS .Return

		SEC : SBC #$09
		EOR #$FF : INC A
		CMP !MsgCharCount			; not increased by commands
		BEQ .Return
		BCC .Return


	.Next	JMP .Process


; input:
;	A = character index
; output:
;	$0E = tile number
;	$0F = character width
READ_FONT_CHAR:
		PHP
		REP #$30
		AND #$00FF				;\
		ASL A					; | $0E = 16-bit index to font data table
		STA $0E					;/
		LDA !MsgFont				;\
		AND #$00FF				; |
		ASL A					; |
		TAX					; | get index to table and add index to font data
		LDA.l GFX_FontData,x			; |
		CMP #$FFFF				; |
		BNE $04 : LDA.l GFX_FontData		; |
		CLC : ADC $0E				;/
		TAX					;\ store font data of char to $0E-$0F
		LDA.l GFX_FontData,x : STA $0E		;/
		PLP
		RTS




; speeds:
; 0 - 1 row per frame
; 1 - 1 word per frame
; 2 - 7 characters per frame
; 3 - 6 characters per frame
; 4 - 5 characters per frame
; 5 - 4 characters per frame
; 6 - 3 characters per frame
; 7 - 2 characters per frame
; 8 - 1 character per frame
; 9 - 1 character every 2 frames
; A - 1 character every 3 frames
; B - 1 character every 4 frames
; C - 1 character every 5 frames
; D - 1 character every 6 frames
; E - 1 character every 7 frames
; F - 1 character every 8 frames

; full row:
;	- get full row input, until hitting end or FE or FF
;	- only process GFX update once
;
; full word:
;	- get input until hitting space, end, FE or FF
;	- only process GFX update once
;
; multi-character:
;	- get input until hitting limit, end, FE or FF
;	- only process GFX update once
;
; single-character:
;	- get input for single character
;	- only process GFX update once
;	- set !MsgDelay to !MsgSpeed - 8


; starting tile should be row * width + $14
; that way i don't need different tables for different dimensions
; VRAM offset is always row * $20





macro copypixel(x, y)
	LDA.w !V_cache*2+<x>+(<y>*128),y
	BNE $02 : LDA $06
	STA.w (!V_buffer+($C00*2)*2)+<x>+(<y>*256),x
endmacro

; input:
; $00 - 16-bit image cache index (font is expected to be stored at the start of the image cache)
; $02 - x position to start writing at
; $04 - width of font tile
; $06 - filler value, written to empty pixels
;
; note that the input GFX is assumed to be a 128x64px linear 2bpp file
; output is a 256x8px linear 2bpp image, uploaded using CCDMA
; this routine can only be run by SA-1 CPU
RENDER_TEXT:
		PHB							; push bank
		PHK : PLB
		LDA $02 : BNE .NoClear					;\ check if X position is 0
		JSR .Clear						;/ if it is, clear the buffer
		.NoClear

		REP #$20
		LDA $00							;\
		CLC : ADC $04						; | index to end on
		STA $04							;/
		LDY $00							; Y = input index
		LDX $02							; X = output index
		SEP #$20						; 8-bit A
		LDA #$80 : STA $223F					; 2bpp
		LDA #$60 : PHA : PLB					; bank = $60

	-	%copypixel($00, $00)					;\
		%copypixel($00, $01)					; |
		%copypixel($00, $02)					; |
		%copypixel($00, $03)					; | copy a column
		%copypixel($00, $04)					; | (empty pixels use filler color)
		%copypixel($00, $05)					; |
		%copypixel($00, $06)					; |
		%copypixel($00, $07)					; |
		%copypixel($00, $08)					;/
		INX							;\
		INY							; | increment index and check for end of tile
		CPY $04 : BCC -						;/

		PLB							; restore bank
		RTS

		.Clear
		PHB							;\
		LDA.b #!GFX_buffer>>16					; | setup
		PHA : PLB						; |
		REP #$20						;/
		LDA !MsgRow						;\
		AND #$00FF : BEQ ..NoBackup				; |
		DEC A							; |
		ASL #4							; |
		TAX							; |
		LDA.w !GFX_buffer+$C02 : STA.w !GFX_buffer+$000,x	; |
		LDA.w !GFX_buffer+$C42 : STA.w !GFX_buffer+$002,x	; |
		LDA.w !GFX_buffer+$C82 : STA.w !GFX_buffer+$004,x	; |
		LDA.w !GFX_buffer+$CC2 : STA.w !GFX_buffer+$006,x	; |
		LDA.w !GFX_buffer+$D02 : STA.w !GFX_buffer+$008,x	; |
		LDA.w !GFX_buffer+$D42 : STA.w !GFX_buffer+$00A,x	; | store second column in a special buffer for dialogue arrow
		LDA.w !GFX_buffer+$D82 : STA.w !GFX_buffer+$00C,x	; |
		LDA.w !GFX_buffer+$DC2 : STA.w !GFX_buffer+$00E,x	; |
		LDA.w !GFX_buffer+$E02 : STA.w !GFX_buffer+$010,x	; |
		LDA.w !GFX_buffer+$E42 : STA.w !GFX_buffer+$012,x	; |
		LDA.w !GFX_buffer+$E82 : STA.w !GFX_buffer+$014,x	; |
		LDA.w !GFX_buffer+$EC2 : STA.w !GFX_buffer+$016,x	; |
		LDA.w !GFX_buffer+$F02 : STA.w !GFX_buffer+$018,x	; |
		LDA.w !GFX_buffer+$F42 : STA.w !GFX_buffer+$01A,x	; |
		LDA.w !GFX_buffer+$F82 : STA.w !GFX_buffer+$01C,x	; |
		LDA.w !GFX_buffer+$FC2 : STA.w !GFX_buffer+$01E,x	; |
		..NoBackup						;/
		LDX #$01FE						;\
	-	LDA.w !GFX_buffer+$E00,x : STA.w !GFX_buffer+$C00,x	; |
		STZ.w !GFX_buffer+$E00,x				; | move second half of render buffer into the first half, then clear the second half
		DEX #2 : BPL -						; |
		PLB							; |
		RTS							;/




DRAW_BORDER:	PHK : PLB

		LDA $400000+!MsgCinematic : BNE +

		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JSR $1E80
	+	RTS


		.SA1
		PHP
		PHB : PHK : PLB
		SEP #$30
		LDX #$00				; tilemap index
		LDY !OAMindex				; OAM index
		LDA.l $400000+!MsgVertOffset		;\
		AND #$3F				; | Y offset
		ASL A					; |
		STA $00					;/
		REP #$20				; 16-bit A
		LDA.l $400000+!MsgVRAM3			;\
		LSR #4					; | tile offset
		SEP #$20				; |
		STA $01					;/
	-	LDA.w .TileMap+0,x : STA.w !OAM+0,y
		LDA.w .TileMap+1,x
		CLC : ADC $00
		STA.w !OAM+1,y
		LDA.w .TileMap+2,x
		CLC : ADC $01
		STA !OAM+2,y
		LDA.w .TileMap+3,x : STA !OAM+3,y
		INY #4
		INX #4
		CPX.b #.End-.TileMap : BCC -
		LDA !OAMindex
		LSR #2
		TAX
		REP #$20
		LDA #$0202
		STA !OAMhi+$00,x
		STA !OAMhi+$02,x
		STA !OAMhi+$04,x
		STA !OAMhi+$06,x
		STA !OAMhi+$08,x
		STA !OAMhi+$0A,x
		STA !OAMhi+$0C,x
		STA !OAMhi+$0E,x
		STA !OAMhi+$10,x
		STA !OAMhi+$12,x
		STA !OAMhi+$14,x
		STA !OAMhi+$16,x
		STA !OAMhi+$18,x
		STY !OAMindex

		PLB
		PLP
		RTL


		; total 26 (0x1A) tiles
		;  ___ ___ ___ ___
		; | X | Y | T | P |
.TileMap	db $31,$37,$00,$21			; > Topleft corner
		db $41,$37,$01,$21			;\
		db $51,$37,$01,$21			; |
		db $61,$37,$01,$21			; |
		db $71,$37,$01,$21			; | Upper border
		db $81,$37,$01,$21			; |
		db $91,$37,$01,$21			; |
		db $A1,$37,$01,$21			; |
		db $B1,$37,$01,$21			;/
		db $C1,$37,$00,$61			; > Topright corner
		db $31,$47,$03,$21			;\
		db $C1,$47,$03,$61			; |
		db $31,$57,$03,$21			; | Side borders
		db $C1,$57,$03,$61			; |
		db $31,$67,$03,$21			; |
		db $C1,$67,$03,$61			;/
		db $31,$77,$00,$A1			; > Botleft corner
		db $41,$77,$01,$A1			;\
		db $51,$77,$01,$A1			; |
		db $61,$77,$01,$A1			; |
		db $71,$77,$01,$A1			; | Lower border
		db $81,$77,$01,$A1			; |
		db $91,$77,$01,$A1			; |
		db $A1,$77,$01,$A1			; |
		db $B1,$77,$01,$A1			;/
		db $C1,$77,$00,$E1			; > Botright corner
		.End



DRAW_PORTRAIT:	BPL .INIT
		JMP .MAIN

		.INIT
		DEC A
		ASL #2
		TAX
		LDA.l !PortraitPointers+2,x : STA $00			;\
		LDA.l !PortraitPointers+3,x : STA $01			; | GFX pointer
		LDA.l !PortraitPointers+4,x : STA $02			;/


		LDA #!VRAMbank
		PHA : PLB
		JSL !GetCGRAM						;\ get CGRAM table index
		BCS ++							;/
		LDA #$3E : STA !CGRAMtable+$00,y			;\ data size
		LDA #$00 : STA !CGRAMtable+$01,y			;/
		LDA.l !PortraitPointers+5,x				;\
		ASL A							; |
		TAX							; |
		LDA.l (!PortraitPointers&$FF0000)+read2(!PortraitPointers)+0,x	; | source address
		STA !CGRAMtable+$02,y					; |
		LDA.l (!PortraitPointers&$FF0000)+read2(!PortraitPointers)+1,x	; |
		STA !CGRAMtable+$03,y					; |
		LDA.b #!PortraitPointers>>16				; |
		STA !CGRAMtable+$04,y					;/
		LDA !MsgPal : STA !CGRAMtable+$05,y			; > destination CGRAM

	++	LDA #$10 : STA $03					; > 16 8x8 tiles
		JSL !PlaneSplit						; > decode


		REP #$20
		JSL !GetBigCCDMA
		LDA #$0100 : STA !CCDMAtable+$00,x			; upload size = .5 KB
		LDA.w #!BufferLo : STA !CCDMAtable+$02,x		; source address = !BufferLo
		LDA !MsgVRAM1 : STA !CCDMAtable+$05,x			; dest VRAM = !MsgVRAM1
		SEP #$20
		LDA.b #!BufferLo>>16 : STA !CCDMAtable+$04,x		; source bank
		LDA #$09 : STA !CCDMAtable+$07,x			; settings = 4bpp, 32px
		REP #$20
		JSL !GetBigCCDMA
		LDA #$0100 : STA !CCDMAtable+$00,x			; upload size = .5 KB
		LDA.w #!BufferLo+$100 : STA !CCDMAtable+$02,x		; source address = !BufferLo+$100
		LDA !MsgVRAM1						;\
		CLC : ADC #$0100					; | dest VRAM = !MsgVRAM1 + 0x100
		STA !CCDMAtable+$05,x					;/
		SEP #$20
		LDA.b #!BufferLo>>16 : STA !CCDMAtable+$04,x		; source bank
		LDA #$09 : STA !CCDMAtable+$07,x			; settings = 4bpp, 32px
		REP #$20
		JSL !GetBigCCDMA
		LDA #$0100 : STA !CCDMAtable+$00,x			; upload size = .5 KB
		LDA.w #!BufferHi : STA !CCDMAtable+$02,x		; source address = !BufferHi
		LDA !MsgVRAM2 : STA !CCDMAtable+$05,x			; dest VRAM = !MsgVRAM2
		SEP #$20
		LDA.b #!BufferHi>>16 : STA !CCDMAtable+$04,x		; source bank
		LDA #$09 : STA !CCDMAtable+$07,x			; settings = 4bpp, 32px
		REP #$20
		JSL !GetBigCCDMA
		LDA #$0100 : STA !CCDMAtable+$00,x			; upload size = .5 KB
		LDA.w #!BufferHi+$100 : STA !CCDMAtable+$02,x		; source address = !BufferHi+$100
		LDA !MsgVRAM2						;\
		CLC : ADC #$0100					; | dest VRAM = !MsgVRAM2 + 0x100
		STA !CCDMAtable+$05,x					;/
		SEP #$20
		LDA.b #!BufferHi>>16 : STA !CCDMAtable+$04,x		; source bank
		LDA #$09 : STA !CCDMAtable+$07,x			; settings = 4bpp, 32px

	;	REP #$20						; > A 16-bit
	;	JSL !GetVRAM						; > get VRAM table index
	;	LDA #$0080						;\
	;	STA !VRAMtable+$00,x					; |
	;	STA !VRAMtable+$07,x					; |
	;	STA !VRAMtable+$0E,x					; |
	;	STA !VRAMtable+$15,x					; | data size
	;	STA !VRAMtable+$1C,x					; |
	;	STA !VRAMtable+$23,x					; |
	;	STA !VRAMtable+$2A,x					; |
	;	STA !VRAMtable+$31,x					;/
	;	LDA.w #!BufferLo+$000					;\
	;	STA !VRAMtable+$02,x					; |
	;	LDA.w #!BufferLo+$080					; |
	;	STA !VRAMtable+$09,x					; |
	;	LDA.w #!BufferLo+$100					; |
	;	STA !VRAMtable+$10,x					; |
	;	LDA.w #!BufferLo+$180					; | source address
	;	STA !VRAMtable+$17,x					; |
	;	LDA.w #!BufferHi+$000					; |
	;	STA !VRAMtable+$1E,x					; |
	;	LDA.w #!BufferHi+$080					; |
	;	STA !VRAMtable+$25,x					; |
	;	LDA.w #!BufferHi+$100					; |
	;	STA !VRAMtable+$2C,x					; |
	;	LDA.w #!BufferHi+$180					; |
	;	STA !VRAMtable+$33,x					;/
	;	LDA.w #!BufferLo>>16					;\
	;	STA !VRAMtable+$04,x					; |
	;	STA !VRAMtable+$0B,x					; |
	;	STA !VRAMtable+$12,x					; |
	;	STA !VRAMtable+$19,x					; | source bank
	;	STA !VRAMtable+$20,x					; |
	;	STA !VRAMtable+$27,x					; |
	;	STA !VRAMtable+$2E,x					; |
	;	STA !VRAMtable+$35,x					;/
	;	LDA !MsgVRAM1 : STA !VRAMtable+$05,x			;\
	;	CLC : ADC #$0100 : STA !VRAMtable+$0C,x			; |
	;	SEC : SBC #$00C0 : STA !VRAMtable+$13,x			; |
	;	CLC : ADC #$0100 : STA !VRAMtable+$1A,x			; | dest VRAM
	;	LDA !MsgVRAM2 : STA !VRAMtable+$21,x			; |
	;	CLC : ADC #$0100 : STA !VRAMtable+$28,x			; |
	;	SEC : SBC #$00C0 : STA !VRAMtable+$2F,x			; |
	;	CLC : ADC #$0100 : STA !VRAMtable+$36,x			;/

		LDA #$80 : TSB !MsgPortrait				; > set portrait init flag

		LDY !MsgCinematic : BEQ .NoCutout
		LDA !MsgPortrait
		LDX #$3E
		PHB : PHK : PLB
		CPY #$02 : BEQ .CutoutBot
		.CutoutTop
		AND #$40 : BNE +
		LDA #$DF						;\
	-	STA $0211,x						; | cut out hole for portrait, top right
		DEX #2 : BPL -						;/
		BRA .FinishCutout
	+	LDA #$20						;\
	-	STA $0210,x						; | cut out hole for portrait, top left
		DEX #2 : BPL -						;/
		BRA .FinishCutout
		.CutoutBot
		AND #$40 : BNE +
		LDA #$DF						;\
	-	STA $0351,x						; | cut out hole for portrait, bottom right
		DEX #2 : BPL -						;/
		BRA .FinishCutout
	+	LDA #$20						;\
	-	STA $0350,x						; | cut out hole for portrait, bottom left
		DEX #2 : BPL -						;/
		.FinishCutout
		PLB
		.NoCutout


		.MAIN
		REP #$20
		LDA !MsgVRAM1
		LSR #4
		STA $00
		LDA !MsgVRAM2
		LSR #4
		SEP #$20
		SEC : SBC $00						; > make it so we can get this by just adding $01 after already processing $00
		STA $01							;

		LDA !MsgPortrait
		AND #$40						;\
		ORA #$30						; | get YXPPCCCT
		STA $02							;/
		LDA !MsgPal
		LSR #4
		SEC : SBC #$08
		ASL A
		TSB $02
		LDA !MsgVRAM1+1
		CMP #$70
		BCC +
		LDA #$01 : TSB $02
	+	PHB : PHK : PLB						; bank wrapper


		LDX !OAMindex						; X = OAM index
		LDY #$03						; Y = times to loop
		LDA $400000+!MsgVertOffset : BMI .TopCorner		; top corner
		LDA $400000+!MsgCinematic : BNE .Cinematic

	.Normal
		BIT $02 : BVC .NormalRight

	.NormalLeft
		LDA $400000+!MsgVertOffset
		AND #$3F
		ASL A
		STA $03
	..loop	LDA .NormalLeftX,y
		STA !OAM+$000,x
		STA !OAM+$004,x
		LDA .NormalY,y
		SEC : SBC $03
		STA !OAM+$001,x
		STA !OAM+$005,x
		TXA
		CLC : ADC #$08
		TAX
		DEY : BPL ..loop
		JMP .End

	.NormalRight
		LDA $400000+!MsgVertOffset
		AND #$3F
		ASL A
		STA $03
	..loop	LDA .NormalRightX,y
		STA !OAM+$000,x
		STA !OAM+$004,x
		LDA .NormalY,y
		SEC : SBC $03
		STA !OAM+$001,x
		STA !OAM+$005,x
		TXA
		CLC : ADC #$08
		TAX
		DEY : BPL ..loop
		JMP .End

	.TopCorner
		LDA .TopCornerX,y
		STA !OAM+$000,x
		STA !OAM+$004,x
		LDA .TopCornerY,y
		STA !OAM+$001,x
		STA !OAM+$005,x
		TXA
		CLC : ADC #$08
		TAX
		DEY : BPL .TopCorner
		BRA .End

	.Cinematic
		CMP #$02 : BEQ .CinBot

	.CinTop
		BIT $02 : BVC .CinTopRight

	.CinTopLeft
		LDA .CinLeftX,y
		STA !OAM+$000,x
		STA !OAM+$004,x
		LDA .CinTopY,y
		STA !OAM+$001,x
		STA !OAM+$005,x
		TXA
		CLC : ADC #$08
		TAX
		DEY : BPL .CinTopLeft
		BRA .End

	.CinTopRight
		LDA .CinRightX,y
		STA !OAM+$000,x
		STA !OAM+$004,x
		LDA .CinTopY,y
		STA !OAM+$001,x
		STA !OAM+$005,x
		TXA
		CLC : ADC #$08
		TAX
		DEY : BPL .CinTopRight
		BRA .End

	.CinBot
		BIT $02 : BVC .CinBotRight

	.CinBotLeft
		LDA .CinLeftX,y
		STA !OAM+$000,x
		STA !OAM+$004,x
		LDA .CinBotY,y
		STA !OAM+$001,x
		STA !OAM+$005,x
		TXA
		CLC : ADC #$08
		TAX
		DEY : BPL .CinBotLeft
		BRA .End

	.CinBotRight
		LDA .CinRightX,y
		STA !OAM+$000,x
		STA !OAM+$004,x
		LDA .CinBotY,y
		STA !OAM+$001,x
		STA !OAM+$005,x
		TXA
		CLC : ADC #$08
		TAX
		DEY : BPL .CinBotRight

		.End
		LDA !OAMindex
		LSR #2
		TAX
		LDA #$02
		STA !OAMhi+$00,x
		STA !OAMhi+$01,x
		STA !OAMhi+$02,x
		STA !OAMhi+$03,x
		STA !OAMhi+$04,x
		STA !OAMhi+$05,x
		STA !OAMhi+$06,x
		STA !OAMhi+$07,x

		LDX !OAMindex
		LDY #$03
	-	LDA .Tiles,y
		CLC : ADC $00
		STA !OAM+$002,x
		CLC : ADC $01
		STA !OAM+$006,x
		LDA $02 : STA !OAM+$003,x
		INC #2
		STA !OAM+$007,x
		TXA
		CLC : ADC #$08
		TAX
		DEY : BPL -
		STX !OAMindex

		PLB
		RTS


.NormalLeftX	db $41,$31,$41,$31
.NormalRightX	db $B1,$C1,$B1,$C1
.NormalY	db $17,$17,$27,$27

.TopCornerX	db $C8,$B8,$C8,$B8
.TopCornerY	db $10,$10,$20,$20

.CinLeftX	db $10,$00,$10,$00
.CinRightX	db $E0,$F0,$E0,$F0
.CinTopY	db $08,$08,$18,$18
.CinBotY	db $A8,$A8,$B8,$B8

.Tiles		db $00,$02,$04,$06



;====================;
;UPDATE ARROW ROUTINE;
;====================;
UPDATE_ARROW:	PHB : PHK : PLB
		PHP
		SEP #$30
		LDA.b #.SA1 : STA $3180
		LDA.b #.SA1>>8 : STA $3181
		LDA.b #.SA1>>16 : STA $3182
		JSR $1E80
		PLP
		PLB
		RTS

; don't change $00 ($3000) during this routine
; that address holds the joypad input and it's a waste to have to reload it later


		.SA1
		PHB
		PHP

		SEP #$20							;\
		LDA #$40							; |
		PHA : PLB							; |
		REP #$30							; | clear output buffer
		LDX #$001E							; |
	-	STZ.w !GFX_buffer+$2A0,x					; |
		DEX #2 : BPL -							;/

		LDA !MsgOptionRow						;\
		CLC : ADC !MsgArrow						; |
		AND #$00FF							; |
		ASL A								; |
		TAY								; | prepare arrow
		LDX #$0000							; |
	-	LDA.w !GFX_buffer+$280,x : STA.w !GFX_buffer+$2A0,y		; |
		INX #2								; |
		INY #2								; |
		CPX #$0009*2 : BCC -						;/

		SEP #$20
		LDA #$00 : STA.l $2250						; prepare multiplication
		LDA #$60 : PHA							; prepare bank 60

		REP #$30
		LDA $400000+!MsgOptionRow
		CLC : ADC $400000+!MsgArrow
		AND #$00FF
		ASL #6
		TAX
		PLB
		SEP #$20
		LDY #$0000
	-	LDA.w !V_buffer*2,x : BEQ +
		STA.w (!V_buffer+($2A0*2))*2,y
	+	INX
		INY
		CPY #$0080 : BCC -

		PHK : PLB							; generic bank
		SEP #$30
		LDA $400000+!MsgOptionRow
		CLC : ADC $400000+!MsgArrow
		STA $2251
		STZ $2252


		JSL !GetSmallCCDMA						; get index
		LDA #$02 : STA !VRAMbase+!CCDMAtable+$07,x			; mode: 8px 2bpp
		LDA.b #!GFX_buffer>>16 : STA !VRAMbase+!CCDMAtable+$04,x	;\
		REP #$20							; | source address
		LDA.w #!GFX_buffer+$2A0 : STA !VRAMbase+!CCDMAtable+$02,x	;/
		LDA $400000+!MsgWidth						;\
		AND #$00FF							; |
		ASL #3								; |
		STA $0E								; > VRAM tile offset for second row
		STA $2253							; |
		LDA !210C							; | dest VRAM calculation
		AND #$000F							; |
		XBA								; |
		ASL #4								; |
		ORA $2306							; |
		CLC : ADC.w #$0015*8						; |
		STA !VRAMbase+!CCDMAtable+$05,x					;/
		CLC : ADC $0E							;\ store VRAM address for second upload
		STA $0E								;/
		LDA #$0010 : STA !VRAMbase+!CCDMAtable+$00,x			; > 16 bytes

		SEP #$20
		JSL !GetSmallCCDMA						; get index
		LDA #$02 : STA !VRAMbase+!CCDMAtable+$07,x			; mode: 8px 2bpp
		LDA.b #!GFX_buffer>>16 : STA !VRAMbase+!CCDMAtable+$04,x	;\
		REP #$20							; | source address
		LDA.w #!GFX_buffer+$2B0 : STA !VRAMbase+!CCDMAtable+$02,x	;/
		LDA $0E : STA !VRAMbase+!CCDMAtable+$05,x			; dest VRAM
		LDA #$0010 : STA !VRAMbase+!CCDMAtable+$00,x			; > 16 bytes

	;	JSL !GetCCDMA
	;	LDA #$02						;\
	;	STA $3190,x						; | width = 8px, bit depth = 2bpp
	;	STA $3190+8,x						;/
	;	LDA.b #!GFX_buffer>>16					;\
	;	STA $3195,x						; |
	;	STA $3195+8,x						; | source address = !GFX_buffer+$2A0 and !GFX_buffer+$2B0
	;	REP #$20						; |
	;	LDA.w #!GFX_buffer+$2A0 : STA $3193,x			; |
	;	LDA.w #!GFX_buffer+$2B0 : STA $3193+8,x			;/
	;	LDA #$0010						;\
	;	STA $3196,x						; | 16 bytes
	;	STA $3196+8,x						;/
	;	LDA $400000+!MsgWidth					;\
	;	AND #$00FF						; |
	;	ASL #3							; |
	;	PHA							; > preserve for second tile
	;	STA $2253						; |
	;	LDA !210C						; | VRAM address = layer 3 GFX address + (row * width * 8) + ($15 * 8)
	;	AND #$000F						; |
	;	XBA							; |
	;	ASL #4							; |
	;	ORA $2306						; |
	;	CLC : ADC.w #$0015*8					; |
	;	STA $3191,x						;/
	;	PLA							;\
	;	CLC : ADC $3191,x					; | VRAM address of second tile
	;	STA $3191+8,x						;/
	;	INC $317F						;\ 2 CCDMA uploads
	;	INC $317F						;/

		SEP #$30
		LDA #$40
		PHA : PLB

		LDA !MsgOptionRow
		CLC : ADC !MsgArrow
		CMP !MsgCurrentArrow : BEQ .Return
		TAX
		LDA !MsgCurrentArrow : BEQ .Return

	; if arrow has moved, erase the previous one

		LDA.l .Bits,x
		INX
		ORA.l .Bits,x
		EOR !MsgArrowMem
		AND !MsgArrowMem
		REP #$20
		AND #$00FF
		STA $0E
		LDY #$00
	-	LSR $0E : BCS .Erase
		INY
		CPY #$08 : BCC -

	.Return	LDA !MsgOptionRow
		CLC : ADC !MsgArrow
		STA !MsgCurrentArrow
		SEP #$30
		TAX
		LDA.l .Bits,x
		INX
		ORA.l .Bits,x
		STA !MsgArrowMem

		PLP
		PLB
		RTL

		.Erase
		JSL !GetSmallCCDMA
		TYA								;\
		AND #$00FF							; |
		STA.l $2251							; |
		LDA !MsgWidth							; |
		ASL #3								; |
		STA.l $2253							; |
		LDA.l !210C							; | dest VRAM
		AND #$000F							; |
		XBA								; |
		ASL #4								; |
		ORA.l $2306							; |
		CLC : ADC.w #$0015*8						; |
		STA !CCDMAtable+$05,x						;/

		TYA								;\
		AND #$00FF							; |
		ASL #4								; | source address
		CLC : ADC.w #!GFX_buffer+$000					; |
		STA !CCDMAtable+$02,x						;/

		LDA #$0010 : STA !CCDMAtable+$00,x				; upload size

		SEP #$20
		LDA #$02 : STA !CCDMAtable+$07,x				; CCDMA mode
		LDA.b #!GFX_buffer>>16 : STA !CCDMAtable+$04,x			; source bank
		REP #$20
		INY
		BRA -


	.Bits
		db $01,$02,$04,$08,$10,$20,$40,$80




;========================;
;COMMAND-HANDLING ROUTINE;
;========================;
; commands:
; 80-9F free
; AX - font (X is font)
; BX - set player 2 character (X is character)
; CX - set player 1 character (X is character)
; DX - talk (X is talk flag value)
; EX - speed (X is speed value)
; F0 - unused
; F1 - unused
; F2 - clear box
; F3,XX - music, !SPC3 value
; F4,XX - portrait, value
; F5,XX - auto scroll, rows to scroll (0 is valid but useless)
; F6,XX - wait for input, rows to scroll (0 is valid)
; F7,XX - delay, frame count
; F8,XX,XX - dialogue, parameter 1 (lo 2 bits = number of options-1, rest is destination/type), parameter 2 (row to start dialogue on)
; F9,XX - next message, message number
; FA,XX,XX - set exit, exit options
; FB - trigger exit
; FC,XX - end level (00 = leave, 01 = beat level)
; FD - instant line
; FE - line break
; FF - end of message
;
; programming note:
;	$0F can be used freely as scratch RAM in this routine
;
HANDLE_COMMANDS:
		CMP #$A0 : BCC .Return			; 80-9F are currently unused
		CMP #$B0 : BCC .Font			; AX - font
		CMP #$C0 : BCC .P2Char			; BX - player 2 character
		CMP #$D0 : BCC .P1Char			; CX - player 1 character
		CMP #$E0 : BCC .Talk			; DX - talk
		CMP #$F0 : BCC .Speed			; EX - speed
		AND #$0F				;\
		ASL A					; |
		XBA					; |
		LDA #$00				; | FX - special command
		XBA					; |
		TAX					; |
		PEA.w .Return-1				; |
		JMP (.Ptr,x)				;/

	.Font	AND #$0F
		STA !MsgFont
		CMP !MsgCachedFont : BEQ .Return
		JSR UpdateFont
		BRA .Return

	.P2Char	AND #$0F
		CMP.l !P2Character : BEQ .Return
		STA.l !P2Character
		STA $0F
		LDA !Characters
		AND #$F0
		ORA $0F
		STA !Characters
		BRA .UpdateMario

	.P1Char	AND #$0F
		CMP.l !P2Character-$80 : BEQ .Return
		STA.l !P2Character-$80
		ASL #4
		STA $0F
		LDA !Characters
		AND #$0F
		ORA $0F
		STA !Characters
		BRA .UpdateMario

	.Talk	AND #$0F
		STA !MsgTalk
		BRA .Return

	.Speed	AND #$0F
		STA !MsgSpeed

	.Unused
	.Return	INY
		STY !MsgIndex
		RTS

	.UpdateMario
		LDA !Characters
		BIT #$F0 : BEQ ..P1
		BIT #$0F : BEQ ..P2
	..nomario
		LDA #$00 : STA !CurrentMario
	..dead	LDA #$01 : STA.l !P1Dead
		LDA #$7F : STA !MarioMaskBits
		LDA #$09 : STA !MarioAnim
		BRA .Return

	..P2	LDA #$02 : STA !CurrentMario
		LDX #$0080
		BRA +
	..P1	LDA #$01 : STA !CurrentMario
		LDX #$0000
	+	LDA.l !P2Status-$80,x : BNE ..dead

	..alive	LDA #$00 : STA.l !P1Dead
		STZ !MarioMaskBits
		STZ !MarioAnim
		REP #$20
		LDA.l !P2XPosLo-$80,x : STA $94
		LDA.l !P2YPosLo-$80,x
		SEC : SBC #$0010
		STA $96
		SEP #$20
		BRA .Return




.Ptr		dw .HeaderSettings	; F0, variable length followup
		dw .Unused		; F1
		dw .ClearBox		; F2
		dw .Music		; F3,XX
		dw .Portrait		; F4,XX
		dw .Scroll		; F5,XX
		dw .WaitForInput	; F6
		dw .Delay		; F7,XX
		dw .Dialogue		; F8,XX,XX
		dw .Next		; F9,XX
		dw .SetExit		; FA,XX,XX
		dw .TriggerExit		; FB
		dw .EndLevel		; FC,XX
		dw .InstantLine		; FD
		dw .LineBreak		; FE
		dw .End			; FF


; how many extra bytes each command has
.CommandLength	db $FF			; F0, special variable length
		db $00			; F1
		db $00			; F2
		db $01			; F3
		db $01			; F4
		db $01			; F5
		db $00			; F6
		db $01			; F7
		db $02			; F8
		db $01			; F9
		db $02			; FA
		db $00			; FB
		db $01			; FC
		db $00			; FD
		db $00			; FE
		db $00			; FF


.HeaderSettings	INY
		LDA [$08],y : BEQ ..cinematic
		CMP #$01 : BEQ ..width
		CMP #$02 : BEQ ..verticaloffset
		CMP #$03 : BEQ ..border
		CMP #$04 : BEQ ..mode
		CMP #$05 : BEQ ..filler
		CMP #$06 : BEQ ..important
		RTS
		..cinematic
		INY
		LDA [$08],y : STA !MsgCinematic
		BEQ +					;\
		LDA !MsgPortrait : BEQ ++		; |
		LDA #$1A				; | cinematic width with portrait = 26 tiles
		BRA +++					; |
	++	LDA #$1F				; | cinematic width with no portrait = 31 tiles
		BRA +++					; |
	+	LDA #$12				; | normal mode width = 18 tiles
	+++	STA !MsgWidth				;/
		BRA .HeaderSettings
		..width
		INY
		LDA [$08],y : STA !MsgWidth
		BRA .HeaderSettings
		..verticaloffset
		INY
		LDA [$08],y
		AND #$3F
		STA $0F
		LDA !MsgVertOffset
		AND.b #$3F^$FF
		ORA $0F
		STA !MsgVertOffset
		BRA .HeaderSettings
		..border
		INY
		LDA [$08],y
		BEQ $02 : LDA #$40
		EOR #$40
		STA $0F
		LDA !MsgVertOffset
		AND.b #$40^$FF
		ORA $0F
		STA !MsgVertOffset
		BRA .HeaderSettings
		..mode
		INY
		LDA [$08],y : STA !MsgMode
		BRA .HeaderSettings
		..filler
		INY
		LDA [$08],y : STA !MsgFillerColor
		BRA .HeaderSettings
		..important
		INY
		LDA [$08],y : STA !MsgImportant
		JMP .HeaderSettings


.ClearBox	LDA #$01 : STA !MsgTerminateRender
		JMP CLEAR_BOX

.Music		INY
		LDA [$08],y : STA.l !SPC3
		RTS

.Portrait	INY
		LDA [$08],y
		AND #$7F : STA !MsgPortrait		; load portrait
		LDA !MsgVertOffset
		AND.b #$80^$FF
		STA !MsgVertOffset
		LDA [$08],y
		AND #$80
		TSB !MsgVertOffset			; set "lock portrait to top-right corner" bit
		RTS

.Scroll		INY
		LDA [$08],y
		CMP #$FF : BNE +			;\
		LDA !MsgRow				; | special value 0xFF scroll just off-screen regardless of distance
		INC A					;/
	+	STA $0F
		ASL #3
		CLC : ADC $0F
		CLC : ADC !MsgTargScroll
		STA !MsgTargScroll
		LDA #$01 : STA !MsgTerminateRender
		STZ !MsgInstantLine
		RTS

.WaitForInput	LDA #$01
		STA !MsgWaitFlag
		STA !MsgTerminateRender
		STZ !MsgInstantLine
		RTS

.Delay		INY
		LDA [$08],y : STA !MsgDelay
		LDA #$01 : STA !MsgTerminateRender
		STZ !MsgInstantLine
		RTS

.Dialogue	INY
		LDA [$08],y
		AND #$03
		STA !MsgOptions
		LDA [$08],y
		LSR #2
		INC A
		STA !MsgDestination
		INY
		LDA [$08],y : STA !MsgOptionRow
		STZ !MsgArrow
		RTS

.Next		LDA !MsgCounter
		TAX
		INY
		LDA [$08],y : STA !MsgSequence,x
		INC !MsgCounter
		RTS

.SetExit	PHX
		INY
		LDA [$08],y
		LDX #$001F
	-	STA $79B8,x
		DEX : BPL -
		INY
		LDA [$08],y
		LDX #$001F
	-	STA $79D8,x
		DEX : BPL -
		PLX
		RTS

.TriggerExit	LDA #$06 : STA $71
		STZ $88
		STZ $89
		RTS

.EndLevel	PHB : PHK : PLB
		PHX
		LDA #$02 : STA $73CE			; clear midway
		LDA #$80				;\ fade music
		STA !SPC3				;/
		STA $6DD5				; set exit
		LDX !Translevel : BEQ ++		;\ > intro level does not count
		LDA !LevelTable1,x : BMI +		; |
		INC $7F2E				; > you've now beaten one more level (only once/level)
		ORA #$80				; | set clear, remove midway
	+	AND.b #$60^$FF				; > clear checkpoint
		STA !LevelTable1,x			;/
		STZ !LevelTable2,x			; > clear checkpoint level
		STZ $73CE				; > clear midway flag
	++	LDA #$0B : STA !GameMode		; > load realm select
		INY					;\ 00 = leave level, 01+ = beat level
		LDA [$08],y : BEQ ..R			;/
		LDA #$00 : XBA				;\
		LDX !Level				; |
		LDA.l $188060,x				; |
		TAX					; | unlock level
		LDA !LevelTable4,x			; |
		ORA #$80				; |
		STA !LevelTable4,x			;/
	..R	PLX
		PLB
		RTS

.InstantLine	LDA #$01 : STA !MsgInstantLine
		RTS

.LineBreak	STZ !MsgX
		INC !MsgRow
		STZ !MsgInstantLine
		RTS

.End		LDA #$01 : STA !MsgEnd
		STZ !MsgInstantLine
		RTS








cleartable
table "MessageTable.txt"
print "Text pointers stored at $", pc, "."
incsrc "TextPointers.asm"
print "Text data stored at $", pc, "."
incsrc "TextData.asm"


GFX:

; each character needs:
; - tile number (8 bits)
; - width (8 bits)
;
; for table order, see MessageTable.txt
;
; the font GFX is 128px wide, whereas the output width is 256px


; text format is pretty simple
; any value 00-4F will index the table below
; 50-7E are special characters that can't be entered directly into the text data (you have to use macros or byte code for this, see TextPointers.asm)
; 7F is a space, which simply skips ahead without rendering any GFX (it is also ignored if it comes at the end of a line)
; 80-FF are commands without associated GFX, many of these are more than 1 byte long, they are most easily inserted using macros
; FF is the most important command as it will end the message


macro Char(number, width)
	db <number>
	db <width>
endmacro


.FontData
		dw ..Default-.FontData		; 00
		dw ..Classic-.FontData		; 01
		dw $FFFF			; 02
		dw $FFFF			; 03
		dw $FFFF			; 04
		dw $FFFF			; 05
		dw $FFFF			; 06
		dw $FFFF			; 07
		dw $FFFF			; 08
		dw $FFFF			; 09
		dw $FFFF			; 0A
		dw $FFFF			; 0B
		dw $FFFF			; 0C
		dw $FFFF			; 0D
		dw $FFFF			; 0E
		dw $FFFF			; 0F


..Default	%Char($00, 6)	; A
		%Char($01, 6)	; B
		%Char($02, 6)	; C
		%Char($03, 6)	; D
		%Char($04, 6)	; E
		%Char($05, 6)	; F
		%Char($06, 6)	; G
		%Char($07, 6)	; H
		%Char($08, 5)	; I
		%Char($09, 6)	; J
		%Char($0A, 6)	; K
		%Char($0B, 5)	; L
		%Char($0C, 8)	; M
		%Char($0D, 8)	; N
		%Char($0E, 6)	; O
		%Char($0F, 6)	; P
		%Char($20, 6)	; Q
		%Char($21, 6)	; R
		%Char($22, 6)	; S
		%Char($23, 6)	; T
		%Char($24, 6)	; U
		%Char($25, 6)	; V
		%Char($26, 8)	; W
		%Char($27, 7)	; X
		%Char($28, 6)	; Y
		%Char($29, 6)	; Z
		%Char($2A, 3)	; .
		%Char($2B, 3)	; ,
		%Char($2C, 4)	; !
		%Char($2D, 6)	; ?
		%Char($2E, 3)	; :
		%Char($2F, 3)	; ;
		%Char($40, 6)	; a
		%Char($41, 5)	; b
		%Char($42, 5)	; c
		%Char($43, 6)	; d
		%Char($44, 5)	; e
		%Char($45, 6)	; f
		%Char($46, 6)	; g
		%Char($47, 5)	; h
		%Char($48, 4)	; i
		%Char($49, 5)	; j
		%Char($4A, 5)	; k
		%Char($4B, 4)	; l
		%Char($4C, 7)	; m
		%Char($4D, 5)	; n
		%Char($4E, 5)	; o
		%Char($4F, 5)	; p
		%Char($60, 6)	; q
		%Char($61, 5)	; r
		%Char($62, 5)	; s
		%Char($63, 5)	; t
		%Char($64, 5)	; u
		%Char($65, 5)	; v
		%Char($66, 7)	; w
		%Char($67, 6)	; x
		%Char($68, 5)	; y
		%Char($69, 5)	; z
		%Char($6A, 6)	; +
		%Char($6B, 5)	; -
		%Char($6C, 6)	; *
		%Char($6D, 5)	; /
		%Char($6E, 5)	; \
		%Char($6F, 5)	; =
		%Char($80, 7)	; 0
		%Char($81, 5)	; 1
		%Char($82, 7)	; 2
		%Char($83, 7)	; 3
		%Char($84, 6)	; 4
		%Char($85, 7)	; 5
		%Char($86, 7)	; 6
		%Char($87, 7)	; 7
		%Char($88, 7)	; 8
		%Char($89, 7)	; 9
		%Char($8A, 4)	; (
		%Char($8B, 4)	; )
		%Char($8C, 8)	; &
		%Char($8D, 7)	; $
		%Char($8E, 7)	; %
		%Char($8F, 5)	; > (cursor symbol)

		; index 50+
		%Char($A0, 10)	; A button
		%Char($A2, 10)	; B button
		%Char($A4, 10)	; X button
		%Char($A6, 10)	; Y button
		%Char($A8, 15)	; L button
		%Char($AA, 15)	; R button
		%Char($AC, 19)	; start button
		%Char($CC, 19)	; select button
		%Char($C0, 7)	; D-pad right
		%Char($C1, 7)	; D-pad left
		%Char($C2, 7)	; D-pad down
		%Char($C3, 7)	; D-pad up

		%Char($E0, 6)	; "
		%Char($E1, 3)	; '
		%Char($E2, 8)	; ~
		%Char($E3, 4)	; [
		%Char($E4, 4)	; ]
		%Char($E5, 5)	; japanese [
		%Char($E6, 5)	; japanese ]


..Classic	%Char($00, 7)	; A
		%Char($01, 7)	; B
		%Char($02, 7)	; C
		%Char($03, 7)	; D
		%Char($04, 7)	; E
		%Char($05, 7)	; F
		%Char($06, 7)	; G
		%Char($07, 7)	; H
		%Char($08, 7)	; I
		%Char($09, 7)	; J
		%Char($0A, 7)	; K
		%Char($0B, 7)	; L
		%Char($0C, 7)	; M
		%Char($0D, 7)	; N
		%Char($0E, 7)	; O
		%Char($0F, 7)	; P
		%Char($20, 7)	; Q
		%Char($21, 7)	; R
		%Char($22, 7)	; S
		%Char($23, 7)	; T
		%Char($24, 7)	; U
		%Char($25, 7)	; V
		%Char($26, 7)	; W
		%Char($27, 7)	; X
		%Char($28, 7)	; Y
		%Char($29, 7)	; Z
		%Char($2A, 7)	; .
		%Char($2B, 7)	; ,
		%Char($2C, 7)	; !
		%Char($2D, 7)	; ?
		%Char($2E, 7)	; :
		%Char($2F, 7)	; ;
		%Char($40, 7)	; a
		%Char($41, 7)	; b
		%Char($42, 7)	; c
		%Char($43, 7)	; d
		%Char($44, 7)	; e
		%Char($45, 7)	; f
		%Char($46, 7)	; g
		%Char($47, 7)	; h
		%Char($48, 7)	; i
		%Char($49, 7)	; j
		%Char($4A, 7)	; k
		%Char($4B, 7)	; l
		%Char($4C, 7)	; m
		%Char($4D, 7)	; n
		%Char($4E, 7)	; o
		%Char($4F, 7)	; p
		%Char($60, 7)	; q
		%Char($61, 7)	; r
		%Char($62, 7)	; s
		%Char($63, 7)	; t
		%Char($64, 7)	; u
		%Char($65, 7)	; v
		%Char($66, 7)	; w
		%Char($67, 7)	; x
		%Char($68, 7)	; y
		%Char($69, 7)	; z
		%Char($6A, 7)	; +
		%Char($6B, 7)	; -
		%Char($6C, 7)	; *
		%Char($6D, 7)	; /
		%Char($6E, 7)	; \
		%Char($6F, 7)	; =
		%Char($80, 7)	; 0
		%Char($81, 7)	; 1
		%Char($82, 7)	; 2
		%Char($83, 7)	; 3
		%Char($84, 7)	; 4
		%Char($85, 7)	; 5
		%Char($86, 7)	; 6
		%Char($87, 7)	; 7
		%Char($88, 7)	; 8
		%Char($89, 7)	; 9
		%Char($8A, 7)	; (
		%Char($8B, 7)	; )
		%Char($8C, 7)	; #
		%Char($8D, 7)	; $
		%Char($8E, 7)	; %
		%Char($8F, 7)	; > (cursor symbol)


.FontGFX
		dw !File_default_font	; 00
		dw !File_classic_font	; 01
		dw $FFFF		; 02
		dw $FFFF		; 03
		dw $FFFF		; 04
		dw $FFFF		; 05
		dw $FFFF		; 06
		dw $FFFF		; 07
		dw $FFFF		; 08
		dw $FFFF		; 09
		dw $FFFF		; 0A
		dw $FFFF		; 0B
		dw $FFFF		; 0C
		dw $FFFF		; 0D
		dw $FFFF		; 0E
		dw $FFFF		; 0F



.End

	print "In total this patch takes up ", freespaceuse, " (0x", hex(GFX_End-MESSAGE_ENGINE), ") bytes."
	print " "