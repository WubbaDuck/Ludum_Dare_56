extends RefCounted

static func cameraRaycast(camera: Camera3D, camera2Dcoords: Vector2) -> Dictionary:
  var rayFrom = camera.project_ray_origin(camera2Dcoords)
  var rayTo = rayFrom + camera.project_ray_normal(camera2Dcoords) * 1000.0
  var rayParams:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(rayFrom, rayTo)
  
  var result:Dictionary = camera.get_world_3d().get_direct_space_state().intersect_ray(rayParams)

  if result.size() > 0:
    return result
  return {}