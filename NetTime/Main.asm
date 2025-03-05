;NetTime (izzx)
;Утилита синхронизации времени с инетом
    device ZXSPECTRUM48
	org #8000
origin
	jp start
UTC ds 4 ;переменная
start
	xor a
	ld (23692),a ;отложить запрос на сролл экрана
	
	call Uart.init ;инициализация карты

	call read_buf ;принять ответ
	ld hl,buffer
	call print_mes ;печать ответа
	
	; ld b,cmd_ate0_e-cmd_ate0 ;отключить эхо
	; ld hl,cmd_ate0
	; call write_cmd
	
	; call read_buf
	;ld hl,buffer
	;call print_mes
;	
	ld b,cmd_break_e-cmd_break ;прервать обмен, если был
	ld hl,cmd_break
	call write_cmd
	
	call read_buf
	ld hl,buffer
	call print_mes
	ld a,13
	rst 16
;	
	ld b,cmd_ipclose_e-cmd_ipclose ;закрыть соединение, если было
	ld hl,cmd_ipclose
	call write_cmd
	
	call read_buf
	ld hl,buffer
	call print_mes
	ld a,13
	rst 16
;
	; ld b,cmd_savetrans0_e-cmd_savetrans0 ;установить прямое соединение
	; ld hl,cmd_savetrans0
	; call write_cmd
	
	; call read_buf
	;ld hl,buffer
	;call print_mes
; ;
	; ld b,cmd_cwjap_e-cmd_cwjap ;задать точку доступа
	; ld hl,cmd_cwjap
	; call write_cmd
	
	; call read_buf
	;ld hl,buffer
	;call print_mes
;
	; ld b,cmd_ipmux_e-cmd_ipmux ;режим обмена одно соединение
	; ld hl,cmd_ipmux
	; call write_cmd
	
	; call read_buf
	;ld hl,buffer
	;call print_mes
;	
	ld b,cmd_ipstart_e-cmd_ipstart ;установить соединение
	ld hl,cmd_ipstart
	call write_cmd
	
	call read_buf
	ld hl,buffer
	call print_mes
	ld a,13
	rst 16
;	
	; ld b,cmd_savetrans_e-cmd_savetrans
	; ld hl,cmd_savetrans
	; call write_cmd
	
	; call read_buf
	;ld hl,buffer
	;call print_mes
;	
	ld b,cmd_ipsend_e-cmd_ipsend ;задать размер пакета
	ld hl,cmd_ipsend
	call write_cmd
	
	call read_buf
	ld hl,buffer
	call print_mes
	; ld a,13
	; rst 16
;	
	;печать времени клиента
	ld hl,mes_client_RTS
	call print_mes
	call print_client_time
	ret c

	;запрос на сервер
	ld b,cmd_req_e-cmd_req ;отправить пакет
	ld hl,cmd_req
	call write_cmd
	
	call read_buf
	;ld hl,buffer
	;call print_mes
	
	;проверка пакета
	ld hl,buffer
	ld de,pack_id
	ld b,0 ;ограничение на поиск
	ld ixl,pack_id_e-pack_id ;символов для сравнения
compar1
	ld a,(de)
	cp (hl)
	jr z,compar2
	ld ixl,pack_id_e-pack_id 
	inc hl
	djnz compar1
	jr compar_no
compar2
	inc de
	inc hl
	dec ixl
	jr nz,compar1
	jr compar_ok
compar_no ;не нашли
	ld hl,mes_no_answer
	call print_mes
	ret ;выход
compar_ok
	;в hl указатель на начало ответного пакета
	ld (pack_answer),hl
	
;	
	call calc_server_time
	call set_client_time
	ret c
;	
	ld b,cmd_ipclose_e-cmd_ipclose ;закрыть соединение
	ld hl,cmd_ipclose
	call write_cmd
	
	call read_buf
	ld hl,buffer
	call print_mes
;финал
	ld hl,mes_press_key
	call print_mes
	;печать в цикле текущего времени
end_loop
	ld hl,mes_curent_RTS
	call print_mes
	call print_client_time
	ret c
	halt
	ld a,(23556) ;нажатая клавиша
	cp 255
	jr z,end_loop
	di
	xor a
	ld bc,#7ffd
	out (c),a ;128 бейсик
	jp 0 ;выход



calc_server_time
	;обработка времени, полученного с сервера
	ld hl,mes_server_RTS
	call print_mes
	
	ld hl,1900 ;начнём отсчёт с 01.01.1900
	ld (cur_year),hl
	ld hl,1
	ld (cur_month),hl
	ld (cur_day),hl
	ld hl,0	
	ld (cur_hour),hl
	ld (cur_minute),hl
	ld (cur_second),hl
	ld hl,(pack_answer)
	ld bc,40
	add hl,bc ;указатель на значении Transmit
	
	ld b,(hl) ;старшие 2 байта будут в IX
	inc hl
	ld c,(hl)
	inc hl
	push bc
	pop ix
	;ld (server_t_h),ix
	ld d,(hl) ;младшие 2 будут в HL
	inc hl
	ld e,(hl)
	ex de,hl
	;ld (server_t_l),hl
	
	;прибавляем или вычитаем часовой пояс
	ld de,(UTC+1) ;utc старшие байты
	ld d,0
	ld a,(UTC+2) ;utc младшие байты	
	ld b,a
	ld a,(UTC+3)
	ld c,a
	ld a,(UTC)
	cp "+"
	jr z,calc_utc_plus
calc_utc_minus ;вычитаем utc
	exx
	ld de,0 ;фикс IX подготовить
	exx
	and a
	sbc hl,bc ;вычтем UTC младшие два байта
	jr nc,calc_utc3
	push bc
	push hl
	push ix
	pop hl
	ld bc,1
	exx
	ld de,1 ;фикс IX запомнить
	exx
	and a
	sbc hl,bc
	push hl
	pop ix
	pop hl
	pop bc
	jr nc,calc_utc3
	inc ix ;на шаг назад если не хватило
	add hl,bc
	jr calc_year ;выход
calc_utc3	
	and a
	push hl ;рокировка регистров
	push ix
	pop hl
	sbc hl,de ;вычтем utc старшие два байта
	push hl
	pop ix
	pop hl
	jr nc,calc_year
	;на шаг назад
	add ix,de
	exx
	add ix,de ;фикс IX вспомнить
	exx
	add hl,bc
	jr calc_year

calc_utc_plus ;прибавляем utc
	add hl,bc
	jr nc,calc_utc_plus1
	inc ix
calc_utc_plus1
	add ix,de


	;вычисление года
calc_year 
	exx
	ld de,0 ;фикс IX подготовить
	exx
	push hl
	call check_year_leap ;високосный?
	pop hl
	jr nc,calc_year1
	ld de,(year_leap_h) ;год в секундах високосный
	ld bc,(year_leap_l)
	jr calc_year2
calc_year1
	ld de,(year_h) ;год в секундах обычный
	ld bc,(year_l)
calc_year2
	and a
	sbc hl,bc ;вычтем год младшие два байта
	jr nc,calc_year3
	push bc
	push hl
	push ix
	pop hl
	ld bc,1
	exx
	ld de,1 ;фикс IX запомнить
	exx
	and a
	sbc hl,bc
	push hl
	pop ix
	pop hl
	pop bc
	jr nc,calc_year3
	inc ix ;на шаг назад если не хватило
	add hl,bc
	jr calc_year_ex ;выход из цикла
calc_year3	
	and a
	push hl ;рокировка регистров
	push ix
	pop hl
	sbc hl,de ;вычтем год старшие два байта
	push hl
	pop ix
	pop hl
	jr nc,calc_year3h
	;на шаг назад
	add ix,de
	exx
	add ix,de ;фикс IX вспомнить
	exx
	add hl,bc
	jr calc_year_ex ;выход из цикла
calc_year3h
	;прибавляем год к переменной
	push hl
	ld hl,(cur_year)
	inc hl
	ld (cur_year),hl
	pop hl
	jr calc_year ;цикл
calc_year_ex

	;печать года
	push hl
	ld hl,(cur_year)
	call toDecimal
	ld hl,decimalS+3
	call print_mes
	pop hl

	ld a,"."
	rst 16

	;вычисление месяца
	push hl
	call check_year_leap ;високосный?
	;pop hl
	jr nc,calc_month1
	ld hl,month_leap ;месяцы в секундах високосные
	jr calc_month2
calc_month1
	ld hl,month ;месяцы в секундах обычные
calc_month2	
	ld (month_cur_tabl),hl ;сохранить указатель на месяц
	pop hl
calc_month
	exx
	ld de,0 ;фикс IX подготовить
	exx
	push hl
	ld hl,(month_cur_tabl)
	ld a,(hl)
	inc hl
	ld b,(hl) ;младшие байты
	inc hl
	ld c,(hl)
	inc hl
	ld (month_cur_tabl),hl ;сохранить указатель на месяц
	ld d,0 ;старшие байты
	ld e,a
	pop hl

	and a
	sbc hl,bc ;вычтем месяц младшие два байта
	jr nc,calc_month3
	push bc
	push hl
	push ix
	pop hl
	ld bc,1
	exx
	ld de,1 ;фикс IX запомнить
	exx
	and a
	sbc hl,bc
	push hl
	pop ix
	pop hl
	pop bc
	jr nc,calc_month3
	inc ix ;на шаг назад если не хватило
	add hl,bc
	jr calc_month_ex ;выход из цикла
calc_month3	
	and a
	push hl ;рокировка регистров
	push ix
	pop hl
	sbc hl,de ;вычтем месяц старшие два байта
	push hl
	pop ix
	pop hl
	jr nc,calc_month3h
	;на шаг назад
	add ix,de
	exx
	add ix,de ;фикс IX вспомнить
	exx
	add hl,bc
	jr calc_month_ex ;выход из цикла
calc_month3h
	;прибавляем месяц к переменной
	push hl
	ld hl,(cur_month)
	inc hl
	ld (cur_month),hl
	pop hl
	jr calc_month ;цикл
calc_month_ex

	; ;коррекция месяца
	; push hl
	; ld hl,(cur_month)
	; ld a,l
	; cp 1
	; jr z,calc_month5
	; dec hl
	; ld (cur_month),hl	
; calc_month5	
	
	;печать месяца
	push hl
	ld hl,(cur_month)
	call toDecimal
	ld hl,decimalS+3
	call print_mes	
	pop hl

	ld a,"."
	rst 16

	;вычисление дня
	ld a,(day_h)
	ld e,a
	ld d,0
	ld a,(day_l+1) ;младшие байты
	ld b,a
	ld a,(day_l)
	ld c,a	
calc_day
	exx
	ld de,0 ;фикс IX подготовить
	exx
	and a
	sbc hl,bc ;вычтем день младшие два байта
	jr nc,calc_day3
	push bc
	push hl
	push ix
	pop hl
	ld bc,1
	exx
	ld de,1 ;фикс IX запомнить
	exx
	and a
	sbc hl,bc
	push hl
	pop ix
	pop hl
	pop bc
	jr nc,calc_day3
	inc ix ;на шаг назад если не хватило
	add hl,bc
	jr calc_day_ex ;выход из цикла
calc_day3	
	and a
	push hl ;рокировка регистров
	push ix
	pop hl
	sbc hl,de ;вычтем месяц старшие два байта
	push hl
	pop ix
	pop hl
	jr nc,calc_day3h
	;на шаг назад
	add ix,de
	exx
	add ix,de ;фикс IX вспомнить
	exx
	add hl,bc
	jr calc_day_ex ;выход из цикла
calc_day3h
	;прибавляем день к переменной
	push hl
	ld hl,(cur_day)
	inc hl
	ld (cur_day),hl
	pop hl
	jr calc_day ;цикл
calc_day_ex

	; ;коррекция дня
	; push hl
	; ld hl,(cur_day)
	; ld a,l
	; cp 1
	; jr z,calc_day5
	; inc hl
	; ld (cur_day),hl	
; calc_day5	
	
	;печать дня
	push hl
	ld hl,(cur_day)
	call toDecimal
	ld hl,decimalS+3
	call print_mes	
	pop hl

	ld a," "
	rst 16	
	
	;вычисление часа
	ld de,0 ;старшие байты
	ld bc,3600 ;секунд в часе ;младшие байты
calc_hour
	exx
	ld de,0 ;фикс IX подготовить
	exx
	and a
	sbc hl,bc ;вычтем час младшие два байта
	jr nc,calc_hour3
	push bc
	push hl
	push ix
	pop hl
	ld bc,1
	exx
	ld de,1 ;фикс IX запомнить
	exx
	and a
	sbc hl,bc
	push hl
	pop ix
	pop hl
	pop bc
	jr nc,calc_hour3
	inc ix ;на шаг назад если не хватило
	add hl,bc
	jr calc_hour_ex ;выход из цикла
calc_hour3	
	and a
	push hl ;рокировка регистров
	push ix
	pop hl
	sbc hl,de ;вычтем час старшие два байта
	push hl
	pop ix
	pop hl
	jr nc,calc_hour3h
	;на шаг назад
	add ix,de
	exx
	add ix,de ;фикс IX вспомнить
	exx
	add hl,bc
	jr calc_hour_ex ;выход из цикла
calc_hour3h
	;прибавляем час к переменной
	push hl
	ld hl,(cur_hour)
	inc hl
	ld (cur_hour),hl
	pop hl
	jr calc_hour ;цикл
calc_hour_ex

	;печать часа
	push hl
	ld hl,(cur_hour)
	call toDecimal
	ld hl,decimalS+3
	call print_mes	
	pop hl

	ld a,":"
	rst 16	

	;вычисление минут
	ld de,0 ;старшие байты
	ld bc,60 ;секунд в минуте ;младшие байты
calc_minute
	exx
	ld de,0 ;фикс IX подготовить
	exx
	and a
	sbc hl,bc ;вычтем час младшие два байта
	jr nc,calc_minute3
	push bc
	push hl
	push ix
	pop hl
	ld bc,1
	exx
	ld de,1 ;фикс IX запомнить
	exx
	and a
	sbc hl,bc
	push hl
	pop ix
	pop hl
	pop bc
	jr nc,calc_minute3
	inc ix ;на шаг назад если не хватило
	add hl,bc
	jr calc_minute_ex ;выход из цикла
calc_minute3	
	and a
	push hl ;рокировка регистров
	push ix
	pop hl
	sbc hl,de ;вычтем минуту старшие два байта
	push hl
	pop ix
	pop hl
	jr nc,calc_minute3h
	;на шаг назад
	add ix,de
	exx
	add ix,de ;фикс IX вспомнить
	exx
	add hl,bc
	jr calc_minute_ex ;выход из цикла
calc_minute3h
	;прибавляем минуту к переменной
	push hl
	ld hl,(cur_minute)
	inc hl
	ld (cur_minute),hl
	pop hl
	jr calc_minute ;цикл
calc_minute_ex

	;печать минут
	push hl
	ld hl,(cur_minute)
	call toDecimal
	ld hl,decimalS+3
	call print_mes	
	pop hl

	ld a,":"
	rst 16
	
	;вычисление секунд
	ld (cur_second),hl

	;печать секунд
	push hl
	ld hl,(cur_second)
	call toDecimal
	ld hl,decimalS+3
	call print_mes	
	pop hl

	ld a,13
	rst 16
	ret


set_client_time ;установка времени клиента
	;подготовка текущей даты
	ld hl,(cur_year)
	;надо оставить две последние цифры года
	call toDecimal
	ld hl,decimalS+3
	ld d,(hl)
	inc hl
	ld e,(hl)
	ld a,d
	sub "0"
	ld d,a
	or a
	jr z,set_client_year
	xor a
set_client_year1 ;десятки
	add a,10
	dec d
	jr nz,set_client_year1
	ld d,a
set_client_year
	ld a,e
	sub "0" ;единицы
	add d
	ld e,a ;год готов

	ld a,(cur_month)
	ld b,a ;месяц
	ld a,(cur_day)
	ld c,a ;число
	call Clock.writeDate
	jr nc,write_date_ok
	ld hl,mes_no_RTC
	call print_mes
	scf ;ошибка
	ret ;выход
write_date_ok	
	
	;установка часов
	ld a,(cur_hour)
	ld e,a ;часы
	ld a,(cur_minute)
	ld b,a ;минуты
	ld a,(cur_second)
	ld c,a ;секунды	
	call Clock.writeTime
	jr nc,write_time_ok
	ld hl,mes_no_RTC
	call print_mes
	scf
	ret ;выход	
write_time_ok
	or a ;нет ошибки
	ret	
	
print_client_time ;печать времени клиента
	;печать текущей даты 
	call Clock.readDate
	jr nc,read_date_ok
	ld hl,mes_no_RTC
	call print_mes
	scf ;ошибка
	ret ;выход
read_date_ok	
	ld l,e ;год
	ld h,0
	call toDecimal
	ld hl,decimalS+3
	call print_mes
	ld a,"."
	rst 16
	ld l,b ;месяц
	ld h,0
	call toDecimal
	ld hl,decimalS+3
	call print_mes
	ld a,"."
	rst 16
	ld l,c ;число
	ld h,0
	call toDecimal
	ld hl,decimalS+3
	call print_mes
	
	ld a," "
	rst 16
	
	;печать текущего времени
	call Clock.readTime
	jr nc,read_time_ok
	ld hl,mes_no_RTC
	call print_mes
	scf
	ret ;выход	
read_time_ok
	ld l,e ;часы
	ld h,0
	call toDecimal
	ld hl,decimalS+3
	call print_mes
	ld a,":"
	rst 16
	ld l,b ;минуты
	ld h,0
	call toDecimal
	ld hl,decimalS+3
	call print_mes
	ld a,":"
	rst 16
	ld l,c ;секунды
	ld h,0
	call toDecimal
	ld hl,decimalS+3
	call print_mes
	or a ;нет ошибки
	ret
	
read_buf	;чтение в буфер
	ld bc,257 ;очистить буфер
	ld hl,buffer
	ld de,buffer+1
	ld (hl),0
	ldir
	
	ld b,0 ;чтение данных
	ld hl,buffer
read_buf1
	call Uart.read
	ret nc
	ld (hl),a
	inc hl
	djnz read_buf1
	ret
	
write_cmd ;отправить данные
	;ld hl,buffer
	;ld b,0
write_cmd1
	ld a,(hl)
	push bc
	call Uart.write
	pop bc
	inc hl
	djnz write_cmd1
	ret
	
print_mes ; печать строки до цифры 0. В hl адрес строки
	push bc
	ld b,0 ;не больше 256
print_mes1
	ld a,(hl)
	or a
	jr z,print_mes_e
	rst 16
	inc hl
	djnz print_mes1
print_mes_e
	pop bc
	ret
	
toDecimal		;конвертирует 2 байта в 5 десятичных цифр
				;на входе в HL число
			ld de,10000 ;десятки тысяч
			ld a,255
toDecimal10k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal10k
			add hl,de
			add a,48
			ld (decimalS),a
			ld de,1000 ;тысячи
			ld a,255
toDecimal1k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal1k
			add hl,de
			add a,48
			ld (decimalS+1),a
			ld de,100 ;сотни
			ld a,255
toDecimal01k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal01k
			add hl,de
			add a,48
			ld (decimalS+2),a
			ld de,10 ;десятки
			ld a,255
toDecimal001k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal001k
			add hl,de
			add a,48
			ld (decimalS+3),a
			ld de,1 ;единицы
			ld a,255
toDecimal0001k			
			and a
			sbc hl,de
			inc a
			jr nc,toDecimal0001k
			add hl,de
			add a,48
			ld (decimalS+4),a		
			
			ret
	
decimalS	ds 6 ;десятичные цифры
	
check_year_leap ;проверка не високосный ли год, на выходе флаг C=1 если да
	ld bc,(cur_year)
	ld hl,year_leap
check_year_leap3
	ld a,(hl)
	or a
	jr z,check_year_leap_no ;конец таблицы, не нашли
	cp c
	jr nz,check_year_leap2
	inc hl
	ld a,(hl)
	cp b
	jr nz,check_year_leap1
	scf ;нашли, значит високосный
	ret

check_year_leap2
	inc hl
check_year_leap1
	inc hl
	jr check_year_leap3


check_year_leap_no ;не високосный
	or a
	ret
	

	include drivers/zx-wifi.asm
	include drivers/SMUC-RTS.asm

cmd_ate0 db "ATE0",13,10
cmd_ate0_e	
cmd_cwjap db "AT+CWJAP_DEF=\"ТочкаДоступа\",\"Парол\"",13,10
cmd_cwjap_e
cmd_break db "+++"
cmd_break_e	
cmd_ipmux db "AT+CIPMUX=0",13,10
cmd_ipmux_e
cmd_ipclose db "AT+CIPCLOSE",13,10
cmd_ipclose_e
cmd_ipstart db "AT+CIPSTART=\"UDP\",\"time.windows.com\",123",13,10
;cmd_ipstart db "AT+CIPSTART=\"UDP\",\"time.windows.com\",2390",13,10
cmd_ipstart_e
;cmd_ipsend db "AT+CIPSEND=48,\"time.windows.com\",123",13,10
cmd_ipsend db "AT+CIPSEND=48",13,10
cmd_ipsend_e
cmd_savetrans db "AT+SAVETRANSLINK=1,\"time.windows.com\",123,\"UDP\"",13,10
cmd_savetrans_e
cmd_savetrans0 db "AT+SAVETRANSLINK=0",13,10
cmd_savetrans0_e
; cmd_req db 0x11,0xfa,0x00,0x00,0x00,0x00,0x00,0x01,0x03,0xfe
	; ds 48-10
cmd_req 
	;db 0b00010011
	;db 0b01101000
	;db 0b11100011
	db 0b00011011 ;Leap indicator = 0 (00); Version number=3 (011); Mode=3 (011)(клиент)
	ds 1
	ds 1
	ds 1
 	ds 4
	ds 4
 	ds 4
	ds 8 ;Reference время на сервере
	ds 8 ;Originate
 	ds 8 ;Receive
	db #E7,#AB,#B7,#00 ;Transmit текущее время клиента (количество секунд с 1 января 1900 г, для примера забита дата 02.03.2023)
	ds 4
cmd_req_e

pack_id db "+IPD,48:" ;метка пакета от сервера
pack_id_e
pack_answer dw 0 ;указатель на начало полученного пакета
mes_no_RTC db 13,#10,2,"Fail. RTC error.",0
mes_no_answer db 13,#10,2,"Fail. Server answer error.",0
mes_client_RTS db 13,"Client time: ",0
mes_server_RTS db 13,"Server time: ",0
mes_curent_RTS 	db #16,21,1,#10,4,"Current time: ",0
mes_press_key	db #10,4,13,"Press key to reset.",13,13,0



cur_year dw 1900 ;текущая дата для рассчётов
cur_month dw 01
cur_day dw 01
cur_hour dw 0 
cur_minute dw 0
cur_second dw 0
year_h dw #1E1 ;секунд в году
year_l dw #3380
year_leap_h dw #1E2 ;секунд в високосном году
year_leap_l dw #8500
;server_t_h dw 0 ;полученное с сервера время
;server_t_l dw 0
day_h dw #0001 ;секунд в дне
day_l dw #5180
month_cur_tabl dw 0; указатель на месяц

;список месяцев в секундах
;31,28,31,30,31,30,31,31,30,31,30,31
month db #28,#DE,#80 ;31
	db #24,#EA,#00 ;28
	db #28,#DE,#80 ;31
	db #27,#8D,#00 ;30
	db #28,#DE,#80 ;31
	db #27,#8D,#00 ;30
	db #28,#DE,#80 ;31
	db #28,#DE,#80 ;31
	db #27,#8D,#00 ;30
	db #28,#DE,#80 ;31
	db #27,#8D,#00 ;30
	db #28,#DE,#80 ;31	
	
;31,29,31,30,31,30,31,31,30,31,30,31	
month_leap  db #28,#DE,#80 ;31
	db #26,#3B,#80 ;29
	db #28,#DE,#80 ;31
	db #27,#8D,#00 ;30
	db #28,#DE,#80 ;31
	db #27,#8D,#00 ;30
	db #28,#DE,#80 ;31
	db #28,#DE,#80 ;31
	db #27,#8D,#00 ;30
	db #28,#DE,#80 ;31
	db #27,#8D,#00 ;30
	db #28,#DE,#80 ;31	
	
;високосные годы
year_leap dw 1904, 1908, 1912, 1916, 1920, 1924, 1928, 1932, 1936, 1940, 1944, 1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020, 2024, 2028, 2032,2036, 2040, 2044, 2048, 2052, 2056, 2060, 2064, 2068, 2072, 2080, 2084, 2088, 2092, 2096, 2104, 2108, 2112, 2116, 2120, 2124, 2128, 2132,0 ;
	
    SAVETRD "NETTIME.TRD",|"nettime.C",origin, $ - origin
	
	align #1000
buffer