#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global setup_adc
.global rotate_servo
.global print_message

;===============================================================
; Setup ADC function yang dipanggil dari Arduino
;===============================================================
setup_adc:
    ; Inisialisasi ADC dengan interrupt
    SBI   DDRC, 0                       ; Set PC0 sebagai output untuk kontrol penyiraman
    LDI   R20, 0xC0                     ; Internal 2.56V, right-justified data, ADC0
    STS   ADMUX, R20
    LDI   R20, 0x8F                     ; ADEN=1, ADSC=1, ADATE=0, ADIF=0, ADIE=1, prescaler=111
    STS   ADCSRA, R20                   ; Enable ADC & interrupt
    RET

;===============================================================
; ADC Interrupt Service Routine
;===============================================================
.global ADC_vect
ADC_vect:
    PUSH  R16                           ; Simpan register yang digunakan
    PUSH  R17
    PUSH  R18
    PUSH  R19
    IN    R19, SREG                     ; Simpan Status Register
    PUSH  R19
    
    ; Baca nilai ADC
    LDS   R16, ADCL                     ; Baca nilai ADC Low byte
    LDS   R17, ADCH                     ; Baca nilai ADC High byte
    
    ; Threshold untuk kelembaban tanah
    LDI   R19, 150                      ; Threshold kelembaban rendah
    
    ; Bandingkan nilai ADC dengan threshold
    CPI   R17, 0                        ; Cek high byte
    BRNE  not_low_moisture              ; Jika > 255, tidak rendah
    CP    R16, R19                      ; Threshold kelembaban rendah
    BRSH  not_low_moisture              ; Jika >= 150, tidak rendah
    
    ; Kelembaban rendah - aktifkan penyiraman
    SBI   PORTC, 0                      ; Aktifkan output penyiraman
    
    ; Load alamat dari pesan
    LDI   R30, lo8(watering_msg)
    LDI   R31, hi8(watering_msg)
    ; Mencetak pesan menggunakan fungsi C
    PUSH  R30                           ; Simpan Z register
    PUSH  R31
    ; Panggil fungsi print_message C
    PUSH  R30                           ; Pass address sebagai parameter
    PUSH  R31
    CALL  print_message
    POP   R31                           ; Clean-up stack
    POP   R30
    POP   R31                           ; Restore Z register
    POP   R30
    
    ; Gerakkan servo untuk penyiraman
    LDI   R24, 180                      ; PWM untuk posisi penyiraman
    PUSH  R24
    CALL  rotate_servo
    POP   R24
    RJMP  adc_process_done
    
not_low_moisture:
    ; Kelembaban tidak rendah - matikan penyiraman
    CBI   PORTC, 0                      ; Matikan output penyiraman
    
    ; Cek apakah dalam status normal
    LDI   R19, 200                      ; Threshold kelembaban normal
    CP    R16, R19                      ; Bandingkan dengan nilai kelembaban
    BRLO  normal_moisture
    
    ; Kelembaban terlalu tinggi - tampilkan pesan
    LDI   R30, lo8(high_moisture_msg)
    LDI   R31, hi8(high_moisture_msg)
    PUSH  R30                           ; Pass address sebagai parameter
    PUSH  R31
    CALL  print_message
    POP   R31                           ; Clean-up stack
    POP   R30
    RJMP  adc_process_done
    
normal_moisture:
    ; Kelembaban normal - tampilkan pesan
    LDI   R30, lo8(normal_moisture_msg)
    LDI   R31, hi8(normal_moisture_msg)
    PUSH  R30                           ; Pass address sebagai parameter
    PUSH  R31
    CALL  print_message
    POP   R31                           ; Clean-up stack
    POP   R30
    
adc_process_done:
    ; Mulai konversi ADC berikutnya
    LDI   R18, 0x8F                     ; ADEN=1, ADSC=1, ADIE=1, prescaler=111 (0x8F = 10001111b)
    STS   ADCSRA, R18
    
    POP   R19                           ; Restore Status Register
    OUT   SREG, R19
    POP   R19                           ; Kembalikan register yang digunakan
    POP   R18
    POP   R17
    POP   R16
    RETI                                ; Return dari interrupt

;===============================================================
; Pesan status untuk level moisture
;===============================================================
watering_msg:
    .ascii "WATERING: Moisture level too low! Activating irrigation system..."
    .byte 0
    
normal_moisture_msg:
    .ascii "STATUS: Moisture level normal. System idle."
    .byte 0
    
high_moisture_msg:
    .ascii "STATUS: Moisture level high. No watering needed."
    .byte 0