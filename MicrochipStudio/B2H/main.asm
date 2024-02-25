;========================================================================
.def MODE = R18						; ����Ѻ��ʶҹШҡ PINC
.def TMP1 = R20						; ����Ѻ��˹� I/O port
.def TMP2 = R21						; ����Ѻ��ҹ��� BCH �ҡ Switch
.def INCDEC = R22					; ����Ѻ�ѹ�֡����Ţ�Ѩ�غѹ
.def INPUT_BCH = R25				; ���繾��������������
.def OUTPUT7SEG = R25				; ���繾������������͡
;========================================================================
.cseg								; �������÷ӧҹẺ CodeSegment
.org 0x0000							; ��� Pointer ���价����˹� 0x0000 � memory
;========================================================================
start: 	
		ldi		TMP1, 0b00111111	; ��駨ӹǹ port-b ������  (a, b, c, d, e, f)
		out		DDRB, TMP1
		ldi		TMP1, 0b11000000	; ��駨ӹǹ port-d ������  (g, dp)
		out		DDRD, TMP1
		ldi		TMP1, 0b11000000	; ��駨ӹǹ port-c ������  (PC0-PC3 as Input-BCH),
		out		DDRC, TMP1			;					   (PC4-PC5 as Input-Mode)
		eor		R25,  R25			; ��˹����������鹢ͧ INPUT, OUTPUT �� 0
		eor		R22,  R22			; ��˹����������鹢ͧ INC, DEC �� 0
;========================================================================
loop: 	
		rcall	MCHECK				; ��Ǩ�ͺʶҹ� Switch-2
		rcall	SELECT				; ���͡ mode ��÷ӧҹ
		rjmp	loop
;========================================================================
MCHECK:
		in		MODE,	PINC		; �ѹ�֡��� SW2 �ҡ PD4
		lsr		MODE				; ����͹�Ե仢��
		lsr		MODE				; ����͹�Ե仢��
		lsr		MODE				; ����͹�Ե仢��
		lsr		MODE				; ����͹�Ե仢��
		andi	MODE,	0x03		; ��ͧ���������� INPUT �ͧ Mode (PC4-PC5)
		ret
;========================================================================
SELECT:
		cpi		MODE,		0x00	; Switch-2 �Դ���
        breq	READ_SW				; ��ҹ��� BCH �ҡ Switch-1
		rcall	INC_MODE			; �礵�����ʶҹ� Switch-2 ������
		rjmp	loop
INC_MODE:
		cpi		MODE,		0x01	; Switch-2 �Դ�ѹ�á
		breq	INCREASE			; �ʴ����������鹨ҡ 0-F ���� 1
		rcall	DEC_MODE			; �礵�����ʶҹ� Switch-2 ������
		rjmp	loop
DEC_MODE:
		cpi		MODE,		0x02	; Switch-2 �Դ�ѹ����ͧ�Դ
		breq	DECREASE			; �ʴ��������Ŵ�ҡ F-0 ���� 1
		rcall	READ_SW				; Switch-2 �Դ�ء�ѹ�����ҹ��� BCH �ҡ Switch-1
		rjmp	loop
READ_SW:
		rcall	INPUT_FILTER		; ��ͧ����� PB0-PB3
		rcall	Display				; �ʴ�����ѧ 7-SEG
		rjmp	READ_SW
;========================================================================
INPUT_FILTER:
		in		TMP2,		PINC	; �Ӥ�ҷ����ҹ�ҡ PC0-PC3 �ҡ�ͧ�� 4 �Ե�á
		ldi		INPUT_BCH,	0x0F	; ��� 0b00001111
		and		INPUT_BCH,	TMP2	; ź��ҺԵ�٧�͡
		ret
;========================================================================
INCREASE:
		cpi		INCDEC,		0x0F	; ��Ǩ��һѨ�غѹ�Թ F ���
		breq	INC_REST			; �ҡ���� F �ӡ�����絤��
		inc		INCDEC				; ���¡��� F ������� +1
		mov		INPUT_BCH,	INCDEC	; �Ѿവ�Ţ�Ѩ�غѹ
		rjmp	Display				; �Ӽ��Ѿ����ʴ��� 7-Seg
INC_REST:
		ldi		INCDEC, 	0x00	; ����¹����� 0
		mov		INPUT_BCH,	INCDEC	; �Ѿവ�Ţ�Ѩ�غѹ
		rjmp	Display				; �Ӽ��Ѿ����ʴ��� 7-Seg
;========================================================================
DECREASE:
		cpi		INCDEC,		0x00	; ��Ǩ��һѨ�غѹ�� 0 ���
		breq	DEC_REST			; �ҡ���� 0 �ӡ�����絤��
		dec		INCDEC				; ���¡��� 0 ���Ŵ -1
		mov		INPUT_BCH,	INCDEC	; �Ѿവ�Ţ�Ѩ�غѹ
		rjmp	Display				; �Ӽ��Ѿ����ʴ��� 7-Seg
DEC_REST:
		ldi		INCDEC, 	0x0F	; ����¹����� F
		mov		INPUT_BCH,	INCDEC	; �Ѿവ�Ţ�Ѩ�غѹ
		rjmp	Display				; �Ӽ��Ѿ����ʴ��� 7-Seg
;========================================================================
Display:
		rcall 	DISP_7SEG			; �ʴ����Ѿ�캹 7-Seg
		rcall	DELAY_500MS			; ˹�ǧ���� 0.5 �Թҷ�
		rjmp 	loop
;========================================================================
DISP_7SEG:
		call	BIN_TO_7SEG			; �ŧ bits ���ѭ�ҳ�Ңͧ 7-Seg
		out		PORTD,	OUTPUT7SEG	; ���ѭ�ҳ�� PB (a - f)
		out		PORTB,	OUTPUT7SEG	; ���ѭ�ҳ�� PD (g, dp)
		ret
;========================================================================
BIN_TO_7SEG:
        push	ZL					; �纤�Ңͧ�è������ ZL �������
        push	ZH					; �纤�Ңͧ�è������ ZL �������
        push	R0					; �纤�Ңͧ�è������ R0 �������	
        sub		R0,		R0			; �������è������ R0 �դ����ҡѺ�ٹ��
        rjmp	LOOK_TABLE			; ���ⴴ�������ҧ������ѧ���� LOOK_TABLE
;========================================================================
;---��ǹ���ͧ������繡���纵��ҧ���Ңͧ������ʡ�õԴ�Ѻ�ͧ����մժ�Դ 7-Segment---;
TB_7SEG:.DB 0b00111111, 0b00000110	; 0 ��� 1	----a----
        .DB 0b01011011, 0b01001111	; 2 ��� 3	f       b
        .DB 0b01100110, 0b01101101	; 4 ��� 5	----g----
        .DB 0b01111101, 0b00000111	; 6 ��� 7	e       c
        .DB 0b01111111, 0b01101111	; 8 ��� 9	----d----
        .DB 0b01110111, 0b01111100	; A ��� B
        .DB 0b00111001, 0b01011110	; C ��� D
        .DB 0b01111001, 0b01110001	; E ��� F
        .DB 0b01001001, 0b00110110	; special value
;========================================================================
LOOK_TABLE: ldi ZL, low(TB_7SEG*2)	; ��èؤ�ҵ���˹�亵���Ңͧ TB_7SEG ��� ZL
			ldi ZH, high(TB_7SEG*2)	; ��èؤ�ҵ���˹�亵��٧�ͧ TB_7SEG ��� ZH
			add ZL, INPUT_BCH		; �ǡ��� ZL ���¤�����ʺիմ��Թ�ص
			adc ZH, R0				; �ǡ��ҷ���Ҩ�ա�÷�� Carry ���� ZH
			lpm						; ��ҹ˹��¤�������������� Z ����������� R0
			mov OUTPUT7SEG, R0		; �觤��� R0 ��ѧ�è�����������Ѻ�׹���
			pop R0					; ��ҹ�����Ңͧ R0 �׹�Ҩҡ���
			pop ZH					; ��ҹ�����Ңͧ ZH �׹�Ҩҡ���
			pop ZL					; ��ҹ�����Ңͧ ZL �׹�Ҩҡ���
			ret
;========================================================================
;---------------�Ѻ�ٷչ����Ѻ˹�ǧ���� 10 ������Թҷ� (CPU 16 MHz)---------------;
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
;---------------�Ѻ�ٷչ����Ѻ˹�ǧ���� 500 ������Թҷ� (CPU 16 MHz)--------------;
DELAY_500MS:
			ldi R16, 50			; 100 x 10 milliseconds = 500 milliseconds
delay_loop:
			rcall DELAY10MS		; ���¡��Ѻ�ٷչ DELAY10MS
			dec R16				; Ŵ��� R16 ŧ���� 1
			brne delay_loop		; ����ͤú�ͺ�������˹��繡�è� Delay
			ret
;========================================================================