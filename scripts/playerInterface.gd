extends Node2D

@export var units: Node3D = null

@onready var playerCamera: Node3D = $CameraBase
@onready var uiSelectBox: NinePatchRect = $UISelectBox
const moduleCamera:GDScript = preload("res://scripts/moduleCamera.gd")

var mouseLeftClick: bool = false
var dragRectangleArea: Rect2 = Rect2(0, 0, 0, 0)
const minDragSquared: float = 128
var selectedUnits: Array = []
var highlightedHoneycomb: Honeycomb = null

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

  castHoneycombHighlight()

func _input(_event: InputEvent) -> void:
  if Input.is_action_just_pressed("mouseLeftClick"):
    mouseLeftClick = true
    dragRectangleArea.position = get_global_mouse_position()
    uiSelectBox.position = dragRectangleArea.position
  if Input.is_action_just_released("mouseLeftClick"):
    mouseLeftClick = false
    uiSelectBox.visible = false

    var shift: bool = Input.is_action_pressed("shift")
    
    if dragRectangleArea.size.length_squared() > minDragSquared:
      castBoxSelection(shift)
    else:
      castSingleSelection(get_global_mouse_position(), shift)

func castBoxSelection(shift: bool) -> void:
  if !shift:
    selectionClear()

  for unit in units.get_children():
    if dragRectangleArea.abs().has_point(playerCamera.getCameraSpaceFromWorldSpace(unit.transform.origin)):
      selectionAddUnit(unit)

func castSingleSelection(mousePos: Vector2, shift: bool) -> void:
  if !shift:
    selectionClear()

  for unit in units.get_children():
    var unit2Dpos: Vector2 = playerCamera.getCameraSpaceFromWorldSpace(unit.transform.origin + Vector3(0, 1, 0))

    if (mousePos.distance_to(unit2Dpos) < 30):   
        selectionToggleUnit(unit)

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
  
func selectionAddUnit(unit: Node3D) -> void:
  selectedUnits.append(unit)
  unit.select(true)

func selectionAddUnits(unitsArray: Array) -> void:
  for unit in unitsArray:
    if !selectedUnits.has(unit):
      selectionAddUnit(unit)

func selectionRemoveUnit(unit: Node3D) -> void:
  if selectedUnits.has(unit):
    selectedUnits.erase(unit)
    unit.select(false)

func selectionRemoveUnits(unitsArray: Array) -> void:
  for unit in unitsArray:
    selectionRemoveUnit(unit)

func selectionToggleUnit(unit: Node3D) -> void:
  if selectedUnits.has(unit):
    selectionRemoveUnit(unit)
  else:
    selectionAddUnit(unit)

func selectionClear() -> void:
  for unit in selectedUnits:
    unit.select(false)
  selectedUnits.clear()

func castHoneycombHighlight() -> void:
  if selectedUnits.size() == 0:
    return
  var mousePos:Vector2 = get_viewport().get_mouse_position()
  var camera:Camera3D = get_viewport().get_camera_3d()
  var raycastResult:Dictionary = moduleCamera.cameraRaycast(camera, mousePos)

  if raycastResult.size() == 0:
    if highlightedHoneycomb != null:
      highlightedHoneycomb.setMaterialDefault()
      highlightedHoneycomb = null
    return

  var hitObject = raycastResult["collider"]
  
  while hitObject.get_parent() != null:
    if hitObject is Honeycomb:
      break
    hitObject = hitObject.get_parent()
  
  if hitObject is Honeycomb:
    if highlightedHoneycomb == hitObject:
      return
    if highlightedHoneycomb != null:
      highlightedHoneycomb.setMaterialDefault()
    highlightedHoneycomb = hitObject
    highlightedHoneycomb.setMaterialHighlight()
  else:
    if highlightedHoneycomb != null:
      highlightedHoneycomb.setMaterialDefault()
      highlightedHoneycomb = null
