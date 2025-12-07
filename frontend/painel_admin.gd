extends Control

# --- REFERÊNCIAS AOS NÓS ---
@onready var lista_admin: ItemList = $VBoxContainer/ItemList
@onready var btn_excluir: Button = $VBoxContainer/BtnExcluir
@onready var btn_sair: Button = $VBoxContainer/BtnSair
@onready var label_status: Label = $VBoxContainer/LabelStatus

# Se o HTTPRequest estiver na raiz da cena:
@onready var http: HTTPRequest = $HTTPRequest

# Variável para controlar o que estamos fazendo
var acao_atual = "" 

func _ready():
	# Conexões
	if btn_excluir: btn_excluir.pressed.connect(_on_btn_excluir_pressed)
	if btn_sair: btn_sair.pressed.connect(_on_btn_sair_pressed)
	if http: http.request_completed.connect(_on_request_completed)
	
	# Carrega a lista ao abrir
	carregar_lista()

func carregar_lista():
	acao_atual = "LISTAR"
	label_status.text = "Atualizando lista..."
	lista_admin.clear()
	
	# Chama a rota de admin
	http.request("http://127.0.0.1:5000/admin/todas_reservas")

func _on_btn_excluir_pressed():
	if lista_admin.get_selected_items().size() == 0:
		label_status.text = "Selecione uma reserva para excluir."
		return
	
	var index = lista_admin.get_selected_items()[0]
	var id_reserva = lista_admin.get_item_metadata(index)
	
	print("Excluindo reserva ID: ", id_reserva)
	
	acao_atual = "EXCLUIR"
	label_status.text = "Excluindo..."
	
	# Adicionamos int(...) para remover o .0
	var url = "http://127.0.0.1:5000/admin/excluir_reserva/" + str(int(id_reserva))
	http.request(url, [], HTTPClient.METHOD_DELETE)

func _on_request_completed(result, code, headers, body):
	if code != 200 and code != 201:
		label_status.text = "Erro no servidor: " + str(code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if acao_atual == "LISTAR":
		if json == null:
			label_status.text = "Erro na leitura dos dados."
		elif json.size() == 0:
			label_status.text = "Nenhuma reserva no sistema."
		else:
			label_status.text = ""
			for item in json:
				# --- FORMATAÇÃO DE HORA BONITA ---
				var h_float = float(item["horario"])
				var h_int = int(h_float)
				var horario_fmt = "%02d:00" % h_int # Transforma 8 em "08:00"
				
				# Texto final da linha
				var texto = str(item["sala_nome"]) + " - " + horario_fmt + " | Aluno: " + str(item["usuario_nome"])
				
				var index = lista_admin.add_item(texto)
				
				# Guarda o ID real para podermos excluir depois
				lista_admin.set_item_metadata(index, item["reserva_id"])
	
	elif acao_atual == "EXCLUIR":
		if json.get("sucesso") == true:
			label_status.text = "Reserva removida!"
			carregar_lista() # Recarrega a lista
		else:
			label_status.text = "Erro ao excluir."

func _on_btn_sair_pressed():
	Global.usuario_id = 0
	Global.is_admin = false
	
	# --- VOLTA IMEDIATA (SEM TRANSIÇÃO) ---
	get_tree().change_scene_to_file("res://main.tscn")
