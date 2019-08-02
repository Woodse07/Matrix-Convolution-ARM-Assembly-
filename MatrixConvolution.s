	AREA	BonusEffect, CODE, READONLY
	IMPORT	main
	IMPORT	getPicAddr
	IMPORT	putPic
	IMPORT	getPicWidth
	IMPORT	getPicHeight
	EXPORT	start
	PRESERVE8

start

	BL	getPicAddr	; load the start address of the image in R4
	MOV	R4, R0
	BL	getPicHeight	; load the height of the image (rows) in R5
	MOV	R5, R0
	BL	getPicWidth	; load the width of the image (columns) in R6
	MOV	R6, R0

	MUL R3, R5, R6				; R3 = pixelAmount;
	BL matrixconvolution		; matrixconvolution();

	BL	putPic		; re-display the updated image

stop	B	stop

; edgedetection subroutine
; uses a selected convolution matrix to alter an image
; Parameters: R3: Length of Array
; 	R4: Starting address of picture
; Returns: none
matrixconvolution
	STMFD SP!, {R4 - R12, lr}	; pushing stack

	EOR R8, R8					; R8 = count;
	EOR R9, R9					; R9 = pixel;
	LDR R10, =0					; R10 = row;
	LDR R11, =0					; R11 = column;
	
	STMFD SP!, {R1-R2}			; pushing stack
	MOV R1, R4					; R1 = picAddr;
	MOV R2, R3					; R2 = pixelAmount;
	BL clonepicture				; clonePicture();
	MOV R4, R0					; R4 = clonePicAddr;
	LDMFD SP!, {R1-R2}			; popping stack
	
whl CMP R8, R3					; while(count <= pixelAmount)
	BEQ endwhl					; {
	
	LDR R1, =6					; 	R1 = matrix ;choose effect(1 = Edge Detection, 2 = Emboss, 3 = sharpen, 4 = vertical line detection
								;									5 = horizontal line detection, 6 = angle line detection,)
	CMP R1, #1					;	if(matrix == 1)
	BNE emboss					; 	{
	LDR R1, =edgedmat			;		matrix = edgeDetection;
	B run						;	}
emboss							
	CMP R1, #2					; 	if(matrix == 2)
	BNE sharpen					;	{
	LDR R1, =embossmat			;		matrix = emboss;
	B run						;	}
sharpen			
	CMP R1, #3					; 	if(matrix == 3)
	BNE vertical				;	{
	LDR R1, =sharpenmat			;		matrix = sharpen;
	B run						;	}					
vertical			
	CMP R1, #4					;	if(matrix == 4)
	BNE horizontal				;	{
	LDR R1, =verticaldetmat		;		matrix = verticalEdgeDetection;
	B run						;	}
horizontal		
	CMP R1, #5					;	if(matrix == 5)
	BNE angle					;	{
	LDR R1, =horizontaldetmat	;		matrix = horizontalEdgeDetection;
	B run						;	}
angle
	CMP R1, #6
	BNE run
	LDR R1, =angledetmat
run
	BL applymatrix 				; 	appplymatrix();
	MOV R9, R0					; 	R9 = pixel;
	MOV R1, R10					; 	R1 = row;
	MOV R2, R11					;	R2 = column;
	BL sendpixel				;	sendpixel();
	ADD R8, R8, #1				;	count++;
	
	ADD R11, R11, #1			; 	column++;
	CMP R11, R6					;	if(column > picWidth)
	BLE dontadd					;	{
	ADD R10, R10, #1			;		row++;
	LDR R11, =0					;		column = 0;
dontadd							; 	}
	
	B whl						; }

endwhl

	LDMFD SP!, {R4-R12, PC}		; popping stack

; getpixel subroutine
; gets a single pixel from a picture
; Parameters: R1: Row
;	R2: Column
;	R4: Start address of picture
;	R6: Picture Width
; Returns: R0: Pixel
getpixel
	STMFD SP!, {R1-R4, R6, LR}	; pushing stack
	BL getPicWidth				; getPicWidth();
	MOV R6, R0					; R6 = picWidth;
	EOR R3, R3					; R3 = pixelAddr;
	MOV R1, R10					; R1 = row;
	MOV R2, R11					; R2 = column;
	MUL R3, R1, R6				; pixelAddr = row * picWidth;
	ADD R3, R3, R2				; pixelAddr += column;
	LSL R3, #2					; pixelAddr *= 4;
	ADD R3, R4, R3				; pixelAddr += picAddr;
	LDR R0, [R3]				; pixel = memory.get[pixelAddr];
	LDMFD SP!, {R1-R4, R6, PC}	; popping stack

; sendpixel subroutine
; stores a single pixel back into memory
; Parameters: R1: Row
; 	R2: Column
; 	R4: Start address of picture
;	R6: Picture Width
;	R9: Pixel value
; Returns: none
sendpixel
	STMFD SP!, {R1-R4, R6, LR}	; pushing stack
	BL getPicWidth				; getPicWidth();
	MOV R6, R0					; R6 = picWidth;
	BL getPicAddr				; getPicAddr();
	MOV R4, R0					; R4 = picAddr;
	EOR R3, R3					; R3 = pixelAddr;
	MOV R1, R10					; R1 = row;
	MOV R2, R11					; R2 = column;
	MUL R3, R1, R6				; pixelAddr = row * picWidth;
	ADD R3, R3, R2				; pixelAddr += column;
	LSL R3, #2					; pixelAddr *= 4;
	ADD R0, R4, R3				; pixelAddr += picAddr;
	STR R9, [R0]				; memory.get[pixelAddr] = pixel;
	LDMFD SP!, {R1-R4, R6, PC}	; popping stack
		
; getred subroutine
; Gets the red components of a pixel.
; Parameters: R1: Pixel value
; Returns: R1: Red component.
getred
	STMFD SP!, {R1, LR}			; pushing stack
	AND R1, #0X000000FF			; pixel = pixel AND NOT(0xFFFFFF00);
	MOV R0, R1					; redComponent = pixel;
	LDMFD SP!, {R1, PC}			; popping stack

; getgreen subroutine
; Gets the green components of a pixel.
; Parameters: R1: Pixel value
; Returns: R1: Green component.
getgreen
	STMFD SP!, {R1, LR}			; pushing stack
	AND R1, #0x0000FF00			; pixel = pixel AND NOT(0xFFFF00FF);
	LSR R1, #8					; pixel /= 0x100;
	MOV R0, R1					; greenComponent = pixel;
	LDMFD SP!, {R1, PC}			; popping stack
	
; getblue subroutine
; Gets the blue components of a pixel.
; Parameters: R1: Pixel value
; Returns: R1: Blue component.
getblue
	STMFD SP!, {R1, LR}			; pushing stack
	AND R1, #0x00FF0000			; pixel = pixel AND NOT(0xFF00FFFF);
	LSR R1, #16					; pixel /= 0x10000;
	MOV R0, R1					; blueComponent = pixel;
	LDMFD SP!, {R1, PC}			; popping stack

; divide subroutine
; takes two numbers and divides them
; paramaters: R1: number to be divided
; 	R2: divisor
; returns: R0: Quotient
divide
	STMFD SP!, {R1-R3, LR}		; pushing stack
	EOR R3, R3					; R3 = quotient;
whlnotend						
	CMP R1, R2					; while(num < divisor)
	BLO end						; {
	SUB R1, R1, R2				;	num -= divisor;
	ADD R3, R3, #1				; 	quotient++;
	B whlnotend					; }
end
	MOV R0, R3					; R0 = quotient;
	LDMFD SP!, {R1-R3, PC}		; popping stack

; applymatrix subroutine
; takes a convolution matrix and applies it to a pixel.
; paramaters: R1: start address of matrix
; 	R10: row of center pixel
;	R11: column of center pixel
; returns: pixel
applymatrix
	STMFD SP!, {R1-R12, LR}		; pushing stack
	
	LDR R2, =3					; R2 = matrixDimension;
	MOV R3, R1					; R3 = matrixAddr;
	LDR R8, =0					; R8 = rowCount;
	LDR R9, =0					; R9 = columnCount;
	EOR R12, R12				; R12 = pixel;
	EOR R5, R5					; R5 = redComponent;
	EOR R6, R6					; R6 = greenComponent;
	EOR R7, R7					; R7 = blueComponent;
	SUB R10, R10, #1			; row--;
	SUB R11, R11, #1			; column--;

whlmat
	CMP R8, R2					; while(rowCount <= matrixDimension)
	BEQ nextmat					; {
	
	STMFD SP!, {R5-R6}			;	pushing stack
	BL getPicHeight				; 	getPicHeight();
	MOV R5, R0					;	R5 = picHeight;
	BL getPicWidth				;	getPicWidth();
	MOV R6, R0					;	R6 = picWidth;
	CMP R10, #0					;	if(R10 < 0)
	BLT addblack				;		break;
	CMP R11, #0					;	if(R11 < 0)
	BLT addblack				;		break;
	CMP R10, R5					;	if(R10 > picHeight)
	BGT addblack				;		break;
	CMP R11, R6					;	if(R11 > picWidth)
	BGT addblack				;		break;
	LDMFD SP!, {R5-R6}			;	popping stack
			
	STMFD SP!, {R1-R2, R4, R6}	; 	pushing stack
	MOV R1, R10					;	R1 = row;
	MOV R2, R11					; 	R2 = column;
	BL getPicWidth				; 	getPicWidth();
	MOV R6, R0					; 	R6 = picWidth;
	BL getpixel					;	getpixel();
	LDMFD SP!, {R1-R2, R4, R6}	;	popping stack
	
	MOV R1, R0					;   R1 = pixel;
	STMFD SP!, {R4}				; 	pushing stack
	LDR R4, [R3]				; 	R4 = memory.get[matrixAddr];
	B apply						;	goto apply;
	
addblack
	LDMFD SP!, {R5-R6}			;	popping stack;
	MOV R1, #0X00000000			;	R1 = pixel;
	STMFD SP!, {R4}				; 	pushing stack;
	LDR R4, [R3]				;	R4 = memory.get[matrixAddr];
	
apply
	BL getred					;	getred();
	MUL R0, R4, R0				;	redComponent *= memory.get[matrixAddr];
	ADD R5, R0					; 	redComponent += redComponent;

	BL getgreen					; 	getgreen();
	MUL R0, R4, R0				;   greenComponent *= memory.get[matrixAddr];
	ADD R6, R0					; 	greenComponent += greenComponent;
			
	BL getblue					;	getblue();
	MUL R0, R4, R0				;	blueComponent *= memory.get[matrixAddr];
	ADD R7, R0					; 	blueComponent += blueComponent;
	
	LDMFD SP!, {R4}				;	popping stack


nextpixel
	ADD R3, R3, #4				;	matrixAddr += 4;
	ADD R11, R11, #1			; 	column++;
	ADD R9, R9, #1				;	columnCount++;
	CMP R9, R2					;	if(columnCount >= matrixDimension)
	BLT dontaddmat				;	{
	ADD R10, R10, #1			;		row++;
	ADD R8, R8, #1				;		rowCount++;
	SUB R11, R11, #3			;		column -= 3;
	LDR R9, =0					;		columnCount = 0;
dontaddmat						;	}
	B whlmat					; }	
	
nextmat
	CMP R5, #0					; if(redComponent <= 0)
	BGT next7					; {
	LDR R5, =0					;	redComponent = 0;
next7							; }
	CMP R5, #255				; if(redComponent >= 255)
	BLT next8					; {
	LDR R5, =255				;	redComponent = 255;
next8							; }

	CMP R6, #0					; if(greenComponent <= 0)
	BGT next9					; {
	LDR R6, =0					;	greenComponent = 0;
next9							; }
	CMP R6, #255				; if(greenComponent >= 255)
	BLT next10					; {
	LDR R6, =255				;	greenComponent = 255;
next10							; }

	CMP R7, #0					; if(blueComponent <= 0)
	BGT next11					; {
	LDR R7, =0					; 	blueComponent = 0;
next11							; }
	CMP R7, #255 				; if(blueComponent >= 255)
	BLT next12					; {
	LDR R7, =255				; 	blueComponent = 255;
next12							; }

	LSL R6, #8					; greenComponent *= 0x100;
	LSL R7, #16					; blueComponent *= 0x10000;
	
	ADD R0, R5, R6				; pixel = redComponent + greenComponent;
	ADD R0, R0, R7				; pixel += blueComponent;
		
	LDMFD SP!, {R1-R12, PC}		; popping stack
	
	
; clonepicture subroutine
; takes an image and makes a copy of it in memory
; parameters: R1 = start address of original copy
; 	R2 = size of original copy
; returns: R0: start address of clone
clonepicture
	STMFD SP!, {R1-R7, LR}		; pushing stack
	
	LDR R6, =4					; R6 = multiplier;
	MOV R3, R1					; R3 = picAddr;
	MOV R7, R2					; R7 = pixelAmount;
	MUL R2, R6, R2				; clonePicAddr = multiplier * pixelAmount;
	ADD R3, R3, R2				; clonePicAddr += pixelAmount;
	ADD R3, R3, #4 	   			; clonePicAddr += padding;
	MOV R0, R3					; R0 = clonePicAddr;
	EOR R4, R4					; R4 = count;
whlcopy
	CMP R4, R7					; while(count < pixelAmount)
	BEQ endcopy					; {
	LDR R5, [R1]				; 	R5 = memory.get[picAddr]
	STR R5, [R3]				; 	memory.get[clonePicAddr] = R5
	ADD R1, R1, #4				; 	picAddr += 4;
	ADD R3, R3, #4				; 	clonePicAddr += 4;
	ADD R4, R4, #1				; 	count++
	B whlcopy					; }
endcopy	
	
	LDMFD SP!, {R1-R7, PC}		; popping stack
	
	
	AREA	TestArray, DATA, READWRITE

N	EQU	3

edgedmat						; edge detection matrix
		DCD	-1, -1, -1
		DCD	-1,  8, -1
		DCD	-1, -1, -1
			
embossmat						; emboss matrix
		DCD -2, 0, 0
		DCD  0, 1, 0
		DCD  0, 0, 2
			
sharpenmat						; sharpen matrix
		DCD	 0, -1,  0
		DCD -1,  5, -1
		DCD  0, -1,  0
			
		
verticaldetmat					; vertical edge detection matrix
		DCD	-1, 2, -1
		DCD -1, 2, -1
		DCD -1, 2, -1
			
horizontaldetmat				; horizontal edge detection matrix
		DCD -1, -1, -1
		DCD  2,  2,  2
		DCD -1, -1, -1
			
angledetmat						; 45 edge detection matrix
		DCD -1, -1,  2
		DCD -1,  2, -1
		DCD  2, -1, -1
			
	END	
		
	
	