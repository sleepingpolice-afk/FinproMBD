
; Ide utama untuk servo
;===============================================================
#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global servo_motor       ; Import library servo
;===============================================================
servo_motor:
;-----------
    SBI   DDRB, 4         ; Output servo (Adjustable)
;---------------------------------------------------------------
wait_for_input:
    SBIC  PINB, 3         ; Check kalau PB3 (input) LOW (Ubah jadi input ADC maybe?)
    RJMP  pos_0_deg
    RJMP  pos_180_deg     ; Kalau HIGH, servo 180 derajat
;---------------------------------------------------------------
pos_0_deg:
    LDI   R24, 40         ; PWM pulse width for 0 degrees
    RJMP  rotate_servo
;---------------------------------------------------------------
pos_180_deg:
    LDI   R24, 180        ; PWM pulse width for 180 degrees
    RJMP  rotate_servo
;===============================================================

; DISCLAIMER: From this point forward, kode hasil copy-an

rotate_servo:
;------------
    LDI   R20, 10         ; 10 PWM cycles for stability
l2: SBI   PORTB, 4
    RCALL delay_timer0
    CBI   PORTB, 4        ; Send pulse
    RCALL delay_20ms      ; Wait 20ms before re-sending
    DEC   R20
    BRNE  l2              ; Repeat for stable positioning
    RJMP  wait_for_input
;===============================================================
delay_timer0:             ; Timer0 delay
    CLR   R21
    OUT   TCNT0, R21      ; Initialize timer0
    MOV   R21, R24
    OUT   OCR0A, R21
    LDI   R21, 0b00001100
    OUT   TCCR0B, R21     ; Timer0: CTC mode, prescaler 256
l3: IN    R21, TIFR0
    SBRS  R21, OCF0A
    RJMP  l3
    CLR   R21
    OUT   TCCR0B, R21     ; Stop timer0
    LDI   R21, (1<<OCF0A)
    OUT   TIFR0, R21      ; Clear flag
    RET
;===============================================================
delay_20ms:               ; 20ms delay
    LDI   R21, 255
l4: LDI   R22, 210
l5: LDI   R23, 2
l6: DEC   R23
    BRNE  l6
    DEC   R22
    BRNE  l5
    DEC   R21
    BRNE  l4
    RET
