#include <SPI.h>
#include <MFRC522.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Servo.h>

#define RST_PIN 9
#define SS_PIN 10
#define BUZZER_PIN 8
#define SERVO_PIN 7
#define TRIG_PIN 6
#define ECHO_PIN 5

MFRC522 rfid(SS_PIN, RST_PIN);
LiquidCrystal_I2C lcd(0x27, 16, 2);
Servo gateServo;

void setup() {
  Serial.begin(9600);
  SPI.begin();
  rfid.PCD_Init();

  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  gateServo.attach(SERVO_PIN);

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Scan your card...");
  Serial.println("System Ready. Scan your RFID card...");
}

void loop() {
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) {
    return;
  }

  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();

  Serial.print("Card UID: ");
  Serial.println(uid);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Card Scanned...");
  delay(1000);

  if (uid == "B7F2068") {  // ✅ Valid UID
    lcd.setCursor(0, 1);
    lcd.print("Gate Opening...");
    openGate();

    bool detected = false;
    unsigned long startTime = millis();

    while (millis() - startTime < 5000) {
      long distance = getDistance();

      if (distance > 0) {
        Serial.print("Distance: ");
        Serial.print(distance);
        Serial.println(" cm");

        if (distance <= 3) {  // ✅ Detect within 3 cm (safe for accuracy)
          detected = true;
          break;
        }
      } else {
        Serial.println("No echo received.");
      }

      delay(100);  // Small delay for sensor stability
    }

    if (detected) {
      markAttendance(uid);
    } else {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("No one Detected");
      lcd.setCursor(0, 1);
      lcd.print("Try Again!");
      Serial.println("❌ No person detected in range.");
      tone(BUZZER_PIN, 300, 700);
    }

    delay(5000);
    closeGate();

  } else {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Unknown Card");
    lcd.setCursor(0, 1);
    lcd.print("Access Denied");

    Serial.println("Unknown Card - Access Denied");
    Serial.println("Scanned UID: " + uid);
    tone(BUZZER_PIN, 500, 700);
  }

  delay(2000);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Scan your card...");
  rfid.PICC_HaltA();
}

void markAttendance(String uid) {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Hello Nishant");
  lcd.setCursor(0, 1);
  lcd.print("Attendance Done");

  Serial.println("✅ Attendance Marked for Vagish");
  tone(BUZZER_PIN, 1000, 200);
}

void openGate() {
  gateServo.write(100);
  Serial.println("🟢 Gate Opened");
}

void closeGate() {
  gateServo.write(0);
  Serial.println("🔴 Gate Closed");
}

long getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);  // 30ms timeout
  if (duration == 0) return -1;  // No echo received

  long distance = duration * 0.034 / 2;
  return distance;
}
