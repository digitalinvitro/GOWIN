# GOWIN
Examples for FPGA GOWIN

Примеры проектов разной направленности для ПЛИС GOWIN  
a) Передача содержимого блочного ОЗУ FPGA GOWIN по UART. SinglePort BSRAM. Конечный автомат формирует поток UART вида $ADDR#D0 D1 ... D15<CR>
<image src="/images/Dump GOWIN.png" border="5px solid red"/>
б) Перердача содержимого блочного ОЗУ FPGA GOWIN по UART. DualPort BSRAM. С одного порта происходит изменение содержимого ОЗУ, со второго порта передача по UART отладочного потока форматом указанным в пункте а.
<image src="/images/SerialDebug.png" border="5px solid red"/>
