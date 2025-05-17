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

    RJMP agn                            ; Jump to agn to start the loop

agn:
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
    RCALL DHT11_reading

    RCALL DHT11_reading
    MOV R21, R18           ; Store temperature in R21
    

    ; Skip reading temperature decimal and checksum
    RCALL DHT11_reading
    RCALL DHT11_reading

    RCALL printdigit       ; Print temperature value
    RJMP agn                ; Add this to create the infinite loop
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