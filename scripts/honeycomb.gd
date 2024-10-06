extends Node3D
class_name Honeycomb

@onready var honeycombTop: MeshInstance3D = $honeyComb/HoneycombTop
@onready var honeycomb: MeshInstance3D = $honeyComb/Honeycomb
@onready var topMaterialDefault: StandardMaterial3D = preload("res://materials/transparent.tres")
@onready var topMaterialSelected: ShaderMaterial = preload("res://materials/honeycombSelected.tres")
@onready var materialHighlight: ShaderMaterial = preload("res://materials/honeycombHighlight.tres")

var coords: Vector2 = Vector2(0, 0)
var hexRadius = 1
var hexHeight = hexRadius * 2.0
var hexWidth = hexHeight * sqrt(3) / 2.0
var yOffset = 0.0

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
