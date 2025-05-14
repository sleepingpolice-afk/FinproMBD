;=======================
#define __SFR_OFFSET 0x00
#include "avr/io.h"
;=======================
.global SPI_MAX7219_init
.global MAX7219_disp_digits

;=======================
.equ SCK, 5
.equ MOSI, 3
.equ SS, 2

;=======================
SPI_MAX7219_init:
    LDI R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
    OUT DDRB, R17             ; Set MOSI, SCK, SS as output
    LDI R17, (1<<SPE)|(1<<MSTR)|(1<<SPR0)
    OUT SPCR, R17             ; Enable SPI Master, Fosc/16

    ; Initialize all 4 displays
    LDI R20, 0
init_loop:
    ; Intensity
    LDI R17, 0x0A
    LDI R18, 0x03
    RCALL send_bytes_chain

    ; Decode mode off
    LDI R17, 0x09
    LDI R18, 0x00
    RCALL send_bytes_chain

    ; Scan limit = all 8 digits
    LDI R17, 0x0B
    LDI R18, 0x07
    RCALL send_bytes_chain

    ; Shutdown mode off
    LDI R17, 0x0C
    LDI R18, 0x01
    RCALL send_bytes_chain

    INC R20
    CPI R20, 4
    BRNE init_loop

    RET

;=======================
; Send command/data to 1 of 4 displays in chain
; R17 = command, R18 = data, R20 = target display index (0–3)
send_bytes_chain:
    CBI PORTB, SS

    LDI R19, 3         ; 3 = leftmost chip
send_loop:
    CP R19, R20
    BREQ send_cmd_data

    ; Else send NOOP
    LDI R21, 0x00
    OUT SPDR, R21
wait1: IN R22, SPSR
    SBRS R22, SPIF
    RJMP wait1
    OUT SPDR, R21
wait2: IN R22, SPSR
    SBRS R22, SPIF
    RJMP wait2
    RJMP skip

send_cmd_data:
    OUT SPDR, R17
wait3: IN R22, SPSR
    SBRS R22, SPIF
    RJMP wait3
    OUT SPDR, R18
wait4: IN R22, SPSR
    SBRS R22, SPIF
    RJMP wait4

skip:
    DEC R19
    BRPL send_loop

    SBI PORTB, SS
    RET

;=======================
my_delay:
    LDI R21, 100
d1: LDI R22, 255
d2: LDI R23, 200
d3: DEC R23
    BRNE d3
    DEC R22
    BRNE d2
    DEC R21
    BRNE d1
    RET

;=======================
MAX7219_disp_digits:
loop_forever:
    LDI R24, 0          ; display index = 0
    LDI R25, 0          ; digit pattern index = 0
disp_loop:
    LDI R26, 8          ; 8 rows per digit
    LDI R30, lo8(digit0)
    LDI R31, hi8(digit0)
    MUL R25, R26        ; offset = digit index * 8
    ADD R30, R0
    ADC R31, R1

    LDI R17, 1          ; digit register = 1
row_loop:
    LPM R18, Z+
    MOV R20, R24        ; target display = R24
    RCALL send_bytes_chain
    INC R17
    DEC R26
    BRNE row_loop

    INC R24             ; next display
    INC R25             ; next digit
    CPI R24, 4
    BRNE disp_loop

    RCALL my_delay
    RJMP loop_forever

;=======================
digit0:
.byte 0b00000000,0b00011000,0b00100100,0b00100100
.byte 0b00100100,0b00100100,0b00011000,0b00000000

digit1:
.byte 0b00000000,0b00001000,0b00011000,0b00001000
.byte 0b00001000,0b00001000,0b00011100,0b00000000

digit2:
.byte 0b00000000,0b00011000,0b00100100,0b00001000
.byte 0b00010000,0b00100000,0b00111100,0b00000000

digit3:
.byte 0b00000000,0b00111000,0b00000100,0b00111000
.byte 0b00000100,0b00000100,0b00111000,0b00000000
