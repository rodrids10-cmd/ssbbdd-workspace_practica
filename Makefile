# Makefile para gestionar contenedor Docker de Cloudera Hadoop (SBD práctica)
# Autor: Adaptado para Docker Compose v2 basado en guía SBD
# Requisitos: Docker y Docker Compose v2 instalados (docker compose version)
# Servicio: quickstart (ajustado para compatibilidad)

PROJECT_NAME := mids-cloudera-hadoop
SERVICE_NAME := quickstart  # Nombre del servicio en docker-compose.yml
CONTAINER_NAME := mids-cloudera-hadoop-quickstart
LOCAL_FOLDER := /home/rafael/dev/ssbbdd_pec/mids-cloudera-hadoop/workspace/ # Ruta absoluta
JUPYTER_PORT := 8889  # Puerto expuesto para Jupyter (localhost:8889)
HUE_PORT := 8887     # Puerto para HUE/Cloudera Manager (localhost:8887)

# Ayuda: muestra targets disponibles
help:
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "  Makefile para Cloudera Hadoop + Jupyter + Hue (SBD Práctica)"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "🚀 COMANDOS PRINCIPALES:"
	@echo "  make up              - Inicia contenedor con todos los servicios"
	@echo "  make down            - Para contenedor (mantiene volúmenes)"
	@echo "  make restart         - Reinicia contenedor completo"
	@echo "  make exec            - Conecta terminal bash al contenedor"
	@echo "  make logs            - Muestra logs en tiempo real"
	@echo ""
	@echo "📊 VERIFICACIÓN:"
	@echo "  make status          - Estado del contenedor"
	@echo "  make services        - Verifica Jupyter y Hue"
	@echo "  make jupyter-logs    - Ver logs de Jupyter"
	@echo "  make jupyter-token   - Mostrar token de Jupyter"
	@echo ""
	@echo "🌐 ACCESO WEB:"
	@echo "  make jupyter         - Abre Jupyter en navegador"
	@echo "  make hue             - Abre Hue en navegador"
	@echo ""
	@echo "🔧 GESTIÓN DE SERVICIOS:"
	@echo "  make restart-jupyter - Reinicia servicio Jupyter"
	@echo "  make restart-hue     - Reinicia servicio Hue"
	@echo "  make restart-hive    - Reinicia servicio Hive"
	@echo "  make restart-all     - Reinicia ambos servicios web"
	@echo ""
	@echo "🧹 LIMPIEZA:"
	@echo "  make prune           - Limpia recursos (CUIDADO: borra volúmenes)"
	@echo ""
	@echo "📝 URLs:"
	@echo "  Jupyter: http://localhost:$(JUPYTER_PORT)"
	@echo "  Hue:     http://localhost:$(HUE_PORT) (cloudera/cloudera)"
	@echo ""

# Valida configuración del docker-compose.yml
config:
	docker compose config
	@echo "✅ Configuración validada. Revisa errores de sintaxis."

# Descarga imágenes si no existen (primera vez, ~5-10 GB)
build:
	docker compose pull $(SERVICE_NAME)
	@echo "✅ Imágenes descargadas/construidas para $(SERVICE_NAME)."

# Inicia contenedor (descarga si primera vez)
up:
	@echo "🚀 Iniciando contenedor..."
	docker compose up -d $(SERVICE_NAME)
	@echo ""
	@echo "⏳ Contenedor iniciado. Esperando inicialización (~2-5 min)..."
	@echo ""
	@echo "📦 Servicios que se están iniciando:"
	@echo "  ✓ Hadoop (HDFS, YARN, MapReduce)"
	@echo "  ✓ Hue (interfaz web)"
	@echo "  ✓ Jupyter Notebook"
	@sleep 5
	@docker compose ps
	@echo ""
	@echo "💡 Espera 2-3 minutos y luego ejecuta:"
	@echo "   make services    (para verificar estado)"
	@echo "   make jupyter     (para abrir Jupyter)"
	@echo "   make hue         (para abrir Hue)"

# Para contenedor (mantiene volúmenes para notebooks/datos)
down:
	@echo "🛑 Parando contenedor..."
	docker compose down
	@echo "✅ Contenedor parado. Volúmenes preservados."

# Reinicia contenedor
restart:
	@echo "🔄 Reiniciando contenedor completo..."
	@make down
	@sleep 2
	@make up

# Muestra logs en tiempo real (Ctrl+C para salir)
logs:
	@echo "📋 Mostrando logs en tiempo real (Ctrl+C para salir)..."
	docker compose logs -f $(SERVICE_NAME)

# Conecta terminal bash al contenedor (para comandos Hadoop/Hive/MapReduce)
exec:
	@docker compose ps --services | grep -q $(SERVICE_NAME) || (echo "❌ Servicio '$(SERVICE_NAME)' no encontrado" && exit 1)
	@docker compose ps | grep -q "$(CONTAINER_NAME).*Up" || (echo "❌ Contenedor no está corriendo. Ejecuta 'make up' primero." && exit 1)
	@echo "🔌 Conectando al contenedor..."
	@echo "💡 Tip: Usa 'exit' para salir"
	@docker compose exec $(SERVICE_NAME) bash

# Muestra estado del servicio
status:
	@echo "📊 Estado del contenedor:"
	@docker compose ps $(SERVICE_NAME)
	@echo ""
	@echo "📈 Contenedores Docker activos: $$(docker ps -q | wc -l)"

# Verifica estado de servicios Jupyter y Hue
services:
	@echo "═══════════════════════════════════════════"
	@echo "  🔍 Verificando servicios web"
	@echo "═══════════════════════════════════════════"
	@echo ""
	@echo "📓 Jupyter Notebook:"
	@docker exec $(CONTAINER_NAME) ps aux | grep -v grep | grep jupyter > /dev/null && echo "  ✅ Proceso corriendo" || echo "  ❌ Proceso no encontrado"
	@docker exec $(CONTAINER_NAME) netstat -tuln 2>/dev/null | grep $(JUPYTER_PORT) > /dev/null && echo "  ✅ Puerto $(JUPYTER_PORT) escuchando" || echo "  ❌ Puerto $(JUPYTER_PORT) no escucha"
	@echo ""
	@echo "🎨 Hue (Interfaz Gráfica):"
	@docker exec $(CONTAINER_NAME) service hue status 2>/dev/null | grep -q running && echo "  ✅ Servicio corriendo" || echo "  ❌ Servicio parado"
	@docker exec $(CONTAINER_NAME) netstat -tuln 2>/dev/null | grep $(HUE_PORT) > /dev/null && echo "  ✅ Puerto $(HUE_PORT) escuchando" || echo "  ❌ Puerto $(HUE_PORT) no escucha"
	@echo ""
	@echo "🐝 Hive (Base de Datos):"
	@docker exec $(CONTAINER_NAME) service hive-server2 status 2>/dev/null | grep -q running && echo "  ✅ Servicio corriendo" || echo "  ❌ Servicio parado"
	@docker exec $(CONTAINER_NAME) netstat -tuln 2>/dev/null | grep 10000 > /dev/null && echo "  ✅ Puerto 10000 escuchando" || echo "  ❌ Puerto 10000 no escucha"
	@echo ""
	@echo "🌐 URLs de acceso:"
	@echo "  • Jupyter: http://localhost:$(JUPYTER_PORT)"
	@echo "  • Hue:     http://localhost:$(HUE_PORT) (cloudera/cloudera)"
	@echo ""
	@echo "💡 Si los servicios no están corriendo:"
	@echo "   make restart-all    (reinicia todos los servicios)"

# Abre Jupyter notebooks (workspace principal para la práctica)
jupyter:
	@docker compose ps | grep -q "$(CONTAINER_NAME).*Up" || (echo "❌ Contenedor no está corriendo" && exit 1)
	@echo "🚀 Abriendo Jupyter Notebook..."
	@echo "📍 URL: http://localhost:$(JUPYTER_PORT)"
	@xdg-open http://localhost:$(JUPYTER_PORT) 2>/dev/null || open http://localhost:$(JUPYTER_PORT) 2>/dev/null || echo "⚠️  Abre manualmente: http://localhost:$(JUPYTER_PORT)"

# Abre HUE/Cloudera Manager (interfaz web opcional)
hue:
	@docker compose ps | grep -q "$(CONTAINER_NAME).*Up" || (echo "❌ Contenedor no está corriendo" && exit 1)
	@echo "🚀 Abriendo Hue..."
	@echo "📍 URL: http://localhost:$(HUE_PORT)"
	@echo "🔑 Credenciales: cloudera / cloudera"
	@xdg-open http://localhost:$(HUE_PORT) 2>/dev/null || open http://localhost:$(HUE_PORT) 2>/dev/null || echo "⚠️  Abre manualmente: http://localhost:$(HUE_PORT)"

# Muestra logs de Jupyter
jupyter-logs:
	@echo "📋 Logs de Jupyter:"
	@echo "════════════════════════════════════════════"
	@docker exec $(CONTAINER_NAME) cat /var/log/jupyter.log 2>/dev/null || echo "⚠️  No hay logs disponibles"

# Muestra token de Jupyter (si está configurado)
jupyter-token:
	@echo "🔑 Buscando token de Jupyter..."
	@docker exec $(CONTAINER_NAME) cat /var/log/jupyter.log 2>/dev/null | grep token || echo "ℹ️  Sin token configurado (acceso sin autenticación)"

# Reinicia servicio Hue
restart-hue:
	@echo "🔄 Reiniciando Hue..."
	@docker exec $(CONTAINER_NAME) service hue restart
	@sleep 2
	@echo "✅ Hue reiniciado. Verifica con 'make services'"

# Reinicia servicio Jupyter
restart-jupyter:
	@echo "🔄 Reiniciando Jupyter..."
	@docker exec $(CONTAINER_NAME) pkill -f jupyter || echo "  ℹ️  Jupyter no estaba corriendo"
	@sleep 2
	@docker exec -d $(CONTAINER_NAME) bash -c "nohup /opt/anaconda/bin/jupyter notebook --ip=0.0.0.0 --port=8889 --no-browser --notebook-dir=/root > /var/log/jupyter.log 2>&1 &"
	@sleep 3
	@echo "✅ Jupyter reiniciado. Verifica con 'make services'"

restart-hive:
	@echo "🔄 Reiniciando el server de Hive..."
	@docker exec $(CONTAINER_NAME) service hive-server2 restart
	@sleep 2
	@echo "✅ Servidor de hive reiniciado. Verifica con 'make services'"

# Reinicia ambos servicios web
restart-all:
	@echo "🔄 Reiniciando todos los servicios web..."
	@make restart-hue
	@make restart-jupyter
	@make restart-hive
	@echo ""
	@echo "✅ Servicios reiniciados. Verificando estado..."
	@sleep 2
	@make services

# Limpia recursos no usados (CUIDADO: puede borrar datos)
prune:
	@echo "⚠️  ADVERTENCIA: Esto eliminará TODOS los volúmenes y datos"
	@echo "Presiona Ctrl+C en 5 segundos para cancelar..."
	@sleep 5
	docker compose down -v
	docker system prune -f
	@echo "✅ Limpieza completada. Volúmenes eliminados."

# Target para práctica: Configura, inicia y prueba acceso
test:
	@echo "🧪 Ejecutando prueba completa..."
	@make config
	@make up
	@echo "⏳ Esperando inicialización (30 segundos)..."
	@sleep 30
	@make status
	@echo ""
	@make services
	@echo ""
	@echo "💡 Si los servicios no están activos, espera 1-2 minutos más"
	@echo "   y ejecuta: make services"

# Muestra información del sistema
info:
	@echo "═══════════════════════════════════════════"
	@echo "  ℹ️  Información del Sistema"
	@echo "═══════════════════════════════════════════"
	@echo ""
	@echo "📦 Proyecto: $(PROJECT_NAME)"
	@echo "🐳 Contenedor: $(CONTAINER_NAME)"
	@echo "📁 Workspace: $(LOCAL_FOLDER)"
	@echo ""
	@echo "🔌 Puertos:"
	@echo "  • Jupyter:  $(JUPYTER_PORT)"
	@echo "  • Hue:      $(HUE_PORT)"
	@echo ""
	@echo "🐳 Docker Compose:"
	@docker compose version 2>/dev/null || echo "  ❌ Docker Compose no disponible"
	@echo ""
	@echo "🐋 Docker:"
	@docker version --format '  Version: {{.Server.Version}}' 2>/dev/null || echo "  ❌ Docker no disponible"

.PHONY: help config build up down restart logs exec status services jupyter hue jupyter-logs jupyter-token restart-hue restart-jupyter restart-all prune test info
