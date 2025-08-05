---
title: "Proyecto Infraestructura HA para Bot de Whatsapp con N8N y K8S"
author: augusto
date: 2025-08-05
tags: [proyectos, trabajo]
categories: [Proyectos, Trabajo]
description: "Proyecto e implementacion de un entorno de alta disponibilidad en K8S para un Bot de Whatsapp desarrollado en N8N"
mermaid: true
---

# Proyecto Infraestructura HA para Bot de Whatsapp con N8N y K8S

## Descripcion
El objetivo del proyecto es realizar un entorno de alta disponibilidad y escalabilidad para un bot de whatsapp creado con N8N, el cual tiene un alto flujo de peticiones utilizando Kubernetes (Orquestador con el cual N8N no es compatible).
Como N8N (a dia de hoy) no esta pensado para utilizarse con Replicas en K8S. Se creo un servicio custom para monitorear el HPA de K8S y que al aumentar el nuemro de replicas de un entrypoint, este dispare la ejecucion de los deployments necesarios de N8N (MAX 3) para poder manejar la cantidad de trafico entrante.

## Tecnologias utilizadas
**Docker:** Plataforma para ejecutar aplicaciones en contenedores ligeros y portables.
**K8S:** Sistema que gestiona y escala contenedores automáticamente en clústeres.
**N8N:** Herramienta visual de automatización para conectar apps y servicios sin código.
**HaProxy:** es un software de balanceo de carga y proxy inverso de alto rendimiento. 
**Custom Service:** Servicio utilizado para monitorear el HPA de K8S y ejecutar los Deployments de Kubernetes para poder escalar/reducir el las instancias
**N8N Trigger:** Backend donde llegan los mensajes y sirve como trigger para ejecutar los flujos de Chat de N8N

## Diagrama
img src="/assets/img/n8nha.png" alt="Diagrama de la infraestructura" width="600" />

---

## Setup de servicios:

### Entrypoint Service

**Deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whatsapp-web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: whatsapp-web-app
  template:
    metadata:
      labels:
        app: whatsapp-web-app
    spec:
      containers:
        - name: whatsapp-web-app
          image: ghcr.io/privado/whatsapp-web-app:v2
          ports:
            - containerPort: 3008
          envFrom:
            - secretRef:
                name: whatsapp-web-app-secret
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
      imagePullSecrets:
        - name: ghcr-secret
```

**Service.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: whatsapp-web-app-service
spec:
  selector:
    app: whatsapp-web-app
  type: NodePort
  ports:
    - protocol: TCP
      port: 3008
      targetPort: 3008
      nodePort: 31008
```

**Secret.yaml**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: whatsapp-web-app-secret
type: Opaque
stringData:
  POSTGRES_DB_HOST: x
  POSTGRES_DB_USER: x
  POSTGRES_DB_NAME: x
  POSTGRES_DB_PASSWORD: x
  POSTGRES_DB_PORT: "x"
  POSTGRES_DB_SCHEMA: x
  TOKEN_WSP: x
  NUMBER_ID_WSP: "x"
  TOKEN_VERIFY_API_WSP: x
  VERSION_API_WSP: v23.0
  PORT: "3008"
```

**HPA.yaml**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: whatsapp-web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: whatsapp-web-app
  minReplicas: 1
  maxReplicas: 3
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
```

### HAProxy Service

**Service.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: haproxy-nodeport
spec:
  type: NodePort
  selector:
    app: haproxy
  ports:
    - protocol: TCP
      port: 5555
      targetPort: 5555
      nodePort: 30555
```

**Deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: haproxy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: haproxy
  template:
    metadata:
      labels:
        app: haproxy
    spec:
      containers:
        - name: haproxy
          image: haproxy:2.9
          ports:
            - containerPort: 80
          volumeMounts:
            - name: config
              mountPath: /usr/local/etc/haproxy/haproxy.cfg
              subPath: haproxy.cfg
      volumes:
        - name: config
          configMap:
            name: haproxy-config
```

**ConfigMap.yaml**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: haproxy-config
data:
  haproxy.cfg: |
    global
        daemon
        maxconn 256

    defaults
        mode http
        timeout connect 5s
        timeout client  50s
        timeout server  50s

    frontend http-in
        bind *:5555
        default_backend k8s-backend

    backend k8s-backend
        balance roundrobin
        option httpchk GET /
        server n8n1 n8n.default.svc.cluster.local:5678 check
        server n8n3 n8n3.default.svc.cluster.local:5680 check
        server n8n4 n8n4.default.svc.cluster.local:5682 check
```

### N8N Service
En esta parte se despliegan 3 servicios de N8N individuales no solo voy a ejemplificar con uno solo. Hay cambios minimos entre instancias como el puerto y el nombre

**Service.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: n8n4
spec:
  selector:
    app: n8n4
  type: NodePort
  ports:
    - name: http
      port: 5682
      targetPort: 5682
      nodePort: 30582
```

**PV-PVC.yaml**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: n8n4-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /root/kuber/n8n4/.n8n
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: n8n4-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Deployment:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n4
spec:
  replicas: 1
  selector:
    matchLabels:
      app: n8n4
  template:
    metadata:
      labels:
        app: n8n4
    spec:
      containers:
        - name: n8n4
          image: n8nio/n8n:latest
          env:
            - name: GENERIC_TIMEZONE
              value: "America/Argentina/Buenos_Aires"
            - name: N8N_BASIC_AUTH_ACTIVE
              value: "true"
            - name: N8N_BASIC_AUTH_USER
              valueFrom:
                secretKeyRef:
                  name: n8n4-secret
                  key: N8N_BASIC_AUTH_USER
            - name: N8N_BASIC_AUTH_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: n8n4-secret
                  key: N8N_BASIC_AUTH_PASSWORD
#            - name: DB_TYPE
#              value: postgresdb
#            - name: DB_POSTGRESDB_HOST
#              value: postgresql
#            - name: DB_POSTGRESDB_PORT
#              value: "5432"
#            - name: DB_POSTGRESDB_DATABASE
#              value: n8n
#            - name: DB_POSTGRESDB_USER
#              valueFrom:
#                secretKeyRef:
#                  name: n8n-secret
#                  key: DB_POSTGRESDB_USER
#            - name: DB_POSTGRESDB_PASSWORD
#              valueFrom:
#                secretKeyRef:
#                  name: n8n-secret
#                  key: DB_POSTGRESDB_PASSWORD
            - name: WEBHOOK_URL
              value: "https://privado.ar/"
            - name: N8N_PROTOCOL
              value: "https"
            - name: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE
              value: "true"
            - name: N8N_SECURE_COOKIE
              value: "false"
            - name: N8N_PORT
              value: "5682"
          ports:
            - containerPort: 5682
          volumeMounts:
            - name: n8n4-storage
              mountPath: /home/node/.n8n
      volumes:
        - name: n8n4-storage
          persistentVolumeClaim:
            claimName: n8n4-pvc
```

**Secrets.yaml:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: n8n4-secret
type: Opaque
stringData:
  N8N_BASIC_AUTH_USER: x
  N8N_BASIC_AUTH_PASSWORD: x
#  DB_POSTGRESDB_USER: n8nuser
#  DB_POSTGRESDB_PASSWORD: n8npass
```

### HPA-Watcher

**hpa-watcher.service:**

```bash
[Unit]
Description=Watcher de HPA para whatsapp-web-app
After=network.target

[Service]
ExecStart=/usr/local/bin/hpa-watcher.sh
Restart=always
User=root
Environment=KUBECONFIG=/root/.kube/config
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**hpa-watcher.sh:**

```bash
#!/bin/bash

# Configuración
HPA_NAME="whatsapp-web-app-hpa"
NAMESPACE="default"
CHECK_INTERVAL=10

# Nombre de los deployments adicionales
WORKER_DEPLOYMENTS=("n8n3" "n8n4")
YAML_DIR="/usr/local/bin/deployments"

# Validación inicial
if ! kubectl version --short &>/dev/null; then
  echo "[ERROR] kubectl no está configurado correctamente o no tiene permisos."
  exit 1
fi

echo "[INFO] Monitoreando HPA: $HPA_NAME"

# Obtener el valor inicial de réplicas
PREV_REPLICAS=$(kubectl get hpa "$HPA_NAME" -n "$NAMESPACE" -o jsonpath='{.status.currentReplicas}')

while true; do
  CURRENT_REPLICAS=$(kubectl get hpa "$HPA_NAME" -n "$NAMESPACE" -o jsonpath='{.status.currentReplicas}')
  
  if [ "$CURRENT_REPLICAS" != "$PREV_REPLICAS" ]; then
    echo "[EVENT] Cambio de réplicas: $PREV_REPLICAS → $CURRENT_REPLICAS"

    # Controlar despliegue de n8n3 y n8n4 según número de réplicas
    if [ "$CURRENT_REPLICAS" -ge 2 ]; then
      echo "[DEPLOY] Desplegando n8n3"
      kubectl apply -f "$YAML_DIR/n8n3.yaml" -n "$NAMESPACE"
    else
      echo "[DELETE] Eliminando n8n3"
      kubectl delete deployment n8n3 -n "$NAMESPACE" --ignore-not-found
    fi

    if [ "$CURRENT_REPLICAS" -ge 3 ]; then
      echo "[DEPLOY] Desplegando n8n4"
      kubectl apply -f "$YAML_DIR/n8n4.yaml" -n "$NAMESPACE"
    else
      echo "[DELETE] Eliminando n8n4"
      kubectl delete deployment n8n4 -n "$NAMESPACE" --ignore-not-found
    fi

    PREV_REPLICAS=$CURRENT_REPLICAS
  fi

  sleep "$CHECK_INTERVAL"
done

```

## A TENER EN CUENTA
Este post es con fines demostrativos, todos los datos sensibles han sido removidos y lo presentado difiere con lo que se encuentra productivo para proteger la privacidad de la organizacion
