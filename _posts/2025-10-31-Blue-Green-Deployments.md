---
title: "Zero Downtime K8S Blue/Green Deployments"
author: augusto
date: 2025-10-31
tags: [proyectos, trabajo]
categories: [Proyectos, Trabajo]
description: "Documentación completa sobre cómo implementar deployments sin downtime utilizando la estrategia Blue/Green en Kubernetes"
mermaid: true
---

## 📚 ¿Qué es Blue/Green Deployment?

Blue/Green es una estrategia de deployment que mantiene dos entornos idénticos en producción:

- **Blue**: Versión activa recibiendo todo el tráfico
- **Green**: Versión de standby preparada para activarse

Al hacer un nuevo deployment:
1. Se despliega la nueva versión en el entorno inactivo
2. Se espera a que esté completamente operativa
3. Se cambia el tráfico instantáneamente
4. La versión anterior se escala a 0 réplicas

## ✨ Ventajas Clave

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph LR
    A[Blue/Green] --> B[Zero Downtime]
    A --> C[Rollback Rápido]
    A --> D[Testing en Producción]
    A --> E[Aislamiento Total]
    A --> F[Menor Riesgo]
    
    style A fill:#e1f5ff
    style B fill:#d4edda
    style C fill:#cce5ff
    style D fill:#fff3cd
    style E fill:#d1ecf1
    style F fill:#d4edda
```

- ✅ **Zero Downtime**: El tráfico nunca se interrumpe
- ✅ **Rollback Instantáneo**: Solo cambiar el selector del servicio
- ✅ **Testing en Producción**: Validar antes de cambiar tráfico
- ✅ **Sin Impacto**: Usuarios activos nunca se ven afectados
- ✅ **Menor Riesgo**: Fallos no afectan producción inmediata

---

## ⚡ Inicio Rápido

Guía para tener Blue/Green deployments funcionando en menos de 10 minutos.

### Prerrequisitos

- [ ] Cluster de Kubernetes configurado
- [ ] kubectl instalado y configurado
- [ ] Acceso al cluster
- [ ] GitHub Actions configurado
- [ ] Secrets configurados en GitHub

### Paso 1: Configurar Registry Secret

```bash
kubectl create secret docker-registry registry-secret \
  --docker-server=ghcr.io \
  --docker-username="YOUR_USERNAME" \
  --docker-password="YOUR_PAT" \
  --docker-email="your-email@example.com"
```

### Paso 2: Aplicar Deployments

```bash
# Aplicar deployment blue
kubectl apply -f deployment-blue.yaml

# Aplicar deployment green
kubectl apply -f deployment-green.yaml

# Aplicar servicio (apuntando a blue por defecto)
kubectl apply -f service.yaml
```

### Paso 3: Verificar Estado

```bash
# Ver deployments
kubectl get deployments -l app=myapp

# Ver pods
kubectl get pods -l app=myapp

# Ver servicio
kubectl get svc myapp-svc

# Ver versión activa
kubectl get svc myapp-svc -o jsonpath='{.spec.selector.version}'
```

Deberías ver algo como:

```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
myapp-blue            1/1     1            1           5m
myapp-green           0/1     1            0           5m

NAME                        STATUS    AGE
myapp-svc                   ClusterIP 5m

Versión activa: blue
```

### Paso 4: Hacer un Deployment

#### Deployment Automático (GitHub Actions)

```bash
# Hacer push a main
git push origin main

# El workflow automáticamente:
# 1. Build de imagen
# 2. Push a GHCR
# 3. Blue/Green deployment
```

#### Deployment Manual

Si necesitas hacer un deployment manual:

```bash
# Detectar versión actual
CURRENT=$(kubectl get svc myapp-svc -o jsonpath='{.spec.selector.version}')

# Calcular próxima versión
[ "$CURRENT" = "blue" ] && NEXT="green" || NEXT="blue"

# Desplegar
kubectl set image deployment/myapp-$NEXT myapp=ghcr.io/YOUR_ORG/YOUR_APP:latest

# Esperar rollout
kubectl rollout status deployment/myapp-$NEXT --timeout=5m

# Cambiar tráfico
kubectl patch svc myapp-svc -p "{\"spec\":{\"selector\":{\"version\":\"$NEXT\"}}}"

# Limpiar versión anterior
kubectl scale deployment/myapp-$CURRENT --replicas=0
```

---

## 🏗️ Arquitectura del Sistema

### Vista General

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph TB
    subgraph "Development"
        A[Developer]
        B[Git Repository]
    end
    
    subgraph "GitHub"
        C[GitHub Actions]
        D[GHCR Registry]
        E[Secrets]
    end
    
    subgraph "Kubernetes Cluster"
        F[Blue Deployment]
        G[Green Deployment]
        H[Service]
        I[Secrets]
    end
    
    subgraph "Users"
        J[Client 1]
        K[Client 2]
        L[Client N]
    end
    
    A -->|push| B
    B -->|trigger| C
    E --> C
    C -->|build & push| D
    C -->|deploy| F
    C -->|deploy| G
    C -->|configure| H
    I --> F
    I --> G
    
    H -->|route| F
    H -->|route| G
    
    J --> H
    K --> H
    L --> H
    
    style C fill:#e1f5ff
    style D fill:#fff3cd
    style H fill:#d4edda
```

### Componentes Principales

#### 1. GitHub Actions Workflow

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph LR
    A[Checkout] --> B[Build]
    B --> C[Push]
    C --> D[Deploy Blue/Green]
    
    D --> E[Detect Version]
    D --> F[Scale Next]
    D --> G[Update Image]
    D --> H[Wait Rollout]
    D --> I[Switch Traffic]
    D --> J[Cleanup]
    
    style D fill:#cce5ff
```

#### 2. Kubernetes Resources

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph TB
    subgraph "Blue Deployment"
        A[name: myapp-blue<br/>label: version=blue]
        A --> B[1 replica active]
    end
    
    subgraph "Green Deployment"
        C[name: myapp-green<br/>label: version=green]
        C --> D[0 replicas standby]
    end
    
    E[Service] -->|selector: version=blue| A
    E -.->|not routing| C
    
    style A fill:#cce5ff
    style C fill:#d3d3d3
    style E fill:#d4edda
```

### Flujo de Datos

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
sequenceDiagram
    autonumber
    participant Dev as Developer
    participant GH as GitHub
    participant Actions as Workflow
    participant GHCR as Registry
    participant K8s as Kubernetes
    participant Blue
    participant Green
    participant Service
    participant User
    
    Dev->>GH: git push
    GH->>Actions: Trigger
    
    Actions->>Actions: Build image
    Actions->>GHCR: Push image
    Actions->>K8s: kubectl set image
    
    K8s->>Green: Update deployment
    Green->>Green: Pull image
    Green->>Green: Start pod
    
    Actions->>K8s: kubectl rollout status
    Green-->>Actions: Ready
    
    Actions->>K8s: kubectl patch svc
    K8s->>Service: Change selector
    Service->>Green: Route traffic
    Service->>Blue: Stop routing
    
    User->>Service: Request
    Service->>Green: Forward
    
    Actions->>K8s: kubectl scale
    K8s->>Blue: Scale to 0
```

---

## 🔄 Flujo Completo de Deployment

### Ciclo de Deployment

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
stateDiagram-v2
    [*] --> BlueActive: Initial
    
    BlueActive --> GreenBuilding: New Push
    GreenBuilding --> GreenReady: Success
    GreenReady --> GreenActive: Switch
    GreenActive --> BlueStopped: Cleanup
    
    GreenBuilding --> BlueActive: Failed
    
    GreenActive --> BlueBuilding: New Push
    BlueBuilding --> BlueReady: Success
    BlueReady --> BlueActive: Switch
    BlueActive --> GreenStopped: Cleanup
    
    BlueBuilding --> GreenActive: Failed
    
    note right of BlueActive
        1 replica receiving traffic
        All users routed here
    end note
    
    note right of GreenBuilding
        Scaling from 0 to 1
        Updating image
        Not receiving traffic yet
    end note
    
    note right of GreenReady
        Fully ready and tested
        Waiting for traffic switch
    end note
    
    note right of BlueStopped
        Scaled to 0
        Not consuming resources
    end note
```

### Timeline del Deployment

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph TB
    Start([git push origin main]) --> Build[Build Docker Image]
    Build --> Push[Push to GHCR]
    Push --> Detect[Detect Current Version]
    
    Detect -->|Current: blue| DeployGreen[Deploy to Green]
    Detect -->|Current: green| DeployBlue[Deploy to Blue]
    
    DeployGreen --> Wait[Wait for Rollout]
    DeployBlue --> Wait
    
    Wait --> Check{Rollout OK?}
    
    Check -->|✅ Success| Switch[Switch Traffic]
    Check -->|❌ Failed| Stop([Stop: Keep Current])
    
    Switch --> Cleanup[Scale Previous to 0]
    Cleanup --> Success([✅ Complete])
    
    style Start fill:#e1f5ff
    style Switch fill:#cce5ff
    style Success fill:#d4edda
    style Stop fill:#f8d7da
```

---

## 📊 Diagrama Detallado del Workflow

### Pipeline Completo

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph TD
    Start([Push a main / Manual Trigger]) --> Checkout[Checkout Code]
    Checkout --> ShowContext[Show Context]
    ShowContext --> LoginGHCR[Login to GHCR]
    LoginGHCR --> CreateEnv[Create .env from Secrets]
    CreateEnv --> BuildImage[Build Docker Image]
    
    BuildImage --> BuildDetails{2 Tags}
    BuildDetails -->|ghcr.io/YOUR_ORG/YOUR_APP:SHA| Tag1[Tag: $SHA]
    BuildDetails -->|ghcr.io/YOUR_ORG/YOUR_APP:latest| Tag2[Tag: latest]
    
    Tag1 --> PushImage
    Tag2 --> PushImage[Push to GHCR]
    
    PushImage --> CleanEnv[Clean up .env]
    CleanEnv --> SetupKubeconfig[Set up Kubeconfig]
    
    SetupKubeconfig --> DetectVersion[Detect Current Version]
    DetectVersion --> VersionLogic{Get Service Selector}
    
    VersionLogic -->|version=blue| NextGreen[Next: Green]
    VersionLogic -->|version=green| NextBlue[Next: Blue]
    
    NextGreen --> ScaleNext
    NextBlue --> ScaleNext[Scale Next to 1 Replica]
    
    ScaleNext --> CheckReplicas{Replicas = 0?}
    CheckReplicas -->|Yes| ScaleUp[Scale to 1]
    CheckReplicas -->|No| SkipScale[Skip: Already running]
    
    ScaleUp --> UpdateImage
    SkipScale --> UpdateImage[Update Image to $SHA]
    
    UpdateImage --> WaitRollout[Wait for Rollout]
    WaitRollout --> RolloutCheck{Rollout OK?}
    
    RolloutCheck -->|Success| SwitchTraffic[Switch Traffic]
    RolloutCheck -->|Failed| Error[❌ Deployment Failed]
    Error --> StopPipeline([Stop Pipeline<br/>Keep Current Version])
    
    SwitchTraffic --> PatchService[Patch Service Selector]
    PatchService --> ScalePrevious[Scale Previous to 0]
    
    ScalePrevious --> GenerateSummary[Generate Summary]
    GenerateSummary --> Success([✅ Deployment Complete<br/>Zero Downtime])
    
    style Start fill:#e1f5ff
    style Success fill:#d4edda
    style Error fill:#f8d7da
    style StopPipeline fill:#f8d7da
    style BuildImage fill:#fff3cd
    style PushImage fill:#fff3cd
    style SwitchTraffic fill:#cce5ff
    style DetectVersion fill:#d1ecf1
    style RolloutCheck fill:#ffeaa7
```

### Timeline

```mermaid
gantt
    title Typical Deployment Timeline
    dateFormat X
    axisFormat %s
    
    section Build Phase
    Checkout & Setup     :0, 10
    Build Image         :10, 60
    Push to GHCR        :60, 90
    
    section Deploy Phase
    Setup Kubeconfig    :90, 100
    Detect Version      :100, 105
    Scale Deployment    :105, 115
    Update Image        :115, 120
    Wait for Rollout    :120, 180
    
    section Switch Phase
    Switch Traffic      :180, 185
    Scale Previous      :185, 195
```

**Objetivos:**
- Total time: < 5 minutos
- Downtime: 0 segundos
- Switch latency: < 1 segundo

---

## 🎯 Puntos Clave de Diseño

### 1. Aislamiento Total

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph TB
    subgraph "Blue Environment"
        A[Blue Pod 1]
        B[Blue Config]
        C[Blue State]
    end
    
    subgraph "Green Environment"
        D[Green Pod 1]
        E[Green Config]
        F[Green State]
    end
    
    G[Service Layer] -->|active| A
    G -.->|inactive| D
    
    style A fill:#cce5ff
    style D fill:#d3d3d3
    style G fill:#d4edda
```

**Beneficios:**
- Cero interferencia entre versiones
- Testing completo antes del switch
- Rollback sin riesgo

### 2. Tráfico Direccionado

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph LR
    subgraph "Traffic Flow"
        A[Clients] --> B[Service]
        B -->|selector: version=X| C[Active Deployment]
        B -.->|no routing| D[Standby Deployment]
    end
    
    E[Workflow] -->|patch| B
    
    style B fill:#d4edda
    style C fill:#cce5ff
    style D fill:#d3d3d3
```

**Características:**
- Cambio instantáneo del selector
- Sin pérdida de conexiones
- Downtime = 0 segundos

### 3. Gestión de Recursos

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph LR
    A[Active Deployment] -->|1 replica| B[Consuming Resources]
    C[Standby Deployment] -->|0 replicas| D[No Resources]
    
    E[Workflow] -->|scale| C
    
    style B fill:#cce5ff
    style D fill:#d3d3d3
```

**Optimización:**
- Solo versión activa consume recursos
- Standby escalado a 0 automáticamente
- Rollback rápido: escalar a 1

---

## 🔐 Seguridad

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph TB
    subgraph "GitHub Secrets"
        A[PAT Token]
        B[Environment Variables]
        C[Kubeconfig]
    end
    
    subgraph "Kubernetes Secrets"
        D[Registry Secret]
        E[App Secret]
    end
    
    A -->|authenticate| F[GHCR]
    B -->|build| G[.env file]
    C -->|deploy| H[Cluster]
    
    D -->|pull images| I[Deployments]
    E -->|config| I
    
    style A fill:#fff3cd
    style B fill:#fff3cd
    style C fill:#fff3cd
```

### Secretos Requeridos

**GitHub Secrets:**
- `PAT` - Personal Access Token
- `USERNAME` - GitHub username
- `KUBECONFIG_CONTENT` - Configuración del cluster
- Variables de entorno de la aplicación

**Kubernetes Secrets:**
- `registry-secret` - Credenciales del registry
- `myapp-secret` - Variables de entorno

---

## 🔙 Rollback Rápido

Si necesitas hacer rollback inmediato:

```bash
# Obtener versión activa
CURRENT=$(kubectl get svc myapp-svc -o jsonpath='{.spec.selector.version}')

# Determinar versión anterior
[ "$CURRENT" = "blue" ] && PREV="green" || PREV="blue"

# Cambiar tráfico de vuelta
kubectl patch svc myapp-svc \
  -p "{\"spec\":{\"selector\":{\"version\":\"$PREV\"}}}"

# Escalar versión actual a 0
kubectl scale deployment myapp-$CURRENT --replicas=0

echo "✅ Rollback completado a versión: $PREV"
```

**Tiempo de rollback:** 5-10 segundos ⚡

---

## 🚨 Puntos de Falla y Mitigación

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph TB
    subgraph "Failure Points"
        A[Build Failure]
        B[Image Pull Failure]
        C[Deployment Failure]
        D[Runtime Failure]
    end
    
    subgraph "Mitigations"
        E[Skip Deployment]
        F[Keep Current Version]
        G[Auto Rollback]
        H[Manual Rollback]
    end
    
    A --> E
    B --> F
    C --> G
    D --> H
    
    style A fill:#f8d7da
    style B fill:#f8d7da
    style C fill:#f8d7da
    style D fill:#f8d7da
    style G fill:#d4edda
    style H fill:#cce5ff
```

---

## 🐛 Troubleshooting

### El pod no inicia

```bash
# Ver logs
kubectl logs -l app=myapp --tail=50

# Ver eventos
kubectl get events --field-selector involvedObject.kind=Pod

# Ver descripción del pod
kubectl describe pod -l app=myapp,version=blue
```

### El servicio no enruta

```bash
# Verificar endpoints
kubectl get endpoints myapp-svc

# Verificar selector
kubectl get svc myapp-svc -o yaml | grep selector
```

### Imagen no se descarga

```bash
# Verificar secret
kubectl describe secret registry-secret

# Ver eventos
kubectl describe pod -l app=myapp,version=blue
```

---

## 📈 Escalabilidad

### Horizontal Scaling

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph TB
    subgraph "Single Replica"
        A[1 Pod] --> B[Limited Capacity]
    end
    
    subgraph "Multiple Replicas"
        C[Pod 1] --> D[Service]
        E[Pod 2] --> D
        F[Pod 3] --> D
        D --> G[High Capacity]
    end
    
    style B fill:#f8d7da
    style G fill:#d4edda
```

**Para escalar:**

```yaml
spec:
  replicas: 3  # Cambiar en deployment-blue.yaml y deployment-green.yaml
```

### Load Balancing

```mermaid
%%{init: {"themeVariables": { "textColor": "#ff0000"}}}%%
graph LR
    A[Client 1] --> D[Service]
    B[Client 2] --> D
    C[Client 3] --> D
    
    D --> E[Pod 1]
    D --> F[Pod 2]
    D --> G[Pod 3]
    
    style D fill:#d4edda
```

El servicio Kubernetes balancea automáticamente entre réplicas.

---

## 📊 Archivos del Proyecto

### Estructura

```
blue-green-deployments/
├── deployment-blue.yaml      # Deployment para entorno Blue
├── deployment-green.yaml     # Deployment para entorno Green
├── service.yaml              # Service con selector dinámico
├── Docker-build-and-push.yaml  # GitHub Actions workflow
├── scripts/
│   └── install-blue-green.sh   # Script de instalación inicial
└── README.md                    # Documentación general
```

### Deployments (ejemplo)
#### Blue

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
  labels:
    app: myapp
    version: blue
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
        - name: myapp
          image: ghcr.io/YOUR_ORG/YOUR_APP:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 3001
          envFrom:
            - secretRef:
                name: myapp-secret
      imagePullSecrets:
        - name: registry-secret
```

#### Green

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crm-bot-api-green
  labels:
    app: crm-bot-api
    version: green
spec:
  replicas: 1
  selector:
    matchLabels:
      app: crm-bot-api
      version: green
  template:
    metadata:
      labels:
        app: crm-bot-api
        version: green
    spec:
      containers:
        - name: crm-bot-api
          image: ghcr.io/org-sistemas-sn/crm-bot-api:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 3001
          envFrom:
            - secretRef:
                name: crm-bot-api-secret
      imagePullSecrets:
        - name: ghcr-secret
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-svc
  labels:
    app: myapp
spec:
  type: NodePort
  selector:
    app: myapp
    version: blue  # Cambia dinámicamente
  ports:
    - name: http
      port: 3001
      targetPort: 3001
      nodePort: 30059
```

### 🔑 Explicación de Labels y Selectores

El Blue/Green deployment funciona gracias a **labels** (etiquetas) y **selectors** (selectores) en Kubernetes.

#### ¿Qué son los Labels?

Los labels son pares clave-valor que puedes adjuntar a cualquier objeto de Kubernetes. Son fundamentales para organizar y seleccionar recursos.

```mermaid
graph TB
    subgraph "Labels en el Deployment"
        A[Deployment Blue<br/>labels: app=myapp<br/>version=blue]
    end
    
    subgraph "Labels en los Pods"
        B[Pod Blue 1<br/>app: myapp<br/>version: blue]
        C[Pod Green 1<br/>app: myapp<br/>version: green]
    end
    
    A -->|crea pods con| B
    
    style A fill:#cce5ff
    style B fill:#cce5ff
    style C fill:#90EE90
```

#### Tres Niveles de Labels

**1. Labels del Deployment (metadata.labels)**
- Etiquetan el Deployment
- Útiles para filtrado: `kubectl get deployments -l app=myapp`
- No afectan el comportamiento del deployment

**2. Labels del Selector (spec.selector.matchLabels)**
```yaml
selector:
  matchLabels:
    app: myapp
    version: blue
```
- Definen qué pods gestiona este deployment
- Deben coincidir con los labels de los pods
- Blue gestiona pods con `version=blue`
- Green gestiona pods con `version=green`

**3. Labels del Pod Template (spec.template.metadata.labels)**
```yaml
template:
  metadata:
    labels:
      app: myapp
      version: blue
```
- Labels aplicados a los pods creados
- Deben coincidir con el selector
- Kubernetes valida esta coherencia

#### El Selector del Service

El **selector del Service** decide a qué pods enruta el tráfico:

```yaml
spec:
  selector:
    app: myapp       # Etiqueta común a todos
    version: blue    # Etiqueta que cambia
```

**Cómo funciona el enrutamiento:**

```mermaid
graph TB
    subgraph "Cluster"
        Service[Service<br/>selector: app=myapp<br/>version=blue]
    end
    
    subgraph "Blue Pods"
        Pod1[Pod 1<br/>app: myapp<br/>version: blue ✓]
    end
    
    subgraph "Green Pods"
        Pod2[Pod 1<br/>app: myapp<br/>version: green ✗]
    end
    
    Service -->|MATCH| Pod1
    Service -.->|NO MATCH| Pod2
    
    style Service fill:#d4edda
    style Pod1 fill:#cce5ff
    style Pod2 fill:#d3d3d3
```

#### Flujo de enrutamiento

**Estado inicial (Blue activo):**

```mermaid
graph LR
    Client[Clients] --> Svc[Service<br/>selector: version=blue]
    
    Svc -->|Matches| BluePod[Blue Pod<br/>app: myapp<br/>version: blue]
    Svc -.->|No Match| GreenPod[Green Pod<br/>app: myapp<br/>version: green]
    
    style Svc fill:#d4edda
    style BluePod fill:#cce5ff
    style GreenPod fill:#d3d3d3
```

**Después del switch (Green activo):**

```mermaid
graph LR
    Client[Clients] --> Svc[Service<br/>selector: version=green]
    
    Svc -->|Matches| GreenPod[Green Pod<br/>app: myapp<br/>version: green]
    Svc -.->|No Match| BluePod[Blue Pod<br/>app: myapp<br/>version: blue]
    
    style Svc fill:#d4edda
    style GreenPod fill:#90EE90
    style BluePod fill:#d3d3d3
```

#### Cómo cambiar el tráfico

El workflow usa `kubectl patch` para cambiar el selector:

```bash
kubectl patch service myapp-svc \
  -p '{"spec":{"selector":{"app":"myapp","version":"green"}}}'
```

**Proceso:**

```mermaid
sequenceDiagram
    participant Workflow
    participant Service
    participant BluePod
    participant GreenPod
    
    Note over Service: Initial State<br/>selector: version=blue
    
    Client->>Service: Request
    Service->>BluePod: Forward (match)
    
    Note over Workflow: New deployment ready
    
    Workflow->>Service: kubectl patch selector: green
    Service->>Service: Update selector
    
    Note over Service: New State<br/>selector: version=green
    
    Client->>Service: New Request
    Service->>GreenPod: Forward (match)
    Service->>BluePod: Stop routing (no match)
    
    Note over Workflow,Service: ✅ Zero Downtime!
```

#### Ejemplo práctico

Verificar los labels:

```bash
# Ver labels del deployment
kubectl get deployment myapp-blue --show-labels
# Output: app=myapp,version=blue

# Ver labels de los pods
kubectl get pods -l app=myapp --show-labels

# Output:
# NAME                        READY   STATUS    LABELS
# myapp-blue-xxx              1/1     Running   app=myapp,version=blue
# myapp-green-xxx             1/1     Running   app=myapp,version=green

# Ver selector del service
kubectl get svc myapp-svc -o yaml | grep -A 3 selector
# Output:
#   selector:
#     app: myapp
#     version: blue

# Verificar qué pods están siendo enrutados
kubectl get endpoints myapp-svc
# Output:
# NAME                ENDPOINTS
# myapp-svc           10.244.1.5:3001  (Blue pod IP)
```

#### Resumen

```mermaid
graph TB
    subgraph "1. Deployment Labels"
        A[Deployment: version=blue]
        B[Pods creados: version=blue]
    end
    
    subgraph "2. Service Selector"
        C[Service selector:<br/>app + version]
    end
    
    subgraph "3. Matching"
        D{Pods con labels<br/>que coinciden?}
        E[✓ Recibe tráfico]
        F[✗ No recibe tráfico]
    end
    
    A --> B
    B --> D
    C --> D
    D -->|Match| E
    D -->|No Match| F
    
    style A fill:#cce5ff
    style C fill:#d4edda
    style E fill:#90EE90
    style F fill:#d3d3d3
```

**Conclusión:**
- Blue y Green comparten `app=myapp`
- `version` los diferencia
- El selector del Service cambia dinámicamente
- Solo los pods coincidentes reciben tráfico
- Instantáneo y sin pérdida de conexiones

---

## ✅ Checklist de Post-Deployment

Después de tu primer deployment:

- [ ] Verificar que el servicio responde
- [ ] Confirmar que no hubo downtime
- [ ] Probar rollback
- [ ] Configurar monitoreo
- [ ] Documentar para tu equipo

---

## 🎓 Patrones Aplicados

### 1. Canary Deployment (Potencial Evolución)

```mermaid
graph TB
    A[100% Blue] --> B[90% Blue 10% Green]
    B --> C[50% Blue 50% Green]
    C --> D[10% Blue 90% Green]
    D --> E[100% Green]
    
    style A fill:#cce5ff
    style E fill:#d4edda
```

**Nota:** Actualmente se usa switch instantáneo, pero puedes evolucionar a canary.

### 2. Feature Flags (Extensión Futura)

```mermaid
graph TB
    A[Deployment] --> B{Feature Flag}
    B -->|Enabled| C[New Feature]
    B -->|Disabled| D[Old Behavior]
    
    E[Config] --> B
    
    style B fill:#fff3cd
```

### 3. Database Migration Strategies

```mermaid
graph TB
    A[Schema v1] --> B[Schema v2 Compatible]
    B --> C[Schema v2]
    
    D[Blue: v1] --> E[Green: v2]
    
    style A fill:#f8d7da
    style B fill:#fff3cd
    style C fill:#d4edda
```

---

## 🔄 Evolución del Sistema

```mermaid
graph LR
    A[v1.0: Basic BG] --> B[v2.0: GitHub Actions]
    B --> C[v3.0: Canary?]
    C --> D[v4.0: Multi-Region?]
    
    style A fill:#f8d7da
    style B fill:#fff3cd
    style C fill:#cce5ff
    style D fill:#d4edda
```

---

## 📊 Resumen

### Características Principales

- ✅ **Zero Downtime Deployments**
- ✅ **Rollback Rápido** (solo cambiar selector)
- ✅ **Testing en Producción** antes del switch
- ✅ **Escalado Inteligente** (solo activa consume recursos)
- ✅ **Manejo de Errores** (cancela si falla)
- ✅ **Logging Detallado** en cada paso
- ✅ **GitHub Actions Integration**

### Métricas Objetivo

- **Deployment Time**: < 5 minutos
- **Downtime**: 0 segundos
- **Rollback Time**: < 10 segundos
- **Failure Detection**: Automático
- **Resource Efficiency**: Solo activa consume recursos

---

## 📝 Notas Importantes

⚠️ **Migraciones de DB**: Ejecutar antes del deployment  
⚠️ **Sessions**: Usar storage externo (Redis)  
⚠️ **Secrets**: Nunca hardcodear en el código  
⚠️ **Testing**: Siempre probar en staging primero

---

**Creado con ❤️ para deployments sin downtime** 🚀

