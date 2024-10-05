extends Node
class_name Honeycomb

var honeycomb: PackedScene = preload("res://scenes/honeycomb.tscn")
@export var honeycombCount: int
var hexRadius = 1
var hexHeight = hexRadius * 2.0
var hexWidth = hexHeight * sqrt(3) / 2.0

var hexDirections = [
    Vector2(1, 0),
    Vector2(1, -1),
    Vector2(0, -1),
    Vector2(-1, 0),
    Vector2(-1, 1),
    Vector2(0, 1)
]

func _ready():
  print("Hex Width: ", hexWidth)
  print("Hex Height: ", hexHeight)
  clearHoneycombs()
  generateHoneycombs()

func generateHoneycombs():
    var placedHexes = []
    var ring = 0

    # Add center hex
    var honeycombInstance = honeycomb.instantiate()
    honeycombInstance.position = Vector3(0, 0, 0)
    add_child(honeycombInstance)
    placedHexes.append(Vector2(0, 0))

    while placedHexes.size() < honeycombCount:
      ring += 1
      var hexesInRing = getHexesInRing(ring)
      print(hexesInRing)
      for hex in hexesInRing:
        if placedHexes.size() >= honeycombCount:
          break

        var worldPos = hexToWorld(hex, ring)
        honeycombInstance = honeycomb.instantiate()
        honeycombInstance.position = worldPos
        add_child(honeycombInstance)
        placedHexes.append(hex)

func getHexesInRing(ring: int) -> Array:
  var hexes = []

  var hex = Vector2(-1, ring)

  for direction in hexDirections:
    for i in range(ring):
      hexes.append(hex)
      hex += direction
  return hexes

func hexToWorld(hex: Vector2, ring: int) -> Vector3:
  var xOffset = 0.0

  if int(hex.y) % 2 != 0:
    if ring % 2 == 0:
      xOffset = -1*fmod(hex.y, 2.0)*hexWidth / 2.0
    else:
      xOffset = fmod(hex.y, 2.0)*hexWidth / 2.0

  # print(hex.x + (fmod(hex.y, 2.0) * hexWidth / 2.0))
  var x = hex.x * hexWidth + xOffset
  var z = hex.y * hexHeight * 0.75
  print("Hex: ", hex, " World: ", Vector3(x, 0, z))
  return Vector3(x, 0, z)

func clearHoneycombs():
    for child in get_children():
        child.queue_free()
