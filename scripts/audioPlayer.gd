extends Node

var buzz = preload("res://assets/audio/buzz.wav")
var walk = preload("res://assets/audio/walk.wav")
var work = preload("res://assets/audio/work.wav")
var newBee = preload("res://assets/audio/newBee.wav")

func playSFX(soundname: String):
  if get_node_or_null(soundname) != null:
    return

  var stream = null

  match soundname:
    "buzz":
      stream = buzz
    "walk":
      stream = walk
    "work":
      stream = work
    "newBee":
      stream = newBee

  var asp = AudioStreamPlayer.new()
  asp.stream = stream
  asp.name = soundname

  asp.pitch_scale = randf_range(0.8, 1.2)

  add_child(asp)
  asp.play()

  await asp.finished

  asp.queue_free()

func stopSFX(soundname: String):
  var asp = get_node_or_null(soundname)
  if asp != null:
    asp.stop()
    asp.queue_free()
 
