#!/usr/bin/env bash

# Cargar configuración de la Jetson
source "$HOME/jetson_params.env"

echo ""
echo "=============================================="
echo " Waiting for Jetson clock synchronization"
echo " Maximum waiting time: 5 minutes"
echo "=============================================="
echo ""

# Espera hasta que:
# - Chrony tenga una fuente NTP seleccionada.
# - El reloj esté sincronizado.
# - La corrección pendiente sea inferior a 0.2 segundos.
#
# Parámetros:
#   300 = número máximo de comprobaciones
#   0.2 = corrección máxima permitida, en segundos
#   0   = no comprobar el skew
#   1   = intervalo de un segundo
if ! chronyc waitsync 300 0.2 0 1; then
    echo ""
    echo "ERROR: Chrony did not synchronize within 5 minutes."
    echo "ROS 2 nodes will not be started."
    exit 1
fi

echo "Chrony reports that the clock is synchronized."
echo "Checking NTP server and clock offset..."

# Comprobar además:
# - Leap status = Normal
# - Offset inferior a 0.2 segundos
# - Servidor seleccionado = robot-time-server
if ! "$HOME/check_clock_sync.sh"; then
    echo ""
    echo "ERROR: clock synchronization validation failed."
    echo "ROS 2 nodes will not be started."
    exit 1
fi

echo ""
echo "Clock synchronization completed successfully."
echo ""

# Cargar ROS 2 solamente después de sincronizar el reloj
source /opt/ros/jazzy/setup.bash
source "$JETSON_WORKSPACE/install/setup.bash"

echo -e "ROS_DOMAIN_ID\t\t= ${ROS_DOMAIN_ID}"
echo -e "RMW_IMPLEMENTATION\t= ${RMW_IMPLEMENTATION}"
echo -e "WORKSPACE\t\t= ${JETSON_WORKSPACE}/install/setup.bash"
echo ""

# Cerrar únicamente la sesión de screen de la cámara,
# sin cerrar otras sesiones screen que puedan estar ejecutándose.
screen -S zed -X quit 2>/dev/null || true

sleep 5

# Lanzar la cámara ZED
screen -S zed -d -m \
    ros2 launch zed_bringup zed_camera.launch.py \
    camera_model:="$JETSON_CAMERA_1_MODEL" \
    camera_name:="$JETSON_CAMERA_1_ID" \
    namespace:=robot

# Comprobar que la sesión se ha creado
sleep 2

if screen -list | grep -q "[.]zed"; then
    echo "ZED bringup started successfully."
    exit 0
else
    echo "ERROR: the ZED screen session could not be started."
    exit 1
fi
