extends NavigationRegion3D
class_name HoneycombManager

@export var gridWidth: int
@export var gridHeight: int
var honeycomb: PackedScene = preload("res://scenes/honeycomb.tscn")

func _ready():
  # clearHoneycombs()
  generateHoneycombs()
  var childCount: int = get_child_count()
  for i in range(childCount/5):
    removeRandomHoneycomb()

  get_tree().process_frame.emit() # Force a frame to be processed so that the honeycombs are removed before we bake the navmesh

  generateNavMesh()

func generateHoneycombs():
  for x in range(gridWidth):
    for y in range(gridHeight):
      var honeycombInstance = honeycomb.instantiate()
      honeycombInstance.setCoords(Vector2(x, y))
      var hex = hexToWorld(honeycombInstance)
      honeycombInstance.position = hex
      add_child(honeycombInstance)

func hexToWorld(comb: Honeycomb) -> Vector3:
  var coords = comb.getCoords()
  var hexHeight = comb.getHeight()
  var hexWidth = comb.getWidth()
  var x = coords.x * hexWidth + hexWidth / 2.0 * fmod(coords.y, 2.0)
  var z = coords.y * hexHeight * 0.75

  return Vector3(x, 0, z)

func clearHoneycombs():
    for child in get_children():
      if child is Honeycomb:
        child.queue_free()

func removeRandomHoneycomb():
    var children = get_children()
    if children.size() > 0:
        var randomIndex = randi() % children.size()
        children[randomIndex].queue_free()

func generateNavMesh() -> void:
  bake_finished.connect(onBakeFinished)
  await get_tree().process_frame
  bake_navigation_mesh(true)
  
func onBakeFinished() -> void:
  print("Bake Finished")

func getHoneycombAtCoords(coords: Vector2) -> Honeycomb:
  for child in get_children():
    if child is Honeycomb:
      if child.getCoords() == coords:
        return child
  return null

func getClosesetHoneycomb(pos: Vector3) -> Honeycomb:
  var closestHoneycomb: Honeycomb = null
  var closestDistance: float = 1000000
  for child in get_children():
    if child is Honeycomb:
      var distance = child.global_position.distance_to(pos)
      if distance < closestDistance:
        closestDistance = distance
        closestHoneycomb = child
  return closestHoneycomb

func getRandomHoneycombInRadius(pos: Vector3, radius: float, minDistance: float) -> Honeycomb:
  var honeycombs: Array = []
  for child in get_children():
    if child is Honeycomb:
      var distance = child.global_position.distance_to(pos)
      if distance < radius and distance > minDistance:
        honeycombs.append(child)
  if honeycombs.size() > 0:
    return honeycombs[randi() % honeycombs.size()]
  return null
