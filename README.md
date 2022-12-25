# GOWIN
Examples for FPGA GOWIN

Примеры проектов разной направленности для ПЛИС GOWIN  

1. Передача содержимого блочного ОЗУ FPGA GOWIN по UART. Конечный автомат формирует поток UART вида $ADDR#D0 D1 ... D15<CR>   Терминальный доступ для отображения потока отладчика.

   ![](C:\Users\saa\Dropbox\GitHubProjects\GOWIN\images\Dump GOWIN.png)

2. Передача содержимого блочного ОЗУ FPGA GOWIN с одного порта доступа к памяти по UART. По второму порту доступа в ОЗУ производится запись инкрементального счетчика. Для отображения используется утилита SerialDebug (Lazarus, free pascal sources).

![](C:\Users\saa\Dropbox\GitHubProjects\GOWIN\images\SerialDebug.png)
