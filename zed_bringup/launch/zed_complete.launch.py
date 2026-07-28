import os

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.conditions import IfCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import (
    EnvironmentVariable,
    LaunchConfiguration,
    PythonExpression,
)

from ament_index_python.packages import get_package_share_directory


def generate_launch_description():

    declared_args = [
        DeclareLaunchArgument(
            'robot_id',
            default_value=EnvironmentVariable(
                'ROBOT_ID',
                default_value='robot'
            )
        ),

        DeclareLaunchArgument(
            'camera_model',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_MODEL',
                default_value='zed2i'
            )
        ),

        DeclareLaunchArgument(
            'camera_name',
            default_value=EnvironmentVariable(
                'JETSON_CAMERA_ID',
                default_value='top_rgbd_camera'
            )
        ),
    ]

    zed_camera_launch = os.path.join(
        get_package_share_directory('zed_wrapper'),
        'launch',
        'zed_camera.launch.py'
    )

    camera = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            zed_camera_launch
        ),
        launch_arguments={
            'camera_name': LaunchConfiguration('camera_name'),
            'camera_model': LaunchConfiguration('camera_model'),
            'namespace': LaunchConfiguration('robot_id'),
            'publish_urdf': 'false',
        }.items(),
        condition=IfCondition(
            PythonExpression([
                "'",
                LaunchConfiguration('camera_model'),
                "' != 'none'"
            ])
        )
    )

    return LaunchDescription(
        declared_args + [
            camera,
        ]
    )

