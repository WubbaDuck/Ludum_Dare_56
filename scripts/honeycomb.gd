extends Node
class_name Honeycomb

var coords: Vector2 = Vector2(0, 0)
var hexRadius = 1
var hexHeight = hexRadius * 2.0
var hexWidth = hexHeight * sqrt(3) / 2.0


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
