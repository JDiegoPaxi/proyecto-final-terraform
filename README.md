# SisAsistencia - Terraform por tenant

Plantilla Terraform para desplegar una VPC, una subred pública y tres EC2 por tenant:
frontend, backend y database. Los archivos Cloud-Init se mantienen intencionalmente vacíos.

## Requisitos

- Terraform >= 1.10.
- AWS CLI configurado con el usuario IAM `gr-codigo-cero` (o credenciales AWS equivalentes en el entorno del proceso).
- Bucket S3 previamente creado para los estados.
- Permisos IAM para administrar los recursos del proyecto y leer/escribir el estado y lockfile S3.

No se crean el bucket S3 ni el usuario IAM desde este proyecto.

## Red y seguridad incluidas

- Una VPC por tenant.
- Una subred pública por tenant.
- Frontend y backend reciben IP pública.
- Database no recibe IP pública; conserva una IP privada dentro de la misma subred pública.
- HTTP/HTTPS entrante al frontend desde Internet.
- TCP/3000 al backend únicamente desde el Security Group del frontend.
- TCP/5432 a database únicamente desde el Security Group del backend.
- SSH limitado al CIDR configurado en `ssh_allowed_cidr`.
- Salida de red permitida para las instancias.

**Nota de arquitectura:** la instancia database no tiene IP pública, pero está ubicada en la subred pública solicitada. Para producción, se recomienda moverla a una subred privada separada y revisar el acceso administrativo.

## Usuarios Linux

El proyecto usa `tenant_id` como identificador y nombre descriptivo del tenant para reducir parámetros. La etiqueta `RequestedUser` se deriva como `<tenant_id>-ubuntu` en las tres instancias. Es solo una etiqueta: no crea ni cambia usuarios Linux porque los Cloud-Init están vacíos. En Ubuntu, el usuario predeterminado de la AMI suele ser `ubuntu`.

`ssh_allowed_cidr` tiene por defecto `127.0.0.1/32`, que no permite conexiones SSH externas. Al desplegar, proporciona tu IP pública con máscara `/32` para habilitar el acceso administrativo.

## 1. Credenciales AWS

Configura las credenciales de `gr-codigo-cero` en el entorno donde se ejecutará Terraform. En PowerShell:

```powershell
$env:AWS_ACCESS_KEY_ID = "ACCESS_KEY_DEL_USUARIO"
$env:AWS_SECRET_ACCESS_KEY = "SECRET_KEY_DEL_USUARIO"
$env:AWS_DEFAULT_REGION = "us-east-1"
```

No guardes estas credenciales en el proyecto ni las pases mediante `-var`.

## 2. Clave SSH del tenant

No necesitas ejecutar un comando adicional para generar la clave. Durante `terraform apply`, Terraform crea un par RSA y guarda la clave privada en la carpeta definida por `ssh_key_directory`, cuyo valor predeterminado es `C:/llaves`. Terraform crea una subcarpeta con el `tenant_id` y guarda allí el archivo `<tenant_id>.pem`; por ejemplo, `C:/llaves/tenant-001/tenant-001.pem`. El mismo key pair se asigna a las tres instancias. Puedes cambiar la carpeta base mediante `-var="ssh_key_directory=D:/llaves"`. Terraform no vuelve a generar la clave en cada aplicación.

La clave privada también queda almacenada en el estado de Terraform. El backend S3 tiene cifrado activado, pero limita el acceso IAM al estado porque quien pueda leerlo podrá recuperar la clave.

## 3. Inicializar backend S3

El bucket debe existir antes de este paso. Cada tenant utiliza una clave de estado distinta.

Ejemplo para tenant-001:

```powershell
terraform init `
  -backend-config="key=tenants/tenant-001/terraform.tfstate" `
  -backend-config="region=us-east-1"
```

El bucket `sis-asistencia-terraform-state` y `use_lockfile=true` están definidos en `versions.tf`. El bucket debe existir previamente. La aplicación debe construir `key` y `region` dinámicamente y utilizar siempre la misma `key` para todas las operaciones del tenant. No ejecutes en paralelo dos operaciones Terraform sobre el mismo tenant.

La aplicación debe construir estos argumentos dinámicamente y utilizar siempre el mismo `key` para todas las operaciones del tenant. No ejecutes en paralelo dos operaciones Terraform sobre el mismo tenant.

## 4. Validar

```powershell
terraform fmt -recursive
terraform validate
```

## 5. Aplicar desde PowerShell

Ejemplo ilustrativo. Terraform genera y guarda la clave automáticamente al aplicar:

```powershell
$tenantId = "tenant-001"

terraform plan `
  -var="tenant_id=$tenantId" `
  -var="aws_region=us-east-1" `
  -var="ssh_allowed_cidr=203.0.113.10/32" `
  -var="frontend_instance_type=t3.micro" `
  -var="backend_instance_type=t3.micro" `
  -var="database_instance_type=t3.micro"
```

Para aplicar, utiliza los mismos argumentos y agrega `-auto-approve` a `terraform apply` si la aprobación ya fue gestionada por la plataforma. En producción es preferible generar y revisar un plan guardado.

## 6. Consultar únicamente las IP

```powershell
terraform output
```

Las únicas salidas declaradas son:

- `frontend_ip`: IP pública.
- `backend_ip`: IP pública.
- `database_ip`: IP privada.

Para que NestJS/C# las procese:

```powershell
terraform output -json
```

Este JSON es únicamente una salida para consumo de la aplicación; no se utiliza como archivo de entrada.

## Integración con NestJS o C#

La aplicación debe:
1. Validar y normalizar `tenant_id` (también utilizado como nombre descriptivo).
2. Terraform genera el key pair del tenant y guarda el `.pem` en `<ssh_key_directory>/<tenant_id>/` durante `apply`.
3. Crear un directorio de trabajo aislado por ejecución.
4. Ejecutar `terraform init` con el bucket y la ruta S3 del tenant.
5. Ejecutar `terraform plan` y `terraform apply` pasando variables con `-var` o `-var-file` temporal protegido. Esta plantilla está preparada para `-var`.
6. Capturar el código de salida y los logs.
7. Ejecutar `terraform output -json` y devolver las tres IP.
8. Serializar operaciones por tenant y no exponer claves privadas ni credenciales en logs.

El estado contiene la clave privada generada y debe protegerse como un secreto. Las claves públicas pueden aparecer en el estado o en metadatos de recursos; no pases secretos de aplicación como variables Terraform.

## Importante sobre S3 y múltiples tenants

- Un bucket compartido, una ruta `key` distinta por tenant.
- Activar versionado del bucket.
- Activar cifrado y bloquear acceso público al bucket.
- Usar `use_lockfile=true` (Terraform >= 1.10).
- IAM debe permitir las operaciones S3 necesarias sobre el objeto del tenant y su objeto `.tflock`, además de los permisos AWS de infraestructura.
- El bucket y `use_lockfile` del backend S3 están fijados en `versions.tf`; la ruta `key` por tenant y la región se proporcionan con `-backend-config`, porque el backend no puede parametrizarse con variables Terraform convencionales.

## Eliminar infraestructura

Para destruir un tenant, inicializa el backend con la misma ruta `key` de ese tenant y ejecuta `terraform destroy` con los mismos valores de entrada. No elimines el bucket compartido ni el estado de otros tenants.
