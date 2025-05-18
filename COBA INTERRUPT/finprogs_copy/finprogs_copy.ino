#include <avr/io.h>
#include <avr/interrupt.h>
#include <Servo.h>

// Definisi pin
#define MOISTURE_SENSOR_PIN 0  // ADC0
#define PUMP_CONTROL_PIN 0     // PC0
#define SERVO_PIN 9            // Pin untuk servo

// Threshold values
#define MOISTURE_LOW_THRESHOLD 150
#define MOISTURE_HIGH_THRESHOLD 200

// Definisikan servo
Servo irrigationServo;

// Deklarasi fungsi external dari assembly
extern "C" {
  void setup_adc();
}

void setup() {
  // Inisialisasi Serial
  Serial.begin(9600);
  Serial.println("Plant Monitoring System Starting...");
  
  // Setup servo
  irrigationServo.attach(SERVO_PIN);
  irrigationServo.write(0); // Posisi awal
  
  // Setup ADC menggunakan fungsi assembly
  setup_adc();
  
  // Aktifkan global interrupt
  sei();
}

void loop() {
  // Main loop kosong karena semua ditangani oleh interrupt
  delay(1000);
}

// Fungsi untuk menggerakkan servo dari assembly
void rotate_servo(uint8_t angle) {
  irrigationServo.write(angle);
}

// Fungsi untuk mencetak pesan dari assembly
void print_message(const char* msg) {
  Serial.println(msg);
}