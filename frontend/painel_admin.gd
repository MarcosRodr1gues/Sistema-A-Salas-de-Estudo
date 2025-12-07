extends Control

# --- ABA 1: RESERVAS ---
@onready var lista_reservas: ItemList = $"TabContainer/Gerenciar Reservas/ItemList"
@onready var btn_excluir_reserva: Button = $"TabContainer/Gerenciar Reservas/BtnExcluir"
@onready var btn_sair: Button = $"TabContainer/Gerenciar Reservas/BtnSair"
@onready var label_status_reserva: Label = $"TabContainer/Gerenciar Reservas/LabelStatus"

# --- ABA 2: SALAS ---
@onready var input_nome_sala: LineEdit = $"TabContainer/Gerenciar Salas/InputNomeSala"
@onready var btn_add_sala: Button = $"TabContainer/Gerenciar Salas/BtnAdicionarSala"
@onready var lista_salas: ItemList = $"TabContainer/Gerenciar Salas/ListaSalas"
@onready var btn_excluir_sala: Button = $"TabContainer/Gerenciar Salas/BtnExcluirSala"
@onready var label_status_sala: Label = $"TabContainer/Gerenciar Salas/LabelStatusSala"

# --- HTTP REQUESTS SEPARADOS (O Segredo) ---
@onready var http_reservas: HTTPRequest = $HTTPRequest  # O original
@onready var http_salas: HTTPRequest = $HTTPSalas      # O NOVO que você criou

# Controle de fluxo (Só precisa pro Reservas agora, pois Salas tem função própria)
var acao_reserva = "" 
var acao_sala = ""

func _ready():
	# Conexões Botões
	if btn_excluir_reserva: btn_excluir_reserva.pressed.connect(_on_btn_excluir_reserva_pressed)
	if btn_sair: btn_sair.pressed.connect(_on_btn_sair_pressed)
	if btn_add_sala: btn_add_sala.pressed.connect(_on_btn_add_sala_pressed)
	if btn_excluir_sala: btn_excluir_sala.pressed.connect(_on_btn_excluir_sala_pressed)
	
	# --- CONEXÕES HTTP SEPARADAS ---
	# Cada um chama sua própria função de resposta!
	if http_reservas: http_reservas.request_completed.connect(_on_resposta_reservas)
	if http_salas: http_salas.request_completed.connect(_on_resposta_salas)
	
	# Agora podemos chamar os dois ao mesmo tempo sem travar!
	carregar_reservas()
	carregar_salas()

# ========================================================
# LÓGICA DE RESERVAS (Usa http_reservas)
# ========================================================
func carregar_reservas():
	acao_reserva = "LISTAR"
	label_status_reserva.text = "Atualizando..."
	lista_reservas.clear()
	http_reservas.request("http://127.0.0.1:5000/admin/todas_reservas")

func _on_btn_excluir_reserva_pressed():
	if lista_reservas.get_selected_items().size() == 0:
		label_status_reserva.text = "Selecione algo!"
		return
	
	var idx = lista_reservas.get_selected_items()[0]
	var id_reserva = lista_reservas.get_item_metadata(idx)
	
	acao_reserva = "EXCLUIR"
	label_status_reserva.text = "Excluindo..."
	http_reservas.request("http://127.0.0.1:5000/admin/excluir_reserva/" + str(int(id_reserva)), [], HTTPClient.METHOD_DELETE)

# RESPOSTA EXCLUSIVA DE RESERVAS
func _on_resposta_reservas(result, code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if acao_reserva == "LISTAR":
		if json and json.size() > 0:
			label_status_reserva.text = ""
			for item in json:
				var h_fmt = "%02d:00" % int(float(item["horario"]))
				var texto = str(item["sala_nome"]) + " - " + h_fmt + " | " + str(item["usuario_nome"])
				var idx = lista_reservas.add_item(texto)
				lista_reservas.set_item_metadata(idx, item["reserva_id"])
		else:
			label_status_reserva.text = "Nenhuma reserva."
			
	elif acao_reserva == "EXCLUIR":
		if code == 200:
			label_status_reserva.text = "Reserva excluída!"
			carregar_reservas()
		else:
			label_status_reserva.text = "Erro ao excluir."

# ========================================================
# LÓGICA DE SALAS (Usa http_salas)
# ========================================================
func carregar_salas():
	acao_sala = "LISTAR"
	lista_salas.clear()
	# Usa o NOVO nó, que estará livre
	http_salas.request("http://127.0.0.1:5000/salas")

func _on_btn_add_sala_pressed():
	if input_nome_sala.text == "":
		label_status_sala.text = "Digite um nome."
		return
	acao_sala = "CRIAR"
	label_status_sala.text = "Criando..."
	var dados = {"nome": input_nome_sala.text}
	var headers = ["Content-Type: application/json"]
	http_salas.request("http://127.0.0.1:5000/admin/salas", headers, HTTPClient.METHOD_POST, JSON.stringify(dados))

func _on_btn_excluir_sala_pressed():
	if lista_salas.get_selected_items().size() == 0:
		label_status_sala.text = "Selecione uma sala."
		return
	var idx = lista_salas.get_selected_items()[0]
	var id_sala = lista_salas.get_item_metadata(idx)
	
	acao_sala = "EXCLUIR"
	label_status_sala.text = "Excluindo..."
	http_salas.request("http://127.0.0.1:5000/admin/salas/" + str(int(id_sala)), [], HTTPClient.METHOD_DELETE)

# RESPOSTA EXCLUSIVA DE SALAS
func _on_resposta_salas(result, code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if acao_sala == "LISTAR":
		if json:
			for sala in json:
				var idx = lista_salas.add_item(sala["nome"])
				lista_salas.set_item_metadata(idx, sala["id"])
				
	elif acao_sala == "CRIAR":
		if code == 201:
			label_status_sala.text = "Sala criada!"
			input_nome_sala.text = ""
			carregar_salas()
		else:
			label_status_sala.text = "Erro ao criar."

	elif acao_sala == "EXCLUIR":
		if code == 200:
			label_status_sala.text = "Sala removida!"
			carregar_salas()
			carregar_reservas() # Atualiza reservas pois pode ter apagado alguma
		else:
			label_status_sala.text = "Erro ao excluir."

func _on_btn_sair_pressed():
	Global.usuario_id = 0
	Global.is_admin = false
	get_tree().change_scene_to_file("res://main.tscn")
