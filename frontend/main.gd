extends Control

@onready var input_email = $InputEmail
@onready var input_senha = $InputSenha
@onready var label_aviso = $LabelAviso
@onready var http = $HTTPRequest

func _ready():
	$BtnEntrar.pressed.connect(_on_btn_entrar_pressed)
	http.request_completed.connect(_on_request_completed)

func _on_btn_entrar_pressed():
	label_aviso.text = "Conectando..."
	var dados = {"email": input_email.text, "senha": input_senha.text}
	var headers = ["Content-Type: application/json"]
	http.request("http://127.0.0.1:5000/login", headers, HTTPClient.METHOD_POST, JSON.stringify(dados))

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json["sucesso"] == true:
			label_aviso.text = "Sucesso!"
			Global.usuario_id = json["usuario_id"]
			Global.usuario_nome = json["usuario_nome"]
			# Muda para a tela de reservas
			get_tree().change_scene_to_file("res://tela_reserva.tscn")
		else:
			label_aviso.text = json["mensagem"]
	else:
		label_aviso.text = "Erro: " + str(response_code)
