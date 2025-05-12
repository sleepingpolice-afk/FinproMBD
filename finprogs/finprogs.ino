#include <avr/io.h>
#include <avr/interrupt.h>

#define THRESHOLD 700  // Threshold value for ADC reading (out of 1024)

// Function to initialize ADC
void ADC_init()
{
    // Set ADC prescaler to 64 for ADC clock (this is suitable for 8 MHz clock)
    // ADC needs a clock between 50 kHz and 200 kHz, 64 prescaler gives ~125 kHz with 8 MHz system clock
    ADCSRA |= (1 << ADPS2) | (1 << ADPS1);

    // Set reference voltage to AVcc and ADC3 as the input channel (MUX3 = 1, MUX2 = 0, MUX1 = 0, MUX0 = 1)
    ADMUX |= (1 << MUX3);  // Select ADC3 as input channel

    // Enable the ADC and ADC interrupt
    ADCSRA |= (1 << ADEN) | (1 << ADIE);  // Enable ADC and ADC interrupt

    // Start an initial ADC conversion to kick things off
    ADCSRA |= (1 << ADSC);  // Start first conversion
}

// Function to initialize the IO pins (PB2 for LED)
void IO_init()
{
    // Set PB2 as an output (for the LED)
    DDRB |= (1 << PB2);
    // Set PB2 to low initially (LED off)
    PORTB &= ~(1 << PB2);
}

// Function to start ADC conversion
void ADC_start_conversion()
{
    // Start the ADC conversion
    ADCSRA |= (1 << ADSC);
}

// Main function
int main(void)
{
    // Initialize ADC and IO
    ADC_init();
    IO_init();

    // Enable global interrupts
    sei();  // Enable global interrupt flag

    // Main loop
    while (1)
    {
        // Do other tasks here, or simply wait for the ADC interrupt to occur
        // The ISR will handle the ADC reading and LED control
    }
}

// ADC Conversion Complete Interrupt Service Routine
ISR(ADC_vect)
{
    // Read the ADC result (16-bit result stored in ADCL and ADCH)
    uint16_t adc_result = ADC;  // ADC value (10-bit result)

    // If the ADC result is greater than the threshold, turn on LED
    if (adc_result > THRESHOLD)
    {
        // Turn on LED connected to PB2
        PORTB |= (1 << PB2);
    }
    else
    {
        // Turn off LED
        PORTB &= ~(1 << PB2);
    }

    // Start the next ADC conversion
    ADC_start_conversion();
}
