extends Node3D
class_name Honeycomb

@onready var honeycombTop: MeshInstance3D = $honeyComb/HoneycombTop
@onready var honeycomb: MeshInstance3D = $honeyComb/Honeycomb
@onready var topMaterialDefault: StandardMaterial3D = preload("res://materials/transparent.tres")
@onready var topMaterialSelected: ShaderMaterial = preload("res://materials/honeycombSelected.tres")
@onready var materialHighlight: ShaderMaterial = preload("res://materials/honeycombHighlight.tres")
@onready var nectarSprite: Sprite3D = $NectarSprite
@onready var honeySprite: Sprite3D = $HoneySprite

var coords: Vector2 = Vector2(0, 0)
var hexRadius = 1
var hexHeight = hexRadius * 2.0
var hexWidth = hexHeight * sqrt(3) / 2.0
var yOffset = 0.0

var nectarAmount = 0
var maxHoneyAmount = 2
var maxNectarAmount = 14
var nectarPerHoney = 7
var honeyAmount = 0
var nectarFull = false

signal honeyFull(amount: int)

func _ready() -> void:
  honeycombTop.material_override = topMaterialDefault
  nectarSprite.visible = false
  honeySprite.visible = false

func _process(delta: float) -> void:
  if nectarAmount > 0 && nectarAmount <= maxNectarAmount:
    nectarSprite.visible = true
  else:
    nectarSprite.visible = false

  if honeyAmount >= maxHoneyAmount:
    honeySprite.visible = true
    nectarSprite.visible = false
  else:
    honeySprite.visible = false

func getCoords() -> Vector2:
  return coords

func setCoords(newCoords: Vector2):
  coords = newCoords

func getRadius() -> int:
  return hexRadius

func getHeight() -> float:
  return hexHeight

func getWidth() -> float:
  return hexWidth

func setMaterialTopDefault() -> void:
  honeycombTop.material_override = topMaterialDefault

func setMaterialNavSelected() -> void:
  honeycombTop.material_override = topMaterialSelected

func setMaterialHighlight() -> void:
  honeycomb.material_override = materialHighlight

func setMaterialDefault() -> void:
  honeycomb.material_override = null

func addNectar(amount: int) -> void:
  nectarAmount += amount

func fullOfNectar() -> bool:
  if !nectarFull:
    nectarFull = nectarAmount >= maxNectarAmount
  return nectarFull

func cookHoney() -> void:
  if nectarAmount > 0 && honeyAmount < maxHoneyAmount:
    honeyAmount += 1
    nectarAmount -= nectarPerHoney

    if honeyAmount == maxHoneyAmount:
      print("Honey Full")
      emit_signal("honeyFull", honeyAmount)
    

func honeyFinished() -> bool:
  return honeyAmount == maxHoneyAmount
