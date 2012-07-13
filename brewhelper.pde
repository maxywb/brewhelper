#include <LiquidCrystal.h>
#include <LCDKeypad.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include "pitches.h"

//possible actions/menus
#define TOP_POS      0 
#define ALARM_POS    1
#define TEMP_POS     2
#define KEEP_POS     3
#define WARN_POS     4
//menu text
#define TOP_TEXT     "Alarm       Temp"
#define ALARM_TEXT   "Keep        Warn"
#define KEEP_TEXT    " <= "
#define WARN_TEXT    "Warn at: "
#define CUR_TEMP     "    (f): "
//misc
#define TEMP_MOVE   .1
#define DEFAULT_WARN 80
#define DEFAULT_UP   158
#define DEFAULT_LOW  150
#define ONE_WIRE_BUS 3
#define LED          2
#define SPEAKER      11
//globals
byte curMenu;
LCDKeypad lcd;
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
DeviceAddress thermoAddr = { 
  0x28, 0x43, 0xEB, 0x1B, 0x3, 0x0, 0x0, 0xD0};
//0x28, 0xc4, 0xf9, 0x1b, 0x03, 0x00, 0x00, 0x40 };

void flashLed(int pin, int times, int wait) {
  int i=0;
  for (i = 0; i < times; i++) {
    digitalWrite(pin, HIGH);
    delay(wait);
    digitalWrite(pin, LOW);

    if (i + 1 < times) {
      delay(wait);
    }
  }
}

void printTemperature(DeviceAddress deviceAddress)
{
  sensors.requestTemperatures();
  float tempC = sensors.getTempC(deviceAddress);
  if (tempC == -127.00) {
    lcd.print("Error getting temperature");
  } 
  else {
    lcd.print("C:");
    lcd.print(tempC);
    lcd.print(" F:");
    lcd.print(DallasTemperature::toFahrenheit(tempC));
  }
}

void showTemp(){
  lcd.clear();
  while(lcd.button() != KEYPAD_SELECT){
    lcd.setCursor(0,0);
    printTemperature(thermoAddr);   
    delay(100);
  } 
  lcd.clear();
}
void showWarn(){
  float warnTemp = DEFAULT_WARN;
  float curTemp;
  lcd.clear();
  while(lcd.button() != KEYPAD_SELECT){
    sensors.requestTemperatures();
    curTemp = sensors.getTempF(thermoAddr);
    lcd.setCursor(0,0);
    lcd.print(WARN_TEXT);
    lcd.print(warnTemp);
    lcd.setCursor(0,1);
    lcd.print(CUR_TEMP);
    lcd.print(curTemp); 
    switch(lcd.button()){
    case KEYPAD_UP:
      warnTemp += TEMP_MOVE;
      break;
    case KEYPAD_DOWN:
      warnTemp -= TEMP_MOVE;
      break;
    case KEYPAD_RIGHT:
      warnTemp += TEMP_MOVE*10;
      break;
    case KEYPAD_LEFT:
      warnTemp -= TEMP_MOVE*10;
      break;
    default:
      break;
    }
    if( curTemp <= warnTemp && curTemp > 0)
      playAlarm();
    else
      delay(100);
  } 
  lcd.clear();
}

#define CHANGE_UP  1
#define CHANGE_LOW 0

void showKeep(){
  int choices[] = {
    DEFAULT_LOW,DEFAULT_UP              };
  byte curChoice = CHANGE_LOW;
  float curTemp;
  lcd.clear();
  while(lcd.button() != KEYPAD_SELECT){
    sensors.requestTemperatures();
    curTemp = sensors.getTempF(thermoAddr);
    lcd.setCursor(0,0);
    lcd.print(choices[CHANGE_LOW]);
    lcd.print(KEEP_TEXT);
    lcd.print(choices[CHANGE_UP]);
    lcd.setCursor(0,1);
    lcd.print(CUR_TEMP);
    lcd.print(curTemp); 
    switch(lcd.button()){
    case KEYPAD_UP:
      choices[curChoice] += 1;
      break;
    case KEYPAD_DOWN:
      choices[curChoice] -= 1;
      break;
    case KEYPAD_RIGHT:
      curChoice = CHANGE_UP;
      break;
    case KEYPAD_LEFT:
      curChoice = CHANGE_LOW;
      break;
    default:
      break;
    }
    if(curTemp > 0 && (curTemp < choices[0] || curTemp > choices[1]))
      playAlarm();
    else
      delay(100);
  } 
  lcd.clear();
}

void playAlarm(){
  short note = NOTE_C4;
  int duration = 1000/4;
  tone(SPEAKER,note,duration);
  delay(note*1.3);
  noTone(SPEAKER);
}

void playMelody(short *melody,byte *noteDurations,byte len){
  // iterate over the notes of the melody:
  for (byte thisNote = 0; thisNote < len; thisNote++) {

    // to calculate the note duration, take one second 
    // divided by the note type.
    //e.g. quarter note = 1000 / 4, eighth note = 1000/8, etc.
    int noteDuration = 1000/noteDurations[thisNote];
    tone(SPEAKER, melody[thisNote],noteDuration);

    // to distinguish the notes, set a minimum time between them.
    // the note's duration + 30% seems to work well:
    int pauseBetweenNotes = noteDuration * 1.30;
    delay(pauseBetweenNotes);
    // stop the tone playing:
    noTone(SPEAKER);
  }
}
void playZelda(){
  short verse1[]   = {
    NOTE_D4,NOTE_F4,NOTE_D5          };
  byte duration1[] = {
    8,8,2          };
  byte len1        = 3;

  short verse2[]   = {
    NOTE_E5,NOTE_F5,NOTE_E5,NOTE_F5,NOTE_E5,NOTE_D5,NOTE_A4        };
  byte duration2[] = {
    3,8,8,8,8,8,2          };
  byte len2        = 7;

  short verse3[]   = {
    NOTE_A4, NOTE_D4,NOTE_F4,NOTE_G4,NOTE_A4        };
  byte duration3[] = {
    4,4,8,8,2          };
  byte len3        = 5;

  short verse4[]   = {
    NOTE_A4, NOTE_D4,NOTE_F4,NOTE_G4,NOTE_E4        };
  byte duration4[] = {
    4,4,8,8,2          };
  byte len4        = 5;

  short verse5[]   = {
    NOTE_A4,NOTE_D4,NOTE_F4,NOTE_G4,NOTE_A4,NOTE_A4,NOTE_D4        };
  byte duration5[] = {
    4,4,8,8,2,4,1          };
  byte len5        = 7;

  //song
  playMelody(verse1,duration1,len1);
  playMelody(verse1,duration1,len1);
  playMelody(verse2,duration2,len2);
  playMelody(verse3,duration3,len3);
  playMelody(verse4,duration4,len4);
  playMelody(verse1,duration1,len1);
  playMelody(verse1,duration1,len1);
  playMelody(verse2,duration2,len2);
  playMelody(verse5,duration5,len5);
}
void setup()
{
  playAlarm();
  pinMode(LED, OUTPUT);
  lcd.begin(16, 2);
  lcd.clear();
  lcd.print("start");
  delay(500);
  lcd.clear();
  curMenu = TOP_POS;
}

void doMenu(){
  switch (curMenu) {
  case TEMP_POS:
    showTemp();
    curMenu = TOP_POS;
    break;
  case KEEP_POS:
    showKeep();
    curMenu = TOP_POS;
    break;
  case WARN_POS:
    showWarn();
    curMenu = TOP_POS;
    break;
  case TOP_POS:
    lcd.print(TOP_TEXT); 
    break;
  case ALARM_POS:
    lcd.print(ALARM_TEXT);
  }
}

void doAction(){
  switch(waitButton()){
  case KEYPAD_LEFT:
    switch(curMenu){
    case TOP_POS:
      curMenu = ALARM_POS;
      break;
    case ALARM_POS:
      curMenu =  KEEP_POS;
    default:
      break;
    }    
    break;
  case KEYPAD_RIGHT:
    switch(curMenu){
    case TOP_POS:
      curMenu = TEMP_POS;
      break;
    case ALARM_POS:
      curMenu =  WARN_POS;
    default:
      break;
    }    
    break;
  case KEYPAD_DOWN:
    if(curMenu == TOP_POS)
      playZelda();
    break;
  case KEYPAD_SELECT:
  case KEYPAD_UP:
  default:
    break;
  }
}

void loop()
{
  lcd.setCursor(0,0);
  doMenu();
  doAction();
  delay(500);
}

int waitButton()
{
  int buttonPressed; 
  waitReleaseButton;
  lcd.blink();
  while((buttonPressed=lcd.button())==KEYPAD_NONE)
  {
  }
  delay(50);  
  lcd.noBlink();
  return buttonPressed;
}

void waitReleaseButton()
{
  delay(50);
  while(lcd.button()!=KEYPAD_NONE)
  {
  }
  delay(50);
}























