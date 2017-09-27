; analogic clock (using 13h graphic mode)
; written by Leonardo Ono (ono.leo@gmail.com)
; 26/09/2017
; target os: DOS (.COM file extension)
; use: nasm aclock.asm -o aclock.com -f bin

		bits 16
		org 100h

start:
		call start_graphic_mode
		finit
		call draw_background
	.main_loop:
		call update_time
		call update_angles
		
		mov cx, 15
		call draw_pointers
		
		mov ah, 1
		int 16h ; if key pressed, exit
		jnz exit_process

		call sleep ; wait 1 second

		mov cx, 0
		call draw_pointers ; clear previous pointers
		
		jmp .main_loop

sleep:
		mov cx, 0fh
		mov dx, 4240h
		mov ah, 86h
		int 15h
		ret

; in:
;	di = angle
;	si = size
update_pointer:
		fld qword [di]
		fcos
		fld qword [si]
		fmul st1
		fist word [data.x]
		fist word [data.tmp]
	
		fld qword [di]
		fsin
		fld qword [si]
		fmul st1
		fist word [data.y]
		fist word [data.tmp]

		ret

update_angles:
		mov bx, data.v24
		mov si, data.hours
		mov di, data.angle_h
		call update_angle

		mov bx, data.v60
		mov si, data.minutes
		mov di, data.angle_m
		call update_angle

		mov bx, data.v60
		mov si, data.seconds
		mov di, data.angle_s
		call update_angle

		ret;

; in:
;	bx = v24 or v60
;	si = hours, minutes or seconds
;	di = angle_h, angle_m or angle_s
update_angle:
		fld qword [data.v90deg]
		fld qword [data.pi2]
		fld qword [bx]
		fild word [si]
		fdiv st1
		fmul st2
		fsub st3
		fst qword [di]
		fist word [data.tmp]
		fist word [data.tmp]
		fist word [data.tmp]
		ret

update_time:
		; http://vitaly_filatov.tripod.com/ng/asm/asm_029.3.html
		mov ah, 02h
		int 1ah
		; ch = hours (bcd)
		; cl = minutes (bcd)
		; dh = seconds (bcd)

		mov al, ch
		call convert_byte_bcd_to_bin
		mov ah, 0
		mov word [data.hours], ax

		mov al, cl
		call convert_byte_bcd_to_bin
		mov ah, 0
		mov word [data.minutes], ax

		mov al, dh
		call convert_byte_bcd_to_bin
		mov ah, 0
		mov word [data.seconds], ax
		ret

; in:
;	cx = color index
draw_pointers:
		mov di, data.angle_h
		mov si, data.size50
		call update_pointer
		mov di, cx
		call draw_pointer

		mov di, data.angle_m
		mov si, data.size80
		call update_pointer
		mov di, cx
		call draw_pointer

		mov di, data.angle_s
		mov si, data.size80
		call update_pointer
		mov di, cx
		call draw_pointer

		ret

; in:
;	di = color index
draw_pointer:
		pusha
		mov ax, 160
		mov bx, 100
		mov cx, 160
		mov dx, 100
		add cx, word [data.x]
		add dx, word [data.y]
		call draw_line
		popa
		ret

draw_background:
	; draw circle
		mov cx, 720
	.next:
		push cx

		fld qword [data.vhalf_deg]
		fld qword [data.angle_s]
		fadd st1
		fst qword [data.angle_s]
		fist word [data.tmp]

		mov di, data.angle_s
		mov si, data.size90
		call update_pointer

		mov al, 15
		mov cx, 160
		add cx, [data.x]
		mov bx, 100
		add bx, [data.y]
		call pset

		pop cx
		loop .next

	; draw minutes
		mov cx, 60
	.next2:
		push cx

		fld qword [data.v6deg]
		fld qword [data.angle_s]
		fadd st1
		fst qword [data.angle_s]
		fist word [data.tmp]

		mov di, data.angle_s
		mov si, data.size85
		call update_pointer

		mov al, 15
		mov cx, 160
		add cx, [data.x]
		mov bx, 100
		add bx, [data.y]
		call pset

		pop cx
		loop .next2

	; draw hours
		mov cx, 12
	.next3:
		push cx

		fld qword [data.v30deg]
		fld qword [data.angle_s]
		fadd st1
		fst qword [data.angle_s]
		fist word [data.tmp]

		mov di, data.angle_s
		mov si, data.size85
		call update_pointer

	.draw_square:
		mov ax, 159
		mov dx, 99
	.next_dot:		
		call .draw_square_dot
		inc ax
		cmp ax, 162
		jb .next_dot
	.dot_next_y:
		mov ax, 159
		inc dx
		cmp dx, 102
		jb .next_dot

		pop cx
		loop .next3

		ret
	; ax = x
	; dx = y
	.draw_square_dot:
		pusha
		mov cx, ax
		add cx, [data.x]
		mov bx, dx
		add bx, [data.y]
		mov al, 15
		call pset
		popa
		ret

exit_process:
		mov ah, 4ch
		int 21h

; in:
;	example:
;	al = 11h (bcd)
; out:
;	al = 0bh
convert_byte_bcd_to_bin:
		push bx
		push cx
		push dx
		mov bh, 0
		mov bl, al
		and bl, 0fh
		mov ch, 0
		mov cl, al
		shr cx, 4
		xor dx, dx
		mov ax, 10
		mul cx
		add ax, bx
		pop dx
		pop cx
		pop bx
		ret
		
		%include "graphic.inc"

data:
		.angle_s	dq 0
		.angle_m	dq 0
		.angle_h	dq 0

		.hours		dw 0
		.minutes	dw 0
		.seconds	dw 0

		.size90		dq 90.0
		.size85		dq 85.0
		.size84		dq 84.0
		.size80		dq 80.0
		.size50		dq 50.0
		.pi2		dq 6.28318
		.vhalf_deg	dq 0.00872665
		.v6deg		dq 0.10472
		.v90deg		dq 1.5708
		.v30deg		dq 0.523599
		.v60		dq 60.0
		.v24		dq 24.0
		.x 		dw 0
		.y 		dw 0
		.tmp		dw 0

