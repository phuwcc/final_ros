include "map_builder.lua"
include "trajectory_builder.lua"

options = {
  map_builder = MAP_BUILDER,
  trajectory_builder = TRAJECTORY_BUILDER,
  map_frame = "map",
  tracking_frame = "base_link",
  published_frame = "odom",
  odom_frame = "odom",
  provide_odom_frame = false,
  publish_frame_projected_to_2d = true,
  use_odometry = true,
  use_nav_sat = false,
  use_landmarks = false,
  num_laser_scans = 1,
  num_multi_echo_laser_scans = 0,
  num_subdivisions_per_laser_scan = 1,
  num_point_clouds = 0,
  lookup_transform_timeout_sec = 0.2,
  submap_publish_period_sec = 0.3,
  pose_publish_period_sec = 0.005,
  trajectory_publish_period_sec = 0.03,
  rangefinder_sampling_ratio = 1.0,
  odometry_sampling_ratio = 1.0,
  fixed_frame_pose_sampling_ratio = 1.0,
  imu_sampling_ratio = 1.0,
  landmarks_sampling_ratio = 1.0,
}

MAP_BUILDER.use_trajectory_builder_2d = true

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LIDAR RANGE
-- ⚠ Sửa max_range = đúng giá trị <max_range> trong SDF của bạn
-- Gazebo simulation: KHÔNG được set cao hơn giá trị trong SDF
-- missing_data_ray_length phải <= max_range
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TRAJECTORY_BUILDER_2D.use_imu_data = false
TRAJECTORY_BUILDER_2D.min_range = 0.12
TRAJECTORY_BUILDER_2D.max_range = 10.0            -- ← đổi đúng theo SDF của bạn
TRAJECTORY_BUILDER_2D.missing_data_ray_length = 3.0

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SCAN MATCHING
-- Gazebo không có sensor noise thực → tăng occupied_space_weight
-- để tin vào laser hơn odometry
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TRAJECTORY_BUILDER_2D.use_online_correlative_scan_matching = true

TRAJECTORY_BUILDER_2D.real_time_correlative_scan_matcher.linear_search_window = 0.1
TRAJECTORY_BUILDER_2D.real_time_correlative_scan_matcher.angular_search_window = math.rad(20.0)
-- World L-shape: tăng angular search rộng để bắt được loop khi robot
-- quay qua cửa hẹp giữa 2 phòng

TRAJECTORY_BUILDER_2D.ceres_scan_matcher.occupied_space_weight = 20.0
-- Tăng cao vì Gazebo laser gần như không có noise → tin laser hơn
TRAJECTORY_BUILDER_2D.ceres_scan_matcher.translation_weight = 1.0
TRAJECTORY_BUILDER_2D.ceres_scan_matcher.rotation_weight = 40.0
-- rotation_weight cao để chống lệch góc — nguyên nhân chính ghost artifact

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MOTION FILTER
-- Lỗi lớn nhất trong file cũ: 0.1° quá nhỏ
-- Gazebo odometry gần như hoàn hảo → tăng ngưỡng lên
-- tránh insert scan thừa khi robot gần như đứng yên
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TRAJECTORY_BUILDER_2D.motion_filter.max_time_seconds = 5.0
TRAJECTORY_BUILDER_2D.motion_filter.max_distance_meters = 0.15
TRAJECTORY_BUILDER_2D.motion_filter.max_angle_radians = math.rad(0.5)
-- 0.1° → 0.5°: giảm số scan insert từ ~5000 xuống ~1000 cho cùng quãng đường

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SUBMAP
-- World L-shape kích thước vừa → 60 scans/submap là hợp lý
-- Submap nhỏ hơn = loop closure phát hiện sớm hơn
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TRAJECTORY_BUILDER_2D.submaps.num_range_data = 60   -- default 90 → quá lớn
TRAJECTORY_BUILDER_2D.submaps.grid_options_2d.resolution = 0.05

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- POSE GRAPH & LOOP CLOSURE
-- Phần bị thiếu hoàn toàn trong file cũ
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
POSE_GRAPH.optimize_every_n_nodes = 35   -- giữ nguyên, hợp lý

POSE_GRAPH.constraint_builder.sampling_ratio = 0.3
POSE_GRAPH.constraint_builder.max_constraint_distance = 15.0
POSE_GRAPH.constraint_builder.min_score = 0.65
-- Gazebo: tăng min_score cao hơn thực tế vì scan sạch hơn
-- nếu vẫn không có loop closure → thử hạ xuống 0.55
POSE_GRAPH.constraint_builder.global_localization_min_score = 0.70
POSE_GRAPH.constraint_builder.loop_closure_translation_weight = 1.1e4
POSE_GRAPH.constraint_builder.loop_closure_rotation_weight = 1.1e4

-- Tin odometry nhiều hơn vì Gazebo odometry gần lý tưởng
POSE_GRAPH.optimization_problem.local_slam_pose_translation_weight = 1e5
POSE_GRAPH.optimization_problem.local_slam_pose_rotation_weight = 1e5
POSE_GRAPH.optimization_problem.odometry_translation_weight = 1e5
POSE_GRAPH.optimization_problem.odometry_rotation_weight = 1e5

POSE_GRAPH.max_num_final_iterations = 200

return options
