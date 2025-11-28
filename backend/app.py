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
        admin = Usuario(nome="Marcos", email="aluno@uerj.br", senha="123")
        db.session.add(admin)
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

# 1. Login (Mantido da Sprint anterior)
@app.route('/login', methods=['POST'])
def login():
    dados = request.get_json()
    usuario = Usuario.query.filter_by(email=dados.get('email')).first()
    if usuario and usuario.senha == dados.get('senha'):
        return jsonify({"sucesso": True, "usuario_id": usuario.id, "usuario_nome": usuario.nome}), 200
    return jsonify({"sucesso": False, "mensagem": "Dados incorretos"}), 401

# 2. Listar Salas (Para o Godot saber o que mostrar)
@app.route('/salas', methods=['GET'])
def get_salas():
    salas = Sala.query.all()
    lista = [{"id": s.id, "nome": s.nome} for s in salas]
    return jsonify(lista)

# 3. Listar Horários Ocupados de uma Sala
@app.route('/reservas/<int:sala_id>', methods=['GET'])
def get_reservas(sala_id):
    # Retorna lista de horários já ocupados (ex: [10, 14, 16])
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

    # Verifica se já existe reserva naquele horário
    conflito = Reserva.query.filter_by(sala_id=sid, horario=hora).first()
    if conflito:
        return jsonify({"sucesso": False, "mensagem": "Horário já ocupado!"}), 409
    
    nova_reserva = Reserva(usuario_id=uid, sala_id=sid, horario=hora)
    db.session.add(nova_reserva)
    db.session.commit()
    
    return jsonify({"sucesso": True, "mensagem": "Reserva confirmada!"}), 201

if __name__ == '__main__':
    app.run(debug=True, port=5000)