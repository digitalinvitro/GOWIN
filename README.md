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
