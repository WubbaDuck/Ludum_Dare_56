extends Sprite3D

@export var rotationSpeed: float = 0.75

func _ready():
  pass

func _process(delta: float) -> void:
  rotation.y += rotationSpeed * delta
