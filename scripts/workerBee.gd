extends CharacterBody3D

const moduleCamera: GDScript = preload("res://scripts/moduleCamera.gd")
@onready var navAgent: NavigationAgent3D = $NavigationAgent3D
@onready var selectedSprite: Sprite3D = $Selected
@onready var pathRecalcTimer: Timer = $PathRecalcTimer
@onready var animationPlayer: AnimationPlayer = $workerBee/AnimationPlayer
@onready var nectarSprite: Sprite3D = $NectarSprite
@onready var honeySprite: Sprite3D = $HoneySprite


var selected: bool = false
var selectable: bool = true
var navPathTarget: Vector3 = Vector3.ZERO
var navTargetObject: Node3D = null

var moveSpeed: float = 4.0
var steerSpeed: float = 10.0
var rotationFast: bool = false

var stuckMax: int = 9
var stuckCount: int = 0
var lastPos: Vector3 = Vector3.ZERO

var navLineMesh: MeshInstance3D = null

var collectingNectar: bool = false

var flyAwayTarget: Vector3 = Vector3.ZERO
var posBeforeFlyingAway: Vector3 = Vector3.ZERO
var flySpeed: float = 15.0
var flyBack: bool = false

var nectarGatherMax: int = 30
var nectarAmount: int = 0

var makingHoney: bool = false
var atHoneyTarget: bool = false
var honeyMakingTarget: Honeycomb = null
var nectarDepositAmount: int = 1
var honeyMakingMode: bool = false

var cumulativeDelta: float = 0

func _ready() -> void:
  selectedSprite.visible = false
  navAgent.velocity_computed.connect(move)
  pathRecalcTimer.timeout.connect(navPathTimerUpdate)
  set_max_slides(2)

  navLineMesh = MeshInstance3D.new()
  navLineMesh.mesh = ImmediateMesh.new()
  add_child(navLineMesh)

  nectarSprite.visible = false
  honeySprite.visible = false

  animationPlayer.animation_finished.connect(onAnimationFinished)
  animationPlayer.play("Idle")

func _input(event: InputEvent) -> void:
  if selected && Input.is_action_just_pressed("mouseRightClick"):
    var mousePos: Vector2 = get_viewport().get_mouse_position()
    var camera: Camera3D = get_viewport().get_camera_3d()
    var raycastResult: Dictionary = moduleCamera.cameraRaycast(camera, mousePos)

    if raycastResult.size() == 0:
      return
    # var cameraRaycastCoords:Vector3 = raycastResult["position"]
    var hitObject = raycastResult["collider"]
    var hitObjectPos: Vector3 = Vector3.ZERO
    
    while hitObject.get_parent() != null:
      if hitObject is Honeycomb:
        hitObjectPos = hitObject.position
        hitObjectPos = Vector3(hitObjectPos.x, position.y, hitObjectPos.z)
        break
      hitObject = hitObject.get_parent()
    
    if hitObjectPos != Vector3.ZERO:
      navAgent.set_target_position(hitObjectPos)
      navPathTarget = hitObjectPos
      clearTargetMaterial()
      navTargetObject = hitObject
      setTargetMaterial()

      if honeyMakingMode:
        startMakingHoney(hitObject)
        honeyMakingMode = false
      else:
        makingHoney = false

func _process(delta: float) -> void:
  if nectarAmount > 0:
    nectarSprite.visible = true
  else:
    nectarSprite.visible = false

  if makingHoney:
    honeySprite.visible = true
  else:
    honeySprite.visible = false

  cumulativeDelta += delta

  if makingHoney && honeyMakingTarget != null && honeyMakingTarget != navTargetObject && atHoneyTarget:
    if honeyMakingTarget.fullOfNectar():
      if cumulativeDelta > 3.0:
        cumulativeDelta = 0
        honeyMakingTarget.cookHoney()
    else:
      if cumulativeDelta > 1.0:
        cumulativeDelta = 0
        nectarAmount -= nectarDepositAmount
        honeyMakingTarget.addNectar(nectarDepositAmount)

    if honeyMakingTarget != null:
      if (honeyMakingTarget.fullOfNectar() && honeyMakingTarget.honeyFinished()) || nectarAmount == 0:
        finishMakingHoney()

func _physics_process(delta: float) -> void:
  if !collectingNectar:
    if navAgent.is_navigation_finished():
      return

    var nextPos: Vector3 = navAgent.get_next_path_position()
    var direction: Vector3 = global_position.direction_to(nextPos) * moveSpeed
    rotateToDirection(direction, delta)

    var steerVelocity: Vector3 = (direction - velocity) * steerSpeed * delta
    var newAgentVelocity: Vector3 = velocity + (direction - velocity) + steerVelocity
    navAgent.set_velocity(newAgentVelocity)
  elif flyAwayTarget != Vector3.ZERO and posBeforeFlyingAway != Vector3.ZERO:
    var currentTarget: Vector3 = flyAwayTarget
    if flyBack:
      currentTarget = posBeforeFlyingAway
    var direction: Vector3 = global_position.direction_to(currentTarget) * flySpeed
    rotateToDirection(direction, delta)
    global_position += direction * delta

    if flyBack and global_position.distance_to(posBeforeFlyingAway) < 1.0:
      global_position.y = 2.0
      finishCollectingNectar()
    

func move(newVelocity: Vector3) -> void:
  velocity = newVelocity
  move_and_slide()

func rotateToDirection(dir: Vector3, delta: float) -> void:
  if (rotationFast):
    rotation.y = atan2(-dir.x, -dir.z)
  else:
    var pos2D: Vector2 = Vector2(-transform.basis.z.x, -transform.basis.z.z)
    var goal2D: Vector2 = Vector2(-dir.x, -dir.z)
    rotation.y -= pos2D.angle_to(goal2D) * steerSpeed * delta

func navPathTimerUpdate() -> void:
  if collectingNectar:
    return
  if navPathTarget != Vector3.ZERO:
    navAgent.set_target_position(navPathTarget)
    stuckCheck()
    lastPos = global_position

  if velocity != Vector3.ZERO:
    animationPlayer.play("Walk")
  else:
    if makingHoney && atHoneyTarget:
      animationPlayer.play("Work")
    else:
      animationPlayer.play("Idle")

func stuckCheck() -> void:
  if lastPos.distance_squared_to(position) < 0.8:
    if stuckCount < stuckMax:
      stuckCount += 1
    
    if stuckCount >= 3:
      if (global_position.distance_squared_to(navPathTarget) < 10.0 or stuckCount >= stuckMax):
        stuckCount = 0
        cancelNavigation()
  lastPos = position

func cancelNavigation() -> void:
  if navTargetObject != null and honeyMakingTarget != null and navTargetObject == honeyMakingTarget :
    atHoneyTarget = true
    print("At Honey Target")
  else:
    atHoneyTarget = false

  navAgent.emit_signal("navigation_finished")
  navAgent.set_target_position(global_position)
  navPathTarget = Vector3.ZERO
  clearTargetMaterial()
  navTargetObject = null

func select(isSelected: bool) -> void:
  if isSelected && selectable:
    selectedSprite.visible = true
    selected = true
    setTargetMaterial()
  else:
    selectedSprite.visible = false
    selected = false
    honeyMakingMode = false
    clearTargetMaterial()

func setTargetMaterial() -> void:
  if navTargetObject != null:
    if navTargetObject is Honeycomb:
      var honeycomb: Honeycomb = navTargetObject as Honeycomb
      honeycomb.setMaterialNavSelected()

func clearTargetMaterial() -> void:
  if navTargetObject != null:
    if navTargetObject is Honeycomb:
      var honeycomb: Honeycomb = navTargetObject as Honeycomb
      honeycomb.setMaterialTopDefault()

func onAnimationFinished(animName: String) -> void:
  if animName == "Takeoff":
    animationPlayer.play("Fly")
    flyAway()

func collectNectar() -> void:
  cancelNavigation()
  posBeforeFlyingAway = global_position
  collectingNectar = true
  selectable = false
  animationPlayer.play("Takeoff")

func stopCollecting() -> void:
  flyBack = true

func finishCollectingNectar() -> void:
  nectarAmount += nectarGatherMax + randi_range(-10, 10)
  print("Nectar Gathered: ", nectarAmount)
  collectingNectar = false
  selectable = true
  flyBack = false
  flyAwayTarget = Vector3.ZERO
  posBeforeFlyingAway = Vector3.ZERO

func flyAway() -> void:
  var xDir: float = 1 if randf_range(-1, 1) > 0 else -1
  var zDir: float = 1 if randf_range(-1, 1) > 0 else -1
  var randomOffset: Vector3 = Vector3(xDir * 100, 50, zDir * 100)
  flyAwayTarget = global_position + randomOffset

func startMakingHoney(targetHoneycomb: Honeycomb) -> void:
  print("Start Making Honey")
  makingHoney = true
  honeyMakingTarget = targetHoneycomb

func finishMakingHoney() -> void:
  print("Honey Finished")
  makingHoney = false
  animationPlayer.play("Idle")
  # collectingNectar = false
  # selectable = true
  # flyBack = false
  # flyAwayTarget = Vector3.ZERO
  # posBeforeFlyingAway = Vector3.ZERO
  # nectarAmount = 0
  # animationPlayer.play("Land")
  # navPathTarget = Vector3.ZERO
  # clearTargetMaterial()
  # navTargetObject = null
  # selected = false
  # selectedSprite.visible = false
  # animationPlayer.play("Idle")
  # setTargetMaterial()
  # pathRecalcTimer.start()
