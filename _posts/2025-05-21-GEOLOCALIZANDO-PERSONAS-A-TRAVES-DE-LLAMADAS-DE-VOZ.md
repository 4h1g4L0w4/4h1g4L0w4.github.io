---
title: GEOLOCALIZANDO PERSONAS A TRAVÉS-DE LLAMADAS DE VOZ
date: 2025-05-21
---
📌 Introducción​

VoLTE (Voice over LTE) permite realizar llamadas sobre redes móviles 4G utilizando el protocolo IMS (IP Multimedia Subsystem). Este sistema, aunque mejora la calidad de las llamadas, también aumenta la complejidad del servicio y puede introducir problemas de seguridad si no se configura correctamente


📶 Contexto: O2 UK y VoLTE​

Desde 2017, O2 UK ofrece llamadas 4G mediante IMS. Al investigar su implementación con un Google Pixel 8 rooteado y la app Network Signal Guru (NSG), se descubrió que las señales IMS enviadas al iniciar una llamada contenían información privada sensible

🕵️‍♂️ Paso a paso: Cómo se filtraba la ubicación​

    Realiza una llamada VoLTE desde un dispositivo O2 compatible.
    Intercepta los mensajes SIP/IMS enviados por la red al dispositivo llamante.
    Observa los siguientes encabezados SIP que se incluían en la respuesta:
    P-Mav-Extension-IMSI: <IMSI del emisor>
    P-Mav-Extension-IMSI: <IMSI del receptor>
    P-Mav-Extension-IMEI: <IMEI del emisor>
    P-Mav-Extension-IMEI: <IMEI del receptor>
    Cellular-Network-Info: 3GPP-E-UTRAN-FDD;utran-cell-id-3gpp=23410XXXXXXX;cell-info-age=XXXXX
    
