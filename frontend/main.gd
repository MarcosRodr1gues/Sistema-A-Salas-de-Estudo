extends Control

@onready var input_email = $InputEmail
@onready var input_senha = $InputSenha
@onready var label_aviso = $LabelAviso
@onready var http = $HTTPRequest

func _ready():
	$BtnEntrar.pressed.connect(_on_btn_entrar_pressed)
	http.request_completed.connect(_on_request_completed)

func _on_btn_entrar_pressed():
	var email = input_email.text
	var senha = input_senha.text
	
	if email == "" or senha == "":
		label_aviso.text = "Preencha todos os campos!"
		return

	label_aviso.text = "Conectando..."
	
	# Monta o pacote JSON para enviar
	var dados = {"email": email, "senha": senha}
	var headers = ["Content-Type: application/json"]
	var json_string = JSON.stringify(dados)
	
	# Envia POST para o Python
	http.request("http://127.0.0.1:5000/login", headers, HTTPClient.METHOD_POST, json_string)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json["sucesso"] == true:
			label_aviso.text = "Sucesso! Bem-vindo " + json["usuario_nome"]
			# AQUI NO FUTURO VAMOS MUDAR DE CENA
		else:
			label_aviso.text = json["mensagem"]
	elif response_code == 401:
		label_aviso.text = "Senha incorreta!"
	else:
		label_aviso.text = "Erro no servidor: " + str(response_code)
