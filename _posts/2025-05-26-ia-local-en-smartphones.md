---
title: "Como correr IA de manera local en smartphones"
author: augusto
date: 2025-05-26
categories: [IA, Privacidad, Open Source]
tags: [ia, privacidad, open source]
description: "PocketPal AI, una aplicación que lleva modelos de lenguaje directamente a tu teléfono, funcionando completamente offline y protegiendo tu privacidad."
--------------------------------------

## ¿Qué es PocketPal AI?

[**PocketPal AI**](https://github.com/a-ghorbani/pocketpal-ai) es una innovadora aplicación de código abierto que permite ejecutar modelos de lenguaje directamente en tu dispositivo móvil, sin necesidad de conexión a internet. Desarrollada por [Asghar Ghorbani](https://github.com/a-ghorbani), esta herramienta está diseñada para dispositivos iOS y Android, brindando una experiencia de asistente de IA completamente offline y privada.

### Características Principales

* **Modelos de Lenguaje Pequeños (SLMs)**: Utiliza modelos optimizados para funcionar eficientemente en dispositivos móviles.
* **Funcionamiento Offline**: Toda la ejecución se realiza en el dispositivo, eliminando la necesidad de conexión a internet.
* **Privacidad Garantizada**: Tus datos y conversaciones nunca salen de tu teléfono, asegurando una experiencia segura y privada.
* **Compatibilidad Multiplataforma**: Disponible tanto para iOS como para Android.
* **Integración con Hugging Face**: Permite descargar y utilizar modelos directamente desde Hugging Face con autenticación mediante token.

## Instalación y Configuración

### Requisitos Previos

* **Dispositivo Compatible**: Un smartphone con iOS o Android.
* **Espacio de Almacenamiento**: Suficiente espacio para descargar e instalar los modelos de lenguaje.
* **Conexión Inicial a Internet**: Solo necesaria para descargar la aplicación y los modelos deseados.

### Pasos de Instalación

1. **Descargar la Aplicación**:

   * Para Android: Disponible en [Google Play Store](https://play.google.com/store/apps/details?id=com.pocketpalai).
   * Para iOS: Actualmente, la instalación requiere pasos adicionales detallados en el repositorio oficial.

2. **Configurar Token de Hugging Face (Opcional)**:

   * Si deseas acceder a modelos alojados en Hugging Face, necesitarás un token de acceso.
   * Crea una cuenta en [Hugging Face](https://huggingface.co/) y genera un token desde tu perfil.
   * En la aplicación, navega a la sección de configuración y añade tu token para habilitar la descarga de modelos.

3. **Descargar Modelos de Lenguaje**:

   * Dentro de la aplicación, accede a la sección de modelos.
   * Selecciona y descarga los modelos que desees utilizar. Algunos modelos populares incluyen Gemma 3 y Llama.

4. **Iniciar Conversaciones**:

   * Una vez descargados los modelos, puedes comenzar a interactuar con ellos directamente desde la aplicación, sin necesidad de conexión a internet.

## Uso de PocketPal AI

### Interfaz de Usuario

La aplicación presenta una interfaz intuitiva y amigable, facilitando la interacción con los modelos de lenguaje. Algunas funcionalidades destacadas incluyen:

* **Chat en Tiempo Real**: Interactúa con los modelos como lo harías con cualquier asistente de IA.
* **Edición de Mensajes**: Modifica tus entradas para refinar las respuestas obtenidas.
* **Copia de Texto**: Copia fácilmente las respuestas generadas para utilizarlas en otras aplicaciones.
* **Benchmarking**: Evalúa el rendimiento de los modelos en tu dispositivo y contribuye al leaderboard si lo deseas.

### Uso de "Pals"

Una característica única de PocketPal AI es la implementación de "Pals", que son personalidades o configuraciones predefinidas que modifican el comportamiento del modelo para adaptarse a diferentes contextos o necesidades.

## Experiencia en mi S24 Ultra

Actualmente estoy corriendo el modelo qwen2.5-3b-instruct-q5_k_m sin ningun inconveniente. El modelo tarda 1-2 segundos en cargar y genera ~11 t/S a ~90ms por token.

## Conclusión

PocketPal AI representa un avance significativo en la accesibilidad y privacidad de los asistentes de inteligencia artificial. Al permitir la ejecución de modelos de lenguaje directamente en dispositivos móviles y sin conexión a internet, ofrece una solución potente y respetuosa con la privacidad del usuario. Ya seas un entusiasta de la tecnología, un desarrollador o simplemente alguien interesado en explorar las capacidades de la IA, PocketPal AI es una herramienta que vale la pena probar.
