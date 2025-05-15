;=======================
#define __SFR_OFFSET 0x00
#include "avr/io.h"
;=======================
.global main

;=======================
.equ SCK, 5
.equ MOSI, 3
.equ SS, 2

MAX7219_disp_digits2:
loop_forever2:
    LDI R24, 0          ; display index = 0
    LDI R25, 0          ; digit pattern index = 0
disp_loop2:
    LDI R26, 8          ; 8 rows per digit
    LDI R30, lo8(digit4)
    LDI R31, hi8(digit4)
    MUL R25, R26        ; offset = digit index * 8
    ADD R30, R0
    ADC R31, R1

    LDI R17, 1          ; digit register = 1
row_loop2:
    LPM R18, Z+
    MOV R20, R24        ; target display = R24
    RCALL send_bytes_chain
    INC R17
    DEC R26
    BRNE row_loop2

    INC R24             ; next display
    INC R25             ; next digit
    CPI R24, 4
    BRNE disp_loop2

    RCALL my_delay
    ;RJMP loop_forever2
    RET

;=======================


digit4:
.byte 0b00000000,0b00010000,0b00110000,0b01010000
.byte 0b10010000,0b11111110,0b00010000,0b00000000

digit5:
.byte 0b00000000,0b01111110,0b01000000,0b01111100
.byte 0b00000010,0b00000010,0b01111100,0b00000000

digit6:
.byte 0b00000000,0b00111000,0b01000000,0b01111100
.byte 0b01000010,0b01000010,0b00111000,0b00000000


digit7:
.byte 0b00000000,0b01111110,0b00000000,0b00000000
.byte 0b10000001,0b00000000,0b00000000,0b00000000



;=======================
main:
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

again:
    RCALL MAX7219_disp_digits1
    RCALL my_delay
    RCALL MAX7219_disp_digits2
    RCALL my_delay
    jmp again

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
MAX7219_disp_digits1:
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
    ;RJMP loop_forever
    RET

;=======================
digit0:
.byte 0b00000000,0b01010101,0b10101010,0b01010101
.byte 0b10101010,0b01010101,0b00000000,0b00000000

digit1:
.byte 0b00000000,0b01111100,0b01000010,0b01000010
.byte 0b01111100,0b01001000,0b01000100,0b00000000

digit2:
.byte 0b00000000,0b01111110,0b00011000,0b00011000
.byte 0b00011000,0b00011000,0b01111110,0b00000000

digit3:
.byte 0b00000000,0b00011100,0b00100010,0b00100010
.byte 0b00111110,0b00100010,0b00100010,0b00000000
