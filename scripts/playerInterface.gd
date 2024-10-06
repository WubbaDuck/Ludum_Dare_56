extends Node2D

@onready var playerCamera: Node3D = $CameraBase
@onready var uiSelectBox: NinePatchRect = $UISelectBox
@export var units: Node3D = null

var mouseLeftClick: bool = false
var dragRectangleArea: Rect2 = Rect2(0, 0, 0, 0)

const minDragSquared: float = 128

func _ready():
  initInterface()
  pass

func initInterface() -> void:
  uiSelectBox.visible = false

func _process(delta: float) -> void:
  if mouseLeftClick:
    dragRectangleArea.size = get_global_mouse_position() - dragRectangleArea.position
    udpateDragBox()
    if !uiSelectBox.visible:
      if dragRectangleArea.size.length_squared() > minDragSquared:
        uiSelectBox.visible = true
    else:
      udpateDragBox()

func _input(_event: InputEvent) -> void:
  if Input.is_action_just_pressed("mouseLeftClick"):
    mouseLeftClick = true
    dragRectangleArea.position = get_global_mouse_position()
    uiSelectBox.position = dragRectangleArea.position
  if Input.is_action_just_released("mouseLeftClick"):
    mouseLeftClick = false
    uiSelectBox.visible = false
    castSelection()

func castSelection() -> void:
  for unit in units.get_children():
    if dragRectangleArea.abs().has_point(playerCamera.getCameraSpaceFromWorldSpace(unit.transform.origin)):
      unit.select(true)
    else:
      unit.select(false)

func udpateDragBox() -> void:
  uiSelectBox.size = abs(dragRectangleArea.size)
  
  if dragRectangleArea.size.x < 0:
    uiSelectBox.scale.x = -1
  else:
    uiSelectBox.scale.x = 1  
    
  if dragRectangleArea.size.y < 0:
    uiSelectBox.scale.y = -1
  else:
    uiSelectBox.scale.y = 1
  
