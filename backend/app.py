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
    senha = db.Column(db.String(100)) # Em produção, usaríamos hash!

# --- CRIAÇÃO DO BANCO E DADOS INICIAIS ---
with app.app_context():
    db.create_all()
    # Verifica se já existe usuário, se não, cria um de teste
    if not Usuario.query.filter_by(email="aluno@uerj.br").first():
        admin = Usuario(nome="Marcos", email="aluno@uerj.br", senha="123")
        db.session.add(admin)
        db.session.commit()
        print("--- Usuário de Teste Criado: aluno@uerj.br / 123 ---")

# --- ROTAS ---
@app.route('/teste', methods=['GET'])
def teste():
    return jsonify({"status": "Servidor Online"})

# US01: Rota de Login
@app.route('/login', methods=['POST'])
def login():
    dados = request.get_json() # Pega o JSON que o Godot mandou
    email_recebido = dados.get('email')
    senha_recebida = dados.get('senha')

    # Busca no banco
    usuario = Usuario.query.filter_by(email=email_recebido).first()

    if usuario and usuario.senha == senha_recebida:
        return jsonify({
            "sucesso": True,
            "mensagem": "Login realizado!",
            "usuario_id": usuario.id,
            "usuario_nome": usuario.nome
        }), 200
    else:
        return jsonify({
            "sucesso": False,
            "mensagem": "Email ou senha incorretos."
        }), 401

if __name__ == '__main__':
    app.run(debug=True, port=5000)