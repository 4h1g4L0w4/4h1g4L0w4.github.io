---
title: "Geolocalizacion a Traves de Llamadas de Voz"
author: augusto
date: 2025-05-21
tags: [seguridad, privacidad, telecomunicaciones]
categories: [Seguridad, Privacidad]
description: "Cómo la implementación de VoLTE en O2 UK filtra información sensible como ubicación, IMSI e IMEI durante las llamadas 4G a través del protocolo IMS."
---

# Geolocalizando objetivo con una llamada telefonica

## Introducción

**VoLTE** (Voice over LTE) permite realizar llamadas de voz sobre redes 4G utilizando el protocolo **IMS** (IP Multimedia Subsystem). Esta tecnología mejora la calidad de las llamadas y reduce la latencia, pero también introduce nuevas superficies de ataque cuando no se configura de forma segura.

## Contexto: O2 UK y VoLTE

O2 UK ofrece llamadas 4G a través de IMS desde 2017. Al usar un dispositivo **Google Pixel 8 rooteado** junto con la aplicación **Network Signal Guru (NSG)**, se detecta que la red de O2 incluye información sensible dentro de los encabezados SIP/IMS durante el establecimiento de una llamada VoLTE. Esta información expone detalles privados del emisor y del receptor, incluyendo su ubicación aproximada.

## Paso a paso: Cómo se filtra la ubicación

1. Se realiza una llamada VoLTE desde un dispositivo compatible con la red de O2.
2. Se interceptan los mensajes **SIP/IMS** enviados entre el dispositivo y la red móvil.
3. Se inspeccionan los encabezados SIP contenidos en la señalización:

```bash
---
P-Mav-Extension-IMSI: <IMSI del emisor>
P-Mav-Extension-IMSI: <IMSI del receptor>
P-Mav-Extension-IMEI: <IMEI del emisor>
P-Mav-Extension-IMEI: <IMEI del receptor>
Cellular-Network-Info: 3GPP-E-UTRAN-FDD;utran-cell-id-3gpp=23410XXXXXXX;cell-info-age=XXXXX
---
```

## Análisis del encabezado `Cellular-Network-Info`

El encabezado `Cellular-Network-Info` incluye campos que permiten determinar la ubicación aproximada del receptor de la llamada:

- **PLMN ID:** Identificador del operador y país.
- **UTRAN Cell ID:** Identificador de la celda a la que está conectado el usuario.
- **cell-info-age:** Tiempo desde la última actualización de esa información de red.

## Geolocalización con Cell ID

Herramientas públicas como [**cellmapper.net**](https://cellmapper.net) permiten convertir el **Cell ID** en coordenadas GPS con una precisión de hasta **100 m²** en entornos urbanos. Basta con introducir el identificador de celda para visualizar su ubicación en un mapa.

![img](/assets/img/cell-header-breakdown-ee1811a0608846ee73b1ff754a072b07.svg)

## Ejemplo práctico

Con un Cell ID obtenido durante una llamada, se puede:

- Identificar el sitio celular correspondiente.
- Visualizar la celda en **Cellmapper**.
- Estimar la posición física del receptor con alta precisión.

> Incluso si el receptor se encuentra en **roaming**, es posible determinar su ubicación exacta a partir del Cell ID presente en los encabezados SIP.

![img](/assets/img/cell-id-calculator.avif)

## ¿Por qué representa un problema grave?

- **Se expone la ubicación exacta del receptor** sin su consentimiento ni conocimiento.
- **Se revelan identificadores sensibles** como el **IMEI** e **IMSI**, lo cual permite rastrear dispositivos o suplantar la identidad del usuario.
- **No se requiere acceso avanzado**: con conocimientos básicos de redes IMS/SIP y herramientas como Wireshark o NSG, cualquier persona puede explotar esta vulnerabilidad.

![img](/assets/img/cellmapper-sector.avif)

## Implicancias de seguridad

- Permite realizar **rastreo en tiempo real** de usuarios móviles.
- Facilita ataques de **phishing, spoofing o ingeniería social** mediante el uso del IMEI e IMSI.
- Rompe principios básicos de **privacidad de las telecomunicaciones** al exponer metadatos sensibles.

