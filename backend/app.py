import sys
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy

# --- O TRUQUE DO DIRETÓRIO ---
if getattr(sys, 'frozen', False):
    # Se for executável .exe
    pasta_atual = os.path.dirname(sys.executable)
else:
    # Se for script .py
    pasta_atual = os.path.dirname(os.path.abspath(__file__))

# Muda o diretório de trabalho para a pasta do arquivo
os.chdir(pasta_atual)

print(f"--- RODANDO NA PASTA: {os.getcwd()} ---")

app = Flask(__name__)
CORS(app)

# Como já mudamos de pasta com o chdir, podemos usar caminho relativo simples!
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///banco.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# --- MODELOS (Tabelas) ---
class Usuario(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100))
    email = db.Column(db.String(100), unique=True)
    senha = db.Column(db.String(100))

class Sala(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100))

class Reserva(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuario.id'))
    sala_id = db.Column(db.Integer, db.ForeignKey('sala.id'))
    horario = db.Column(db.Integer) # Ex: 10 representa 10:00

# --- INICIALIZAÇÃO DO BANCO ---
with app.app_context():
    db.create_all()
    
    # Criar usuário de teste se não existir
    if not Usuario.query.filter_by(email="aluno@uerj.br").first():
        aluno = Usuario(nome="Marcos", email="aluno@uerj.br", senha="123")
        db.session.add(aluno)
        db.session.commit()
    
    # Criar Salas de teste se não existirem
    if not Sala.query.first():
        s1 = Sala(nome="Sala de Estudos 01")
        s2 = Sala(nome="Sala de Reunião A")
        s3 = Sala(nome="Lab. de Informática")
        db.session.add_all([s1, s2, s3])
        db.session.commit()
        print("--- Salas Criadas com Sucesso ---")

# --- ROTAS ---

# 1. Login (ATUALIZADO COM ADMIN)
@app.route('/login', methods=['POST'])
def login():
    dados = request.get_json()
    email_recebido = dados.get('email')
    senha_recebida = dados.get('senha')

    # --- LÓGICA DO ADMIN ---
    if email_recebido == "admin@uerj.br" and senha_recebida == "123":
        return jsonify({
            "sucesso": True, 
            "usuario_id": 9999, 
            "usuario_nome": "Administrador",
            "is_admin": True 
        }), 200

    # --- LÓGICA DO ALUNO NORMAL ---
    usuario = Usuario.query.filter_by(email=email_recebido).first()
    if usuario and usuario.senha == senha_recebida:
        return jsonify({
            "sucesso": True, 
            "usuario_id": usuario.id, 
            "usuario_nome": usuario.nome,
            "is_admin": False
        }), 200
    
    return jsonify({"sucesso": False, "mensagem": "Dados incorretos"}), 401

# 2. Listar Salas
@app.route('/salas', methods=['GET'])
def get_salas():
    salas = Sala.query.all()
    lista = [{"id": s.id, "nome": s.nome} for s in salas]
    return jsonify(lista)

# 3. Listar Horários Ocupados de uma Sala
@app.route('/reservas/<int:sala_id>', methods=['GET'])
def get_reservas(sala_id):
    reservas = Reserva.query.filter_by(sala_id=sala_id).all()
    ocupados = [r.horario for r in reservas]
    return jsonify(ocupados)

# 4. Fazer Reserva
@app.route('/reservar', methods=['POST'])
def criar_reserva():
    dados = request.get_json()
    uid = dados.get('usuario_id')
    sid = dados.get('sala_id')
    hora = dados.get('horario')

    conflito = Reserva.query.filter_by(sala_id=sid, horario=hora).first()
    if conflito:
        return jsonify({"sucesso": False, "mensagem": "Horário já ocupado!"}), 409
    
    nova_reserva = Reserva(usuario_id=uid, sala_id=sid, horario=hora)
    db.session.add(nova_reserva)
    db.session.commit()
    
    return jsonify({"sucesso": True, "mensagem": "Reserva confirmada!"}), 201

# 5. Listar Minhas Reservas (Aluno)
@app.route('/minhas_reservas/<int:usuario_id>', methods=['GET'])
def minhas_reservas(usuario_id):
    reservas = Reserva.query.filter_by(usuario_id=usuario_id).all()
    
    lista_retorno = []
    for r in reservas:
        sala = Sala.query.get(r.sala_id)
        # Proteção caso a sala tenha sido deletada manualmente sem limpar reservas
        nome_sala = sala.nome if sala else "Sala Removida"
        
        item = {
            "id": r.id,
            "sala_nome": nome_sala,
            "horario": r.horario
        }
        lista_retorno.append(item)
        
    return jsonify(lista_retorno)

# --- NOVAS ROTAS DE ADMIN ---

# 6. Listar TODAS as reservas
@app.route('/admin/todas_reservas', methods=['GET'])
def get_todas_reservas():
    # Faz uma query cruzando as tabelas (JOIN)
    resultados = db.session.query(Reserva, Sala, Usuario)\
        .join(Sala, Reserva.sala_id == Sala.id)\
        .join(Usuario, Reserva.usuario_id == Usuario.id)\
        .all()
    
    lista_completa = []
    
    for r, s, u in resultados:
        item = {
            "reserva_id": r.id,
            "horario": r.horario,
            "sala_nome": s.nome,
            "usuario_nome": u.nome,
            "usuario_email": u.email
        }
        lista_completa.append(item)

    return jsonify(lista_completa)

# 7. Excluir Reserva (Admin)
@app.route('/admin/excluir_reserva/<int:reserva_id>', methods=['DELETE'])
def excluir_reserva(reserva_id):
    reserva = Reserva.query.get(reserva_id)
    
    if reserva:
        db.session.delete(reserva)
        db.session.commit()
        return jsonify({"sucesso": True, "mensagem": "Reserva removida com sucesso"})
    else:
        return jsonify({"sucesso": False, "mensagem": "Reserva não encontrada"}), 404

# 8. Excluir Minha Reserva (Aluno)
@app.route('/minhas_reservas/excluir/<int:reserva_id>', methods=['DELETE'])
def excluir_minha_reserva(reserva_id):
    reserva = Reserva.query.get(reserva_id)
    
    if reserva:
        db.session.delete(reserva)
        db.session.commit()
        return jsonify({"sucesso": True, "mensagem": "Reserva cancelada com sucesso"})
    else:
        return jsonify({"sucesso": False, "mensagem": "Reserva não encontrada"}), 404

# --- NOVAS ROTAS PARA GERENCIAR SALAS (USO FUTURO) ---

# 9. Criar Sala (Admin)
@app.route('/admin/salas', methods=['POST'])
def criar_sala():
    dados = request.get_json()
    nome_sala = dados.get('nome')
    
    if not nome_sala:
         return jsonify({"sucesso": False, "mensagem": "Nome da sala é obrigatório"}), 400

    nova_sala = Sala(nome=nome_sala)
    db.session.add(nova_sala)
    db.session.commit()
    return jsonify({"sucesso": True, "mensagem": "Sala criada com sucesso!"}), 201

# 10. Excluir Sala (Admin)
@app.route('/admin/salas/<int:sala_id>', methods=['DELETE'])
def deletar_sala(sala_id):
    sala = Sala.query.get(sala_id)
    
    if not sala:
        return jsonify({"sucesso": False, "mensagem": "Sala não encontrada"}), 404

    # IMPORTANTE: Primeiro excluímos todas as reservas desta sala
    # para não deixar "lixo" no banco de dados.
    Reserva.query.filter_by(sala_id=sala_id).delete()
    
    # Agora excluímos a sala
    db.session.delete(sala)
    db.session.commit()
    return jsonify({"sucesso": True, "mensagem": "Sala e suas reservas foram removidas!"}), 200

if __name__ == '__main__':
    # O try/except ajuda a manter a janela aberta em caso de erro no .exe
    try:
        print("Iniciando servidor...")
        app.run(debug=True, port=5000)
    except Exception as e:
        print("\nERRO CRÍTICO NO SERVIDOR:")
        print(e)
        input("Pressione ENTER para sair...")