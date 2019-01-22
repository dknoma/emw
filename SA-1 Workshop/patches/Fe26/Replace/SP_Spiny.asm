

pushpc
org $019D1A
	JSL SpinyTileCount		; > Source: LDA #$03 : STA $04

org $019D57
	JSL SpinyTileSize		; > Source: LDA #$03 : LDY #$00


org $019BD5
	db $86,$86,$86,$86		; remap spiny from tile $94


pullpc




	SpinyTileCount:
		LDA $3200,x
		CMP #$14 : BNE .NotSpiny
		STZ $04				; only 1 tile for falling spiny
		RTL

		.NotSpiny
		LDA #$03 : STA $04		; Restore original code if not spiny

		.Return
		RTL

	SpinyTileSize:
		LDA $3200,x
		CMP #$14 : BNE .NotSpiny
		LDA #$00
		LDY #$02
		RTL

		.NotSpiny
		LDA #$03
		LDY #$00

		.Return
		RTL



