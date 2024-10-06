extends Node3D
class_name Honeycomb

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

# func getBottomFaceVerts() -> Array:
#   var offsets:Vector3 = Vector3(0, yOffset, 0)
#   var pos:Vector3 = position
#   var verts:Array = [
#     Vector3(-hexWidth / 2.0, 0, -hexHeight / 2.0) + pos + offsets,
#     Vector3(hexWidth / 2.0, 0, -hexHeight / 2.0) + pos + offsets,
#     Vector3(hexWidth, 0, 0) + pos + offsets,
#     Vector3(hexWidth / 2.0, 0, hexHeight / 2.0) + pos + offsets,
#     Vector3(-hexWidth / 2.0, 0, hexHeight / 2.0) + pos + offsets,
#     Vector3(-hexWidth, 0, 0) + pos + offsets
#   ]
#   return verts
