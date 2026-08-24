import os

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, OpaqueFunction
from launch.conditions import IfCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import EnvironmentVariable, LaunchConfiguration, PythonExpression
from launch_ros.actions import ComposableNodeContainer

from ament_index_python.packages import get_package_share_directory


def validate_camera_names(context):
    model_1 = LaunchConfiguration('camera_model_1').perform(context)
    model_2 = LaunchConfiguration('camera_model_2').perform(context)
    name_1 = LaunchConfiguration('camera_name_1').perform(context)
    name_2 = LaunchConfiguration('camera_name_2').perform(context)

    if model_1 != 'none' and model_2 != 'none' and name_1 == name_2:
        raise RuntimeError(
            'camera_name_1 and camera_name_2 must be different when both cameras are enabled'
        )

    return []


def camera_enabled(camera_number):
    return IfCondition(
        PythonExpression([
            "'",
            LaunchConfiguration(f'camera_model_{camera_number}'),
            "' != 'none'",
        ])
    )


def generate_launch_description():
    declared_args = [
        DeclareLaunchArgument(
            'robot_id',
            default_value=EnvironmentVariable('ROBOT_ID', default_value='robot'),
        ),
        DeclareLaunchArgument(
            'camera_model_1',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_1_MODEL', default_value='zed2i'
            ),
        ),
        DeclareLaunchArgument(
            'camera_name_1',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_1_ID', default_value='top_rgbd_camera'
            ),
        ),
        DeclareLaunchArgument(
            'serial_number_1',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_1_SERIAL_NUMBER', default_value='0'
            ),
        ),
        DeclareLaunchArgument(
            'camera_id_1',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_1_DEVICE_ID', default_value='0'
            ),
        ),
        DeclareLaunchArgument(
            'camera_model_2',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_2_MODEL', default_value='none'
            ),
        ),
        DeclareLaunchArgument(
            'camera_name_2',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_2_ID', default_value='rear_rgbd_camera'
            ),
        ),
        DeclareLaunchArgument(
            'serial_number_2',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_2_SERIAL_NUMBER', default_value='0'
            ),
        ),
        DeclareLaunchArgument(
            'camera_id_2',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_2_DEVICE_ID', default_value='1'
            ),
        ),
    ]

    zed_camera_launch = os.path.join(
        get_package_share_directory('zed_bringup'),
        'launch',
        'zed_camera.launch.py',
    )

    camera_actions = []
    for camera_number in (1, 2):
        container_name = f'zed_container_{camera_number}'
        condition = camera_enabled(camera_number)

        container = ComposableNodeContainer(
            package='rclcpp_components',
            executable='component_container_isolated',
            name=container_name,
            namespace=LaunchConfiguration('robot_id'),
            arguments=[
                '--use_multi_threaded_executor',
                '--ros-args',
                '--log-level',
                'info',
            ],
            output='both',
            composable_node_descriptions=[],
            condition=condition,
        )

        camera = IncludeLaunchDescription(
            PythonLaunchDescriptionSource(zed_camera_launch),
            launch_arguments={
                'camera_name': LaunchConfiguration(f'camera_name_{camera_number}'),
                'camera_model': LaunchConfiguration(f'camera_model_{camera_number}'),
                'namespace': LaunchConfiguration('robot_id'),
                'container_name': container_name,
                'serial_number': LaunchConfiguration(f'serial_number_{camera_number}'),
                'camera_id': LaunchConfiguration(f'camera_id_{camera_number}'),
                'publish_urdf': 'false',
            }.items(),
            condition=condition,
        )

        camera_actions.extend([container, camera])

    return LaunchDescription(
        declared_args + [OpaqueFunction(function=validate_camera_names)] + camera_actions
    )
