extends CharacterBody3D

const moduleCamera:GDScript = preload("res://scripts/moduleCamera.gd")
@onready var navAgent:NavigationAgent3D = $NavigationAgent3D
@onready var selectedSprite: Sprite3D = $Selected
@onready var pathRecalcTimer: Timer = $PathRecalcTimer
@onready var gravityRayCast: RayCast3D = $GravityRayCast

var selected: bool = false
var navPathTarget: Vector3 = Vector3.ZERO
var navTargetObject: Node3D = null

var steerSpeed: float = 10.0
var rotationFast: bool = false

var stuckMax:int = 9
var stuckCount:int = 0
var lastPos:Vector3 = Vector3.ZERO

func _ready() -> void:
  selectedSprite.visible = false
  navAgent.velocity_computed.connect(move)
  pathRecalcTimer.timeout.connect(navPathTimerUpdate)
  set_max_slides(2)


func _input(event: InputEvent) -> void:
  if selected && Input.is_action_just_pressed("mouseRightClick"):
    var mousePos:Vector2 = get_viewport().get_mouse_position()
    var camera:Camera3D = get_viewport().get_camera_3d()
    var raycastResult:Dictionary = moduleCamera.cameraRaycast(camera, mousePos)

    if raycastResult.size() == 0:
      return
    # var cameraRaycastCoords:Vector3 = raycastResult["position"]
    var hitObject = raycastResult["collider"]
    var hitObjectPos:Vector3 = Vector3.ZERO
    
    while hitObject.get_parent() != null:
      if hitObject is Honeycomb:
        hitObjectPos = hitObject.position
        hitObjectPos = Vector3(hitObjectPos.x, position.y, hitObjectPos.z)
        break
      hitObject = hitObject.get_parent()
    
    if hitObjectPos != Vector3.ZERO:
      navAgent.set_target_position(hitObjectPos)
      navPathTarget = hitObjectPos
      navTargetObject = hitObject

func _physics_process(delta: float) -> void:
  if navAgent.is_navigation_finished():
    return

  var nextPos:Vector3 = navAgent.get_next_path_position()
  var direction:Vector3 = global_position.direction_to(nextPos) * navAgent.max_speed

  rotateToDirection(direction, delta)

  var steerVelocity:Vector3 = (direction - velocity) * steerSpeed * delta
  var newAgentVelocity:Vector3 = velocity + (direction - velocity) + steerVelocity
  navAgent.set_velocity(newAgentVelocity)

func move(newVelocity: Vector3) -> void:
  velocity = newVelocity
  move_and_slide()

func rotateToDirection(dir: Vector3, delta: float) -> void:
  if (rotationFast):
    rotation.y = atan2(-dir.x, -dir.z)
  else:
    var pos2D: Vector2 = Vector2(-transform.basis.z.x, -transform.basis.z.z)
    var goal2D: Vector2 = Vector2(dir.x, dir.z)
    rotation.y -= pos2D.angle_to(goal2D) * steerSpeed * delta

func navPathTimerUpdate() -> void:
  if navPathTarget != Vector3.ZERO:
    navAgent.set_target_position(navPathTarget)
    stuckCheck()
    lastPos = global_position

func stuckCheck() -> void:
  if lastPos.distance_squared_to(position) < 0.8:
    if stuckCount < stuckMax:
      stuckCount += 1
    
    if stuckCount >= 3:
      if (global_position.distance_squared_to(navPathTarget) < 10.0 or stuckCount >= stuckMax):
        stuckCount = 0
        navAgent.emit_signal("navigation_finished")
        navAgent.set_target_position(global_position)
        navPathTarget = Vector3.ZERO
  lastPos = position

func select(isSelected: bool) -> void:
  if isSelected:
    selectedSprite.visible = true
    selected = true
  else:
    selectedSprite.visible = false
    selected = false
    navPathTarget = Vector3.ZERO
    navTargetObject = null # TODO udpate shaders
