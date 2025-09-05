extends Area2D

signal brick_hit

func _ready():
	body_entered.connect(self._on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("ball"):
		emit_signal("brick_hit")
		get_parent().queue_free()  
