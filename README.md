# GOWIN
Examples for FPGA GOWIN

Примеры проектов разной направленности для ПЛИС GOWIN  
a) Передача содержимого блочного ОЗУ FPGA GOWIN по UART.

* SinglePort BSRAM. 
* Конечный автомат формирует поток UART вида $ADDR#D0 D1 ... D15<CR>  
  

<image src="/images/Dump GOWIN.png" border="5px solid red"/>

б) Перердача содержимого блочного ОЗУ FPGA GOWIN по UART. 
* DualPort BSRAM. 
* Первый порт - изменение содержимого ОЗУ.
* Второй порт - конечный автомат формирования по UART отладочного потока форматом указанным в пункте а.  
  

<image src="/images/SerialDebug.png" border="5px solid red"/>

SerialDebugFPGA - програмное обеспечение, FreePascal Lazarus, снимающая поток заданного в пункте "а" формата в дамп памяти, снятие потока непрерывное.

в) Секвенсер микрокода отрабатывает последовательность инструкций

MOV AL, 0xA5

MOV [0x0031], AL

MOV AL, 0x5A

MOV [0x0030], AL

MOV BL, 0x40

MOV [BX], AL

<image src="/images/SerialDebug_micro.png" border="5px solid red"/>
