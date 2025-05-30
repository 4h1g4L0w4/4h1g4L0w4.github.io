---
title: "Deshabilitar Backdoor Intel"
author: augusto
date: 2025-05-30
tags: [seguridad, privacidad]
categories: [Seguridad, Privacidad]
description: "Que es y como es posible deshabilitar el Intel Managment Engine a traves de Coreboot"
---
Lo más probable es que ahora mismo estés ejecutando software espía de código cerrado en tu sistema. Diseñado para un control remoto completo y una vigilancia perfecta, esta puerta trasera está instalada en la capa de hardware, lo que hace que sea muy difícil deshacerse de ella.

Así que si no sabes qué es el **Intel Management Engine (IME)** y de qué es capaz, continúa leyendo.

---

## ¿Qué es el IME?

Cuando empezó a salir información sobre IME, lo llamaron un **chip dentro de un chip** porque es un subsistema completamente autónomo.

En realidad, **no está dentro de la CPU**, como se pensó al principio, sino que está ubicado en el **PCH (Platform Controller Hub)**.

Es de **código completamente cerrado**. Incluye varios módulos, uno de los cuales es el **AMT**, para administración remota. Funciona igual que **ILO**, para una administración remota a nivel de hardware.

* Ejecuta un sistema operativo **Minix 3**.
* Está incluido en todos los **chipsets de Intel desde 2008**, y en algunos subconjuntos anteriores a 2006.
* Se ejecuta en un microprocesador **Intel Quark de 32 bits**.
* Tiene su propio sistema de archivos independiente, almacenado en la **SPI Flash**.

Algunos de los otros módulos incluidos en el IME son **Boot Guard**, **DRM** y muchos más.

---

## ¿Qué puede hacer?

* El IME **está activo incluso en estado S3 (apagado)** mientras la energía esté conectada.
* Tiene **su propia red separada y pila TCP/IP independiente del sistema operativo**.
* Se comunica **fuera de banda**: el sistema operativo **no puede ver ni modificar los paquetes**.

> “Podrías pensar: ‘bueno, tengo un dispositivo de red, tengo SEIM, tengo Wireshark ejecutándose en otro sistema’… pero ese sistema **también puede tener un IME** en él.”

* Tiene **acceso completo de lectura y escritura a toda la RAM**.
* Tiene **acceso completo al bus del sistema**.
* Opera en modo **SMM (System Management Mode)**, completamente invisible para el sistema operativo.

Este es **básicamente un modo dios**: puede leer y escribir en cualquier cosa del sistema.

> “Si recibe un paquete mágico a través de la red, el AMT puede **activarse remotamente** para encender el sistema, cambiar configuraciones del BIOS, ver la salida de video… hacer cualquier cosa que un usuario podría hacer sentado físicamente frente al equipo.”

---

## ⚠️ Vulnerabilidades históricas

Con tanto poder, cabría esperar un sistema reforzado. Pero **no es así**. Algunos ejemplos documentados:

* **2009** – *Invisible Things Lab* desarrolló un **rootkit persistente** que vive dentro del IME, en modo SMM, invisible para el sistema operativo.
* **2010** – *Basilis Vassilatos* descubrió un **bypass de autenticación** para AMT, incluso si estaba desactivado en el BIOS.
* **2017** – *Silent Bob* (vulnerabilidad silenciosa): solo enviando un campo nulo como contraseña al AMT, se accede a **capacidades completas de administración remota**.
* **También en 2017** – Vulnerabilidad de **desbordamiento de búfer** que permite ejecución remota de código.

---

## ¿Es esto una puerta trasera?

Todo esto es **de código cerrado**, y muy difícil de auditar. Intel lo ha hecho **intencionalmente difícil de desactivar**:

* El firmware del IME está en una **región protegida** de la SPI Flash.
* Módulos principales **firmados con RSA**. Si la firma falla, **no arranca**.
* Usa compresión **LCMA**, **Huffman**, y un **directorio oculto** como ofuscación.
* Un módulo de verificación revisa la firma cada **30 minutos**. Si detecta fallo, **apaga el sistema**.

> “Todo esto lleva a la especulación de que podría ser una **puerta trasera intencional**, quizás incluso de la **NSA**.”

#### Imaginemos...

> “Si yo fuera la NSA y diseñara una puerta trasera global…”

* Querría que fuera **independiente del sistema operativo**.
* Que **no se pudiera desactivar**.
* Que pudiera **encender el equipo incluso apagado**.
* Que fuera **invisible**.
* Que tuviera **acceso completo**.
* Que tuviera **comunicaciones fuera de banda**.
* Que ofreciera **negación plausible** (explotar bugs en vez de dejar evidencia directa).

#### ¿Qué podría hacer?

* Extraer **claves de cifrado** directamente desde la RAM.
* **Exfiltrar datos** desde sistemas air-gapped, habilitando el módulo Wi-Fi incluso si estaba desactivado.
* **Infectar unidades USB**, que luego infecten otros sistemas aislados.

---

## Cómo deshabilitar el IME y liberar tu PC
### **¿Qué es coreboot?**

**coreboot** (antes LinuxBIOS) es un **firmware de código abierto** diseñado para reemplazar el BIOS propietario que viene preinstalado en la mayoría de las computadoras. Su objetivo es **inicializar el hardware** (como CPU, RAM, y dispositivos de entrada/salida) de la forma más rápida y mínima posible, y luego **pasar el control al sistema operativo**.

A diferencia del BIOS tradicional, coreboot es:

* **Modular** y altamente configurable.
* **Ligero**: hace solo lo necesario para arrancar el sistema.
* **Transparente**: puedes auditar y modificar su código.
* **Libre de software espía** o componentes innecesarios.

---

### **¿Por qué coreboot permite deshabilitar el Intel Management Engine (IME)?**

El IME está integrado en los chipsets Intel, pero no forma parte del CPU. Aunque no puede eliminarse completamente sin afectar la estabilidad del sistema, **sí puede ser "neutralizado" o desactivado parcialmente**, y coreboot es la herramienta más efectiva para lograrlo. Esto se logra de las siguientes maneras:

#### 1. **Permite modificar la región de firmware donde vive el IME**

* El IME reside en una parte de la **SPI flash** que normalmente no es accesible.
* Al usar coreboot junto con herramientas como **me\_cleaner**, se puede eliminar la mayoría de los módulos del IME y dejarlo en un estado "inactivo".

#### 2. **Evita cargar el firmware del IME al inicio**

* Al personalizar tu propio BIOS con coreboot, puedes excluir o minimizar los módulos del IME.
* Algunos portátiles permiten que el IME entre en un estado llamado **"soft-disable"**, lo que significa que el microcódigo aún está ahí, pero **no se ejecuta funcionalmente**.

#### 3. **Te da control total sobre tu firmware**

* No dependes del BIOS del fabricante, que generalmente impide modificar o deshabilitar el IME.
* Puedes auditar qué módulos están incluidos y comprobar que **no hay puertas traseras**.

---

### Conclusión:

La gran mayoria de las laptops Lenovo de la serie Thinkpad son compatibles con Coreboot o alguna distribucion de este. Lo que te garantiza una pc:
* Barata.
* Rápida.
* Segura.
* Sin vigilancia.
* Sin puertas traseras.

 Ejemplo de instalacion de coreboot [Tutorial](https://www.youtube.com/watch?v=hERguULT7Vo) (recuerda buscar tu modelo de preferencia)
