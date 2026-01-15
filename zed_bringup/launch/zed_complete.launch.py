from launch import LaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
import os
from launch.substitutions import LaunchConfiguration
from launch.substitutions import EnvironmentVariable
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch_ros.actions import PushRosNamespace
from launch.actions import GroupAction

from ament_index_python.packages import get_package_share_directory
from launch.conditions import IfCondition
from launch.substitutions import PythonExpression

def generate_launch_description():

    declared_args = [
        DeclareLaunchArgument('robot_id', default_value=EnvironmentVariable('ROBOT_ID', default_value='robot')),
        DeclareLaunchArgument('camera_model_1', default_value=EnvironmentVariable('JETSON_CAMERA_1_MODEL', default_value='none')),
        DeclareLaunchArgument('camera_device_id_1', default_value=EnvironmentVariable('JETSON_CAMERA_1_DEVICE_ID', default_value='0')),
        DeclareLaunchArgument('camera_id_1', default_value=EnvironmentVariable('JETSON_CAMERA_1_ID', default_value='front_rgbd_camera')),

        DeclareLaunchArgument('camera_model_2', default_value=EnvironmentVariable('JETSON_CAMERA_2_MODEL', default_value='none')),
        DeclareLaunchArgument('camera_device_id_2', default_value=EnvironmentVariable('JETSON_CAMERA_2_DEVICE_ID', default_value='0')),
        DeclareLaunchArgument('camera_id_2', default_value=EnvironmentVariable('JETSON_CAMERA_2_ID', default_value='rear_rgbd_camera')),
    ]

    camera_1 = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(get_package_share_directory('zed_bringup'), 'launch/', 'zed_camera.launch.py')
        ),
        launch_arguments={
            'camera_name': LaunchConfiguration('camera_id_1'),
            'camera_model': LaunchConfiguration('camera_model_1'),
            'namespace': LaunchConfiguration('robot_id'),
            'node_name': LaunchConfiguration('camera_id_1'),
            'serial_number': LaunchConfiguration('camera_device_id_1'),
            'publish_urdf': 'true',
            'publish_tf': 'true',
        }.items(),
        condition=IfCondition(PythonExpression(["'", LaunchConfiguration('camera_model_1'), "' != 'none'"]))
    )

    camera_2 = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(get_package_share_directory('zed_bringup'), 'launch/', 'zed_camera.launch.py')
        ),
        launch_arguments={
            'camera_name': LaunchConfiguration('camera_id_2'),
            'camera_model': LaunchConfiguration('camera_model_2'),
            'namespace': LaunchConfiguration('robot_id'),
            'node_name': LaunchConfiguration('camera_id_2'),
            'serial_number': LaunchConfiguration('camera_device_id_2'),
            'publish_urdf': 'true',
            'publish_tf': 'true',
        }.items(),
        condition=IfCondition(PythonExpression(["'", LaunchConfiguration('camera_model_2'), "' != 'none'"]))
    )

    group = GroupAction([
        # PushRosNamespace(LaunchConfiguration('robot_id')),
        camera_1,
        camera_2,
    ])

    return LaunchDescription(declared_args + [group])
