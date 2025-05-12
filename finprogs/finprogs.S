#define __SFR_OFFSET 0x00
#include "avr/io.h"



.global main
;===============================================================
main:
    CLR   R24
    STS   UCSR0A, R24                   ;clear UCSR0A register
    STS   UBRR0H, R24                   ;clear UBRR0H register
    LDI   R24, 103                      ;& store in UBRR0L 103 value
    STS   UBRR0L, R24                   ;to set baud rate 9600
    LDI   R24, 1<<RXEN0 | 1<<TXEN0      ;enable RXB & TXB
    STS   UCSR0B, R24
    LDI   R24, 1<<UCSZ00 | 1<<UCSZ01    ;asynch, no parity, 1 stop, 8 bits
    STS   UCSR0C, R24

    ; Init PORTC (PC0-2) for LED output
    LDI R17, 0b00000111     ; Set PC0, PC1, PC2 as output
    OUT DDRC, R17           ; Set DDRC bits 0–2 as output
    OUT PORTC, R17       

    SBI DDRB, 2     ; Set bit PD2 of DDRB for output TES DOANG

    CBI DDRC, 3
    LDI R20, 0x63   ; Set 01100011 for ADMUX Register
    STS ADMUX, R20  ; 01100011 -> Using AVcc as VRef, which is equal to Vcc, left justified, and uses ADC3
    ;LDI R20, 0x86   ; Set ADCSRA to 0x86 or 10000110
    LDI R20, 0x8E
    STS ADCSRA, R20 ; 10000110 -> Turn on ADC, prescaler to 64. Turn off ADC Conversion for initialization.
    SEI
    RJMP agn
;-----------------------------------------------------------------

readADC:
    LDI R26, 0xC6   ; Load C6 to R26  
    STS ADCSRA, R26 ; Set ADCSRA to C6 -> 11000110 -> Turn on ADC Conversion
waitADC:
    LDS R27, ADCSRA ; Load ADCSRA to R27 as placeholder
    SBRS R27, 4     ; Check for ADIF flag (bit 4 from left) in ADCSRA
    RJMP waitADC     ; Wait for conversion

    LDI R17, 0xD6   ; Set ADIF Flag
    STS ADCSRA, R17 ; Signal that the conversion is complete and ready to be cleared
   
    LDS R24, ADCL   ; Store ADCL to R24, picked the register at random
    LDS R25, ADCH   ; Store ADCH to R25, respectively, also picked the register at random
    MOV R21, R25
    RCALL printdigit
    CPI R25, 20   ; Threshold value of F in Hexadecimal
    RCALL myDelay   ; Adds delay around 0.5s on each loop just in case for unintended behavior
    BRGE LedON      ; If R25 >= threshold value, turn ON LED
    RJMP LedOFF      ; If Condition is not satisfied, Turn OFF LED.
    RET

myDelay:          ; Nested loop subroutine
    LDI R23, 255  ; Outer loop counter
l10: LDI R24, 255  ; mid loop counte
l11: LDI R25, 41   ; inner loop counter to give 0.5s delay
l12: DEC R25       ; decrement inner loop
    BRNE l12       ; loop if not zero
    DEC R24       ; decrement mid loop
    BRNE l11       ; loop if not zero
    DEC R23       ; decrement outer loop
    BRNE l10       ; loop if not zero
    RET           ; return to caller

LedON:
    SBI PORTB, 2  ; Turn on LED
    ;RJMP readADC  ; return to Main Loop
    RCALL print_msg
    RET

LedOFF:
    CBI PORTB, 2  ; Turn off LED
    ;RJMP readADC  ; return to Main Loop
    RET

printdigit:
    ;MOV   R31, R21                      ;simpan low byte of 1st number
    ;MOV   R31, R22                      ;simpan high byte of 1st number


    MOV   R16, R21
    CALL ASCII_MSD
    CALL LCD_buffer1
    STS   UDR0, R16                     ;print digit1 result


    MOV   R16, R21
    CALL ASCII_LSD
    CALL LCD_buffer1
    STS   UDR0, R16                     ;print digit0 result

    ;Print new line \n
    LDI R17, 0x0D
    CALL LCD_buffer1
    STS UDR0, R17
    LDI R18, 0x0A
    CALL LCD_buffer1
    STS UDR0, R18

    RET


LCD_buffer1:
    LDS   R27, UCSR0A
    SBRS  R27, UDRE0                    ;test data buffer if data can be sent
    JMP  LCD_buffer1
    RET


ASCII_MSD:
    MOV   R23, R16                      ;save copy of result
    ANDI  R16, 0xF0                     ;extract & swap high-nibble
    SWAP  R16
    SUBI  R16, -48                      ;R16 = R16 - (48) = R16 + 48
    MOV   R28, R16                      ;save a copy of high-byte result
    SUBI  R28, 58                       ;if +ve      
    BRPL  A_F_D1                        ;branch & add 7 to get ASCII A to F
l1: RET

ASCII_LSD:
    MOV   R16, R23                      ;restore copy of result
    ANDI  R16, 0x0F                     ;extract low-nibble
    SUBI  R16, -48                      ;R16 = R16 - (48) = R16 + 48
    MOV   R28, R16                      ;save a copy of high-byte result
    SUBI  R28, 58                       ;if +ve
    BRPL  A_F_D0                        ;branch & add 7 to get ASCII A to F
l2: RET    


A_F_D1:
    SUBI  R16, -7                       ;R16 = R16 - (7) = R16 + 7
    JMP  l1


A_F_D0:
    SUBI  R16, -7                       ;R16 = R16 - (7) = R16 + 7
    JMP  l2

agn:
    RCALL readADC
    RCALL delay_2s          ; wait for dht11 to get ready
;-----------------------------------------------------------------
    ; Send Start Signal to DHT11
    SBI DDRB, 1         
    CBI PORTB, 1           
    RCALL delay_20ms     
    SBI PORTB, 1       
    CBI DDRB, 1           

    ; Wait for DHT11 response
w1: SBIC PINB, 1
    RJMP w1
w2: SBIS PINB, 1
    RJMP w2
w3: SBIC PINB, 1
    RJMP w3

    ;skip membaca humidity
    RCALL DHT11_reading
    RCALL DHT11_reading

    RCALL DHT11_reading
    MOV R30, R18           ; Store temperature in R30

    ;skip baca temp decimal dan checksum
    RCALL DHT11_reading
    RCALL DHT11_reading

    LDI R20, 26
    CP R30, R20           
    BRLO led1on
    LDI R20, 29
    CP R30, R20           
    BRSH led3on

led2on:
    LDI R17, 0b00000010    ; PC1 ON
    RJMP update_leds

led1on:
    LDI R17, 0b00000001    ; PC0 ON
    RJMP update_leds

led3on:
    LDI R17, 0b00000100    ; PC2 ON

update_leds:
    OUT PORTC, R17
    RJMP agn
;===============================================================

DHT11_reading:
    LDI R17, 8
    CLR R18
w4: SBIS PINB, 1
    RJMP w4
    RCALL delay_timer0
    SBIS PINB, 1
    RJMP skp
    SEC
    ROL R18
    RJMP w5
skp:LSL R18
w5: SBIC PINB, 1
    RJMP w5
    DEC R17
    BRNE w4
    RET


delay_2s:
    LDI R21, 255
l6: LDI R22, 255
l7: LDI R23, 164
l8: DEC R23
    BRNE l8
    DEC R22
    BRNE l7
    DEC R21
    BRNE l6
    RET

delay_20ms:
    LDI R21, 255
l3: LDI R22, 210
l4: LDI R23, 2
l5: DEC R23
    BRNE l5
    DEC R22
    BRNE l4
    DEC R21
    BRNE l3
    RET

delay_timer0:
    CLR R20
    OUT TCNT0, R20
    LDI R20, 100
    OUT OCR0A, R20
    LDI R20, 0b00001010
    OUT TCCR0B, R20
lgatau: IN R20, TIFR0
    SBRS R20, OCF0A
    RJMP lgatau
    CLR R20
    OUT TCCR0B, R20
    LDI R20, (1<<OCF0A)
    OUT TIFR0, R20
    RET

print_msg:
    LDI   R30, lo8(messages)
    LDI   R31, hi8(messages)            ;Z points to string message
    JMP again
again:
    LPM   R18, Z+                       ;load char of string onto R18
    CPI   R18, 0                        ;check if R18=0 (end of string)
    BREQ  ext                           ;if yes, exit
    CALL LCD_buffer                     ;LCD buffer ready?
    STS   UDR0, R18                     ;send char in R18 to serial monitor
    JMP  again                            ;loop back & get next character
ext:
    RET                                 ;store the result

LCD_buffer:
    LDS   R27, UCSR0A
    SBRS  R27, UDRE0                    ; Wait until UDR0 is ready
    RJMP  LCD_buffer
    RET

messages:
    .ascii "LOOP"                       ; String to print
    .byte 10, 13, 0                      ; Newline and null terminator


