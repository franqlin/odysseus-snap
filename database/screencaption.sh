# Função para criar a tabela screencaption no banco de dados screencaption-db
criar_tabela_screencaption() {
    db_path="$pasta/screencaption-db.db"
    sqlite3 "$db_path" <<EOF
CREATE TABLE IF NOT EXISTS screencaption (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT NOT NULL,
    basepath TEXT NOT NULL,
    hash TEXT NOT NULL,
    description TEXT,
    type INTERGER NOT NULL,
    urlRegistro TEXT  NULL   
);
EOF
    echo "Tabela screencaption criada no banco de dados screencaption-db.db."
}
salvar_dados_tabela() {

    local  db_path="$pasta/screencaption-db.db"


    # Verifica se o banco de dados existe
    if [ ! -f "$db_path" ]; then
        echo "Banco de dados '$db_path' não encontrado. Criando banco de dados..."
        criar_tabela_screencaption
    fi

  
        local filename="$1"
        local basepath="$2"
        local hash="$3"
        local description="$4"
        local type="$5"
        local urlRegistro="$6"
        
        # Comando SQL para inserir os dados na tabela screenshot
        sqlite3 $pasta/screencaption-db.db <<EOF
INSERT INTO screencaption (filename, basepath, hash, description,type,urlRegistro)
VALUES ('$filename','$basepath', '$hash', '$description', '$type','$urlRegistro');
EOF
}

exibir_dados_tabela_screen() {
    db_path="$pasta/screencaption-db.db"
    dados=$(sqlite3 "$db_path" "SELECT id, filename, basepath, hash, description, urlRegistro FROM screencaption;")
    
    # Cria um arquivo temporário para passar os dados ao script Python
    temp_file=$(mktemp)
    echo "$dados" > "$temp_file"
    
    # Chama o script Python para exibir os dados e capturar a seleção
    selected=$(python3 - <<EOF
import sys
import tkinter as tk
from tkinter import ttk
import os
import subprocess

# Lê os dados do arquivo temporário
temp_file = "$temp_file"
with open(temp_file, "r") as f:
    data = [line.strip().split("|") for line in f if line.strip()]

# Função para capturar a seleção para edição
def on_edit():
    global selected
    selected = tree.item(tree.selection())["values"]
    action.set("edit")
    root.destroy()

# Função para capturar a seleção para exclusão
def on_delete():
    global selected
    selected = tree.item(tree.selection())["values"]
    action.set("delete")
    root.destroy()

# Função para abrir o arquivo selecionado
def on_open(event):
    selected = tree.item(tree.selection())["values"]
    if selected:
        basepath, filename = selected[2], selected[1]
        filepath = os.path.join(basepath, filename)
        if os.path.exists(filepath):
            subprocess.run(["xdg-open", filepath])
        else:
            print(f"Arquivo não encontrado: {filepath}")

root = tk.Tk()
root.title("Dados da Tabela Screencaption")
root.geometry("800x600")  # Aumenta o tamanho da janela

style = ttk.Style()
style.configure("Treeview.Heading", font=("Arial", 12, "bold"))
style.configure("Treeview", font=("Arial", 10))

tree = ttk.Treeview(root, columns=("ID", "Filename", "Basepath", "Hash", "Description", "URL Registro"), show="headings", height=20)
tree.heading("ID", text="ID")
tree.heading("Filename", text="Filename")
tree.heading("Basepath", text="Basepath")
tree.heading("Hash", text="Hash")
tree.heading("Description", text="Description")
tree.heading("URL Registro", text="URL Registro")
tree.column("ID", width=50, anchor="center")  # Campo ID pequeno
tree.column("Filename", width=200, anchor="w")  # Campo Filename
tree.column("Basepath", width=200, anchor="w")  # Campo Basepath
tree.column("Hash", width=150, anchor="w")  # Campo Hash
tree.column("Description", width=200, anchor="w")  # Campo Description
tree.column("URL Registro", width=200, anchor="w")  # Campo URL Registro
tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

for row in data:
    tree.insert("", tk.END, values=row)

action = tk.StringVar()

# Adiciona evento de duplo clique para abrir o arquivo
tree.bind("<Double-1>", on_open)

button_frame = tk.Frame(root)
button_frame.pack(side=tk.BOTTOM, fill=tk.X, padx=10, pady=10)

button_edit = tk.Button(button_frame, text="Editar", command=on_edit, font=("Arial", 12), bg="#4CAF50", fg="white")
button_edit.pack(side=tk.RIGHT, padx=5)

button_delete = tk.Button(button_frame, text="Deletar", command=on_delete, font=("Arial", 12), bg="#F44336", fg="white")
button_delete.pack(side=tk.RIGHT, padx=5)

root.mainloop()

if "selected" in globals():
    print(action.get() + "|" + "|".join(map(str, selected)))
EOF
)


    # Remove o arquivo temporário
    rm "$temp_file"

    # Verifica se algo foi selecionado
    if [ -n "$selected" ]; then
        action=$(echo "$selected" | cut -d'|' -f1)
        data=$(echo "$selected" | cut -d'|' -f2-)
        if [ "$action" = "edit" ]; then
            editar_dados_tabela_screen "$data"
        elif [ "$action" = "delete" ]; then
            deletar_dados_tabela_screen "$data"
        fi
    fi
}



deletar_dados_tabela_screen(){
    janela=$(yad --info --text="Deseja deletar o arquivo" --button="gtk-cancel:1" --button="gtk-ok:0")
    button=$?
    if [ "$button" -eq 0 ]; then
        
    IFS="|" read -r id  <<< "$1"
    echo "Linha recebida: $1"
   
    # Extraindo o valor do id da linha recebida, considerando que os campos são separados por "|"
    id=$(echo "$1" | cut -d'|' -f1)

    echo "Parametro id: $id"
    sqlite3 "$pasta/screencaption-db.db" <<EOF
DELETE FROM screencaption WHERE id=$id;
EOF
    yad --info --text="Registro deletado com sucesso !" --button="OK"
    gravar_log "Dados da Tabela Screencaption" "Registro deletado com sucesso! $id"
    
    else
        yad --info --text="Registro não deletado!" --button="OK"
    fi  
}



editar_dados_tabela_screen() {
    IFS="|" read -r id <<< "$1"
    echo "Linha recebida: $1"
   
    # Extraindo o valor do id da linha recebida, considerando que os campos são separados por "|"
    id=$(echo "$1" | cut -d'|' -f1)
    echo "Parametro id: $id"
    # Busca os valores atuais dos campos para o registro com o id fornecido
    record=$(sqlite3 "$pasta/screencaption-db.db" "SELECT filename, basepath, hash, description, urlRegistro FROM screencaption WHERE id=$id;")
    IFS="|" read -r filename_ basepath_ hash_ description_ urlRegistro_ <<< "$record"
    echo "Dados atuais do registro:"
    echo "Filename: $filename_"
    echo "Basepath: $basepath_"
    echo "Hash: $hash_"
    echo "Description: $description_"
    echo "URL Registro: $urlRegistro_"

    # Chama o script Python para abrir a janela de edição
    edited=$(python3 - <<EOF
import tkinter as tk
from tkinter import ttk

def save_changes():
    global edited_data
    edited_data = {
        "description": description_var.get(),
        "urlRegistro": urlRegistro_var.get()
    }
    root.destroy()

root = tk.Tk()
root.title("Editar Dados")
root.geometry("900x400")  # Aumenta o tamanho da janela

# Estilo personalizado
style = ttk.Style()
style.configure("TLabel", font=("Arial", 12))
style.configure("TEntry", font=("Arial", 12))
style.configure("TButton", font=("Arial", 12, "bold"), background="#4CAF50", foreground="white")

# Frame principal
frame = ttk.Frame(root, padding="20")
frame.pack(fill=tk.BOTH, expand=True)

# Labels e valores apenas para exibição
ttk.Label(frame, text="Filename:", style="TLabel").grid(row=0, column=0, sticky="w", padx=10, pady=5)
ttk.Label(frame, text="$filename_", style="TLabel").grid(row=0, column=1, sticky="w", padx=10, pady=5)

ttk.Label(frame, text="Basepath:", style="TLabel").grid(row=1, column=0, sticky="w", padx=10, pady=5)
ttk.Label(frame, text="$basepath_", style="TLabel").grid(row=1, column=1, sticky="w", padx=10, pady=5)

ttk.Label(frame, text="Hash:", style="TLabel").grid(row=2, column=0, sticky="w", padx=10, pady=5)
ttk.Label(frame, text="$hash_", style="TLabel").grid(row=2, column=1, sticky="w", padx=10, pady=5)

# Campos editáveis
ttk.Label(frame, text="Description:", style="TLabel").grid(row=3, column=0, sticky="w", padx=10, pady=5)
description_var = tk.StringVar(value="$description_")
ttk.Entry(frame, textvariable=description_var, width=50).grid(row=3, column=1, padx=10, pady=5)

ttk.Label(frame, text="URL Registro:", style="TLabel").grid(row=4, column=0, sticky="w", padx=10, pady=5)
urlRegistro_var = tk.StringVar(value="$urlRegistro_")
ttk.Entry(frame, textvariable=urlRegistro_var, width=50).grid(row=4, column=1, padx=10, pady=5)

# Botão para salvar
ttk.Button(frame, text="Salvar", command=save_changes).grid(row=5, column=1, pady=20, sticky="e")

root.mainloop()

if "edited_data" in globals():
    print(f"{edited_data['description']}|{edited_data['urlRegistro']}")
EOF
)

    if [ -z "$edited" ]; then
        echo "Edição cancelada."
        return
    fi

    IFS="|" read -r description urlRegistro <<< "$edited"
    # Atualiza os dados no banco de dados
    echo "Dados Editados:"
    echo "Description: $description"
    echo "URL Registro: $urlRegistro"
    sqlite3 "$pasta/screencaption-db.db" <<EOF
UPDATE screencaption SET description='$description', urlRegistro='$urlRegistro' WHERE id=$id;
EOF

    yad --info --text="Dados atualizados com sucesso!" --button="OK"
    gravar_log "Dados da Tabela Screencaption" "Dados atualizados com sucesso! $description $urlRegistro"
}