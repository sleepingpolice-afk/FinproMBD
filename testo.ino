//----------------------------------------------
// Assembly via Arduino - MAX7219 8x8 Dot Matrix
//----------------------------------------------
extern "C"
{
  void SPI_MAX7219_init();
  void MAX7219_disp_digits();
}
//----------------------------------------------
void setup()
{
  SPI_MAX7219_init();
  MAX7219_disp_digits();
}
//----------------------------------------------
void loop(){}