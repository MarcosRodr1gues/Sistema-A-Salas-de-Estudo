extends Control

# --- REFERÊNCIAS ---
@onready var label_status: Label = $VBoxContainer/LabelStatus
@onready var lista_reservas: ItemList = $VBoxContainer/ListaReservas
@onready var btn_voltar: Button = $VBoxContainer/BtnVoltar
@onready var btn_cancelar: Button = $VBoxContainer/BtnCancelar  # <--- NOVO BOTÃO

# Ajuste se o HTTPRequest estiver em outro lugar
@onready var http_reservas: HTTPRequest = $HTTPRequest 

# Variável para controlar o que estamos fazendo (Listar ou Excluir)
var acao_atual = ""

func _ready():
	print("--- INICIANDO TELA DE RESERVAS ---")
	
	if btn_voltar: btn_voltar.pressed.connect(_on_btn_voltar_pressed)
	
	# --- CONEXÃO DO NOVO BOTÃO ---
	if btn_cancelar: btn_cancelar.pressed.connect(_on_btn_cancelar_pressed)
	
	if http_reservas: http_reservas.request_completed.connect(_on_request_completed)
	
	carregar_reservas()

func carregar_reservas():
	if Global.usuario_id == 0:
		label_status.text = "Erro: Faça Login novamente."
		return

	acao_atual = "LISTAR"
	label_status.text = "Carregando agendamentos..."
	lista_reservas.clear()
	
	var url = "http://127.0.0.1:5000/minhas_reservas/" + str(Global.usuario_id)
	http_reservas.request(url)

func _on_btn_cancelar_pressed():
	# Verifica se o aluno selecionou alguma linha
	if lista_reservas.get_selected_items().size() == 0:
		label_status.text = "Selecione uma reserva para cancelar."
		return
	
	# Pega o índice visual
	var index = lista_reservas.get_selected_items()[0]
	
	# Recupera o ID REAL que guardamos escondido (metadata)
	var id_reserva = lista_reservas.get_item_metadata(index)
	
	print("Cancelando reserva ID: ", id_reserva)
	
	acao_atual = "EXCLUIR"
	label_status.text = "Cancelando..."
	
	# Chama a rota nova do Python
	var url = "http://127.0.0.1:5000/minhas_reservas/excluir/" + str(int(id_reserva))
	http_reservas.request(url, [], HTTPClient.METHOD_DELETE)

func _on_request_completed(result, code, headers, body):
	# Se der erro de conexão
	if code == 0:
		label_status.text = "Erro: Não foi possível conectar ao servidor."
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if acao_atual == "LISTAR":
		if json == null:
			label_status.text = "Erro ao ler dados."
		elif json.size() == 0:
			label_status.text = "Você não tem reservas."
		else:
			label_status.text = "" 
			for r in json:
				# Formatação de hora
				var h_float = float(r.get("horario", 0))
				var h_fmt = "%02d:00" % int(h_float)
				
				var texto = str(r["sala_nome"]) + " - " + h_fmt
				
				# Adiciona na lista
				var index = lista_reservas.add_item(texto)
				
				# --- O TRUQUE: Guardar o ID no item para usar depois ---
				lista_reservas.set_item_metadata(index, r["id"])
	
	elif acao_atual == "EXCLUIR":
		if code == 200:
			label_status.text = "Reserva cancelada!"
			carregar_reservas()
		else:
			# --- MUDANÇA AQUI PARA VER O ERRO ---
			var msg_erro = "Erro: " + str(code)
			if json and json.has("mensagem"):
				msg_erro += "\n" + json["mensagem"]
			
			label_status.text = msg_erro
			print("ERRO DETALHADO: ", code, body.get_string_from_utf8())

func _on_btn_voltar_pressed():
	# Ajuste para o nome da sua cena principal ou de menu
	get_tree().change_scene_to_file("res://tela_reserva.tscn")
