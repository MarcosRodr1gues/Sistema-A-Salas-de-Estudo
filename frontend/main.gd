extends Node2D

# Pega as referências dos nós que criamos
@onready var http = $HTTPRequest
@onready var label = $Label
@onready var button = $Button

func _ready():
	# Conecta o clique do botão à função
	button.pressed.connect(_on_button_pressed)
	# Conecta a resposta do servidor à função
	http.request_completed.connect(_on_request_completed)

func _on_button_pressed():
	label.text = "Chamando o Python..."
	# Faz o pedido para o seu servidor local
	var url = "http://127.0.0.1:5000/teste"
	var erro = http.request(url)
	
	if erro != OK:
		print("Erro ao tentar fazer a requisição!")

func _on_request_completed(result, response_code, headers, body):
	# O servidor respondeu!
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(json)
	
	# Coloca a mensagem na tela
	label.text = json["mensagem"]
