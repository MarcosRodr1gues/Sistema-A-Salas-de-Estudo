extends Control

# --- VARIÁVEIS (Nomes Definidos) ---
@onready var label_titulo: Label = $VBoxContainer/LabelTitulo
@onready var lista_reservas: ItemList = $VBoxContainer/ListaReservas
@onready var btn_voltar: Button = $VBoxContainer/BtnVoltar
@onready var label_status: Label = $VBoxContainer/LabelStatus

# --- CORREÇÃO: Referência ao nó HTTPRequest ---
@onready var http_reservas: HTTPRequest = $HTTPRequest


func _ready():
	# 1. Debug para sabermos se o script carregou
	print("--- INICIANDO TELA DE RESERVAS ---")
	
	# 2. Conexões de segurança
	if btn_voltar:
		btn_voltar.pressed.connect(_on_btn_voltar_pressed)
	else:
		print("ERRO CRÍTICO: Botão Voltar não encontrado!")

	if http_reservas:
		http_reservas.request_completed.connect(_on_request_completed)
	else:
		print("ERRO CRÍTICO: Nó HTTPRequest não encontrado ou caminho incorreto!")
		label_status.text = "Erro: Configuração de rede faltando."
		return 

	# 3. Lógica de Busca
	print("--- ID GLOBAL: ", Global.usuario_id)
	
	if Global.usuario_id == 0:
		label_status.text = "Erro: Faça Login novamente."
		return

	label_status.text = "Carregando agendamentos..."
	var url = "http://127.0.0.1:5000/minhas_reservas/" + str(Global.usuario_id)
	
	# Tenta fazer a requisição
	var erro = http_reservas.request(url)
	
	if erro != OK:
		label_status.text = "Erro interno ao tentar conectar."
		print("Erro ao iniciar request: ", error_string(erro))

func _on_request_completed(result, code, headers, body):
	print("--- RESPOSTA DO SERVIDOR: CÓDIGO ", code, " ---")
	
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		# Debug do conteúdo
		print("\n--- O QUE O PYTHON MANDOU: ---")
		print(json)
		print("------------------------------\n")
		
		lista_reservas.clear()
		
		if json == null:
			label_status.text = "Erro ao ler dados do servidor."
		elif json is Array and json.size() == 0: 
			label_status.text = "Você ainda não tem reservas."
		elif json is Dictionary and json.has("error"): 
			label_status.text = str(json["error"])
		else:
			label_status.text = "" 
			
			if json is Array:
				for r in json:
					var sala = r.get("sala_nome", "Sala Desconhecida")
					
					# --- FORMATAÇÃO DE HORA APLICADA AQUI ---
					# Pega o valor (ex: 11.0), converte para float e depois para int (vira 11)
					var h_val = r.get("horario", 0)
					var h_int = int(float(h_val))
					
					# Formata: %02d garante 2 dígitos (ex: 8 vira "08", 11 vira "11")
					var horario_formatado = "%02d:00" % h_int
					
					var texto = sala + " - Horário: " + horario_formatado
					lista_reservas.add_item(texto)
			else:
				print("ERRO: O formato recebido não é uma lista!")
				print(json)
				
	else:
		label_status.text = "Erro no servidor. Código: " + str(code)

func _on_btn_voltar_pressed():
	# Muda para a tela de fazer reservas (confirme se o nome do arquivo é esse mesmo)
	get_tree().change_scene_to_file("res://tela_reserva.tscn")
