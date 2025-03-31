#!/bin/bash

abrir_formulario() {
    python3 <<EOF
import sqlite3
from tkinter import Tk, Label, Entry, Button, StringVar, messagebox

def salvar_dados(referencia, solicitacao, registro):
    conn = sqlite3.connect("$pasta/reportdata-db.db")
    cursor = conn.cursor()
    cursor.execute("INSERT INTO report (referencia, solicitacao, registro) VALUES (?, ?, ?)", (referencia, solicitacao, registro))
    conn.commit()
    conn.close()
    messagebox.showinfo("Sucesso", "Dados salvos com sucesso!")
    root.destroy()

def alterar_dados(referencia, solicitacao, registro):
    conn = sqlite3.connect("$pasta/reportdata-db.db")
    cursor = conn.cursor()
    cursor.execute("UPDATE report SET referencia=?, solicitacao=?, registro=? WHERE id=1", (referencia, solicitacao, registro))
    conn.commit()
    conn.close()
    messagebox.showinfo("Sucesso", "Dados alterados com sucesso!")
    root.destroy()

conn = sqlite3.connect("$pasta/reportdata-db.db")
cursor = conn.cursor()
cursor.execute("SELECT COUNT(*) FROM report WHERE id=1")
registro_existente = cursor.fetchone()[0]

root = Tk()
from tkinter import ttk

root.title("Formulário de Registro")
root.geometry("500x400")
root.configure(bg="#f0f0f0")

style = ttk.Style()
style.configure("TLabel", background="#f0f0f0", font=("Arial", 12), anchor="w")
style.configure("TEntry", font=("Arial", 12))
style.configure("TButton", font=("Arial", 12), padding=10)

ttk.Label(root, text="Referência:", anchor="w").pack(pady=(10, 2), fill="x", padx=10)
referencia_var = StringVar()
referencia_entry = ttk.Entry(root, textvariable=referencia_var, width=50)
referencia_entry.pack(pady=(0, 10), padx=10)

ttk.Label(root, text="Solicitação:", anchor="w").pack(pady=(10, 2), fill="x", padx=10)
solicitacao_var = StringVar()
solicitacao_entry = ttk.Entry(root, textvariable=solicitacao_var, width=50)
solicitacao_entry.pack(pady=(0, 10), padx=10)

ttk.Label(root, text="Registro:", anchor="w").pack(pady=(10, 2), fill="x", padx=10)
registro_var = StringVar()
registro_entry = ttk.Entry(root, textvariable=registro_var, width=50)
registro_entry.pack(pady=(0, 10), padx=10)

if registro_existente > 0:
    cursor.execute("SELECT referencia, solicitacao, registro FROM report WHERE id=1")
    alterar_registro = cursor.fetchone()
    referencia_var.set(alterar_registro[0])
    solicitacao_var.set(alterar_registro[1])
    registro_var.set(alterar_registro[2])
    Button(root, text="Salvar Alterações", command=lambda: alterar_dados(referencia_var.get(), solicitacao_var.get(), registro_var.get()), font=("Arial", 12), bg="#4CAF50", fg="white").pack(pady=10)
else:
    Button(root, text="Salvar", command=lambda: salvar_dados(referencia_var.get(), solicitacao_var.get(), registro_var.get()), font=("Arial", 12), bg="#4CAF50", fg="white").pack(pady=10)

conn.close()
root.mainloop()
EOF
gravar_log "Formulário de Registro" "Dados do formulário foram salvos com sucesso."
}
