extends Node2D

@export var units: Node3D = null

@onready var gameOverScreen: Control = $CanvasLayer/GameOverScreen

@onready var playerCamera: Node3D = $CameraBase
@onready var uiSelectBox: NinePatchRect = $UISelectBox
const moduleCamera: GDScript = preload("res://scripts/moduleCamera.gd")

@export var honeycombManager: HoneycombManager = null

var workerBee: PackedScene = preload("res://scenes/workerBee.tscn")

# Buttons
@onready var buttonFlower: TextureButton = $CanvasLayer/Panel/MarginContainer/HBoxContainer/SkillMenuPanel/ButtonFlower
@onready var buttonHoney: TextureButton = $CanvasLayer/Panel/MarginContainer/HBoxContainer/SkillMenuPanel/ButtonHoney
@onready var buttonBee: TextureButton = $CanvasLayer/Panel/MarginContainer/HBoxContainer/SkillMenuPanel/ButtonBee
var buttons: Array = []

var mouseLeftClick: bool = false
var dragRectangleArea: Rect2 = Rect2(0, 0, 0, 0)
const minDragSquared: float = 128
var selectedUnits: Array = []

@export var queenBee: Node3D = null
var selectedQueen: bool = false

var highlightedHoneycomb: Honeycomb = null

# Resources
var honeyAmount: int = 0
var nectarAmount: int = 0
var beesCollecting: Array = []

########################################################
var beeCost: int = 8
########################################################

# UI Items
@onready var honeyLabel: Label = $CanvasLayer/Panel/MarginContainer/HBoxContainer/ResourcesPanel/GridContainer/HoneyLabel
@onready var nectarLabel: Label = $CanvasLayer/Panel/MarginContainer/HBoxContainer/ResourcesPanel/GridContainer/NectarLabel
@onready var beesLabel: Label = $CanvasLayer/Panel/MarginContainer/HBoxContainer/ResourcesPanel/GridContainer/BeesLabel
@onready var honeyProgressBar: ProgressBar = $CanvasLayer/Panel/MarginContainer/HBoxContainer/TimerPanel/GridContainer/MarginContainer/ProgressBarHoney
@onready var nectarProgressBar: ProgressBar = $CanvasLayer/Panel/MarginContainer/HBoxContainer/TimerPanel/GridContainer/MarginContainer2/ProgressBarNectar
@onready var beesProgressBar: ProgressBar = $CanvasLayer/Panel/MarginContainer/HBoxContainer/TimerPanel/GridContainer/MarginContainer3/ProgressBarBees

var honeyTimer: Timer = null
var nectarTimer: Timer = null
var beesTimer: Timer = null
var honeyTimerMaxSeconds: float = 300.0
var nectarTimerMaxSeconds: float = 20.0
var beesTimerMaxSeconds: float = 15.0

var honeyMakingMode: bool = false

func _ready():
  initInterface()
  honeyTimer = Timer.new()
  nectarTimer = Timer.new()
  beesTimer = Timer.new()
  add_child(honeyTimer)
  add_child(nectarTimer)
  add_child(beesTimer)
  nectarProgressBar.value = 0
  beesProgressBar.value = 0
  setHoneyTimer(honeyTimerMaxSeconds)
  gameOverScreen.visible = false

func initInterface() -> void:
  uiSelectBox.visible = false
  buttons.append(buttonFlower)
  buttons.append(buttonHoney)
  buttons.append(buttonBee)
  buttonFlower.pressed.connect(buttonFlowerPressed)
  buttonHoney.pressed.connect(buttonHoneyPressed)
  buttonBee.pressed.connect(buttonBeePressed)

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
  updateButtons()
  updateBeesAmount(units.get_child_count())
  updateHoneyProgress()
  updateNectarProgress()
  updateBeesProgress()

func _input(_event: InputEvent) -> void:
  for button in buttons:
    if button.is_hovered():
      return

  if Input.is_action_just_pressed("mouseLeftClick"):
    mouseLeftClick = true
    dragRectangleArea.position = get_global_mouse_position()
    uiSelectBox.position = dragRectangleArea.position
  if Input.is_action_just_released("mouseLeftClick"):
    mouseLeftClick = false
    uiSelectBox.visible = false

    var shift: bool = Input.is_action_pressed("shift")
    
    if dragRectangleArea.size.length_squared() > minDragSquared:
      checkQueenBoxSelected()
      castBoxSelection(shift)
    else:
      castSingleSelection(get_global_mouse_position(), shift)
      checkQueenSelected()

func castBoxSelection(shift: bool) -> void:
  if !shift:
    selectionClear()

  for unit in units.get_children():
    if dragRectangleArea.abs().has_point(playerCamera.getCameraSpaceFromWorldSpace(unit.transform.origin)):
      if unit.selectable:
        selectionAddUnit(unit)
      selectQueen(false)

func castSingleSelection(mousePos: Vector2, shift: bool) -> void:
  if !shift:
    selectionClear()
    selectQueen(false)

  for unit in units.get_children():
    var unit2Dpos: Vector2 = playerCamera.getCameraSpaceFromWorldSpace(unit.transform.origin + Vector3(0, 1.5, -1))

    if (mousePos.distance_to(unit2Dpos) < 30):
      if unit.selectable:
        selectionToggleUnit(unit)
      selectQueen(false)
    else:
      if highlightedHoneycomb != null:
        highlightedHoneycomb.setMaterialDefault()
        highlightedHoneycomb = null

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
  honeyMakingMode = false

func castHoneycombHighlight() -> void:
  if selectedUnits.size() == 0:
    return
  var mousePos: Vector2 = get_viewport().get_mouse_position()
  var camera: Camera3D = get_viewport().get_camera_3d()
  var raycastResult: Dictionary = moduleCamera.cameraRaycast(camera, mousePos)

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

func buttonFlowerPressed() -> void:
  for unit in selectedUnits:
    unit.collectNectar()
    unit.select(false)
    beesCollecting.append(unit)
  setNectarTimer(nectarTimerMaxSeconds)
  
func buttonHoneyPressed() -> void:
  if selectedUnits.size() > 0:
    honeyMakingMode = true
    var thisUnit = selectedUnits[0]
    thisUnit.honeyMakingMode = true

func buttonBeePressed() -> void:
  if honeyAmount > beeCost:
    setHoneyAmount(honeyAmount - beeCost)
    setBeesTimer(beesTimerMaxSeconds)

func updateButtons() -> void:
  if selectedUnits.size() > 0:
    buttonFlower.disabled = false
    buttonHoney.disabled = false
    buttonBee.disabled = true
  elif selectedQueen:
    buttonFlower.disabled = true
    buttonHoney.disabled = true

    if beesTimer.is_stopped():
      buttonBee.disabled = false
  else:
    buttonFlower.disabled = true
    buttonHoney.disabled = true
    buttonBee.disabled = true

func checkQueenSelected() -> void:
  if selectedUnits.size() > 0:
    return
  var unit2Dpos: Vector2 = playerCamera.getCameraSpaceFromWorldSpace(queenBee.transform.origin + Vector3(0, 3, -1))

  if (get_global_mouse_position().distance_to(unit2Dpos) < 60):
    selectQueen(true)
  else:
    selectQueen(false)

func checkQueenBoxSelected() -> void:
  if dragRectangleArea.abs().has_point(playerCamera.getCameraSpaceFromWorldSpace(queenBee.transform.origin)):
    selectQueen(true)
  else:
    selectQueen(false)

func selectQueen(inBool: bool) -> void:
  selectedQueen = inBool
  queenBee.select(inBool)

func spawnWorkerBee() -> void:
  var newWorker = workerBee.instantiate()
  var honeycomb: Honeycomb = honeycombManager.getRandomHoneycombInRadius(queenBee.global_position, 10.0, 5.0)
  print(honeycomb.global_position)
  units.add_child(newWorker)
  newWorker.global_position = Vector3(honeycomb.global_position.x, queenBee.global_position.y, honeycomb.global_position.z)

func setHoneyAmount(amount: int) -> void:
  honeyAmount = amount
  honeyLabel.text = "Honey: " + str(honeyAmount)

func setNectarAmount(amount: int) -> void:
  nectarAmount = amount
  nectarLabel.text = "Nectar: " + str(nectarAmount)

func updateBeesAmount(amount: int) -> void:
  beesLabel.text = "Bees: " + str(amount)

# Honey Timer
func setHoneyTimer(seconds: float) -> void:
  honeyProgressBar.max_value = seconds
  honeyProgressBar.value = seconds
  honeyTimer.timeout.connect(onHoneyTimerTimeout)
  honeyTimer.start(seconds)

func onHoneyTimerTimeout() -> void:
  honeyTimer.stop()
  
  gameOverScreen.visible = true
  gameOverScreen.get_node("GameOverLabel").text = "You Collected " + str(honeyAmount) + " Honey!"

func updateHoneyProgress() -> void:
  honeyProgressBar.value = honeyTimer.time_left

# Nectar Timer
func setNectarTimer(seconds: float) -> void:
  nectarProgressBar.max_value = seconds
  nectarProgressBar.value = 0
  nectarTimer.timeout.connect(onNectarTimerTimeout)
  nectarTimer.start(seconds)

func onNectarTimerTimeout() -> void:
  nectarTimer.stop()
  for unit in beesCollecting:
    unit.stopCollecting()

func updateNectarProgress() -> void:
  nectarProgressBar.value = nectarProgressBar.max_value - nectarTimer.time_left

# Bees Timer
func setBeesTimer(seconds: float) -> void:
  beesProgressBar.max_value = seconds
  beesProgressBar.value = 0
  beesTimer.timeout.connect(onBeesTimerTimeout)
  beesTimer.start(seconds)
  buttonBee.disabled = true

func onBeesTimerTimeout() -> void:
  beesTimer.stop()
  buttonBee.disabled = false
  spawnWorkerBee()

func updateBeesProgress() -> void:
  beesProgressBar.value = beesProgressBar.max_value - beesTimer.time_left

func onHoneyFull(amount: int) -> void:
  setHoneyAmount(honeyAmount + amount)

func _on_restart_button_pressed() -> void:
  get_tree().reload_current_scene()
