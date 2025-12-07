extends Control

@onready var lista = $Container/ListaReservas
@onready var status = $Container/LabelStatus
@onready var http = $HTTPReservas

func _ready():
	# 1. Conecta o botão voltar
	$Container/BtnVoltar.pressed.connect(_on_btn_voltar_pressed)
	
	# 2. --- CORREÇÃO PRINCIPAL AQUI ---
	# Você precisa "avisar" que quando a resposta chegar, deve rodar a função lá de baixo
	http.request_completed.connect(_on_request_completed)
	# ----------------------------------
	
	# 3. Debug Visual
	status.text = "DEBUG: Meu ID é " + str(Global.usuario_id)
	
	# Aguarda um pouco para ler o debug
	await get_tree().create_timer(1.0).timeout
	
	# 4. Faz a busca
	status.text = "Buscando dados..."
	var url = "http://127.0.0.1:5000/minhas_reservas/" + str(Global.usuario_id)
	var erro = http.request(url)
	
	if erro != OK:
		status.text = "Erro interno ao tentar conectar."

func _on_request_completed(result, code, headers, body):
	if code == 200:
		var dados = JSON.parse_string(body.get_string_from_utf8())
		lista.clear()
		
		if dados.size() == 0:
			status.text = "Nenhuma reserva encontrada."
		else:
			status.text = "" # Limpa o texto de carregando
			for reserva in dados:
				# Formata o texto para ficar bonito na lista
				var texto = reserva["sala_nome"] + " às " + str(reserva["horario"]) + ":00"
				lista.add_item(texto)
	else:
		status.text = "Erro no servidor: " + str(code)

func _on_btn_voltar_pressed():
	# Volta para a tela principal
	get_tree().change_scene_to_file("res://main.tscn")
