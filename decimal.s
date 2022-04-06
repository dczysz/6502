PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

value = $0200 ; 2 bytes
mod10 = $0202 ; 2 bytes
message = $0204 ; 6 bytes

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

  lda #0
  sta message

  ; Initialize value to be the number to convert
  lda number
  sta value
  lda number + 1
  sta value + 1

divide:
  ; Initialize the remainder to zero
  lda #0
  sta mod10
  sta mod10 + 1
  clc ; clear carry bit

  ldx #16
div_loop:
  ; Rotate quotient and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1

  ; a,y registers = divident - divisor
  sec       ; Set carry bit to 1
  lda mod10
  sbc #10   ; Subtract with carry
  tay       ; Save low byte in Y
  lda mod10 + 1
  sbc #0
  bcc ignore_result ; branch if dividend < dividor
  sty mod10
  sta mod10 + 1

ignore_result:
  dex
  bne div_loop
  rol value ; Shift in last bit of the quotient
  rol value + 1

  lda mod10
  clc
  adc #"0"
  jsr push_char

  ; If value != 1, then continue dividing
  lda value
  ora value + 1
  bne divide ; branch if value not zero

  ldx #0
print:
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print

loop:
  jmp loop

number: .word 1729

; Add the A register character to the beginning of null-terminated string `message`
push_char:
  pha ; Push new first char onto stack
  ldy #0

char_loop:
  lda message,y ; Get char from string and put into x
  tax
  pla
  sta message,y ; Pull char off stack and add it to the string
  iny
  txa
  pha           ; Push char from string onto stack
  bne char_loop
  
  pla ; Pull null byte off stack and add to end of the string
  sta message,y

  rts

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
  bne lcd_busy   ; Loop if and result is not zero

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