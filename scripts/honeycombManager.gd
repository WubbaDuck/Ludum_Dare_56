extends NavigationRegion3D
class_name HoneycombManager

@export var gridWidth: int
@export var gridHeight: int
var honeycomb: PackedScene = preload("res://scenes/honeycomb.tscn")

func _ready():
  # clearHoneycombs()
  generateHoneycombs()
  for i in range(2000):
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
