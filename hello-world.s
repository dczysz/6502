; Memory address variables ($)
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

; Binary value variables (%)
E = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  ldx #$ff       ; Initialize stack pointer to 0xff
  txs

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11100000 ; Set top 3 pins on port A to output (RS/RW/E on LCD display)
  sta DDRA

  lda #%00111000 ; Set 8-bit mode, 2-line display, 5x8 font
  jsr lcd_instruction ; Jump to subroutine `lcd_instruction`
  lda #%00001110 ; Set display on, cursor on, blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor, don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  ldx #0
print:
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print
  
loop:
  jmp loop

message: .asciiz "Hello, world!"

lcd_wait:
  pha
  lda #%00000000 ; Set Port B as input
  sta DDRB
lcd_busy:
  lda #RW        ; Tell LCD we want to read busy flag
  sta PORTA
  lda #(RW | E)  ; Execute the instruction
  sta PORTA
  lda PORTB      ; Read busy flag
  and #%10000000
  bne lcd_busy   ; Loop if and result is not 0

  lda #RW        ; Turn off E bit
  sta PORTA
  lda #%11111111 ; Set Port B as output again
  sta DDRB
  pla
  rts

lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to actually send the above instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  rts            ; Return from subroutine

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS, clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to actually send the above instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts

  .org $fffc
  .word reset
  .word $0000