extends Control

# --- REFERÊNCIAS ---
# Ajuste os caminhos se necessário, mas mantive como você enviou nas imagens
@onready var input_email: LineEdit = $TextureRect/ContainerPrincipal/InputEmail
@onready var input_senha: LineEdit = $TextureRect/ContainerPrincipal/InputSenha
@onready var label_aviso: Label = $TextureRect/ContainerPrincipal/LabelAviso
@onready var http_request: HTTPRequest = $TextureRect/ContainerPrincipal/HTTPRequest
@onready var btn_entrar: Button = $TextureRect/ContainerPrincipal/BtnEntrar

func _ready():
	# Verificações de segurança para não travar o jogo se mudar o nome do nó
	if btn_entrar:
		btn_entrar.pressed.connect(_on_btn_entrar_pressed)
	else:
		print("ERRO: Botão Entrar não encontrado.")

	if http_request:
		http_request.request_completed.connect(_on_request_completed)
	else:
		print("ERRO: HTTPRequest não encontrado.")

func _on_btn_entrar_pressed():
	label_aviso.text = "Conectando..."
	var dados = {"email": input_email.text, "senha": input_senha.text}
	var headers = ["Content-Type: application/json"]
	
	# Envia os dados para o Python
	http_request.request("http://127.0.0.1:5000/login", headers, HTTPClient.METHOD_POST, JSON.stringify(dados))

func _on_request_completed(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		if json == null:
			label_aviso.text = "Erro: Resposta vazia."
			return

		if json.get("sucesso") == true:
			Global.usuario_id = int(json["usuario_id"])
			
			# --- VERIFICAÇÃO DE ADMIN ---
			if json.get("is_admin") == true:
				Global.is_admin = true
				print("--- MODO ADMINISTRADOR ATIVADO ---")
				
				# AQUI ESTÁ A MUDANÇA:
				# Usa a sua cena de transição suave para ir ao painel
				Transição.trocar_cena("res://painel_admin.tscn")
				
			else:
				# Caso seja aluno normal
				Global.is_admin = false
				
				# Se quiser transição suave para o aluno também, use Transition.trocar_cena
				# Se quiser corte seco, use get_tree().change_scene_to_file
				Transição.trocar_cena("res://tela_reserva.tscn")
			# ----------------------------
			
		else:
			label_aviso.text = "Erro: " + str(json.get("mensagem", "Dados inválidos"))
	else:
		label_aviso.text = "Erro no servidor: " + str(code)
