from flask import Flask, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy # <--- Importamos a ferramenta
import os

app = Flask(__name__)
CORS(app)

# --- Configuração do Banco de Dados ---
# Define que o arquivo banco.db ficará na pasta 'instance' dentro do backend
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///banco.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app) # <--- Inicializa a conexão

# Modelo de Teste (Só para o banco não ficar vazio)
class Usuario(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(50))

# --- Mágica: Cria o arquivo do banco se ele não existir ---
with app.app_context():
    db.create_all()

# Rota de teste
@app.route('/teste', methods=['GET'])
def teste_conexao():
    return jsonify({
        "mensagem": "Banco de dados configurado com sucesso!",
        "status": "sucesso"
    })

if __name__ == '__main__':
    app.run(debug=True, port=5000)