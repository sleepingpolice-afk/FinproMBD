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

    SBI DDRC, 0
    LDI   R20, 0xC0       ;internal 2.56V, right-justified data, ADC0
    STS   ADMUX, R20
    LDI   R20, 0x87 
    STS   ADCSRA, R20
    
    SBI   DDRB, 4
    RJMP agn                            ; Jump to agn to start the loop

; readADC:
;     LDI R26, 0xC6   ; Load C6 to R26  
;     STS ADCSRA, R26 ; Set ADCSRA to C6 -> 11000110 -> Turn on ADC Conversion
; waitADC:
;     LDS R27, ADCSRA ; Load ADCSRA to R27 as placeholder
;     SBRS R27, 4     ; Check for ADIF flag (bit 4 from left) in ADCSRA
;     RJMP waitADC     ; Wait for conversion

;     LDI R17, 0xD6   ; Set ADIF Flag
;     STS ADCSRA, R17 ; Signal that the conversion is complete and ready to be cleared
   
;     LDS R24, ADCL   ; Store ADCL to R24, picked the register at random
;     LDS R25, ADCH   ; Store ADCH to R25, respectively, also picked the register at random
;     MOV R29, R25
;     RCALL printdigit
;     RCALL myDelay   ; Adds delay around 0.5s on each loop just in case for unintended behavior
;     RET

; myDelay:          ; Nested loop subroutine
;     LDI R23, 255  ; Outer loop counter
; l10: LDI R24, 255  ; mid loop counte
; l11: LDI R25, 41   ; inner loop counter to give 0.5s delay
; l12: DEC R25       ; decrement inner loop
;     BRNE l12       ; loop if not zero
;     DEC R24       ; decrement mid loop
;     BRNE l11       ; loop if not zero
;     DEC R23       ; decrement outer loop
;     BRNE l10       ; loop if not zero
;     RET           ; return to caller

print_ADC:
    LDI   R23, 48         ;constants used to get ASCII values
    LDI   R24, 7          ;for chars 0-->9 & A-->F
    ;-------------------------------------------------------------------
    LDI   R20, 0xC7       ;set ADSC in ADCSRA to start conversion
    STS   ADCSRA, R20
    ;-------------------------------------------------------------------
wait_ADC:
    LDS   R21, ADCSRA     ;check ADIF flag in ADCSRA
    SBRS  R21, 4          ;skip jump when conversion is done (flag set)
    RJMP  wait_ADC        ;loop until ADIF flag is set
    ;------------------------------------------------------------------
    LDI   R17, 0xD7       ;set ADIF flag again
    STS   ADCSRA, R17     ;so that controller clears ADIF
    ;------------------------------------------------------------------
    LDS   R16, ADCL       ;get low-byte result from ADCL
    LDS   R25, ADCH       ;get high-byte result from ADCH
    ;-----------------------------------------------------------------
    ADD   R25, R23        ;add 48 to byte to get ASCII char 0 to 9
    ;-----------------------------------------------------------------
l13: LDS   R17, UCSR0A
    SBRS  R17, UDRE0      ;test data buffer if data can be sent
    RJMP  l13
    ;-----------------------------------------------------------------
    STS   UDR0, R25       ;print ADC MSD on serial monitor
    ;-----------------------------------------------------------------
    PUSH  R16             ;store copy of ADCH in STACK register
    ANDI  R16, 0xF0       ;mask & extract high-nibble
    SWAP  R16             ;swap high-nibble with low-nibble
    ADD   R16, R23        ;add 48 to byte to get ASCII char 0 to 9
    MOV   R28, R16        ;store a copy of byte in R28
    SUBI  R28, 58         ;subtract 58 from R28
    BRPL  A_F_MSD         ;jump if result is +ve
    ;-----------------------------------------------------------------
l23: LDS   R17, UCSR0A
    SBRS  R17, UDRE0      ;test data buffer if data can be sent
    RJMP  l23
    ;-----------------------------------------------------------------
    STS   UDR0, R16       ;print ADC mid digit on serial monitor
    ;-----------------------------------------------------------------
    POP   R16             ;restore ADCH value from STACK register
    ANDI  R16, 0x0F       ;mask & extract low-nibble
    ADD   R16, R23
    MOV   R28, R16
    SUBI  R28, 58
    BRPL  A_F_LSD
    ;-----------------------------------------------------------------
l333: LDS   R17, UCSR0A
    SBRS  R17, UDRE0      ;test data buffer if data can be sent
    RJMP  l333
    ;-----------------------------------------------------------------
    STS   UDR0, R16       ;print ADC LSD on serial monitor
    ;-----------------------------------------------------------------
l43: LDS   R17, UCSR0A
    SBRS  R17, UDRE0      ;test data buffer if data can be sent
    RJMP  l43
    ;-----------------------------------------------------------------
    LDI   R18, 0x0A
    STS   UDR0, R18       ;print newline on serial monitor    
    ;-----------------------------------------------------------------
l53: LDS   R17, UCSR0A
    SBRS  R17, UDRE0      ;test data buffer if data can be sent
    RJMP  l53
    ;-----------------------------------------------------------------
    LDI   R18, 0x0D
    STS   UDR0, R18       ;print carriage return on serial monitor    
    ;-----------------------------------------------------------------
    RCALL delay_sec       ;1 second delay  
    ; RJMP  print_ADC
    RET
;=====================================================================
A_F_MSD:
    ADD   R16, R24        ;add 7 to byte to get ASCII chars A to F
    RJMP  l23
;---------------------------------------------------------------------
A_F_LSD:
    ADD   R16, R24        ;add 7 to byte to get ASCII chars A to F
    RJMP  l333
;---------------------------------------------------------------------
delay_sec:                ;1s delay
    LDI   R20, 255
l63: LDI   R21, 255
l73: LDI   R22, 80
l83: DEC   R22
    BRNE  l83   
    DEC   R21
    BRNE  l73
    DEC   R20
    BRNE  l63
    RET


agn:
    RCALL print_msg_ADC
    RCALL print_ADC
    RCALL delay_2s          ; wait for DHT11 to get ready
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

    ; Skip reading humidity
    RCALL DHT11_reading
    MOV R21, R18           ; Store temperature in R21
    MOV R26, R18

    RCALL DHT11_reading

    RCALL DHT11_reading
    
    

    ; Skip reading temperature decimal and checksum
    RCALL DHT11_reading
    RCALL DHT11_reading

    RCALL print_msg_DHT
    RCALL printdigit       ; Print temperature value

    CPI R26, 25
    BRLO pos_180_deg
    RJMP pos_0_deg

pos_180_deg:
    LDI   R24, 180        ; PWM pulse width for 180 degrees
    RCALL  rotate_servo
    RJMP complete

pos_0_deg:
    LDI   R24, 40         ; PWM pulse width for 0 degrees
    RCALL  rotate_servo
    RJMP complete

complete:
    RJMP agn                ; Add this to create the infinite loop
;===============================================================

rotate_servo:
;------------
    LDI   R20, 10         ; 10 PWM cycles for stability
l22: SBI   PORTB, 4
    RCALL delay_timer03
    CBI   PORTB, 4        ; Send pulse
    RCALL delay_20ms2      ; Wait 20ms before re-sending
    DEC   R20
    BRNE  l22              ; Repeat for stable positioning
    RET
;===============================================================
delay_timer03:             ; Timer0 delay
    CLR   R21
    OUT   TCNT0, R21      ; Initialize timer0
    MOV   R21, R24
    OUT   OCR0A, R21
    LDI   R21, 0b00001100
    OUT   TCCR0B, R21     ; Timer0: CTC mode, prescaler 256
l33: IN    R21, TIFR0
    SBRS  R21, OCF0A
    RJMP  l33
    CLR   R21
    OUT   TCCR0B, R21     ; Stop timer0
    LDI   R21, (1<<OCF0A)
    OUT   TIFR0, R21      ; Clear flag
    RET
;===============================================================
delay_20ms2:               ; 20ms delay
    LDI   R21, 255
l44: LDI   R22, 210
l55: LDI   R23, 2
l66: DEC   R23
    BRNE  l66
    DEC   R22
    BRNE  l55
    DEC   R21
    BRNE  l44
    RET

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
skp: LSL R18
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
l2: IN R20, TIFR0
    SBRS R20, OCF0A
    RJMP l2
    CLR R20
    OUT TCCR0B, R20
    LDI R20, (1<<OCF0A)
    OUT TIFR0, R20
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
l21: RET    


A_F_D1:
    SUBI  R16, -7                       ;R16 = R16 - (7) = R16 + 7
    JMP  l1


A_F_D0:
    SUBI  R16, -7                       ;R16 = R16 - (7) = R16 + 7
    JMP  l21

print_msg_ADC:
    LDI   R30, lo8(messagesADC)
    LDI   R31, hi8(messagesADC)            ;Z points to string message
    JMP agn3
print_msg_DHT:
    LDI   R30, lo8(messagesDHT)
    LDI   R31, hi8(messagesDHT)            ;Z points to string message
    JMP agn3
agn3:
    LPM   R18, Z+                       ;load char of string onto R18
    CPI   R18, 0                        ;check if R18=0 (end of string)
    BREQ  ext                           ;if yes, exit
    CALL LCD_buffer                     ;LCD buffer ready?
    STS   UDR0, R18                     ;send char in R18 to serial monitor
    JMP  agn3                          ;loop back & get next character
ext:
    RET                                 ;store the result

LCD_buffer:
    LDS   R27, UCSR0A
    SBRS  R27, UDRE0                    ; Wait until UDR0 is ready
    RJMP  LCD_buffer
    RET

    messagesADC:
        .ascii "ADC:"                       ; String to print
        .byte 10, 13, 0                      ; Newline and null terminator

    messagesDHT:
    .ascii "DHT:"                       ; String to print
    .byte 10, 13, 0                      