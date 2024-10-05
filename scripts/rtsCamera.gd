extends Node3D

@export_range(0,100,1) var cameraMoveSpeed:float = 50.0

var cameraZoomDirection:float = 0
@export_range(0,100,1) var cameraZoomSpeed:float = 50.0
@export_range(0,100,1) var cameraZoomMin:float = 0.0
@export_range(0,100,1) var cameraZoomMax:float = 50.0
@export_range(0,2,0.1) var cameraZoomSpeedDamp:float = 0.92

@export_range(0,32,4) var cameraPanMargin: int = 16
@export_range(0,100,1) var cameraPanSpeed:int = 40

@export_range(0,10,0.1) var cameraRotateSpeed:float = 3.0
var cameraRotateDirection:float = 0
var cameraSocketRotateDirection:float = 0
@export_range(0,10,1) var cameraSocketRotationMin:float = -1.5
@export_range(0,10,1) var cameraSocketRotationMax:float = -0.25

var cameraCanMoveBase:bool = true
var cameraCanProcess:bool = true
var cameraCanZoom:bool = true
var cameraCanPan:bool = true
var cameraCanRotate:bool = true
var cameraCanRotateSocket:bool = true
var cameraCanRotateMouse:bool = false
var cameraCanPanMouse:bool = false

var mouseLastPos: Vector2 = Vector2.ZERO

@onready var cameraSocket:Node3D = $CameraSocket
@onready var camera:Camera3D = $CameraSocket/Camera3D

func _ready() -> void :
  pass
  
func _process(delta:float) -> void:
  if !cameraCanProcess: return
  cameraBaseMove(delta)
  cameraZoomUpdate(delta)
  cameraPanUpdate(delta)
  cameraPanMouseUpdate(delta)
  cameraRotateUpdate(delta)
  
func _unhandled_input(_event: InputEvent) -> void:
  if Input.is_action_pressed("cameraZoomIn"):
    cameraZoomDirection = -1
  elif Input.is_action_pressed("cameraZoomOut"):
    cameraZoomDirection = 1
  
  if Input.is_action_pressed("cameraRotateLeft"):
    cameraRotateDirection = -1
  elif Input.is_action_pressed("cameraRotateRight"):
    cameraRotateDirection = 1
  else:
    cameraRotateDirection = 0

  if _event.is_action_pressed("cameraRotateMouse"):
    mouseLastPos = _event.get_position()
    cameraCanRotateMouse = true
  elif _event.is_action_released("cameraRotateMouse"):
    cameraCanRotateMouse = false

  if _event.is_action_pressed("cameraPanMouse"):
    mouseLastPos = _event.get_position()
    cameraCanPanMouse = true
    cameraCanPan = false
  elif _event.is_action_released("cameraPanMouse"):
    cameraCanPanMouse = false
    cameraCanPan = true
  
func cameraBaseMove(delta:float) -> void:
  if !cameraCanMoveBase: return

  var velocityDir:Vector3 = Vector3.ZERO

  if Input.is_action_pressed("cameraForward"):
    velocityDir -= transform.basis.z
  if Input.is_action_pressed("cameraBackward"):
    velocityDir += transform.basis.z
  if Input.is_action_pressed("cameraLeft"):
    velocityDir -= transform.basis.x
  if Input.is_action_pressed("cameraRight"):
    velocityDir += transform.basis.x
  
  position += velocityDir.normalized() * cameraMoveSpeed * delta

func cameraZoomUpdate(delta: float) -> void:
  if !cameraCanZoom: return

  var newZoom: float = camera.position.z + cameraZoomDirection * cameraZoomSpeed * delta
  camera.position.z = clamp(newZoom, cameraZoomMin, cameraZoomMax)
  
  cameraZoomDirection *= cameraZoomSpeedDamp

func cameraPanUpdate(delta: float) -> void:
  if !cameraCanPan: return

  var mousePos: Vector2 = get_viewport().get_mouse_position()
  var screenSize: Vector2 = get_viewport().size
  var panDir: Vector2 = Vector2.ZERO
  
  if mousePos.x < cameraPanMargin:
    panDir.x = -1
  elif mousePos.x > screenSize.x - cameraPanMargin:
    panDir.x = 1
  if mousePos.y < cameraPanMargin:
    panDir.y = -1
  elif mousePos.y > screenSize.y - cameraPanMargin:
    panDir.y = 1
  
  if panDir != Vector2.ZERO:
    var panDir3D: Vector3 = Vector3(panDir.x, 0, panDir.y)
    var worldPanDir: Vector3 = transform.basis * panDir3D
    position += worldPanDir * cameraPanSpeed * delta

func cameraPanMouseUpdate(delta: float) -> void:
  if !cameraCanPanMouse: return
  var mouseOffset: Vector2 = get_viewport().get_mouse_position() - mouseLastPos
  mouseLastPos = get_viewport().get_mouse_position()
  var panDir: Vector3 = Vector3(mouseOffset.x, 0, mouseOffset.y)
  var worldPanDir: Vector3 = transform.basis * panDir
  position -= worldPanDir * (cameraPanSpeed/15.0) * delta

func cameraRotateUpdate(delta: float) -> void:
  if cameraCanRotate:
    cameraRotate(delta, cameraRotateDirection)
  if cameraCanRotateMouse:
    cameraRotateMouse(delta)

func cameraRotate(delta: float, dir: float) -> void:
  rotation.y += dir * cameraRotateSpeed * delta

func cameraSocketRotate(delta: float, dir: float) -> void:
  if !cameraCanRotateSocket: return
  var newRot: float = cameraSocket.rotation.x
  newRot -= dir * cameraRotateSpeed * delta
  newRot = clamp(newRot, cameraSocketRotationMin, cameraSocketRotationMax)
  cameraSocket.rotation.x = newRot

func cameraRotateMouse(delta: float) -> void:
  if !cameraCanRotateMouse or !cameraCanRotateSocket: return
  var mouseOffset: Vector2 = get_viewport().get_mouse_position() - mouseLastPos
  mouseLastPos = get_viewport().get_mouse_position()

  cameraRotate(delta, -mouseOffset.x)
  cameraSocketRotate(delta, mouseOffset.y)
