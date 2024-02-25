;========================================================================
.def MODE = R18						; สำหรับเก็บสถานะจาก PINC
.def TMP1 = R20						; สำหรับกำหนด I/O port
.def TMP2 = R21						; สำหรับอ่านค่า BCH จาก Switch
.def INCDEC = R22					; สำหรับบันทึกค่าเลขปัจจุบัน
.def INPUT_BCH = R25				; ใช้เป็นพารามิเตอร์นําเข้า
.def OUTPUT7SEG = R25				; ใช้เป็นพารามิเตอร์ส่งออก
;========================================================================
.cseg								; เริ่มการทำงานแบบ CodeSegment
.org 0x0000							; ให้ Pointer ชี้ไปที่ตำแหน่ง 0x0000 ใน memory
;========================================================================
start: 	
		ldi		TMP1, 0b00111111	; ตั้งจำนวน port-b ที่จะใช้  (a, b, c, d, e, f)
		out		DDRB, TMP1
		ldi		TMP1, 0b11000000	; ตั้งจำนวน port-d ที่จะใช้  (g, dp)
		out		DDRD, TMP1
		ldi		TMP1, 0b11000000	; ตั้งจำนวน port-c ที่จะใช้  (PC0-PC3 as Input-BCH),
		out		DDRC, TMP1			;					   (PC4-PC5 as Input-Mode)
		eor		R25,  R25			; กำหนดค่าเริ่มต้นของ INPUT, OUTPUT เป็น 0
		eor		R22,  R22			; กำหนดค่าเริ่มต้นของ INC, DEC เป็น 0
;========================================================================
loop: 	
		rcall	MCHECK				; ตรวจสอบสถานะ Switch-2
		rcall	SELECT				; เลือก mode การทำงาน
		rjmp	loop
;========================================================================
MCHECK:
		in		MODE,	PINC		; บันทึกค่า SW2 จาก PD4
		lsr		MODE				; เลื่อนบิตไปขวา
		lsr		MODE				; เลื่อนบิตไปขวา
		lsr		MODE				; เลื่อนบิตไปขวา
		lsr		MODE				; เลื่อนบิตไปขวา
		andi	MODE,	0x03		; กรองให้เหลือแค่ INPUT ของ Mode (PC4-PC5)
		ret
;========================================================================
SELECT:
		cpi		MODE,		0x00	; Switch-2 ปิดหมด
        breq	READ_SW				; อ่านค่า BCH จาก Switch-1
		rcall	INC_MODE			; เช็คต่อว่าสถานะ Switch-2 เป็นอะไร
		rjmp	loop
INC_MODE:
		cpi		MODE,		0x01	; Switch-2 เปิดอันแรก
		breq	INCREASE			; แสดงการเพิ่มขึ้นจาก 0-F ทีละ 1
		rcall	DEC_MODE			; เช็คต่อว่าสถานะ Switch-2 เป็นอะไร
		rjmp	loop
DEC_MODE:
		cpi		MODE,		0x02	; Switch-2 เปิดอันที่สองเปิด
		breq	DECREASE			; แสดงการเพิ่มลดจาก F-0 ทีละ 1
		rcall	READ_SW				; Switch-2 เปิดทุกอันให้อ่านค่า BCH จาก Switch-1
		rjmp	loop
READ_SW:
		rcall	INPUT_FILTER		; กรองเอาแค่ PB0-PB3
		rcall	Display				; แสดงผลไปยัง 7-SEG
		rjmp	READ_SW
;========================================================================
INPUT_FILTER:
		in		TMP2,		PINC	; นำค่าที่อ่านจาก PC0-PC3 มากรองแค่ 4 บิตแรก
		ldi		INPUT_BCH,	0x0F	; เติม 0b00001111
		and		INPUT_BCH,	TMP2	; ลบค่าบิตสูงออก
		ret
;========================================================================
INCREASE:
		cpi		INCDEC,		0x0F	; ตรวจว่าปัจจุบันเกิน F ไหม
		breq	INC_REST			; มากกว่า F ทำการรีเซ็ตค่า
		inc		INCDEC				; น้อยกว่า F ให้เพิ่ม +1
		mov		INPUT_BCH,	INCDEC	; อัพเดตเลขปัจจุบัน
		rjmp	Display				; นำผลลัพธ์ไปแสดงบน 7-Seg
INC_REST:
		ldi		INCDEC, 	0x00	; เปลี่ยนให้เป็น 0
		mov		INPUT_BCH,	INCDEC	; อัพเดตเลขปัจจุบัน
		rjmp	Display				; นำผลลัพธ์ไปแสดงบน 7-Seg
;========================================================================
DECREASE:
		cpi		INCDEC,		0x00	; ตรวจว่าปัจจุบันเป็น 0 ไหม
		breq	DEC_REST			; มากกว่า 0 ทำการรีเซ็ตค่า
		dec		INCDEC				; น้อยกว่า 0 ให้ลด -1
		mov		INPUT_BCH,	INCDEC	; อัพเดตเลขปัจจุบัน
		rjmp	Display				; นำผลลัพธ์ไปแสดงบน 7-Seg
DEC_REST:
		ldi		INCDEC, 	0x0F	; เปลี่ยนให้เป็น F
		mov		INPUT_BCH,	INCDEC	; อัพเดตเลขปัจจุบัน
		rjmp	Display				; นำผลลัพธ์ไปแสดงบน 7-Seg
;========================================================================
Display:
		rcall 	DISP_7SEG			; แสดงผลลัพธ์บน 7-Seg
		rcall	DELAY_500MS			; หน่วงเวลา 0.5 วินาที
		rjmp 	loop
;========================================================================
DISP_7SEG:
		call	BIN_TO_7SEG			; แปลง bits เป็นสัญญาณขาของ 7-Seg
		out		PORTD,	OUTPUT7SEG	; ส่งสัญญาณขา PB (a - f)
		out		PORTB,	OUTPUT7SEG	; ส่งสัญญาณขา PD (g, dp)
		ret
;========================================================================
BIN_TO_7SEG:
        push	ZL					; เก็บค่าของเรจิสเตอร์ ZL ไว้ในสแต็ก
        push	ZH					; เก็บค่าของเรจิสเตอร์ ZL ไว้ในสแต็ก
        push	R0					; เก็บค่าของเรจิสเตอร์ R0 ไว้ในสแต็ก	
        sub		R0,		R0			; ตั้งให้เรจิสเตอร์ R0 มีค่าเท่ากับศูนย์
        rjmp	LOOK_TABLE			; กระโดดข้ามตารางค้นหาไปยังป้าย LOOK_TABLE
;========================================================================
;---ส่วนนี้ของโปรแกรมเป็นการเก็บตารางค้นหาของค่ารหัสการติดดับของแอลอีดีชนิด 7-Segment---;
TB_7SEG:.DB 0b00111111, 0b00000110	; 0 และ 1	----a----
        .DB 0b01011011, 0b01001111	; 2 และ 3	f       b
        .DB 0b01100110, 0b01101101	; 4 และ 5	----g----
        .DB 0b01111101, 0b00000111	; 6 และ 7	e       c
        .DB 0b01111111, 0b01101111	; 8 และ 9	----d----
        .DB 0b01110111, 0b01111100	; A และ B
        .DB 0b00111001, 0b01011110	; C และ D
        .DB 0b01111001, 0b01110001	; E และ F
        .DB 0b01001001, 0b00110110	; special value
;========================================================================
LOOK_TABLE: ldi ZL, low(TB_7SEG*2)	; บรรจุค่าตําแหน่งไบต์ต่ําของ TB_7SEG ใส่ ZL
			ldi ZH, high(TB_7SEG*2)	; บรรจุค่าตําแหน่งไบต์สูงของ TB_7SEG ใส่ ZH
			add ZL, INPUT_BCH		; บวกค่า ZL ด้วยค่ารหัสบีซีดีอินพุต
			adc ZH, R0				; บวกค่าที่อาจมีการทดใน Carry ใส่ใน ZH
			lpm						; อ่านหน่วยความจําโปรแกรมที่ Z ชี้อยู่ใส่ใน R0
			mov OUTPUT7SEG, R0		; ส่งค่าใน R0 ไปยังเรจิสเตอร์สําหรับคืนค่า
			pop R0					; อ่านค่าเก่าของ R0 คืนมาจากสแต็ก
			pop ZH					; อ่านค่าเก่าของ ZH คืนมาจากสแต็ก
			pop ZL					; อ่านค่าเก่าของ ZL คืนมาจากสแต็ก
			ret
;========================================================================
;---------------ซับรูทีนสำหรับหน่วงเวลา 10 มิลลิวินาที (CPU 16 MHz)---------------;
DELAY10MS:
			push	R16				
			push	R17
			ldi		R16, 	0x00
LOOP2:		inc		R16
			ldi		R17,  	0x00
LOOP1:		inc		R17
			cpi		R17, 	249
			brlo	LOOP1
			nop
			cpi		R16, 	160
			brlo	LOOP2
			pop		R17
			pop		R16
			ret
;========================================================================
;---------------ซับรูทีนสำหรับหน่วงเวลา 500 มิลลิวินาที (CPU 16 MHz)--------------;
DELAY_500MS:
			ldi R16, 50			; 100 x 10 milliseconds = 500 milliseconds
delay_loop:
			rcall DELAY10MS		; เรียกใช้ซับรูทีน DELAY10MS
			dec R16				; ลดค่า R16 ลงทีละ 1
			brne delay_loop		; เมื่อครบรอบตามที่กำหนดเป็นการจบ Delay
			ret
;========================================================================