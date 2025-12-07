extends CanvasLayer

@onready var anim = $AnimationPlayer

func trocar_cena(caminho_da_cena: String):
	# 1. Faz a imagem aparecer (Fade In)
	anim.play("dissolver")
	await anim.animation_finished
	
	# 2. Troca a cena atrás da imagem
	get_tree().change_scene_to_file(caminho_da_cena)
	
	# 3. Faz a imagem sumir (Fade Out)
	anim.play_backwards("dissolver")
