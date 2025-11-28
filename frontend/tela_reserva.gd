extends Control

# --- CAMINHOS CERTOS PARA SUA TELA DE RESERVA ---
@onready var container_principal = $ContainerPrincipal
@onready var btn_salas = $ContainerPrincipal/BtnSalas
@onready var btn_horario = $ContainerPrincipal/BtnHorario
@onready var btn_reservar = $ContainerPrincipal/BtnReservar
@onready var label_status = $ContainerPrincipal/LabelStatus

# --- CAMINHOS DOS HTTPs (Estão fora do Container) ---
@onready var http_salas = $HTTPSalas
@onready var http_reservar = $HTTPReservar

func _ready():
	# 1. Busca as salas assim que abre a tela
	label_status.text = "Buscando salas..."
	http_salas.request_completed.connect(_on_salas_carregadas)
	http_salas.request("http://127.0.0.1:5000/salas")
	
	# 2. Conecta o botão de reservar
	btn_reservar.pressed.connect(_on_btn_reservar_pressed)
	http_reservar.request_completed.connect(_on_reserva_concluida)

	# 3. Preenche o menu de horários (das 8h às 18h)
	btn_horario.clear()
	for i in range(8, 19):
		var texto = str(i) + ":00"
		btn_horario.add_item(texto, i)

# --- QUANDO AS SALAS CHEGAM DO PYTHON ---
func _on_salas_carregadas(result, code, headers, body):
	if code == 200:
		var lista_salas = JSON.parse_string(body.get_string_from_utf8())
		btn_salas.clear()
		for sala in lista_salas:
			btn_salas.add_item(sala["nome"], sala["id"])
		label_status.text = "Pronto."
	else:
		label_status.text = "Erro ao carregar salas."

# --- QUANDO CLICA EM RESERVAR ---
func _on_btn_reservar_pressed():
	if btn_salas.selected == -1:
		label_status.text = "Selecione uma sala!"
		return
		
	var sala_id = btn_salas.get_item_id(btn_salas.selected)
	var horario = btn_horario.get_selected_id()
	
	if horario == -1:
		label_status.text = "Escolha um horário!"
		return
	
	label_status.text = "Reservando..."
	
	var dados = {
		"usuario_id": Global.usuario_id,
		"sala_id": sala_id,
		"horario": int(horario)
	}
	var headers = ["Content-Type: application/json"]
	
	http_reservar.request("http://127.0.0.1:5000/reservar", headers, HTTPClient.METHOD_POST, JSON.stringify(dados))

# --- RESULTADO DA RESERVA ---
func _on_reserva_concluida(result, code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if code == 201:
		label_status.text = "SUCESSO: " + json["mensagem"]
	elif code == 409:
		label_status.text = "ERRO: " + json["mensagem"]
	else:
		label_status.text = "Erro: " + str(code)
