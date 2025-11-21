## 🗓️ Cronograma de Desenvolvimento (Sprints)

O projeto segue a metodologia Scrum, dividido em 5 Sprints de 1 semana.

### **Sprint 1 – Definição do Projeto**
- **Objetivo:** Definir escopo, requisitos e plano de desenvolvimento.
- **Entregáveis:**
  - [x] Proposta completa.
  - [x] Criação do repositório GitHub.
  - [x] Backlog inicial definido (Prioridade: US01, US04, US05).
  - [x] Cronograma de Sprints.

### **Sprint 2 – Protótipo e Estrutura Inicial (Arquitetura)**
- **Objetivo:** Provar a comunicação Cliente (Godot) ↔ Servidor (Flask).
- **Entregáveis:**
  - [x] Backend (Flask): API rodando com endpoint de teste.
  - [x] Backend (Flask): Configuração do banco SQLite com SQLAlchemy.
  - [x] Frontend (Godot): Cena com `HTTPRequest` funcional.
  - [x] Protótipo: Botão no Godot que consome dados da API Flask.

### **Sprint 3 – Funcionalidades Principais (Core)**
- **Objetivo:** Implementar fluxo de Autenticação e Reservas.
- **Entregáveis:**
  - [ ] **Backend:** Criar endpoints `/login` (US01) e `/reservar` (US04).
  - [ ] **Frontend:** Cena de Login funcional.
  - [ ] **Frontend:** Grade de horários interativa para realizar reservas.
  - [ ] **Integração:** Login real e persistência de reservas no banco.

### **Sprint 4 – Integração e Refinamento**
- **Objetivo:** Concluir fluxo do aluno e Administrativo.
- **Entregáveis:**
  - [ ] **Backend:** Endpoints `/minhas-reservas` e painel Admin.
  - [ ] **Frontend:** Tela "Minhas Reservas" (US05).
  - [ ] **Frontend:** (Se houver tempo) Tela de Admin para gerenciar salas.
  - [ ] **Design:** Polimento visual da interface.

### **Sprint 5 – Testes e Entrega Final**
- **Objetivo:** Garantir qualidade e entregar o produto.
- **Entregáveis:**
  - [ ] Testes ponta-a-ponta (Segurança e Fluxo).
  - [ ] Manual do usuário (Como rodar Server + Client).
  - [ ] Apresentação Final.