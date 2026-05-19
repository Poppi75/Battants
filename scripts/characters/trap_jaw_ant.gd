extends Player

var can_extra_dmg: bool = false
@onready var extra_dmg_timer: Timer = $ExtraDmgTimer

func _on_extra_dmg_timer_timeout() -> void:
	can_extra_dmg = true
