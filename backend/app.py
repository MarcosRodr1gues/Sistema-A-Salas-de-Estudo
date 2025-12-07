from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
CORS(app)

# --- Configuração do Banco ---
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'instance', 'banco.db')
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
            "is_admin": True # <--- Flag importante para o Godot
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
        item = {
            "id": r.id,
            "sala_nome": sala.nome,
            "horario": r.horario
        }
        lista_retorno.append(item)
        
    return jsonify(lista_retorno)

# --- NOVAS ROTAS DE ADMIN ---

# 6. Listar TODAS as reservas (Para o painel do Admin)
@app.route('/admin/todas_reservas', methods=['GET'])
def get_todas_reservas():
    # Faz uma query cruzando as tabelas (JOIN)
    # Queremos: Dados da Reserva + Nome da Sala + Nome do Usuário
    
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
@app.route('/admin/excluir_reserva/<int:reserva_id>', methods=['DELETE']) # Usamos DELETE ou POST
def excluir_reserva(reserva_id):
    reserva = Reserva.query.get(reserva_id)
    
    if reserva:
        db.session.delete(reserva)
        db.session.commit()
        return jsonify({"sucesso": True, "mensagem": "Reserva removida com sucesso"})
    else:
        return jsonify({"sucesso": False, "mensagem": "Reserva não encontrada"}), 404

if __name__ == '__main__':
    app.run(debug=True, port=5000)